#!/bin/bash
# AutoGit Homelab Manager
# A unified script to sync, deploy, monitor, and manage the homelab environment.

set -e

# Load environment variables
if [ -f ".env" ]; then
    set -a
    source .env
    set +a
fi

USER=${HOMELAB_SSH_USER:-"kang"}
HOST=${HOMELAB_SSH_HOST:-"192.168.1.170"}
KEY_PATH=${HOMELAB_SSH_KEY_PATH:-"~/.ssh/id_ed25519"}
TARGET_PATH="/home/$USER/autogit"
DOCKER_SOCKET="unix:///run/user/1000/docker.sock"

# Colors for UI
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

show_status() {
    clear
    echo -e "${BLUE}========================================================================${NC}"
    echo -e "${BLUE} AUTOGIT HOMELAB MANAGER | $(date)${NC}"
    echo -e "${BLUE} RESOURCES: 28 Cores / 56 Threads | 128GB RAM${NC}"
    echo -e "${BLUE}========================================================================${NC}"
    echo ""
    echo -e "${GREEN}--- System Status ---${NC}"
    ssh -i "$KEY_PATH" -o ConnectTimeout=2 "$USER@$HOST" "uptime && free -h | grep Mem" || echo -e "${RED}Host unreachable${NC}"
    echo ""
    echo -e "${GREEN}--- Container Status ---${NC}"
    ssh -i "$KEY_PATH" -o ConnectTimeout=2 "$USER@$HOST" "export DOCKER_HOST=$DOCKER_SOCKET && docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'" || echo -e "${RED}Docker not responding${NC}"
    echo ""
    echo -e "${GREEN}--- Service Health ---${NC}"
    # Run health checks in parallel to avoid blocking the UI
    (
        GITLAB_HEALTH=$(ssh -i "$KEY_PATH" -o ConnectTimeout=2 "$USER@$HOST" "curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/-/health || echo 'FAIL'")
        echo "GITLAB:$GITLAB_HEALTH" > /tmp/autogit_health
    ) &
    (
        RUNNER_HEALTH=$(ssh -i "$KEY_PATH" -o ConnectTimeout=2 "$USER@$HOST" "curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/health || echo 'FAIL'")
        echo "RUNNER:$RUNNER_HEALTH" >> /tmp/autogit_health
    ) &

    # Wait a moment for health checks or show "Checking..."
    sleep 0.5
    GITLAB_STATUS=$(grep "GITLAB" /tmp/autogit_health | cut -d: -f2 || echo "...")
    RUNNER_STATUS=$(grep "RUNNER" /tmp/autogit_health | cut -d: -f2 || echo "...")

    echo -e "GitLab: $([[ $GITLAB_STATUS == "200" ]] && echo -e "${GREEN}UP (200)${NC}" || echo -e "${RED}DOWN ($GITLAB_STATUS)${NC}")"
    echo -e "Runner Coordinator: $([[ $RUNNER_STATUS == "200" ]] && echo -e "${GREEN}UP (200)${NC}" || echo -e "${RED}DOWN ($RUNNER_STATUS)${NC}")"
    echo ""
    echo -e "${BLUE}========================================================================${NC}"
    echo -e "${GREEN}Commands:${NC}"
    echo -e "  [s]ync    - Rsync files to homelab"
    echo -e "  [d]eploy  - Run Terraform apply (full deploy)"
    echo -e "  [u]p      - Docker compose up -d --build (fast update)"
    echo -e "  [r]estart - Restart all containers"
    echo -e "  [t]ear    - Docker compose down"
    echo -e "  [l]ogs    - Tail container logs"
    echo -e "  [q]uit    - Exit manager"
    echo ""
    echo -n "Choose an option: "
}

sync_files() {
    echo -e "${BLUE}Syncing files...${NC}"
    /home/spooky/Documents/projects/autogit/scripts/sync-to-homelab.sh "$USER" "$HOST" "$TARGET_PATH"
}

deploy() {
    echo -e "${BLUE}Starting deployment via Terraform...${NC}"
    cd /home/spooky/Documents/projects/autogit/infrastructure/homelab
    terraform apply -auto-approve -var="ssh_user=$USER" -var="ssh_key_path=$KEY_PATH"
    cd /home/spooky/Documents/projects/autogit
}

fast_update() {
    echo -e "${BLUE}Performing fast update (up -d --build)...${NC}"
    ssh -i "$KEY_PATH" "$USER@$HOST" "export DOCKER_HOST=$DOCKER_SOCKET && cd $TARGET_PATH && docker compose up -d --build"
}

restart_services() {
    echo -e "${BLUE}Restarting services...${NC}"
    ssh -i "$KEY_PATH" "$USER@$HOST" "export DOCKER_HOST=$DOCKER_SOCKET && cd $TARGET_PATH && docker compose restart"
}

tear_down() {
    echo -e "${RED}Tearing down services...${NC}"
    ssh -i "$KEY_PATH" "$USER@$HOST" "export DOCKER_HOST=$DOCKER_SOCKET && cd $TARGET_PATH && docker compose down"
}

show_logs() {
    echo -e "${BLUE}Tailing logs (Ctrl+C to return to menu)...${NC}"
    ssh -i "$KEY_PATH" "$USER@$HOST" "export DOCKER_HOST=$DOCKER_SOCKET && cd $TARGET_PATH && docker compose logs -f" || true
}

# Main Loop
while true; do
    show_status
    read -r -n 1 opt
    echo ""
    case $opt in
        s)
            sync_files
            read -r -n 1 -p "Press any key to continue..."
            ;;
        d)
            sync_files
            deploy
            read -r -n 1 -p "Press any key to continue..."
            ;;
        u)
            sync_files
            fast_update
            read -r -n 1 -p "Press any key to continue..."
            ;;
        r)
            restart_services
            read -r -n 1 -p "Press any key to continue..."
            ;;
        t)
            tear_down
            read -r -n 1 -p "Press any key to continue..."
            ;;
        l) show_logs ;;
        q) exit 0 ;;
        *)
            echo "Invalid option"
            sleep 1
            ;;
    esac
done
