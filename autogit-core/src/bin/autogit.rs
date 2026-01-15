//! autogit - GitLab automation CLI
//!
//! Type-safe, fast GitLab management for self-hosted GitOps.

use clap::{CommandFactory, Parser, Subcommand, ValueEnum};
use clap_complete::{generate, Shell};
use clap_complete_nushell::Nushell;
use tracing::{info, Level};

mod commands;

use autogit_core::Result;
use commands::OutputFormat;

/// Supported shells for completion generation
#[derive(Clone, Copy, Debug, ValueEnum)]
pub enum CompletionShell {
    Bash,
    Zsh,
    Fish,
    PowerShell,
    Elvish,
    Nushell,
}

/// GitLab automation for self-hosted GitOps
#[derive(Parser)]
#[command(name = "autogit")]
#[command(author, version, about, long_about = None)]
#[command(propagate_version = true)]
struct Cli {
    /// Configuration file path
    #[arg(short, long, default_value = "autogit.toml", env = "AUTOGIT_CONFIG")]
    config: String,

    /// GitLab instance URL (overrides config)
    #[arg(long, env = "GITLAB_URL")]
    gitlab_url: Option<String>,

    /// GitLab API token (overrides config)
    #[arg(long, env = "GITLAB_TOKEN")]
    gitlab_token: Option<String>,

    /// Dry run - show what would be done without making changes
    #[arg(short = 'n', long, global = true)]
    dry_run: bool,

    /// Verbose output
    #[arg(short, long, action = clap::ArgAction::Count, global = true)]
    verbose: u8,

    /// Output format
    #[arg(long, default_value = "text", global = true, value_enum)]
    format: OutputFormat,

    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Bootstrap users and service accounts
    Bootstrap {
        /// Skip creating human users
        #[arg(long)]
        service_only: bool,

        /// Output credentials file path
        #[arg(short, long, default_value = "gitlab-credentials.env")]
        output: String,
    },

    /// Manage repository mirroring
    Mirror {
        #[command(subcommand)]
        action: MirrorCommands,
    },

    /// Manage GitLab runners
    Runner {
        #[command(subcommand)]
        action: RunnerCommands,
    },

    /// Show or validate configuration
    Config {
        #[command(subcommand)]
        action: ConfigCommands,
    },

    /// Show status of GitLab instance and managed resources
    Status,

    /// Generate shell completions
    Completions {
        /// Shell to generate completions for (bash, zsh, fish, powershell, elvish, nushell)
        #[arg(value_enum)]
        shell: CompletionShell,
    },

    /// Output for starship prompt integration (fast, minimal)
    #[command(name = "_starship")]
    #[command(hide = true)]
    Starship,
}

#[derive(Subcommand)]
enum MirrorCommands {
    /// Set up mirroring from GitHub to GitLab
    Add {
        /// Source repository (github:owner/repo or https://...)
        source: String,

        /// Target group/namespace in GitLab
        #[arg(short, long)]
        target: Option<String>,

        /// Mirror direction: pull (default) or push
        #[arg(long, default_value = "pull")]
        direction: String,
    },

    /// List all configured mirrors
    List,

    /// Sync a mirror immediately
    Sync {
        /// Repository name or ID
        repo: String,
    },

    /// Remove a mirror configuration
    Remove {
        /// Repository name or ID
        repo: String,

        /// Skip confirmation
        #[arg(short, long)]
        yes: bool,

        /// Also delete the local GitLab project (DESTRUCTIVE)
        #[arg(long)]
        purge: bool,
    },
}

#[derive(Subcommand)]
enum RunnerCommands {
    /// Register a new runner
    Register {
        /// Runner description
        #[arg(short, long)]
        description: Option<String>,

        /// Runner tags (comma-separated)
        #[arg(short, long)]
        tags: Option<String>,

        /// Run untagged jobs
        #[arg(long)]
        run_untagged: bool,

        /// Enable GPU support (auto-detects NVIDIA GPUs)
        #[arg(long)]
        gpu: bool,
    },

    /// List registered runners
    List {
        /// Show all runners (including inactive)
        #[arg(short, long)]
        all: bool,
    },

    /// Show runner status
    Status {
        /// Runner ID or description
        runner: Option<String>,
    },

    /// Remove a runner
    Remove {
        /// Runner ID
        id: u64,

        /// Skip confirmation
        #[arg(short, long)]
        yes: bool,
    },
}

#[derive(Subcommand)]
enum ConfigCommands {
    /// Show current configuration
    Show,

    /// Validate configuration file
    Validate,

    /// Initialize a new configuration file
    Init {
        /// Overwrite existing file
        #[arg(short, long)]
        force: bool,
    },
}

fn init_logging(verbose: u8) {
    let level = match verbose {
        0 => Level::INFO,
        1 => Level::DEBUG,
        _ => Level::TRACE,
    };

    tracing_subscriber::fmt()
        .with_max_level(level)
        .with_target(verbose > 1)
        .init();
}

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();

    init_logging(cli.verbose);

    if cli.dry_run {
        info!("🔍 DRY RUN - no changes will be made");
    }

    match cli.command {
        Commands::Bootstrap {
            service_only,
            output,
        } => commands::bootstrap::run(&cli.config, &output, service_only, cli.dry_run).await,
        Commands::Mirror { action } => commands::mirror::run(action, cli.dry_run, cli.format).await,
        Commands::Runner { action } => commands::runner::run(action, cli.dry_run, cli.format).await,
        Commands::Config { action } => commands::config::run(action, &cli.config).await,
        Commands::Status => commands::status::run(&cli.config, cli.format).await,
        Commands::Completions { shell } => {
            let mut cmd = Cli::command();
            match shell {
                CompletionShell::Bash => {
                    generate(Shell::Bash, &mut cmd, "autogit", &mut std::io::stdout())
                }
                CompletionShell::Zsh => {
                    generate(Shell::Zsh, &mut cmd, "autogit", &mut std::io::stdout())
                }
                CompletionShell::Fish => {
                    generate(Shell::Fish, &mut cmd, "autogit", &mut std::io::stdout())
                }
                CompletionShell::PowerShell => generate(
                    Shell::PowerShell,
                    &mut cmd,
                    "autogit",
                    &mut std::io::stdout(),
                ),
                CompletionShell::Elvish => {
                    generate(Shell::Elvish, &mut cmd, "autogit", &mut std::io::stdout())
                }
                CompletionShell::Nushell => {
                    generate(Nushell, &mut cmd, "autogit", &mut std::io::stdout())
                }
            }
            Ok(())
        }
        Commands::Starship => commands::starship::run().await,
    }
}
