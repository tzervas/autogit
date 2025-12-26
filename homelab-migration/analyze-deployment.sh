#!/bin/bash
# Deployment Analysis and Optimization Script
# Analyzes monitoring data to identify bottlenecks and suggest improvements

set -euo pipefail

LOG_DIR="./deployment-logs"
LATEST_LOG=$(ls -t "$LOG_DIR"/deployment_monitor_*.log 2>/dev/null | head -1)
LATEST_METRICS=$(ls -t "$LOG_DIR"/deployment_metrics_*.csv 2>/dev/null | head -1)

if [[ ! -f $LATEST_LOG ]]; then
    echo "❌ No deployment logs found in $LOG_DIR"
    echo "Run ./monitor-deployment.sh during deployment first"
    exit 1
fi

echo "📊 Analyzing Deployment Performance"
echo "==================================="
echo "Log File: $LATEST_LOG"
echo "Metrics File: $LATEST_METRICS"
echo ""

# Extract key timing data
START_TIME=$(grep "Starting comprehensive deployment monitoring" "$LATEST_LOG" | head -1 | cut -d' ' -f1-2)
END_TIME=$(grep "DEPLOYMENT REPORT" "$LATEST_LOG" | head -1 | cut -d' ' -f1-2 || echo "Unknown")

if [[ -n $START_TIME && -n $END_TIME ]]; then
    TOTAL_DURATION=$(($(date -d "$END_TIME" +%s) - $(date -d "$START_TIME" +%s)))
    echo "⏱️  Total Deployment Time: ${TOTAL_DURATION}s ($((TOTAL_DURATION / 60))m $((TOTAL_DURATION % 60))s)"
fi

echo ""

# Analyze key phases
echo "🔍 Key Phase Analysis:"
echo "---------------------"

# SSL Certificate generation time
SSL_START=$(grep "Starting comprehensive deployment monitoring" "$LATEST_LOG" | head -1 | cut -d' ' -f1-2)
SSL_END=$(grep "SSL certificates generated" "$LATEST_LOG" | head -1 | cut -d' ' -f1-2)
if [[ -n $SSL_START && -n $SSL_END ]]; then
    SSL_DURATION=$(($(date -d "$SSL_END" +%s) - $(date -d "$SSL_START" +%s)))
    echo "🔐 SSL Certificate Generation: ${SSL_DURATION}s"
fi

# Container startup time
CONTAINER_START=$(grep "SSL certificates generated" "$LATEST_LOG" | head -1 | cut -d' ' -f1-2)
CONTAINER_END=$(grep "GitLab container started" "$LATEST_LOG" | head -1 | cut -d' ' -f1-2)
if [[ -n $CONTAINER_START && -n $CONTAINER_END ]]; then
    CONTAINER_DURATION=$(($(date -d "$CONTAINER_END" +%s) - $(date -d "$CONTAINER_START" +%s)))
    echo "🐳 Container Startup: ${CONTAINER_DURATION}s"
fi

# GitLab health check time
HEALTH_START=$(grep "GitLab container started" "$LATEST_LOG" | head -1 | cut -d' ' -f1-2)
HEALTH_END=$(grep "GitLab is healthy" "$LATEST_LOG" | head -1 | cut -d' ' -f1-2)
if [[ -n $HEALTH_START && -n $HEALTH_END ]]; then
    HEALTH_DURATION=$(($(date -d "$HEALTH_END" +%s) - $(date -d "$HEALTH_START" +%s)))
    echo "💚 GitLab Health Check: ${HEALTH_DURATION}s"
fi

echo ""

# Analyze system resource usage with detailed breakdown
if [[ -f $LATEST_METRICS ]]; then
    echo "📈 Detailed System Resource Analysis:"
    echo "-------------------------------------"

    # Peak CPU usage
    PEAK_CPU=$(tail -n +2 "$LATEST_METRICS" | cut -d',' -f2 | sort -n | tail -1)
    AVG_CPU=$(tail -n +2 "$LATEST_METRICS" | cut -d',' -f2 | awk '{sum+=$1; count++} END {if(count>0) print sum/count; else print 0}')

    # Memory analysis
    PEAK_MEM_USED=$(tail -n +2 "$LATEST_METRICS" | cut -d',' -f3 | sort -n | tail -1)
    AVG_MEM_USED=$(tail -n +2 "$LATEST_METRICS" | cut -d',' -f3 | awk '{sum+=$1; count++} END {if(count>0) print sum/count; else print 0}')
    MEM_TOTAL=$(tail -n +2 "$LATEST_METRICS" | cut -d',' -f4 | head -1)

    # Disk I/O analysis
    TOTAL_DISK_READ=$(tail -n +2 "$LATEST_METRICS" | cut -d',' -f8 | awk '{sum+=$1} END {print sum}')
    TOTAL_DISK_WRITE=$(tail -n +2 "$LATEST_METRICS" | cut -d',' -f9 | awk '{sum+=$1} END {print sum}')

    # Container performance
    CONTAINER_PEAK_CPU=$(tail -n +2 "$LATEST_METRICS" | cut -d',' -f12 | grep -v '^$' | sort -n | tail -1)
    CONTAINER_PEAK_MEM=$(tail -n +2 "$LATEST_METRICS" | cut -d',' -f13 | grep -v '^$' | sort -n | tail -1)

    # Network analysis
    NETWORK_INTERFACES=$(tail -n +2 "$LATEST_METRICS" | cut -d',' -f10 | head -1)

    echo "🔥 CPU Usage: Peak=${PEAK_CPU}%, Average=${AVG_CPU}%"
    echo "🧠 Memory: Peak=${PEAK_MEM_USED}MB used of ${MEM_TOTAL}MB total, Average=${AVG_MEM_USED}MB used"
    echo "💾 Disk I/O: ${TOTAL_DISK_READ}MB read, ${TOTAL_DISK_WRITE}MB written"
    echo "🐳 Container Performance: Peak CPU=${CONTAINER_PEAK_CPU}%, Peak Mem=${CONTAINER_PEAK_MEM}%"
    echo "🌐 Network Interfaces: $NETWORK_INTERFACES"

    # Performance recommendations
    if (($(echo "$PEAK_CPU > 80" | bc -l 2>/dev/null || echo "0"))); then
        echo "⚠️  CRITICAL: CPU usage exceeded 80% - deployment may be CPU-bound"
        echo "   💡 Consider increasing CPU cores or optimizing GitLab configuration"
    fi

    if (($(echo "$PEAK_MEM_USED > $MEM_TOTAL * 0.9" | bc -l 2>/dev/null || echo "0"))); then
        echo "⚠️  CRITICAL: Memory usage near capacity - risk of OOM kills"
        echo "   💡 Increase RAM or reduce GitLab worker processes"
    fi

    if (($(echo "$CONTAINER_PEAK_CPU > 50" | bc -l 2>/dev/null || echo "0"))); then
        echo "⚠️  WARNING: Container CPU usage high - check GitLab configuration"
    fi
fi

echo ""

# Analyze network dependencies
NETWORK_LOG="$LOG_DIR/network_monitor.log"
if [[ -f $NETWORK_LOG ]]; then
    echo "🌐 Network Dependency Analysis:"
    echo "-------------------------------"

    # Docker Hub connectivity
    DOCKER_HUB_LATENCY=$(grep "NETWORK" "$NETWORK_LOG" | cut -d',' -f3 | grep -v "0" | awk '{sum+=$1; count++} END {if(count>0) print sum/count; else print "N/A"}')
    echo "🐳 Docker Hub Latency: ${DOCKER_HUB_LATENCY}s average"

    # GitHub API connectivity
    GITHUB_API_LATENCY=$(grep "NETWORK" "$NETWORK_LOG" | cut -d',' -f4 | grep -v "0" | awk '{sum+=$1; count++} END {if(count>0) print sum/count; else print "N/A"}')
    echo "🐙 GitHub API Latency: ${GITHUB_API_LATENCY}s average"

    # GitLab.com connectivity
    GITLAB_COM_LATENCY=$(grep "NETWORK" "$NETWORK_LOG" | cut -d',' -f5 | grep -v "0" | awk '{sum+=$1; count++} END {if(count>0) print sum/count; else print "N/A"}')
    echo "🦊 GitLab.com Latency: ${GITLAB_COM_LATENCY}s average"

    # DNS performance
    DNS_AVG_TIME=$(grep "NETWORK" "$NETWORK_LOG" | cut -d',' -f6 | grep -v "^$" | awk '{sum+=$1; count++} END {if(count>0) print sum/count; else print "N/A"}')
    echo "🔍 DNS Resolution Time: ${DNS_AVG_TIME}s average"

    # Network bottleneck detection
    if [[ $DOCKER_HUB_LATENCY != "N/A" && $(echo "$DOCKER_HUB_LATENCY > 2.0" | bc -l 2>/dev/null) ]]; then
        echo "⚠️  WARNING: Slow Docker Hub connectivity - consider local registry mirror"
    fi

    if [[ $GITHUB_API_LATENCY != "N/A" && $(echo "$GITHUB_API_LATENCY > 1.0" | bc -l 2>/dev/null) ]]; then
        echo "⚠️  WARNING: Slow GitHub API - may impact repository mirroring"
    fi
fi
echo "🚨 Issues & Errors Found:"
echo "------------------------"
ERROR_COUNT=$(grep -c "ERROR\|error\|failed\|Failed" "$LATEST_LOG" || echo "0")
if [[ $ERROR_COUNT -gt 0 ]]; then
    echo "❌ Found $ERROR_COUNT errors/issues:"
    grep -n "ERROR\|error\|failed\|Failed" "$LATEST_LOG" | head -5
else
    echo "✅ No errors detected in logs"
fi

echo ""

# Generate optimization recommendations
echo "🚀 Optimization Recommendations:"
echo "-------------------------------"

# Time-based recommendations
if [[ -n $TOTAL_DURATION ]]; then
    if [[ $TOTAL_DURATION -gt 1200 ]]; then # 20 minutes
        echo "🐌 SLOW DEPLOYMENT DETECTED (>20min)"
        echo "   💡 Pre-pull Docker images: docker pull gitlab/gitlab-ce:latest"
        echo "   💡 Use faster storage (SSD vs HDD)"
        echo "   💡 Increase network bandwidth"
        echo "   💡 Consider GitLab Omnibus pre-configuration"
    elif [[ $TOTAL_DURATION -gt 600 ]]; then # 10 minutes
        echo "🐌 MODERATE DEPLOYMENT TIME (10-20min)"
        echo "   💡 Optimize Docker image layers"
        echo "   💡 Pre-generate SSL certificates"
        echo "   💡 Use Docker layer caching"
    else
        echo "✅ FAST DEPLOYMENT (<10min)"
        echo "   🎉 Deployment performance is good!"
    fi
fi

# SSL-specific optimizations
if [[ -n $SSL_DURATION && $SSL_DURATION -gt 10 ]]; then
    echo "🔐 SSL OPTIMIZATION:"
    echo "   💡 Pre-generate certificates to skip this step"
    echo "   💡 Use ECC certificates for faster generation"
fi

# Container startup optimizations
if [[ -n $CONTAINER_DURATION && $CONTAINER_DURATION -gt 60 ]]; then
    echo "🐳 CONTAINER OPTIMIZATION:"
    echo "   💡 Pre-pull Docker images before deployment"
    echo "   💡 Use faster storage for Docker volumes"
    echo "   💡 Optimize GitLab configuration for faster startup"
fi

# Health check optimizations
if [[ -n $HEALTH_DURATION && $HEALTH_DURATION -gt 300 ]]; then
    echo "💚 HEALTH CHECK OPTIMIZATION:"
    echo "   💡 Reduce GitLab worker processes for faster startup"
    echo "   💡 Pre-configure database settings"
    echo "   💡 Use health check parallelization"
fi

echo ""
echo "📋 Next Steps:"
echo "1. Review the detailed logs in $LATEST_LOG"
echo "2. Analyze metrics in $LATEST_METRICS with your favorite spreadsheet"
echo "3. Implement the recommended optimizations"
echo "4. Re-run deployment with monitoring to measure improvements"

echo ""
echo "🎯 Ready to implement optimizations?"
