use std::process::Command;

pub fn notify_error(message: &str) {
    if let Err(e) = Command::new("notify-send")
        .args([
            "-u",
            "critical",
            "-i",
            "dialog-error",
            "ActivityWatch",
            message,
        ])
        .spawn()
    {
        log::error!("{}", message);
        log::warn!("Failed to send desktop notification: {}", e);
    }
}
