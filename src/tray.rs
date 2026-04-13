use crate::config::Config;
use crate::notify::notify_error;
use crate::process::{shutdown_children_gracefully, ManagedProcess, ProcessStatus};
use ksni::{menu::StandardItem, Category, MenuItem, Status, ToolTip, Tray};
use std::{
    process::Command,
    sync::{
        atomic::{AtomicBool, Ordering},
        Arc, RwLock,
    },
    time::Duration,
};

pub struct AwTray {
    pub config: Config,
    pub children: Option<Vec<ManagedProcess>>,
    pub shutdown_requested: Arc<AtomicBool>,
    health: Arc<RwLock<HealthSnapshot>>,
}

impl AwTray {
    pub fn new(
        config: Config,
        children: Option<Vec<ManagedProcess>>,
        shutdown_requested: Arc<AtomicBool>,
    ) -> Self {
        let tray = Self {
            config,
            children,
            shutdown_requested,
            health: Arc::new(RwLock::new(HealthSnapshot::default())),
        };
        tray.refresh_health();
        tray
    }

    pub fn shutdown(&mut self) {
        if let Some(mut children) = self.children.take() {
            log::info!("Shutting down {} managed processes...", children.len());
            shutdown_children_gracefully(&mut children, Duration::from_secs(2));
            log::info!("All processes shut down.");
        }
        self.refresh_health();
    }

    pub fn refresh_health(&self) {
        let snapshot = self.collect_health_snapshot();
        *self.health.write().unwrap_or_else(|p| p.into_inner()) = snapshot;
    }

    fn restart_process(&mut self, index: usize) {
        let Some(process) = self
            .children
            .as_ref()
            .and_then(|children| children.get(index))
        else {
            return;
        };

        if let Err(e) = process.restart(Duration::from_secs(2)) {
            let msg = format!("Failed to restart {}: {}", process.display_name(), e);
            log::error!("{}", msg);
            notify_error(&msg);
        }
    }
}

impl Drop for AwTray {
    fn drop(&mut self) {
        self.shutdown();
    }
}

impl Tray for AwTray {
    fn id(&self) -> String {
        "aw_tray".into()
    }

    fn category(&self) -> Category {
        Category::SystemServices
    }

    fn icon_name(&self) -> String {
        "preferences-system-time".into()
    }

    fn status(&self) -> Status {
        if self.has_attention() {
            Status::NeedsAttention
        } else {
            Status::Active
        }
    }

    fn attention_icon_name(&self) -> String {
        if self.has_attention() {
            "dialog-warning".into()
        } else {
            Default::default()
        }
    }

    fn tool_tip(&self) -> ToolTip {
        let snapshot = self.health_snapshot();
        let stopped_names: Vec<String> = snapshot
            .entries
            .iter()
            .filter(|entry| !entry.status.is_running())
            .map(|entry| format!("{} ({})", entry.name, entry.status))
            .collect();

        let mut description = format!(
            "{} managed process(es), {} running, {} stopped",
            snapshot.total, snapshot.running, snapshot.stopped
        );

        if !stopped_names.is_empty() {
            description.push_str("\nStopped: ");
            description.push_str(&stopped_names.join(", "));
        }

        ToolTip {
            title: "ActivityWatch".into(),
            description,
            ..Default::default()
        }
    }

    fn title(&self) -> String {
        "ActivityWatch".into()
    }

    fn menu(&self) -> Vec<MenuItem<Self>> {
        let snapshot = self.health_snapshot();
        let mut menu = vec![
            StandardItem {
                label: "Managed Processes".into(),
                enabled: false,
                ..Default::default()
            }
            .into(),
            MenuItem::Separator,
            StandardItem {
                label: "Open Dashboard".into(),
                activate: Box::new(|this: &mut AwTray| {
                    if let Err(e) = Command::new("xdg-open")
                        .arg(&this.config.dashboard_url)
                        .spawn()
                    {
                        let msg = format!("Failed to open browser: {}", e);
                        log::error!("{}", msg);
                        notify_error(&msg);
                    }
                }),
                ..Default::default()
            }
            .into(),
        ];

        if let Some(children) = self.children.as_ref() {
            menu.push(MenuItem::Separator);
            for (index, process) in children.iter().enumerate() {
                let status = snapshot
                    .entries
                    .get(index)
                    .map(|entry| entry.status)
                    .unwrap_or(ProcessStatus::Error);
                menu.push(
                    StandardItem {
                        label: format!("Restart {} ({status})", process.display_name()),
                        activate: Box::new(move |tray: &mut AwTray| {
                            tray.restart_process(index);
                        }),
                        ..Default::default()
                    }
                    .into(),
                );
            }
        }

        menu.push(MenuItem::Separator);
        menu.push(
            StandardItem {
                label: "Stop Monitoring".into(),
                activate: Box::new(|tray: &mut AwTray| {
                    tray.shutdown_requested.store(true, Ordering::Relaxed);
                }),
                ..Default::default()
            }
            .into(),
        );

        menu
    }
}

#[derive(Clone, Default)]
struct HealthSnapshot {
    total: usize,
    running: usize,
    stopped: usize,
    entries: Vec<HealthEntry>,
}

#[derive(Clone)]
struct HealthEntry {
    name: String,
    status: ProcessStatus,
}

impl AwTray {
    fn collect_health_snapshot(&self) -> HealthSnapshot {
        let mut running = 0;
        let mut stopped = 0;
        let mut entries = Vec::new();

        if let Some(children) = self.children.as_ref() {
            for child in children {
                let status = child.status();
                if status.is_running() {
                    running += 1;
                } else {
                    stopped += 1;
                }
                entries.push(HealthEntry {
                    name: child.display_name(),
                    status,
                });
            }
        }

        HealthSnapshot {
            total: running + stopped,
            running,
            stopped,
            entries,
        }
    }

    fn health_snapshot(&self) -> HealthSnapshot {
        self.health
            .read()
            .unwrap_or_else(|p| p.into_inner())
            .clone()
    }

    fn has_attention(&self) -> bool {
        self.health_snapshot().stopped > 0
    }
}

#[cfg(test)]
mod tests {
    use super::AwTray;
    use crate::config::Config;
    use crate::process::ManagedProcess;
    use ksni::{MenuItem, Tray};
    use std::{
        process::Command,
        sync::{
            atomic::{AtomicBool, Ordering},
            Arc,
        },
    };

    fn sample_config() -> Config {
        Config {
            dashboard_url: "http://localhost:5600".to_string(),
            health_check_interval_secs: 5,
            process_paths: vec!["/usr/bin/true".to_string()],
        }
    }

    #[test]
    fn menu_contains_core_actions() {
        let tray = AwTray::new(sample_config(), None, Arc::new(AtomicBool::new(false)));

        let labels: Vec<String> = tray
            .menu()
            .into_iter()
            .filter_map(|item| match item {
                MenuItem::Standard(s) => Some(s.label),
                _ => None,
            })
            .collect();

        assert!(labels.iter().any(|l| l == "Managed Processes"));
        assert!(labels.iter().any(|l| l == "Open Dashboard"));
        assert!(labels.iter().any(|l| l == "Stop Monitoring"));
    }

    #[test]
    fn stop_monitoring_item_sets_shutdown_flag() {
        let flag = Arc::new(AtomicBool::new(false));
        let mut tray = AwTray::new(sample_config(), None, Arc::clone(&flag));

        let mut menu = tray.menu();
        for item in &mut menu {
            if let MenuItem::Standard(s) = item {
                if s.label == "Stop Monitoring" {
                    (s.activate)(&mut tray);
                    break;
                }
            }
        }

        assert!(flag.load(Ordering::Relaxed));
    }

    #[test]
    fn menu_includes_restart_item_for_running_process() {
        let child = Command::new("sh")
            .args(["-c", "sleep 1"])
            .spawn()
            .expect("failed to spawn test child");
        let process = ManagedProcess::new("/bin/sleep".to_string(), child);

        let mut tray = AwTray::new(
            sample_config(),
            Some(vec![process]),
            Arc::new(AtomicBool::new(false)),
        );

        let labels: Vec<String> = tray
            .menu()
            .into_iter()
            .filter_map(|item| match item {
                MenuItem::Standard(s) => Some(s.label),
                _ => None,
            })
            .collect();

        assert!(labels.iter().any(|l| l.starts_with("Restart")));
        tray.shutdown();
    }
}
