//! GitLab user bootstrap CLI
//!
//! Fast, type-safe replacement for bootstrap-gitlab-api.sh

use autogit_core::{
    config::Config,
    credentials::CredentialStore,
    gitlab::{
        AuthMethod, CreateTokenRequest, CreateUserRequest, GitLabClient, Token, TokenScope,
    },
    Result,
};
use tracing::{error, info, warn};

/// Service account definitions
const SERVICE_ACCOUNTS: &[(&str, &str, &str, &[TokenScope])] = &[
    (
        "autogit-ci",
        "ci@vectorweight.com",
        "CI Service",
        &[TokenScope::Api, TokenScope::ReadRepository, TokenScope::WriteRepository],
    ),
    (
        "autogit-api",
        "api@vectorweight.com",
        "API Service",
        &[TokenScope::Api, TokenScope::ReadApi],
    ),
    (
        "autogit-backup",
        "backup@vectorweight.com",
        "Backup Service",
        &[TokenScope::Api, TokenScope::ReadRepository, TokenScope::Sudo],
    ),
];

/// Human user definitions
const HUMAN_USERS: &[(&str, &str, &str, bool)] = &[
    ("sysadmin", "sysadmin@vectorweight.com", "System Admin", true),
    ("kang", "kang@vectorweight.com", "Kang", false),
    ("dev", "dev@vectorweight.com", "Developer", false),
];

/// Generate secure password
fn generate_password() -> String {
    use rand::Rng;
    let mut rng = rand::thread_rng();

    // 20 random alphanumeric chars + special suffix
    let base: String = (0..20)
        .map(|_| {
            let idx = rng.gen_range(0..62);
            match idx {
                0..=25 => (b'a' + idx) as char,
                26..=51 => (b'A' + idx - 26) as char,
                _ => (b'0' + idx - 52) as char,
            }
        })
        .collect();

    format!("{}#Ag{}", base, rng.gen_range(1000..9999))
}

#[tokio::main]
async fn main() -> Result<()> {
    // Load config and initialize logging
    let config = Config::from_env()?;
    config.init_tracing();

    info!("🔐 GitLab User Bootstrap (Rust)");
    info!("================================");

    // Get token from environment
    let auth = config.auth()?;

    // Build client
    let client = GitLabClient::builder()
        .base_url(&config.gitlab_url)?
        .auth(auth)
        .allow_insecure_localhost()
        .build()?;

    info!("Connected to {}", config.gitlab_url);

    // Verify authentication
    let me = client.current_user().await?;
    info!("Authenticated as: {} (admin={})", me.username, me.is_admin);

    if !me.is_admin {
        error!("Admin privileges required for user creation");
        return Err(autogit_core::Error::Authentication(
            "Admin privileges required".into(),
        ));
    }

    // Credential store for output
    let mut creds = CredentialStore::new();

    // Create human users
    info!("");
    info!("👥 Creating human users...");

    for (username, email, name, is_admin) in HUMAN_USERS {
        if client.user_exists(username).await? {
            info!("  ⏭️  User '{}' exists", username);
            continue;
        }

        let password = generate_password();
        let request = CreateUserRequest::new(*username, *email, *name, &password)
            .admin(*is_admin);

        match client.create_user(&request).await {
            Ok(user) => {
                info!("  ✅ Created {} (id={}, admin={})", username, user.id, is_admin);
                creds.set(format!("GITLAB_PASSWORD_{}", username), password);
            }
            Err(e) => {
                warn!("  ❌ Failed to create {}: {}", username, e);
            }
        }
    }

    // Create service accounts with tokens
    info!("");
    info!("🤖 Creating service accounts...");

    let expiry = chrono::Utc::now()
        .date_naive()
        .checked_add_days(chrono::Days::new(365))
        .expect("valid date");

    for (username, email, name, scopes) in SERVICE_ACCOUNTS {
        if client.user_exists(username).await? {
            info!("  ⏭️  Service '{}' exists", username);
            continue;
        }

        let password = generate_password();
        let request = CreateUserRequest::new(*username, *email, format!("{} (Service)", name), &password);

        match client.create_user(&request).await {
            Ok(user) => {
                info!("  ✅ Created {} (id={})", username, user.id);
                creds.set(
                    format!("GITLAB_PASSWORD_{}", username.replace('-', "_")),
                    &password,
                );

                // Create token
                let token_request = CreateTokenRequest::new("autogit-token", scopes.to_vec())
                    .expires_at(expiry);

                match client.create_user_token(user.id, &token_request).await {
                    Ok(pat) => {
                        if let Some(token) = pat.token() {
                            info!("     🎫 Token created (expires: {})", expiry);
                            creds.set(
                                format!("GITLAB_TOKEN_{}", username.replace('-', "_")),
                                token.expose(),
                            );
                        }
                    }
                    Err(e) => {
                        warn!("     ❌ Token failed: {}", e);
                    }
                }
            }
            Err(e) => {
                warn!("  ❌ Failed to create {}: {}", username, e);
            }
        }
    }

    // Save credentials
    let creds_path = std::env::var("CREDS_FILE").unwrap_or_else(|_| "gitlab-credentials.env".into());
    creds.save(&creds_path)?;

    info!("");
    info!("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    info!("✅ Bootstrap complete!");
    info!("");
    info!("📁 Credentials: {}", creds_path);

    Ok(())
}
