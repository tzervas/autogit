//! Starship prompt integration
//!
//! Provides fast, minimal output for starship custom modules.
//! Hidden command: `autogit _starship`
//!
//! # Starship Configuration
//!
//! Add to your `~/.config/starship.toml`:
//!
//! ```toml
//! [custom.autogit]
//! command = "autogit _starship"
//! when = "command -v autogit"
//! format = "[$output]($style) "
//! style = "bold purple"
//! # Only check every 30 seconds to keep prompt fast
//! # Uses cached status from last full check
//! ```
//!
//! # Output Format
//!
//! Returns a single line with status indicators:
//! - `⬡` = GitLab connected
//! - `⬢` = GitLab disconnected
//! - `M:N` = N mirrors configured
//! - `R:N` = N runners online
//!
//! Example: `⬡ M:3 R:2` = connected, 3 mirrors, 2 runners

use std::env;
use std::time::{Duration, SystemTime};
use autogit_core::gitlab::{AuthMethod, GitLabClient, Token};
use autogit_core::Result;

/// Cache file for starship status (avoids hammering GitLab API on every prompt)
const CACHE_FILE: &str = "/tmp/autogit-starship-cache";
const CACHE_TTL_SECS: u64 = 30;

pub async fn run() -> Result<()> {
    // Check cache first for fast prompt response
    if let Some(cached) = read_cache() {
        print!("{}", cached);
        return Ok(());
    }

    let status = fetch_status().await;

    // Cache the result
    write_cache(&status);

    print!("{}", status);
    Ok(())
}

async fn fetch_status() -> String {
    let url = match env::var("GITLAB_URL") {
        Ok(u) => u,
        Err(_) => return "⬢".to_string(), // No URL configured
    };

    let token = match env::var("GITLAB_TOKEN") {
        Ok(t) => t,
        Err(_) => return "⬢".to_string(), // No token configured
    };

    let client = match GitLabClient::builder()
        .base_url(&url)
        .map(|b| b.auth(AuthMethod::PrivateToken(Token::new(&token))))
        .and_then(|b| b.build())
    {
        Ok(c) => c,
        Err(_) => return "⬢".to_string(),
    };

    // Quick connectivity check
    let connected = client.current_user().await.is_ok();

    if !connected {
        return "⬢".to_string();
    }

    // Gather stats (parallel)
    let (mirrors, runners) = tokio::join!(
        count_mirrors(&client),
        count_runners(&client),
    );

    let mut parts = vec!["⬡".to_string()];

    if mirrors > 0 {
        parts.push(format!("M:{}", mirrors));
    }
    if runners > 0 {
        parts.push(format!("R:{}", runners));
    }

    parts.join(" ")
}

async fn count_mirrors(client: &GitLabClient) -> usize {
    client.list_mirror_projects().await.map(|p| p.len()).unwrap_or(0)
}

async fn count_runners(client: &GitLabClient) -> usize {
    client.list_runners().await
        .map(|r| r.iter().filter(|r| r.active).count())
        .unwrap_or(0)
}

fn read_cache() -> Option<String> {
    let metadata = std::fs::metadata(CACHE_FILE).ok()?;
    let modified = metadata.modified().ok()?;
    let age = SystemTime::now().duration_since(modified).ok()?;

    if age > Duration::from_secs(CACHE_TTL_SECS) {
        return None;
    }

    std::fs::read_to_string(CACHE_FILE).ok()
}

fn write_cache(status: &str) {
    let _ = std::fs::write(CACHE_FILE, status);
}
