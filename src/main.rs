mod config;
mod error;
mod notify;
mod process;
mod tray;

use directories::ProjectDirs;
use error::AppError;
use fs2::FileExt;
use ksni::blocking::TrayMethods;
use std::fs::{self, OpenOptions};
use std::sync::{
    atomic::{AtomicBool, Ordering},
    Arc,
};
use std::thread::{self, JoinHandle};
use std::time::Duration;

struct InstanceLock {
    _file: std::fs::File,
}

fn acquire_instance_lock() -> Result<InstanceLock, AppError> {
    let proj_dirs = ProjectDirs::from("", "", "aw-tray").ok_or(AppError::HomeDirNotFound)?;
    let lock_dir = proj_dirs.data_local_dir();
    fs::create_dir_all(lock_dir)?;

    let lock_file = lock_dir.join("aw-tray-control.lock");
    let file = OpenOptions::new()
        .create(true)
        .read(true)
        .write(true)
        .truncate(false)
        .open(lock_file)?;

    match file.try_lock_exclusive() {
        Ok(()) => Ok(InstanceLock { _file: file }),
        Err(e) if e.kind() == std::io::ErrorKind::WouldBlock => Err(AppError::AlreadyRunning),
        Err(e) => Err(AppError::Io(e)),
    }
}

struct AppRuntime {
    _instance_lock: InstanceLock,
    term_flag: Arc<AtomicBool>,
    tray_shutdown_flag: Arc<AtomicBool>,
    tray_handle: ksni::blocking::Handle<tray::AwTray>,
    health_thread: Option<JoinHandle<()>>,
}

impl AppRuntime {
    fn start() -> Result<Self, AppError> {
        let instance_lock = acquire_instance_lock()?;

        let term_flag = Arc::new(AtomicBool::new(false));
        signal_hook::flag::register(signal_hook::consts::SIGTERM, Arc::clone(&term_flag))?;
        signal_hook::flag::register(signal_hook::consts::SIGINT, Arc::clone(&term_flag))?;

        let config = config::load_config()?;

        let mut process_paths = config.process_paths.clone();
        if process::dashboard_port_in_use(&config.dashboard_url) {
            let removed = process::remove_aw_server_paths(&mut process_paths);
            if removed > 0 {
                log::warn!(
                    "External aw-server detected on dashboard port; skipping {removed} managed aw-server entry(ies)."
                );
            }
        }

        process::verify_dependencies(&process_paths)?;
        let children = process::spawn_processes(&process_paths)?;

        let tray_shutdown_flag = Arc::new(AtomicBool::new(false));
        let tray = tray::AwTray::new(
            config.clone(),
            Some(children),
            Arc::clone(&tray_shutdown_flag),
        );

        let tray_handle = tray.spawn()?;

        let health_tray_handle = tray_handle.clone();
        let health_term_flag = Arc::clone(&term_flag);
        let health_tray_shutdown_flag = Arc::clone(&tray_shutdown_flag);
        let health_check_interval = Duration::from_secs(config.health_check_interval_secs);

        let health_thread = thread::spawn(move || {
            while !health_term_flag.load(Ordering::Relaxed)
                && !health_tray_shutdown_flag.load(Ordering::Relaxed)
            {
                thread::sleep(health_check_interval);
                let _ = health_tray_handle.update(|tray: &mut tray::AwTray| tray.refresh_health());
            }
        });

        Ok(Self {
            _instance_lock: instance_lock,
            term_flag,
            tray_shutdown_flag,
            tray_handle,
            health_thread: Some(health_thread),
        })
    }

    fn wait(&self) {
        while !self.term_flag.load(Ordering::Relaxed)
            && !self.tray_shutdown_flag.load(Ordering::Relaxed)
        {
            thread::park_timeout(Duration::from_secs(1));
        }
    }

    fn stop(&mut self) {
        log::info!("Shutting down...");
        self.tray_shutdown_flag.store(true, Ordering::Relaxed);
        self.tray_handle.update(|tray| tray.shutdown());
        self.tray_handle.shutdown().wait();

        if let Some(handle) = self.health_thread.take() {
            let _ = handle.join();
        }
    }
}

fn run() -> Result<(), AppError> {
    env_logger::init();

    let mut runtime = AppRuntime::start()?;
    runtime.wait();
    runtime.stop();

    Ok(())
}

fn main() {
    if let Err(e) = run() {
        log::error!("{e}");
        notify::notify_error(&e.to_string());
        std::process::exit(1);
    }
}
