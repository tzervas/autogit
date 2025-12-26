#!/bin/bash
# Optimize GitLab resource allocation based on actual usage patterns
# This script analyzes current resource consumption and recommends adjustments

HOMELAB_USER="kang"
HOMELAB_HOST="192.168.1.170"
DOCKER_SOCK="unix:///run/user/1000/docker.sock"
CONTAINER_NAME="autogit-git-server"

echo "📊 GitLab Resource Usage Analysis"
echo "=================================="
echo ""

# Get current resource usage over 10 seconds
echo "⏱️  Sampling resource usage (10 second average)..."
SAMPLES=()
for _ in {1..10}; do
    SAMPLE=$(ssh ${HOMELAB_USER}@${HOMELAB_HOST} "export DOCKER_HOST=${DOCKER_SOCK} && docker stats --no-stream ${CONTAINER_NAME} --format '{{.CPUPerc}},{{.MemPerc}},{{.MemUsage}}'")
    SAMPLES+=("$SAMPLE")
    echo -n "."
    sleep 1
done
echo " done!"
echo ""

# Parse samples
TOTAL_CPU=0
TOTAL_MEM=0
COUNT=0

for sample in "${SAMPLES[@]}"; do
    CPU=$(echo "$sample" | cut -d',' -f1 | sed 's/%//')
    MEM_PCT=$(echo "$sample" | cut -d',' -f2 | sed 's/%//')

    if [[ $CPU =~ ^[0-9.]+$ ]]; then
        TOTAL_CPU=$(echo "$TOTAL_CPU + $CPU" | bc)
        TOTAL_MEM=$(echo "$TOTAL_MEM + $MEM_PCT" | bc)
        ((COUNT++))
    fi
done

AVG_CPU=$(echo "scale=2; $TOTAL_CPU / $COUNT" | bc)
AVG_MEM=$(echo "scale=2; $TOTAL_MEM / $COUNT" | bc)

# Get actual memory usage in GB
MEM_USAGE=$(ssh ${HOMELAB_USER}@${HOMELAB_HOST} "export DOCKER_HOST=${DOCKER_SOCK} && docker stats --no-stream ${CONTAINER_NAME} --format '{{.MemUsage}}'" | cut -d'/' -f1)

# Get current limits
CURRENT_CPU_NANO=$(ssh ${HOMELAB_USER}@${HOMELAB_HOST} "export DOCKER_HOST=${DOCKER_SOCK} && docker inspect ${CONTAINER_NAME} --format='{{.HostConfig.NanoCpus}}'")
CURRENT_MEM=$(ssh ${HOMELAB_USER}@${HOMELAB_HOST} "export DOCKER_HOST=${DOCKER_SOCK} && docker inspect ${CONTAINER_NAME} --format='{{.HostConfig.Memory}}'")

CURRENT_CPU_CORES=$(echo "scale=1; $CURRENT_CPU_NANO / 1000000000" | bc)
CURRENT_MEM_GB=$(echo "scale=1; $CURRENT_MEM / 1073741824" | bc)

# Get container uptime
UPTIME=$(ssh ${HOMELAB_USER}@${HOMELAB_HOST} "export DOCKER_HOST=${DOCKER_SOCK} && docker ps --filter name=${CONTAINER_NAME} --format '{{.Status}}'")

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📈 Current Resource Usage"
echo "------------------------"
echo "Container Uptime:  $UPTIME"
echo "Average CPU:       ${AVG_CPU}%"
echo "Average Memory:    ${AVG_MEM}% ($MEM_USAGE)"
echo ""
echo "Current Limits:"
echo "  CPU Limit:       ${CURRENT_CPU_CORES} cores"
echo "  Memory Limit:    ${CURRENT_MEM_GB}GB"
echo ""

# Determine phase
CORES_USED=$(echo "scale=2; $AVG_CPU / 100" | bc)
if [[ $UPTIME =~ "second" ]] || [[ $UPTIME =~ "minute" ]]; then
    # Extract minutes
    if [[ $UPTIME =~ ([0-9]+).*minute ]]; then
        MINUTES="${BASH_REMATCH[1]}"
    else
        MINUTES=0
    fi

    if [ "$MINUTES" -lt 2 ]; then
        PHASE="Early Initialization"
        EXPECTED_CPU="100-200%"
        EXPECTED_MEM="2-3GB"
    elif [ "$MINUTES" -lt 4 ]; then
        PHASE="Mid Initialization (Migrations/Loading)"
        EXPECTED_CPU="400-800%"
        EXPECTED_MEM="4-8GB"
    else
        PHASE="Late Initialization or Steady State"
        EXPECTED_CPU="50-150%"
        EXPECTED_MEM="4-6GB"
    fi
else
    PHASE="Unknown"
    EXPECTED_CPU="N/A"
    EXPECTED_MEM="N/A"
fi

echo "Detected Phase:    $PHASE"
echo "Expected CPU:      $EXPECTED_CPU"
echo "Expected Memory:   $EXPECTED_MEM"
echo "Cores in Use:      ~${CORES_USED} cores"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Generate recommendations
echo "💡 Resource Allocation Recommendations"
echo "======================================="
echo ""

# CPU recommendations
if (($(echo "$AVG_CPU < 100" | bc -l))); then
    echo "🟢 CPU Allocation: EXCELLENT"
    echo "   Current usage is very low. Container has plenty of CPU headroom."
    echo "   ✅ No CPU adjustment needed"
    RECOMMENDED_CPU_CORES=$(echo "scale=0; $CURRENT_CPU_CORES / 2" | bc)
    if [ "$RECOMMENDED_CPU_CORES" -lt 8 ]; then
        RECOMMENDED_CPU_CORES=8
    fi
    echo "   💰 Could reduce to ${RECOMMENDED_CPU_CORES} cores if cost optimization needed"
elif (($(echo "$AVG_CPU < 400" | bc -l))); then
    echo "🟢 CPU Allocation: GOOD"
    echo "   Using ~${CORES_USED} of ${CURRENT_CPU_CORES} cores"
    echo "   ✅ Current allocation is appropriate"
    RECOMMENDED_CPU_CORES=$CURRENT_CPU_CORES
elif (($(echo "$AVG_CPU < 1200" | bc -l))); then
    echo "🟡 CPU Allocation: MODERATE"
    echo "   Using ~${CORES_USED} of ${CURRENT_CPU_CORES} cores"
    echo "   ⚠️  Container is using significant CPU (this is normal during migrations)"
    RECOMMENDED_CPU_CORES=$CURRENT_CPU_CORES
elif (($(echo "$AVG_CPU < 2000" | bc -l))); then
    echo "🟡 CPU Allocation: HIGH USAGE"
    echo "   Using ~${CORES_USED} of ${CURRENT_CPU_CORES} cores"
    echo "   ⚠️  Container is using most allocated CPU"
    RECOMMENDED_CPU_CORES=$(echo "scale=0; ($CURRENT_CPU_CORES * 1.5) / 1" | bc)
    echo "   📈 Consider increasing to ${RECOMMENDED_CPU_CORES} cores for faster processing"
else
    echo "🔴 CPU Allocation: MAXED OUT"
    echo "   Container is CPU-constrained!"
    RECOMMENDED_CPU_CORES=$(echo "scale=0; ($CURRENT_CPU_CORES * 2) / 1" | bc)
    echo "   🚨 Increase to ${RECOMMENDED_CPU_CORES} cores immediately"
fi

echo ""

# Memory recommendations
MEM_USAGE_GB=$(echo "$MEM_USAGE" | sed 's/GiB//' | sed 's/MiB//')
if [[ $MEM_USAGE =~ "MiB" ]]; then
    MEM_USAGE_GB=$(echo "scale=2; $MEM_USAGE_GB / 1024" | bc)
fi

if (($(echo "$AVG_MEM < 25" | bc -l))); then
    echo "🟢 Memory Allocation: EXCELLENT"
    echo "   Using only ${AVG_MEM}% of allocated memory"
    echo "   ✅ No memory adjustment needed"
    RECOMMENDED_MEM_GB=$CURRENT_MEM_GB
elif (($(echo "$AVG_MEM < 50" | bc -l))); then
    echo "🟢 Memory Allocation: GOOD"
    echo "   Using ${AVG_MEM}% of allocated memory"
    echo "   ✅ Current allocation is appropriate"
    RECOMMENDED_MEM_GB=$CURRENT_MEM_GB
elif (($(echo "$AVG_MEM < 75" | bc -l))); then
    echo "🟡 Memory Allocation: MODERATE"
    echo "   Using ${AVG_MEM}% of allocated memory"
    echo "   ⚠️  Getting close to limit"
    RECOMMENDED_MEM_GB=$(echo "scale=0; ($CURRENT_MEM_GB * 1.5) / 1" | bc)
    echo "   📈 Consider increasing to ${RECOMMENDED_MEM_GB}GB"
elif (($(echo "$AVG_MEM < 90" | bc -l))); then
    echo "🟠 Memory Allocation: HIGH USAGE"
    echo "   Using ${AVG_MEM}% of allocated memory"
    echo "   ⚠️  Approaching memory limit"
    RECOMMENDED_MEM_GB=$(echo "scale=0; ($CURRENT_MEM_GB * 2) / 1" | bc)
    echo "   🚨 Increase to ${RECOMMENDED_MEM_GB}GB to prevent OOM"
else
    echo "🔴 Memory Allocation: CRITICAL"
    echo "   Using ${AVG_MEM}% of allocated memory!"
    echo "   🚨 Container may be OOM-killed soon!"
    RECOMMENDED_MEM_GB=$(echo "scale=0; ($CURRENT_MEM_GB * 2) / 1" | bc)
    echo "   🚨 Increase to ${RECOMMENDED_MEM_GB}GB IMMEDIATELY"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎯 Recommended Configuration"
echo "============================="
echo ""
echo "CPU Limit:     ${RECOMMENDED_CPU_CORES} cores"
echo "Memory Limit:  ${RECOMMENDED_MEM_GB}GB"
echo ""

# Check if changes needed
if [ "$RECOMMENDED_CPU_CORES" != "$CURRENT_CPU_CORES" ] || [ "$RECOMMENDED_MEM_GB" != "$CURRENT_MEM_GB" ]; then
    echo "📝 Changes Needed:"
    echo ""
    echo "Edit docker-compose.rootless.yml:"
    echo ""
    echo "  deploy:"
    echo "    resources:"
    echo "      limits:"
    echo "        cpus: '${RECOMMENDED_CPU_CORES}.0'"
    echo "        memory: ${RECOMMENDED_MEM_GB}G"
    echo ""
    echo "Then redeploy:"
    echo "  ./deploy-clean.sh"
else
    echo "✅ Current allocation is optimal - no changes needed!"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
