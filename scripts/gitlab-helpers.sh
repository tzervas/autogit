#!/bin/bash
# GitLab Helper Functions

# Source the environment
if [ -f ".env.gitlab" ]; then
    set -a
    source .env.gitlab
    set +a
fi

# List projects
gitlab-projects() {
    curl -sf --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
        "${GITLAB_URL}/api/v4/projects" | jq -r '.[] | "\(.id)\t\(.name)\t\(.web_url)"'
}

# Trigger pipeline
gitlab-trigger() {
    local project_id=${1:-$GITLAB_PROJECT_ID}
    local ref=${2:-main}

    echo "Triggering pipeline for project ${project_id} on ${ref}..."
    curl -sf --request POST \
        --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
        "${GITLAB_URL}/api/v4/projects/${project_id}/pipeline?ref=${ref}" | jq .
}

# List pipelines
gitlab-pipelines() {
    local project_id=${1:-$GITLAB_PROJECT_ID}

    curl -sf --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
        "${GITLAB_URL}/api/v4/projects/${project_id}/pipelines" \
        | jq -r '.[] | "\(.id)\t\(.status)\t\(.ref)\t\(.created_at)"'
}

# Get pipeline jobs
gitlab-jobs() {
    local project_id=${1:-$GITLAB_PROJECT_ID}
    local pipeline_id=$2

    if [ -z "$pipeline_id" ]; then
        # Get latest pipeline
        pipeline_id=$(curl -sf --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
            "${GITLAB_URL}/api/v4/projects/${project_id}/pipelines" | jq -r '.[0].id')
    fi

    curl -sf --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
        "${GITLAB_URL}/api/v4/projects/${project_id}/pipelines/${pipeline_id}/jobs" \
        | jq -r '.[] | "\(.id)\t\(.name)\t\(.status)\t\(.stage)"'
}

# Watch runners
watch-runners() {
    watch -n 2 "curl -s ${COORDINATOR_URL}/runners | jq '.'"
}

# Watch containers
watch-containers() {
    watch -n 2 "ssh homelab 'DOCKER_HOST=unix:///run/user/1000/docker.sock docker ps --filter name=autogit-runner'"
}

# Get job log
gitlab-job-log() {
    local project_id=${1:-$GITLAB_PROJECT_ID}
    local job_id=$2

    if [ -z "$job_id" ]; then
        echo "Usage: gitlab-job-log [project_id] <job_id>"
        return 1
    fi

    curl -sf --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
        "${GITLAB_URL}/api/v4/projects/${project_id}/jobs/${job_id}/trace"
}

# Show help
gitlab-help() {
    cat << 'EOF'
GitLab Helper Commands:

  gitlab-projects          - List all projects
  gitlab-trigger [id] [ref]- Trigger pipeline (default: autogit, main)
  gitlab-pipelines [id]    - List pipelines for project
  gitlab-jobs [id] [pid]   - List jobs for pipeline
  gitlab-job-log [id] <jid>- Get job log
  watch-runners            - Watch active runners in real-time
  watch-containers         - Watch runner containers on homelab

Environment:
  GITLAB_URL:       ${GITLAB_URL}
  GITLAB_PROJECT_ID:${GITLAB_PROJECT_ID}
  COORDINATOR_URL:  ${COORDINATOR_URL}

EOF
}

# Export functions if sourced
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    export -f gitlab-projects gitlab-trigger gitlab-pipelines gitlab-jobs
    export -f gitlab-job-log watch-runners watch-containers gitlab-help
    echo "GitLab helper functions loaded. Run 'gitlab-help' for usage."
fi
