//! Bootstrap command - create users and service accounts

use autogit_core::{
    credentials::CredentialStore,
    gitlab::{CreateTokenRequest, CreateUserRequest, GitLabClient, TokenScope},
    Result,
};
use tracing::{info, warn};

/// User definition for bootstrap
struct UserDef {
    username: &'static str,
    email: &'static str,
    name: &'static str,
    is_admin: bool,
    is_service: bool,
    scopes: Option<&'static [TokenScope]>,
}

const USERS: &[UserDef] = &[
    // Human users
    UserDef {
        username: "sysadmin",
        email: "sysadmin@vectorweight.com",
        name: "System Admin",
        is_admin: true,
        is_service: false,
        scopes: None,
    },
    UserDef {
        username: "kang",
        email: "kang@vectorweight.com",
        name: "Kang",
        is_admin: false,
        is_service: false,
        scopes: None,
    },
    UserDef {
        username: "dev",
        email: "dev@vectorweight.com",
        name: "Developer",
        is_admin: false,
        is_service: false,
        scopes: None,
    },
    // Service accounts
    UserDef {
        username: "autogit-ci",
        email: "ci@vectorweight.com",
        name: "CI Service",
        is_admin: false,
        is_service: true,
        scopes: Some(&[TokenScope::Api, TokenScope::ReadRepository, TokenScope::WriteRepository]),
    },
    UserDef {
        username: "autogit-api",
        email: "api@vectorweight.com",
        name: "API Service",
        is_admin: false,
        is_service: true,
        scopes: Some(&[TokenScope::Api, TokenScope::ReadApi]),
    },
    UserDef {
        username: "autogit-backup",
        email: "backup@vectorweight.com",
        name: "Backup Service",
        is_admin: true,
        is_service: true,
        scopes: Some(&[TokenScope::Api, TokenScope::ReadRepository, TokenScope::Sudo]),
    },
];

/// Generate secure password
fn generate_password() -> String {
    use rand::Rng;
    let mut rng = rand::thread_rng();

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

pub async fn run(
    config_path: &str,
    output_path: &str,
    service_only: bool,
    dry_run: bool,
) -> Result<()> {
    info!("🔐 GitLab User Bootstrap");
    info!("========================");

    // Load config and create client
    let config = autogit_core::config::Config::from_env()?;
    let auth = config.auth()?;

    let client = GitLabClient::builder()
        .base_url(&config.gitlab_url)?
        .auth(auth)
        .allow_insecure_localhost()
        .build()?;

    // Verify authentication
    let me = client.current_user().await?;
    info!("Authenticated as: {} (admin={})", me.username, me.is_admin);

    if !me.is_admin {
        return Err(autogit_core::Error::Authentication(
            "Admin privileges required".into(),
        ));
    }

    let mut creds = CredentialStore::new();
    let expiry = chrono::Utc::now()
        .date_naive()
        .checked_add_days(chrono::Days::new(365))
        .expect("valid date");

    // Process users
    for user in USERS {
        // Skip human users if service_only
        if service_only && !user.is_service {
            continue;
        }

        // Check if exists
        if client.user_exists(user.username).await? {
            info!("  ⏭️  User '{}' exists", user.username);
            continue;
        }

        let password = generate_password();

        if dry_run {
            info!("  [DRY RUN] Would create user '{}'", user.username);
            continue;
        }

        let request = CreateUserRequest::new(
            user.username,
            user.email,
            if user.is_service {
                format!("{} (Service)", user.name)
            } else {
                user.name.to_string()
            },
            &password,
        )
        .admin(user.is_admin);

        match client.create_user(&request).await {
            Ok(created) => {
                info!(
                    "  ✅ Created {} (id={}, admin={})",
                    user.username, created.id, user.is_admin
                );
                creds.set(
                    format!("GITLAB_PASSWORD_{}", user.username.replace('-', "_")),
                    &password,
                );

                // Create token for service accounts
                if let Some(scopes) = user.scopes {
                    let token_request =
                        CreateTokenRequest::new("autogit-token", scopes.to_vec())
                            .expires_at(expiry);

                    match client.create_user_token(created.id, &token_request).await {
                        Ok(pat) => {
                            if let Some(token) = pat.token() {
                                info!("     🎫 Token created (expires: {})", expiry);
                                creds.set(
                                    format!("GITLAB_TOKEN_{}", user.username.replace('-', "_")),
                                    token.expose(),
                                );
                            }
                        }
                        Err(e) => warn!("     ❌ Token failed: {}", e),
                    }
                }
            }
            Err(e) => warn!("  ❌ Failed to create {}: {}", user.username, e),
        }
    }

    // Save credentials
    if !dry_run {
        creds.save(output_path)?;
        info!("");
        info!("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        info!("✅ Bootstrap complete!");
        info!("📁 Credentials: {}", output_path);
    }

    Ok(())
}
