#!/bin/bash
# Capture CI Pipeline Screenshots and Metrics for Documentation

set -e

echo "========================================================================="
echo " AutoGit CI Pipeline Results Capture"
echo "========================================================================="

# Configuration
PROJECT_ID="${PROJECT_ID:-1}"
GITLAB_URL="${GITLAB_URL:-http://192.168.1.170:3000}"
GITLAB_TOKEN="${GITLAB_TOKEN:?Error: GITLAB_TOKEN environment variable must be set}"
OUTPUT_DIR="docs/ci-results"

# Create output directory
mkdir -p "${OUTPUT_DIR}"

echo "📊 Fetching pipeline information..."

# Get latest pipeline
PIPELINE_JSON=$(curl -s -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    "${GITLAB_URL}/api/v4/projects/${PROJECT_ID}/pipelines?per_page=1")

PIPELINE_ID=$(echo "$PIPELINE_JSON" | jq -r '.[0].id')
PIPELINE_STATUS=$(echo "$PIPELINE_JSON" | jq -r '.[0].status')
PIPELINE_REF=$(echo "$PIPELINE_JSON" | jq -r '.[0].ref')

echo "Pipeline ID: ${PIPELINE_ID}"
echo "Status: ${PIPELINE_STATUS}"
echo "Branch: ${PIPELINE_REF}"

# Get detailed pipeline info
echo ""
echo "📋 Fetching pipeline details..."
curl -s -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    "${GITLAB_URL}/api/v4/projects/${PROJECT_ID}/pipelines/${PIPELINE_ID}" |
    jq '.' >"${OUTPUT_DIR}/pipeline-${PIPELINE_ID}.json"

# Get all jobs in the pipeline
echo ""
echo "🔧 Fetching job information..."
JOBS_JSON=$(curl -s -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    "${GITLAB_URL}/api/v4/projects/${PROJECT_ID}/pipelines/${PIPELINE_ID}/jobs")

echo "$JOBS_JSON" | jq '.' >"${OUTPUT_DIR}/jobs-${PIPELINE_ID}.json"

# Extract job details
JOB_COUNT=$(echo "$JOBS_JSON" | jq '. | length')
echo "Total jobs: ${JOB_COUNT}"

# Create summary report
cat >"${OUTPUT_DIR}/pipeline-summary-${PIPELINE_ID}.md" <<EOF
# AutoGit CI Pipeline Results

## Pipeline Overview
- **Pipeline ID**: ${PIPELINE_ID}
- **Status**: ${PIPELINE_STATUS}
- **Branch**: ${PIPELINE_REF}
- **Date**: $(date)

## Hardware Configuration
- **Server**: 192.168.1.170 (Debian 12)
- **CPU**: 28 Cores / 56 Threads
- **RAM**: 128GB
- **Storage**: 200GB allocated for GitLab

## Jobs Summary

EOF

# Append job details
echo "$JOBS_JSON" | jq -r '.[] | "### \(.name)\n- **Stage**: \(.stage)\n- **Status**: \(.status)\n- **Duration**: \(.duration)s\n- **Runner**: \(.runner.description // "N/A")\n"' >>"${OUTPUT_DIR}/pipeline-summary-${PIPELINE_ID}.md"

# Fetch job logs for each job
echo ""
echo "📝 Fetching job logs..."
echo "$JOBS_JSON" | jq -r '.[].id' | while read -r JOB_ID; do
    JOB_NAME=$(echo "$JOBS_JSON" | jq -r ".[] | select(.id==${JOB_ID}) | .name")
    echo "  - Fetching logs for ${JOB_NAME} (Job ID: ${JOB_ID})"

    curl -s -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
        "${GITLAB_URL}/api/v4/projects/${PROJECT_ID}/jobs/${JOB_ID}/trace" \
        >"${OUTPUT_DIR}/job-${JOB_ID}-${JOB_NAME}.log"
done

# Generate performance metrics
echo ""
echo "📊 Generating performance metrics..."
cat >"${OUTPUT_DIR}/performance-metrics-${PIPELINE_ID}.md" <<EOF
# Performance Metrics - Pipeline ${PIPELINE_ID}

## Job Execution Times

\`\`\`
$(echo "$JOBS_JSON" | jq -r '.[] | "\(.name): \(.duration)s"')
\`\`\`

## Total Pipeline Duration

\`\`\`
Total: $(echo "$JOBS_JSON" | jq '[.[].duration] | add')s
\`\`\`

## Runner Utilization

\`\`\`
$(echo "$JOBS_JSON" | jq -r '.[] | "Job: \(.name)\nRunner: \(.runner.description // "N/A")\nStatus: \(.status)\n"')
\`\`\`

## Resource Usage
EOF

# Get runner metrics from the homelab
echo ""
echo "💻 Capturing runner metrics..."
ssh homelab "export DOCKER_HOST=unix:///run/user/1000/docker.sock && docker stats --no-stream" >"${OUTPUT_DIR}/runner-stats-${PIPELINE_ID}.txt"

echo ""
echo "✅ Results captured successfully!"
echo ""
echo "Output directory: ${OUTPUT_DIR}"
echo "Files generated:"
ls -lh "${OUTPUT_DIR}"
echo ""
echo "To view the summary:"
echo "  cat ${OUTPUT_DIR}/pipeline-summary-${PIPELINE_ID}.md"
echo "========================================================================="
