//! Runner command - GitLab runner management

use crate::RunnerCommands;
use super::output::{OutputFormat, RunnerInfo, RunnerListOutput, TextOutput};
use autogit_core::gitlab::{
    AuthMethod, GitLabClient, RegisterRunnerRequest, Runner, RunnerDetail, RunnerInfo as GitLabRunnerInfo,
    RunnerStatus, Token,
};
use autogit_core::Result;
use std::env;
use tracing::info;

pub async fn run(action: RunnerCommands, dry_run: bool, format: OutputFormat) -> Result<()> {
    match action {
        RunnerCommands::Register {
            description,
            tags,
            run_untagged,
            gpu,
        } => register_runner(description, tags, run_untagged, gpu, dry_run).await,
        RunnerCommands::List { all } => list_runners(all, format).await,
        RunnerCommands::Status { runner } => runner_status(runner, format).await,
        RunnerCommands::Remove { id, yes } => remove_runner(id, yes, dry_run).await,
    }
}

/// Create GitLab client from environment
fn create_client() -> Result<GitLabClient> {
    let url = env::var("GITLAB_URL")
        .map_err(|_| autogit_core::Error::Config("GITLAB_URL not set".into()))?;
    let token = env::var("GITLAB_TOKEN")
        .map_err(|_| autogit_core::Error::Config("GITLAB_TOKEN not set".into()))?;

    GitLabClient::builder()
        .base_url(&url)?
        .auth(AuthMethod::PrivateToken(Token::new(token)))
        .build()
}

async fn register_runner(
    description: Option<String>,
    tags: Option<String>,
    run_untagged: bool,
    gpu: bool,
    dry_run: bool,
) -> Result<()> {
    info!("🏃 Registering runner...");

    let desc = description.unwrap_or_else(|| {
        let hostname = hostname::get()
            .map(|h| h.to_string_lossy().to_string())
            .unwrap_or_else(|_| "unknown".to_string());
        format!("autogit-runner-{}", hostname)
    });

    info!("  Description: {}", desc);

    // Parse and display tags
    let mut tag_list: Vec<String> = tags
        .map(|t| t.split(',').map(|s| s.trim().to_string()).collect())
        .unwrap_or_default();

    // Auto-detect GPU if requested
    if gpu {
        info!("  🎮 Detecting GPUs...");
        let gpus = detect_nvidia_gpus();
        if !gpus.is_empty() {
            for gpu_info in &gpus {
                info!("     Found: {}", gpu_info);
                tag_list.push(format!("gpu:{}", gpu_info.replace(' ', "-").to_lowercase()));
            }
            tag_list.push("gpu".to_string());
            tag_list.push("cuda".to_string());
        } else {
            info!("     No NVIDIA GPUs detected");
        }
    }

    info!("  Tags: {:?}", tag_list);
    info!("  Run untagged: {}", run_untagged);

    if dry_run {
        info!("[DRY RUN] Would register runner with GitLab");
        return Ok(());
    }

    let client = create_client()?;

    // Get instance runner registration token
    // Note: This resets the token - in production you'd get it from admin UI
    info!("  Getting runner registration token...");
    let reg_token = env::var("GITLAB_RUNNER_TOKEN").map_err(|_| {
        autogit_core::Error::Config(
            "GITLAB_RUNNER_TOKEN not set. Get it from GitLab Admin > CI/CD > Runners".into(),
        )
    })?;

    // Build runner info
    let runner_info = GitLabRunnerInfo {
        name: Some(desc.clone()),
        version: Some(env!("CARGO_PKG_VERSION").to_string()),
        revision: None,
        platform: Some(std::env::consts::OS.to_string()),
        architecture: Some(std::env::consts::ARCH.to_string()),
    };

    // Build registration request
    let request = RegisterRunnerRequest::new(reg_token)
        .description(&desc)
        .info(runner_info)
        .run_untagged(run_untagged)
        .tags(tag_list);

    info!("  Registering runner...");
    let response = client.register_runner(&request).await?;

    info!("  ✓ Runner registered successfully!");
    info!("    ID: {}", response.id);
    info!("    Token: {}", mask_token(&response.token));
    if let Some(expires) = response.token_expires_at {
        info!("    Token expires: {}", expires);
    }

    // Store the runner token for later use
    info!("");
    info!("  ⚠️  Save this token securely:");
    info!("    GITLAB_RUNNER_AUTH_TOKEN={}", response.token);

    Ok(())
}

async fn list_runners(all: bool, format: OutputFormat) -> Result<()> {
    if !format.is_json() {
        info!("📋 Listing runners...\n");
    }

    let client = create_client()?;
    let runners = client.list_runners().await?;

    // Filter by status unless --all
    let runners: Vec<_> = if all {
        runners
    } else {
        runners
            .into_iter()
            .filter(|r| matches!(r.status, RunnerStatus::Online))
            .collect()
    };

    let output = RunnerListOutput {
        runners: runners
            .iter()
            .map(|r| RunnerInfo {
                id: r.id,
                description: r.description.clone(),
                status: format!("{:?}", r.status),
                runner_type: format!("{:?}", r.runner_type),
                tags: r.tag_list.clone(),
                paused: r.paused,
                online: matches!(r.status, RunnerStatus::Online),
            })
            .collect(),
    };

    format.print(&output);
    Ok(())
}

async fn runner_status(runner: Option<String>, format: OutputFormat) -> Result<()> {
    let client = create_client()?;

    match runner {
        Some(id_str) => {
            // Show detailed status for specific runner
            let id: u64 = id_str
                .parse()
                .map_err(|_| autogit_core::Error::Config("Invalid runner ID".into()))?;

            if !format.is_json() {
                info!("📊 Runner {} status:\n", id);
            }
            let detail = client.get_runner(id).await?;
            print_runner_detail(&detail);
        }
        None => {
            // Show summary of all runners
            if !format.is_json() {
                info!("📊 Runner status overview:\n");
            }
            let runners = client.list_runners().await?;

            let online = runners
                .iter()
                .filter(|r| matches!(r.status, RunnerStatus::Online))
                .count();
            let offline = runners
                .iter()
                .filter(|r| matches!(r.status, RunnerStatus::Offline))
                .count();
            let paused = runners.iter().filter(|r| r.paused).count();

            info!("  Total runners: {}", runners.len());
            info!("  🟢 Online: {}", online);
            info!("  🔴 Offline: {}", offline);
            info!("  ⏸️  Paused: {}", paused);
        }
    }

    Ok(())
}

fn print_runner_detail(detail: &RunnerDetail) {
    let status_icon = match detail.status {
        RunnerStatus::Online => "🟢",
        RunnerStatus::Offline => "🔴",
        RunnerStatus::Stale => "🟡",
        _ => "⚪",
    };

    info!(
        "  {} {} (ID: {})",
        status_icon,
        detail.description.as_deref().unwrap_or("unnamed"),
        detail.id
    );
    info!("     Status: {:?}", detail.status);
    info!("     Type: {:?}", detail.runner_type);
    info!("     Active: {}", detail.active);
    info!("     Paused: {}", detail.paused);

    if let Some(v) = &detail.version {
        info!("     Version: {}", v);
    }
    if let Some(p) = &detail.platform {
        info!("     Platform: {}", p);
    }
    if let Some(a) = &detail.architecture {
        info!("     Arch: {}", a);
    }
    if let Some(contacted) = &detail.contacted_at {
        info!("     Last contact: {}", contacted);
    }

    if !detail.tag_list.is_empty() {
        info!("     Tags: {}", detail.tag_list.join(", "));
    }

    if !detail.projects.is_empty() {
        info!("     Projects:");
        for proj in &detail.projects {
            info!("       - {}", proj.path_with_namespace);
        }
    }
}

async fn remove_runner(id: u64, confirmed: bool, dry_run: bool) -> Result<()> {
    if !confirmed && !dry_run {
        return Err(autogit_core::Error::Config(
            "Use --yes to confirm runner removal".into(),
        ));
    }

    info!("🗑️  Removing runner: {}", id);

    if dry_run {
        info!("[DRY RUN] Would remove runner {}", id);
        return Ok(());
    }

    let client = create_client()?;

    // Get runner info first
    let runner = client.get_runner(id).await?;
    info!(
        "  Removing: {} ({:?})",
        runner.description.as_deref().unwrap_or("unnamed"),
        runner.runner_type
    );

    client.delete_runner(id).await?;
    info!("  ✓ Runner removed successfully");

    Ok(())
}

/// Detect NVIDIA GPUs using nvidia-smi
fn detect_nvidia_gpus() -> Vec<String> {
    // Try to run nvidia-smi
    match std::process::Command::new("nvidia-smi")
        .args(["--query-gpu=name", "--format=csv,noheader"])
        .output()
    {
        Ok(output) if output.status.success() => {
            String::from_utf8_lossy(&output.stdout)
                .lines()
                .map(|s| s.trim().to_string())
                .filter(|s| !s.is_empty())
                .collect()
        }
        _ => Vec::new(),
    }
}

/// Mask token for display
fn mask_token(token: &str) -> String {
    if token.len() > 8 {
        format!("{}...{}", &token[..4], &token[token.len() - 4..])
    } else {
        "****".to_string()
    }
}
