//! Mirror command - repository mirroring management

use super::output::{MirrorInfo, MirrorListOutput, OutputFormat};
use crate::MirrorCommands;
use autogit_core::gitlab::{
    AuthMethod, CreateProjectRequest, GitLabClient, MirrorConfig, Token, Visibility,
};
use autogit_core::Result;
use std::env;
use tracing::info;

pub async fn run(action: MirrorCommands, dry_run: bool, format: OutputFormat) -> Result<()> {
    match action {
        MirrorCommands::Add {
            source,
            target,
            direction,
        } => add_mirror(&source, target.as_deref(), &direction, dry_run).await,
        MirrorCommands::List => list_mirrors(format).await,
        MirrorCommands::Sync { repo } => sync_mirror(&repo, dry_run).await,
        MirrorCommands::Remove { repo, yes, purge } => {
            remove_mirror(&repo, yes, purge, dry_run).await
        }
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

async fn add_mirror(
    source: &str,
    target: Option<&str>,
    direction: &str,
    dry_run: bool,
) -> Result<()> {
    info!("🔗 Adding mirror: {} -> {:?}", source, target);

    // Parse source URL
    let (provider, owner, repo) = parse_source(source)?;
    let mirror_url = build_mirror_url(provider, owner, repo)?;

    // Target project path (default: mirrors/owner-repo)
    let target_path = target
        .map(|t| t.to_string())
        .unwrap_or_else(|| format!("mirrors/{}-{}", owner, repo));
    let project_name = target_path.split('/').next_back().unwrap_or(repo);

    info!("  Provider: {}", provider);
    info!("  Source: {}/{}", owner, repo);
    info!("  Mirror URL: {}", mirror_url);
    info!("  Target: {}", target_path);
    info!("  Direction: {}", direction);

    if dry_run {
        info!("[DRY RUN] Would:");
        info!("  1. Create project '{}' in GitLab", project_name);
        info!("  2. Configure {} mirror from {}", direction, mirror_url);
        info!("  3. Trigger initial sync");
        return Ok(());
    }

    let client = create_client()?;

    // Check if project already exists
    if let Some(existing) = client.get_project(&target_path).await? {
        info!(
            "  ℹ️  Project already exists: {}",
            existing.path_with_namespace
        );

        if existing.mirror {
            info!("  ✓ Mirror already configured");
            return Ok(());
        }

        // Configure mirror on existing project
        info!("  Configuring mirror on existing project...");
        let config = MirrorConfig {
            url: mirror_url,
            enabled: true,
            only_protected_branches: false,
            keep_divergent_refs: false,
        };
        client.configure_pull_mirror(existing.id, &config).await?;
        info!("  ✓ Mirror configured");

        // Trigger initial sync
        client.trigger_mirror_pull(existing.id).await?;
        info!("  ✓ Initial sync triggered");

        return Ok(());
    }

    // Create new project with mirror configuration
    info!("  Creating project '{}'...", project_name);
    let mut create_req = CreateProjectRequest::new(project_name)
        .visibility(Visibility::Private)
        .import_url(mirror_url.clone())
        .mirror(true);

    // Set path if target includes a group prefix
    if target_path.contains('/') {
        let path_only = target_path.split('/').next_back().unwrap();
        create_req = create_req.path(path_only.to_string());
    }

    let project = client.create_project(&create_req).await?;
    info!("  ✓ Project created: {}", project.path_with_namespace);
    info!("  ✓ Mirror automatically configured via import_url");

    // Note: When creating with import_url + mirror=true, GitLab auto-starts sync
    info!("  ✓ Initial sync started automatically");

    Ok(())
}

async fn list_mirrors(format: OutputFormat) -> Result<()> {
    if !format.is_json() {
        info!("📋 Listing configured mirrors...\n");
    }

    let client = create_client()?;
    let mirrors = client.list_mirror_projects().await?;

    let output = MirrorListOutput {
        mirrors: mirrors
            .iter()
            .map(|m| MirrorInfo {
                id: m.id,
                name: m.name.clone(),
                path: m.path_with_namespace.clone(),
                url: m.web_url.clone(),
                mirror_url: None, // Would need extended project info
                import_status: m.import_status.clone(),
            })
            .collect(),
    };

    format.print(&output);
    Ok(())
}

async fn sync_mirror(repo: &str, dry_run: bool) -> Result<()> {
    info!("🔄 Syncing mirror: {}", repo);

    if dry_run {
        info!("[DRY RUN] Would trigger sync for {}", repo);
        return Ok(());
    }

    let client = create_client()?;

    // Get project by path
    let project = client
        .get_project(repo)
        .await?
        .ok_or_else(|| autogit_core::Error::Config(format!("Project not found: {}", repo)))?;

    if !project.mirror {
        return Err(autogit_core::Error::Config(format!(
            "Project '{}' is not configured as a mirror",
            repo
        )));
    }

    client.trigger_mirror_pull(project.id).await?;
    info!("  ✓ Sync triggered for {}", project.path_with_namespace);

    Ok(())
}

async fn remove_mirror(repo: &str, confirmed: bool, purge: bool, dry_run: bool) -> Result<()> {
    // Purge requires explicit confirmation
    if purge && !confirmed && !dry_run {
        return Err(autogit_core::Error::Config(
            "⚠️  DESTRUCTIVE OPERATION: --purge will permanently delete the GitLab project and ALL its data.\n\
             Use --yes --purge to confirm complete removal.".into(),
        ));
    }

    if !confirmed && !dry_run {
        return Err(autogit_core::Error::Config(
            "Use --yes to confirm mirror removal".into(),
        ));
    }

    if purge {
        info!("🗑️  PURGING mirror (full deletion): {}", repo);
        info!("  ⚠️  WARNING: This will permanently delete:");
        info!("     - The GitLab project");
        info!("     - All repository data (commits, branches, tags)");
        info!("     - All merge requests and issues");
        info!("     - All CI/CD pipelines and artifacts");
        info!("     - All project settings and webhooks");
    } else {
        info!("🔌 Disabling mirror: {}", repo);
    }

    if dry_run {
        if purge {
            info!("[DRY RUN] Would permanently DELETE project {}", repo);
        } else {
            info!("[DRY RUN] Would disable mirror configuration for {}", repo);
        }
        return Ok(());
    }

    let client = create_client()?;

    let project = client
        .get_project(repo)
        .await?
        .ok_or_else(|| autogit_core::Error::Config(format!("Project not found: {}", repo)))?;

    if purge {
        // DESTRUCTIVE: Delete the entire project
        info!(
            "  Deleting project {} (ID: {})...",
            project.path_with_namespace, project.id
        );
        client.delete_project(project.id).await?;
        info!(
            "  ✓ Project PERMANENTLY DELETED: {}",
            project.path_with_namespace
        );
        info!("  ℹ️  This action cannot be undone");
    } else {
        // Safe: Just disable mirroring, keep the project
        let config = MirrorConfig {
            url: String::new(),
            enabled: false,
            only_protected_branches: false,
            keep_divergent_refs: false,
        };
        client.configure_pull_mirror(project.id, &config).await?;

        info!("  ✓ Mirror disabled for {}", project.path_with_namespace);
        info!("  ℹ️  Project still exists - use --purge to fully delete");
    }

    Ok(())
}

/// Parse source repository string
/// Formats: "github:owner/repo", "gitlab:owner/repo", "https://..."
fn parse_source(source: &str) -> Result<(&str, &str, &str)> {
    if let Some(rest) = source.strip_prefix("github:") {
        let parts: Vec<&str> = rest.splitn(2, '/').collect();
        if parts.len() == 2 {
            return Ok(("github", parts[0], parts[1]));
        }
    } else if let Some(rest) = source.strip_prefix("gitlab:") {
        let parts: Vec<&str> = rest.splitn(2, '/').collect();
        if parts.len() == 2 {
            return Ok(("gitlab", parts[0], parts[1]));
        }
    } else if source.starts_with("https://github.com/") {
        let path = source.strip_prefix("https://github.com/").unwrap();
        let parts: Vec<&str> = path.trim_end_matches(".git").splitn(2, '/').collect();
        if parts.len() == 2 {
            return Ok(("github", parts[0], parts[1]));
        }
    } else if source.starts_with("https://gitlab.com/") {
        let path = source.strip_prefix("https://gitlab.com/").unwrap();
        let parts: Vec<&str> = path.trim_end_matches(".git").splitn(2, '/').collect();
        if parts.len() == 2 {
            return Ok(("gitlab", parts[0], parts[1]));
        }
    }

    Err(autogit_core::Error::Config(format!(
        "Invalid source format: {}. Use 'github:owner/repo' or 'https://github.com/owner/repo'",
        source
    )))
}

/// Build HTTPS URL for mirroring
fn build_mirror_url(provider: &str, owner: &str, repo: &str) -> Result<String> {
    match provider {
        "github" => Ok(format!("https://github.com/{}/{}.git", owner, repo)),
        "gitlab" => Ok(format!("https://gitlab.com/{}/{}.git", owner, repo)),
        _ => Err(autogit_core::Error::Config(format!(
            "Unsupported provider: {}",
            provider
        ))),
    }
}
