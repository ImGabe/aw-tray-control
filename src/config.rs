use crate::error::AppError;
use directories::{BaseDirs, ProjectDirs};
use serde::{Deserialize, Serialize};
use std::fs;
use url::Url;

#[derive(Deserialize, Serialize, Clone, Debug)]
pub struct Config {
    pub dashboard_url: String,
    #[serde(default = "default_health_check_interval_secs")]
    pub health_check_interval_secs: u64,
    /// Paths to managed executables. Field name kept in English for
    /// interoperability; TOML key will be `process_paths`.
    pub process_paths: Vec<String>,
}

fn default_health_check_interval_secs() -> u64 {
    5
}

pub fn get_default_config() -> Result<Config, AppError> {
    let base_dirs = BaseDirs::new().ok_or(AppError::HomeDirNotFound)?;
    let home = base_dirs.home_dir();

    Ok(Config {
        dashboard_url: "http://localhost:5600".into(),
        health_check_interval_secs: default_health_check_interval_secs(),
        process_paths: vec![
            home.join(".local/opt/activitywatch/aw-server/aw-server")
                .to_string_lossy()
                .into_owned(),
            home.join(".cargo/bin/aw-watcher-media-player")
                .to_string_lossy()
                .into_owned(),
            home.join(".cargo/bin/awatcher")
                .to_string_lossy()
                .into_owned(),
        ],
    })
}

fn validate_config(cfg: &Config) -> Result<(), AppError> {
    if cfg.process_paths.is_empty() {
        return Err(AppError::InvalidConfig(
            "process_paths must contain at least one executable path".to_string(),
        ));
    }

    if cfg.process_paths.iter().any(|p| p.trim().is_empty()) {
        return Err(AppError::InvalidConfig(
            "process_paths cannot contain empty entries".to_string(),
        ));
    }

    const MAX_INTERVAL_SECS: u64 = 3600;
    if cfg.health_check_interval_secs == 0 {
        return Err(AppError::InvalidConfig(
            "health_check_interval_secs must be greater than zero".to_string(),
        ));
    }
    if cfg.health_check_interval_secs > MAX_INTERVAL_SECS {
        return Err(AppError::InvalidConfig(format!(
            "health_check_interval_secs must be ≤ {} (got {})",
            MAX_INTERVAL_SECS, cfg.health_check_interval_secs
        )));
    }

    let parsed = Url::parse(&cfg.dashboard_url)
        .map_err(|e| AppError::InvalidConfig(format!("dashboard_url is invalid: {}", e)))?;

    if parsed.scheme() != "http" && parsed.scheme() != "https" {
        return Err(AppError::InvalidConfig(
            "dashboard_url must start with http:// or https://".to_string(),
        ));
    }

    Ok(())
}

pub fn load_config() -> Result<Config, AppError> {
    let proj_dirs = ProjectDirs::from("", "", "aw-tray").ok_or(AppError::HomeDirNotFound)?;

    let config_dir = proj_dirs.config_dir();
    fs::create_dir_all(config_dir)?;

    let config_file = config_dir.join("config.toml");

    if config_file.exists() {
        let content = fs::read_to_string(&config_file)?;
        let cfg: Config = toml::from_str(&content).map_err(|e| AppError::ConfigParse {
            path: config_file,
            source: e,
        })?;
        validate_config(&cfg)?;
        Ok(cfg)
    } else {
        let default_cfg = get_default_config()?;
        validate_config(&default_cfg)?;
        let toml_string =
            toml::to_string_pretty(&default_cfg).expect("Default config should always serialize");
        fs::write(&config_file, toml_string)?;
        log::info!(
            "Default configuration created at: {}",
            config_file.display()
        );
        Ok(default_cfg)
    }
}

#[cfg(test)]
mod tests {
    use super::{validate_config, Config};

    #[test]
    fn validate_config_accepts_valid_values() {
        let cfg = Config {
            dashboard_url: "http://localhost:5600".to_string(),
            health_check_interval_secs: 5,
            process_paths: vec!["/usr/bin/true".to_string()],
        };

        assert!(validate_config(&cfg).is_ok());
    }

    #[test]
    fn validate_config_rejects_invalid_url() {
        let cfg = Config {
            dashboard_url: "localhost:5600".to_string(),
            health_check_interval_secs: 5,
            process_paths: vec!["/usr/bin/true".to_string()],
        };

        let err = validate_config(&cfg).expect_err("expected invalid URL error");
        let msg = err.to_string();
        assert!(msg.contains("dashboard_url"));
    }

    #[test]
    fn validate_config_rejects_empty_process_paths() {
        let cfg = Config {
            dashboard_url: "http://localhost:5600".to_string(),
            health_check_interval_secs: 5,
            process_paths: Vec::new(),
        };

        let err = validate_config(&cfg).expect_err("expected process_paths error");
        let msg = err.to_string();
        assert!(msg.contains("process_paths"));
    }

    #[test]
    fn validate_config_rejects_zero_health_interval() {
        let cfg = Config {
            dashboard_url: "http://localhost:5600".to_string(),
            health_check_interval_secs: 0,
            process_paths: vec!["/usr/bin/true".to_string()],
        };

        let err = validate_config(&cfg).expect_err("expected health interval error");
        assert!(err.to_string().contains("health_check_interval_secs"));
    }

    #[test]
    fn validate_config_rejects_excessive_health_interval() {
        let cfg = Config {
            dashboard_url: "http://localhost:5600".to_string(),
            health_check_interval_secs: 4000, // Exceeds 3600 max
            process_paths: vec!["/usr/bin/true".to_string()],
        };

        let err = validate_config(&cfg).expect_err("expected max interval error");
        assert!(err.to_string().contains("health_check_interval_secs"));
        assert!(err.to_string().contains("3600"));
    }
}
