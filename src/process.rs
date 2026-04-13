use crate::error::AppError;
use crate::notify::notify_error;
use std::fmt;
use std::{
    net::{TcpStream, ToSocketAddrs},
    os::unix::fs::PermissionsExt,
    path::Path,
    process::{Child, Command, ExitStatus},
    sync::{Mutex, MutexGuard},
    thread,
    time::{Duration, Instant},
};
use url::Url;

use nix::{
    sys::signal::{kill, Signal},
    unistd::Pid,
};

pub fn verify_dependencies(process_paths: &[String]) -> Result<(), AppError> {
    let missing: Vec<String> = process_paths
        .iter()
        .filter(|path| !is_executable(Path::new(path)))
        .cloned()
        .collect();

    if !missing.is_empty() {
        return Err(AppError::MissingDependencies(missing));
    }
    Ok(())
}

fn is_executable(path: &Path) -> bool {
    path.exists()
        && path
            .metadata()
            .map(|meta| meta.permissions().mode() & 0o111 != 0)
            .unwrap_or(false)
}

pub fn is_aw_server_path(path: &str) -> bool {
    Path::new(path)
        .file_name()
        .is_some_and(|name| name == "aw-server")
}

pub fn remove_aw_server_paths(process_paths: &mut Vec<String>) -> usize {
    let initial_len = process_paths.len();
    process_paths.retain(|path| !is_aw_server_path(path));
    initial_len - process_paths.len()
}

pub fn dashboard_port_in_use(dashboard_url: &str) -> bool {
    let Ok(url) = Url::parse(dashboard_url) else {
        return false;
    };
    let Some(host) = url.host_str() else {
        return false;
    };
    let Some(port) = url.port_or_known_default() else {
        return false;
    };

    let addr = format!("{host}:{port}");
    let Ok(addrs) = addr.to_socket_addrs() else {
        return false;
    };

    addrs
        .into_iter()
        .any(|a| TcpStream::connect_timeout(&a, Duration::from_millis(300)).is_ok())
}

pub fn spawn_processes(process_paths: &[String]) -> Result<Vec<ManagedProcess>, AppError> {
    let mut children = Vec::with_capacity(process_paths.len());

    for path in process_paths {
        match Command::new(path).spawn() {
            Ok(child) => {
                log::info!("Started: {path}");
                children.push(ManagedProcess::new(path.clone(), child));
            }
            Err(source) => {
                let msg = format!("Failed to start '{path}': {source}");
                log::error!("{msg}");
                notify_error(&msg);
                shutdown_children_gracefully(&mut children, Duration::from_secs(1));
                return Err(AppError::ProcessSpawn {
                    path: path.clone(),
                    source,
                });
            }
        }
    }

    Ok(children)
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ExitKind {
    Code(i32),
    Signal,
    Unknown,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ProcessStatus {
    Running,
    Stopped(ExitKind),
    Error,
}

impl ProcessStatus {
    pub fn is_running(self) -> bool {
        matches!(self, Self::Running)
    }
}

impl fmt::Display for ProcessStatus {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            ProcessStatus::Running => f.write_str("Running"),
            ProcessStatus::Stopped(ExitKind::Code(code)) => write!(f, "Stopped (exit {code})"),
            ProcessStatus::Stopped(ExitKind::Signal) => f.write_str("Stopped (signal)"),
            ProcessStatus::Stopped(ExitKind::Unknown) => f.write_str("Stopped (?)"),
            ProcessStatus::Error => f.write_str("Error"),
        }
    }
}

#[derive(Debug)]
pub struct ManagedProcess {
    path: String,
    state: Mutex<ManagedProcessState>,
}

#[derive(Debug)]
enum ManagedProcessState {
    Running(Child),
    Stopped(Option<ExitStatus>),
}

impl ManagedProcess {
    pub fn new(path: String, child: Child) -> Self {
        Self {
            path,
            state: Mutex::new(ManagedProcessState::Running(child)),
        }
    }

    pub fn display_name(&self) -> String {
        Path::new(&self.path)
            .file_name()
            .map_or_else(|| self.path.clone(), |n| n.to_string_lossy().into())
    }

    pub fn status(&self) -> ProcessStatus {
        let mut state = self.lock_state();
        match &mut *state {
            ManagedProcessState::Running(child) => match child.try_wait() {
                Ok(None) => ProcessStatus::Running,
                Ok(Some(status)) => {
                    let status_kind = exit_kind(&status);
                    *state = ManagedProcessState::Stopped(Some(status));
                    ProcessStatus::Stopped(status_kind)
                }
                Err(e) => {
                    log::warn!("Failed to check process status for '{}': {e}", self.path);
                    ProcessStatus::Error
                }
            },
            ManagedProcessState::Stopped(status) => {
                ProcessStatus::Stopped(status.as_ref().map_or(ExitKind::Unknown, exit_kind))
            }
        }
    }

    pub fn restart(&self, timeout: Duration) -> Result<(), AppError> {
        self.shutdown(timeout);

        let child = Command::new(&self.path)
            .spawn()
            .map_err(|source| AppError::ProcessSpawn {
                path: self.path.clone(),
                source,
            })?;

        *self.lock_state() = ManagedProcessState::Running(child);
        Ok(())
    }

    pub fn shutdown(&self, timeout: Duration) {
        let old_state = {
            let mut state = self.lock_state();
            std::mem::replace(&mut *state, ManagedProcessState::Stopped(None))
        };

        if let ManagedProcessState::Running(mut child) = old_state {
            shutdown_child_gracefully(&mut child, timeout);
        }
    }

    fn lock_state(&self) -> MutexGuard<'_, ManagedProcessState> {
        self.state.lock().unwrap_or_else(|p| p.into_inner())
    }
}

fn exit_kind(status: &ExitStatus) -> ExitKind {
    match status.code() {
        Some(code) => ExitKind::Code(code),
        None => ExitKind::Signal,
    }
}

pub fn shutdown_child_gracefully(child: &mut Child, timeout: Duration) {
    let pid = Pid::from_raw(child.id() as i32);
    let _ = kill(pid, Signal::SIGTERM);

    let deadline = Instant::now() + timeout;
    while Instant::now() < deadline {
        if let Ok(Some(_)) = child.try_wait() {
            return;
        }
        thread::sleep(Duration::from_millis(100));
    }

    let _ = child.kill();
    let _ = child.wait();
}

pub fn shutdown_children_gracefully(children: &mut [ManagedProcess], timeout: Duration) {
    for child in children {
        child.shutdown(timeout);
    }
}

#[cfg(test)]
mod tests {
    use super::{
        dashboard_port_in_use, is_aw_server_path, remove_aw_server_paths, ExitKind, ProcessStatus,
    };

    #[test]
    fn aw_server_path_detection_uses_binary_name() {
        assert!(is_aw_server_path("/opt/activitywatch/aw-server"));
        assert!(!is_aw_server_path("/opt/activitywatch/aw-server-helper"));
    }

    #[test]
    fn remove_aw_server_paths_keeps_other_processes() {
        let mut paths = vec![
            "/opt/activitywatch/aw-server".to_string(),
            "/usr/bin/awatcher".to_string(),
            "/usr/bin/aw-watcher-media-player".to_string(),
        ];

        let removed = remove_aw_server_paths(&mut paths);

        assert_eq!(removed, 1);
        assert_eq!(paths.len(), 2);
        assert!(paths.iter().all(|p| !is_aw_server_path(p)));
    }

    #[test]
    fn dashboard_port_check_returns_false_for_invalid_url() {
        assert!(!dashboard_port_in_use("not-a-url"));
    }

    #[test]
    fn process_status_display_is_consistent() {
        assert_eq!(ProcessStatus::Running.to_string(), "Running");
        assert_eq!(
            ProcessStatus::Stopped(ExitKind::Code(1)).to_string(),
            "Stopped (exit 1)"
        );
        assert_eq!(
            ProcessStatus::Stopped(ExitKind::Signal).to_string(),
            "Stopped (signal)"
        );
        assert_eq!(
            ProcessStatus::Stopped(ExitKind::Unknown).to_string(),
            "Stopped (?)"
        );
        assert_eq!(ProcessStatus::Error.to_string(), "Error");
    }
}
