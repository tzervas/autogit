#!/bin/bash
# Quick status check for GitLab deployment

HOMELAB_USER="kang"
HOMELAB_HOST="192.168.1.170"
DOCKER_SOCK="unix:///run/user/1000/docker.sock"
CONTAINER_NAME="autogit-git-server"

echo "🔍 GitLab Status Check"
echo "====================="
echo ""

# Container status
echo "📦 Container Status:"
ssh ${HOMELAB_USER}@${HOMELAB_HOST} "export DOCKER_HOST=${DOCKER_SOCK} && docker ps -a --filter name=${CONTAINER_NAME} --format 'Name: {{.Names}} | Status: {{.Status}} | Health: {{.Health}}'"
echo ""

# Resource usage
echo "📊 Resource Usage:"
ssh ${HOMELAB_USER}@${HOMELAB_HOST} "export DOCKER_HOST=${DOCKER_SOCK} && docker stats --no-stream ${CONTAINER_NAME} --format 'CPU: {{.CPUPerc}} | Memory: {{.MemUsage}} ({{.MemPerc}})'"
echo ""

# Resource limits
echo "🎯 Resource Limits (from docker-compose.yml):"
echo "CPU: 24 cores | Memory: 32GB | SHM: 8GB"
echo ""

# PostgreSQL config verification
echo "🐘 PostgreSQL Configuration:"
ssh ${HOMELAB_USER}@${HOMELAB_HOST} "export DOCKER_HOST=${DOCKER_SOCK} && docker logs ${CONTAINER_NAME} 2>&1 | grep -E 'shared_buffers|maintenance_work_mem|max_parallel' | tail -5"
echo ""

# Recent important logs
echo "📋 Recent Activity (last 10 important lines):"
ssh ${HOMELAB_USER}@${HOMELAB_HOST} "export DOCKER_HOST=${DOCKER_SOCK} && docker logs --tail=200 ${CONTAINER_NAME} 2>&1 | grep -iE 'ready|start|migrate|error|fatal|listening|puma|worker' | tail -10"
echo ""

# Health check
echo "💚 Health Check:"
ssh ${HOMELAB_USER}@${HOMELAB_HOST} "curl -s -o /dev/null -w 'HTTP %{http_code}' http://localhost:8080/-/health && echo '' || echo 'Not ready yet'"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TIP: Watch live logs: ssh homelab 'docker logs -f ${CONTAINER_NAME}'"
