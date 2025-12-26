#!/bin/bash
# GitLab Deployment Monitor
# Captures logs, metrics, and timing data for deployment optimization

set -uo pipefail

LOG_DIR="./deployment-logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOG_DIR/deployment_monitor_$TIMESTAMP.log"
METRICS_FILE="$LOG_DIR/deployment_metrics_$TIMESTAMP.csv"

# Create log directory
mkdir -p "$LOG_DIR"

echo "📊 GitLab Deployment Monitor Started at $(date)"
echo "📊 GitLab Deployment Monitor Started at $(date)" >"$LOG_FILE"
echo "timestamp,cpu_percent,mem_used_mb,mem_total_mb,mem_percent,disk_read_ops,disk_write_ops,disk_read_mb,disk_write_mb,network_interfaces,container_count,container_cpu_percent,container_mem_percent,container_status,gitlab_health,gitlab_response_time,load_average,process_count" >"$METRICS_FILE"

# Function to sanitize sensitive data from logs
sanitize_output() {
    local input="$1"

    # Sanitize GitHub tokens (format: github_pat_...)
    input=$(echo "$input" | sed 's/github_pat_[a-zA-Z0-9_]\{36,\}/github_pat_***SANITIZED***/g')

    # Sanitize GitLab tokens (format: glpat-...)
    input=$(echo "$input" | sed 's/glpat-[a-zA-Z0-9_-]\{20,\}/glpat-***SANITIZED***/g')

    # Sanitize generic tokens (long alphanumeric strings that might be tokens)
    input=$(echo "$input" | sed 's/\b[a-zA-Z0-9_-]\{32,\}\b/***SANITIZED_TOKEN***/g')

    echo "$input"
}

# Function to log with timestamp and sanitization
log() {
    local sanitized_message
    sanitized_message=$(sanitize_output "$1")
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $sanitized_message" | tee -a "$LOG_FILE"
}

# Function to collect detailed system metrics
collect_detailed_metrics() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    # Basic system metrics
    local cpu_percent
    cpu_mem=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    local cpu_percent=${cpu_mem:-0}

    local mem_info
    mem_info=$(free | grep Mem | awk '{printf "%.2f,%.2f,%.2f", $3/1024, $2/1024, ($3/$2)*100}')
    IFS=',' read -r mem_used mem_total mem_percent <<<"$mem_info"

    # Disk I/O with more detail
    local disk_stats
    disk_stats=$(iostat -d 1 1 2>/dev/null | tail -1 | awk '{print $2,$3,$4,$5,$6}')
    local disk_read=${disk_stats%% *}
    disk_stats=${disk_stats#* }
    local disk_write=${disk_stats%% *}
    disk_stats=${disk_stats#* }
    local disk_read_mb=${disk_stats%% *}
    disk_stats=${disk_stats#* }
    local disk_write_mb=${disk_stats%% *}

    # Network I/O with interface breakdown
    local net_stats=""
    while read -r iface rx tx; do
        if [[ $iface =~ ^(eth|enp|wlan|docker) ]]; then
            net_stats="${net_stats}${iface}:${rx}:${tx},"
        fi
    done < <(cat /proc/net/dev | tail -n +3 | awk '{print $1,$2,$10}' | tr -d ':')

    # Docker container metrics
    local container_count=0
    local container_status=""
    local container_cpu=0
    local container_mem=0

    if sudo docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q autogit; then
        container_count=$(sudo docker ps --filter "name=autogit" --format "{{.Names}}" | wc -l)

        # Get detailed container stats
        container_stats=$(sudo docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemPerc}}" | grep autogit | head -1)
        if [[ -n $container_stats ]]; then
            container_cpu=$(echo "$container_stats" | awk '{print $2}' | tr -d '%')
            container_mem=$(echo "$container_stats" | awk '{print $3}' | tr -d '%')
        fi

        container_status="running"
    else
        container_status="stopped"
    fi

    # GitLab health with more detail
    local gitlab_health="unknown"
    local gitlab_response_time="0"
    local gitlab_db_status="unknown"

    if curl -k -s -w "%{time_total}" -o /dev/null "https://gitlab.vectorweight.com/-/health" 2>/dev/null; then
        gitlab_health="healthy"
        gitlab_response_time=$(curl -k -s -w "%{time_total}" -o /dev/null "https://gitlab.vectorweight.com/-/health" 2>/dev/null)
    elif sudo docker ps | grep -q autogit-git-server; then
        gitlab_health="starting"
    else
        gitlab_health="down"
    fi

    # System load average
    local load_avg
    load_avg=$(uptime | awk -F'load average:' '{print $2}' | tr -d ' ')

    # Process count
    local process_count
    process_count=$(ps aux | wc -l)

    # Write detailed CSV
    echo "$timestamp,$cpu_percent,$mem_used,$mem_total,$mem_percent,$disk_read,$disk_write,$disk_read_mb,$disk_write_mb,$net_stats,$container_count,$container_cpu,$container_mem,$container_status,$gitlab_health,$gitlab_response_time,$load_avg,$process_count" >>"$METRICS_FILE"
}

# Function to monitor network connectivity and external dependencies
monitor_network_dependencies() {
    log "🌐 Starting network dependency monitoring..."

    while true; do
        local timestamp=$(date +"%Y-%m-%d %H:%M:%S")

        # Test connectivity to key services
        local docker_hub
        docker_hub=$(curl -s -w "%{time_total}" -o /dev/null https://registry-1.docker.io 2>/dev/null || echo "0")

        local github_api
        github_api=$(curl -s -w "%{time_total}" -o /dev/null https://api.github.com 2>/dev/null || echo "0")

        local gitlab_com
        gitlab_com=$(curl -s -w "%{time_total}" -o /dev/null https://gitlab.com 2>/dev/null || echo "0")

        # DNS resolution time
        local dns_time
        dns_time=$( (time nslookup gitlab.vectorweight.com >/dev/null 2>&1) 2>&1 | grep real | awk '{print $2}' | sed 's/0m//' | sed 's/s//' || echo "0")

        # Log network status
        echo "$timestamp,NETWORK,$docker_hub,$github_api,$gitlab_com,$dns_time" >>"$LOG_DIR/network_monitor.log"

        sleep 10
    done &
    NETWORK_MONITOR_PID=$!
}

# Function to monitor system resources
monitor_system() {
    log "📊 Starting detailed system metrics monitoring..."
    while true; do
        collect_detailed_metrics
        sleep 2 # More frequent sampling for detailed metrics
    done &
    SYSTEM_MONITOR_PID=$!
}

# Function to check deployment phases with detailed timing
monitor_deployment_phases() {
    log "🔍 Starting detailed deployment phase monitoring..."

    local phases=(
        "SSL certificates generated:./data/gitlab/ssl/gitlab.vectorweight.com.crt"
        "GitLab container started:autogit-git-server"
        "GitLab database ready:gitlab-health-db"
        "GitLab application ready:gitlab-health-app"
        "GitLab fully healthy:gitlab-health-full"
    )

    local phase_start_time=$(date +%s)

    for phase in "${phases[@]}"; do
        local phase_name="${phase%%:*}"
        local phase_check="${phase#*:}"
        local phase_start=$(date +%s)

        log "⏳ Monitoring: $phase_name"

        while true; do
            local current_time=$(date +%s)
            local elapsed=$((current_time - phase_start))

            case $phase_check in
            "./data/gitlab/ssl/gitlab.vectorweight.com.crt")
                [[ -f $phase_check ]] && break
                ;;
            "autogit-git-server")
                sudo docker ps | grep -q "$phase_check" && break
                ;;
            "gitlab-health-db")
                sudo docker compose exec -T gitlab gitlab-psql -c "SELECT 1;" >/dev/null 2>&1 && break
                ;;
            "gitlab-health-app")
                curl -k -s "https://gitlab.vectorweight.com/-/readiness" | grep -q "ok" && break
                ;;
            "gitlab-health-full")
                curl -k -s -f "https://gitlab.vectorweight.com/-/health" >/dev/null 2>&1 && break
                ;;
            esac

            # Log progress every 30 seconds
            if ((elapsed % 30 == 0 && elapsed > 0)); then
                log "⏳ Still waiting for $phase_name... (${elapsed}s elapsed)"
            fi

            sleep 5
        done

        local phase_duration=$(($(date +%s) - phase_start))
        log "✅ $phase_name completed in ${phase_duration}s"
    done

    local total_phase_time=$(($(date +%s) - phase_start_time))
    log "📊 All phases completed in ${total_phase_time}s"
}

# Function to generate deployment report
generate_report() {
    log "📈 Generating deployment report..."

    local total_time
    total_time=$(($(date +%s) - START_TIME))

    local final_metrics
    final_metrics=$(tail -1 "$METRICS_FILE" 2>/dev/null || echo "No metrics collected")

    {
        echo "========================================"
        echo "📊 DEPLOYMENT REPORT"
        echo "========================================"
        echo "Start Time: $(date -d "@$START_TIME" +"%Y-%m-%d %H:%M:%S")"
        echo "End Time: $(date +"%Y-%m-%d %H:%M:%S")"
        echo "Total Duration: ${total_time}s ($((total_time / 60))m $((total_time % 60))s)"
        echo ""
        echo "📋 Key Events:"
        grep -E "(SSL certificates generated|GitLab container started|GitLab is healthy)" "$LOG_FILE" 2>/dev/null || echo "No key events captured"
        echo ""
        echo "📊 Final System State:"
        echo "$final_metrics"
        echo ""
        echo "📁 Log Files:"
        echo "  - Main Log: $LOG_FILE"
        echo "  - Metrics CSV: $METRICS_FILE"
        echo ""
        echo "🔧 Recommendations:"
        if ((total_time > 600)); then
            echo "  - Consider pre-building Docker images"
            echo "  - Check network connectivity for faster downloads"
        fi
        if grep -q "ERROR\|failed\|timeout" "$LOG_FILE"; then
            echo "  - Review error logs for optimization opportunities"
        fi
        echo "========================================"
    } | tee -a "$LOG_FILE"
}

# Main monitoring function
main() {
    START_TIME=$(date +%s)
    log "🚀 Starting comprehensive deployment monitoring..."

    # Start all monitoring processes
    monitor_system
    monitor_docker_logs
    monitor_network_dependencies
    monitor_deployment_phases

    # Wait for deployment to complete (you can interrupt with Ctrl+C)
    log "⏳ Monitoring deployment... Press Ctrl+C when deployment completes"

    # Setup cleanup trap
    trap 'log "🛑 Monitoring interrupted by user"; generate_report; kill $SYSTEM_MONITOR_PID $DOCKER_LOG_PID $NETWORK_MONITOR_PID 2>/dev/null; exit 0' INT TERM

    # Keep monitoring until interrupted
    wait
}

# Run main function
main "$@"
