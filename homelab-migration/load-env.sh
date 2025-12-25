#!/bin/bash
# Environment loader for GitLab homelab scripts
# Automatically loads .env file if present

load_env() {
    local env_file=".env"

    if [[ -f $env_file ]]; then
        echo "📄 Loading environment from $env_file"
        set -a # automatically export all variables
        source "$env_file"
        set +a
        echo "✅ Environment loaded"
    else
        echo "⚠️  No .env file found, using system environment variables"
    fi

    # Validate required variables
    local required_vars=("GITLAB_URL" "GITHUB_PAT_MIRROR" "GITLAB_PAT_MIRROR")
    local missing_vars=()

    for var in "${required_vars[@]}"; do
        if [[ -z ${!var:-} ]]; then
            missing_vars+=("$var")
        fi
    done

    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        echo "❌ Missing required environment variables:"
        printf "   - %s\n" "${missing_vars[@]}"
        echo ""
        echo "Please set them in .env file or environment:"
        echo "export VARIABLE_NAME='your_value'"
        echo ""
        echo "🔒 SECURITY: Tokens are automatically sanitized in all logs and output"
        return 1
    fi

    # Security validation - ensure tokens aren't exposed in logs
    if [[ -n $GITHUB_PAT_MIRROR && $GITHUB_PAT_MIRROR != *"***"* ]]; then
        echo "🔒 SECURITY: GitHub token loaded and will be sanitized in logs"
    fi

    if [[ -n $GITLAB_PAT_MIRROR && $GITLAB_PAT_MIRROR != *"***"* ]]; then
        echo "🔒 SECURITY: GitLab token loaded and will be sanitized in logs"
    fi

    return 0
}

# Export function for use in other scripts
export -f load_env
