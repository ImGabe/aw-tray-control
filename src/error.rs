#[derive(Debug, thiserror::Error)]
pub enum AppError {
    #[error("Could not determine home directory ($HOME not defined).")]
    HomeDirNotFound,

    #[error("Missing dependencies or no execute permission:\n  - {}", .0.join("\n  - "))]
    MissingDependencies(Vec<String>),

    #[error("Failed to parse configuration at {path}: {source}")]
    ConfigParse {
        path: std::path::PathBuf,
        source: toml::de::Error,
    },

    #[error("Invalid configuration: {0}")]
    InvalidConfig(String),

    #[error("Failed to start process '{path}': {source}")]
    ProcessSpawn {
        path: String,
        source: std::io::Error,
    },

    #[error("Another aw-tray-control instance is already running.")]
    AlreadyRunning,

    #[error("Tray service error: {0}")]
    Tray(#[from] ksni::Error),

    #[error("I/O error: {0}")]
    Io(#[from] std::io::Error),
}
