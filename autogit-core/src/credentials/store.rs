//! Secure credential storage and retrieval

use secrecy::{ExposeSecret, SecretString};
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};

use crate::error::{Error, Result};

/// Secure credential store
///
/// Stores credentials in memory with secure handling.
/// Can load from/save to env files with restricted permissions.
pub struct CredentialStore {
    credentials: HashMap<String, SecretString>,
    file_path: Option<PathBuf>,
}

impl CredentialStore {
    /// Create empty credential store
    pub fn new() -> Self {
        Self {
            credentials: HashMap::new(),
            file_path: None,
        }
    }

    /// Load credentials from env file
    ///
    /// File format: KEY='value' or KEY="value" per line
    pub fn from_file(path: impl AsRef<Path>) -> Result<Self> {
        let path = path.as_ref();
        let content = fs::read_to_string(path)?;

        let mut store = Self::new();
        store.file_path = Some(path.to_path_buf());

        for line in content.lines() {
            let line = line.trim();

            // Skip comments and empty lines
            if line.is_empty() || line.starts_with('#') {
                continue;
            }

            // Parse KEY='value' or KEY="value" or KEY=value
            if let Some((key, value)) = line.split_once('=') {
                let key = key.trim();
                let value = value.trim();

                // Remove surrounding quotes
                let value = value
                    .strip_prefix('\'')
                    .and_then(|s| s.strip_suffix('\''))
                    .or_else(|| value.strip_prefix('"').and_then(|s| s.strip_suffix('"')))
                    .unwrap_or(value);

                store
                    .credentials
                    .insert(key.to_string(), SecretString::from(value.to_string()));
            }
        }

        Ok(store)
    }

    /// Get a credential value
    pub fn get(&self, key: &str) -> Option<&SecretString> {
        self.credentials.get(key)
    }

    /// Get a credential and expose it (use carefully)
    pub fn get_exposed(&self, key: &str) -> Option<String> {
        self.credentials
            .get(key)
            .map(|s| s.expose_secret().to_string())
    }

    /// Set a credential
    pub fn set(&mut self, key: impl Into<String>, value: impl Into<String>) {
        self.credentials
            .insert(key.into(), SecretString::from(value.into()));
    }

    /// Remove a credential
    pub fn remove(&mut self, key: &str) -> bool {
        self.credentials.remove(key).is_some()
    }

    /// Check if credential exists
    pub fn contains(&self, key: &str) -> bool {
        self.credentials.contains_key(key)
    }

    /// Get all keys (not values!)
    pub fn keys(&self) -> impl Iterator<Item = &str> {
        self.credentials.keys().map(|s| s.as_str())
    }

    /// Save credentials to file with restricted permissions (0600)
    pub fn save(&self, path: impl AsRef<Path>) -> Result<()> {
        let path = path.as_ref();

        let mut content = String::from("# Autogit credentials - KEEP SECURE\n");
        content.push_str(&format!(
            "# Generated: {}\n\n",
            chrono::Utc::now().to_rfc3339()
        ));

        for (key, value) in &self.credentials {
            // Escape single quotes in value
            let escaped = value.expose_secret().replace('\'', "'\\''");
            content.push_str(&format!("{}='{}'\n", key, escaped));
        }

        // Write file
        fs::write(path, &content)?;

        // Set permissions to 0600 (owner read/write only)
        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            fs::set_permissions(path, fs::Permissions::from_mode(0o600))?;
        }

        Ok(())
    }

    /// Save to original file path (if loaded from file)
    pub fn save_to_original(&self) -> Result<()> {
        let path = self.file_path.as_ref().ok_or_else(|| {
            Error::Credential("No file path set - use save() with explicit path".into())
        })?;
        self.save(path)
    }
}

impl Default for CredentialStore {
    fn default() -> Self {
        Self::new()
    }
}

impl std::fmt::Debug for CredentialStore {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("CredentialStore")
            .field("keys", &self.credentials.keys().collect::<Vec<_>>())
            .field("file_path", &self.file_path)
            .finish()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Write;
    use tempfile::NamedTempFile;

    #[test]
    fn parse_env_file() {
        let mut file = NamedTempFile::new().unwrap();
        writeln!(file, "# Comment").unwrap();
        writeln!(file, "KEY1='value1'").unwrap();
        writeln!(file, "KEY2=\"value2\"").unwrap();
        writeln!(file, "KEY3=value3").unwrap();
        writeln!(file).unwrap();

        let store = CredentialStore::from_file(file.path()).unwrap();

        assert_eq!(store.get_exposed("KEY1"), Some("value1"));
        assert_eq!(store.get_exposed("KEY2"), Some("value2"));
        assert_eq!(store.get_exposed("KEY3"), Some("value3"));
    }

    #[test]
    fn debug_hides_values() {
        let mut store = CredentialStore::new();
        store.set("SECRET", "super_secret_value");

        let debug = format!("{:?}", store);
        assert!(!debug.contains("super_secret_value"));
        assert!(debug.contains("SECRET"));
    }
}
