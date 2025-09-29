#!/bin/bash

# ClarityClear Performance Monitoring Script
# Continuously monitors application performance and sends metrics to Prometheus

set -euo pipefail

# Configuration
PROMETHEUS_PUSHGATEWAY="${PROMETHEUS_PUSHGATEWAY:-http://192.168.0.207:9091}"
APP_URL="${APP_URL:-https://app.andub.go.ro}"
API_URL="${API_URL:-https://pb.andub.go.ro}"
MONITORING_INTERVAL="${MONITORING_INTERVAL:-30}"
NAMESPACE="clarity_performance"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Log function
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

# Function to measure response time
measure_response_time() {
    local url=$1
    local name=$2

    local start_time=$(date +%s%N)
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" -m 10 "$url" 2>/dev/null || echo "000")
    local end_time=$(date +%s%N)

    local duration=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds

    echo "$name $duration $http_code"
}

# Function to get Core Web Vitals from the application
get_web_vitals() {
    local response=$(curl -s -m 5 "${APP_URL}/api/metrics/vitals" 2>/dev/null || echo "{}")

    if [ ! -z "$response" ] && [ "$response" != "{}" ]; then
        echo "$response"
    else
        echo '{"lcp": 0, "fid": 0, "cls": 0}'
    fi
}

# Function to check system resources
check_system_resources() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    local mem_usage=$(free -m | awk 'NR==2{printf "%.2f", $3*100/$2}')
    local disk_usage=$(df -h / | awk 'NR==2{print $5}' | sed 's/%//')

    echo "$cpu_usage $mem_usage $disk_usage"
}

# Function to send metrics to Prometheus
send_to_prometheus() {
    local metric_name=$1
    local metric_value=$2
    local metric_labels=$3

    local data="${NAMESPACE}_${metric_name}${metric_labels} ${metric_value}"

    echo "$data" | curl -s -X POST --data-binary @- "${PROMETHEUS_PUSHGATEWAY}/metrics/job/performance_monitor" &>/dev/null
}

# Function to perform health checks
perform_health_checks() {
    local services=("${APP_URL}/api/health" "${API_URL}/api/health" "${APP_URL}/_next/static")
    local all_healthy=true

    for service in "${services[@]}"; do
        local status=$(curl -s -o /dev/null -w "%{http_code}" -m 5 "$service" 2>/dev/null || echo "000")

        if [ "$status" != "200" ] && [ "$status" != "304" ]; then
            all_healthy=false
            warning "Service $service returned status: $status"
        fi
    done

    echo "$all_healthy"
}

# Function to monitor database performance
monitor_database() {
    local query_time=$(curl -s -m 5 "${API_URL}/api/metrics/db" 2>/dev/null | jq -r '.query_time_ms // 0' 2>/dev/null || echo "0")
    local connection_count=$(curl -s -m 5 "${API_URL}/api/metrics/db" 2>/dev/null | jq -r '.active_connections // 0' 2>/dev/null || echo "0")

    echo "$query_time $connection_count"
}

# Function to monitor cache performance
monitor_cache() {
    local cache_stats=$(curl -s -m 5 "${APP_URL}/api/metrics/cache" 2>/dev/null || echo "{}")

    if [ ! -z "$cache_stats" ] && [ "$cache_stats" != "{}" ]; then
        local hit_rate=$(echo "$cache_stats" | jq -r '.hit_rate // 0' 2>/dev/null || echo "0")
        local memory_usage=$(echo "$cache_stats" | jq -r '.memory_usage_mb // 0' 2>/dev/null || echo "0")
        echo "$hit_rate $memory_usage"
    else
        echo "0 0"
    fi
}

# Main monitoring loop
main() {
    log "Starting ClarityClear Performance Monitor"
    log "Monitoring interval: ${MONITORING_INTERVAL}s"
    log "App URL: ${APP_URL}"
    log "API URL: ${API_URL}"

    while true; do
        log "Collecting performance metrics..."

        # Measure response times
        read -r name duration status <<< $(measure_response_time "${APP_URL}" "homepage")
        send_to_prometheus "response_time_ms" "$duration" "{endpoint=\"homepage\",status=\"$status\"}"

        read -r name duration status <<< $(measure_response_time "${API_URL}/api/health" "api_health")
        send_to_prometheus "response_time_ms" "$duration" "{endpoint=\"api_health\",status=\"$status\"}"

        # Get Web Vitals
        web_vitals=$(get_web_vitals)
        if [ "$web_vitals" != '{"lcp": 0, "fid": 0, "cls": 0}' ]; then
            lcp=$(echo "$web_vitals" | jq -r '.lcp // 0')
            fid=$(echo "$web_vitals" | jq -r '.fid // 0')
            cls=$(echo "$web_vitals" | jq -r '.cls // 0')

            send_to_prometheus "web_vitals_lcp_ms" "$lcp" ""
            send_to_prometheus "web_vitals_fid_ms" "$fid" ""
            send_to_prometheus "web_vitals_cls" "$cls" ""

            log "Web Vitals - LCP: ${lcp}ms, FID: ${fid}ms, CLS: ${cls}"
        fi

        # Check system resources
        read -r cpu mem disk <<< $(check_system_resources)
        send_to_prometheus "system_cpu_usage_percent" "$cpu" ""
        send_to_prometheus "system_memory_usage_percent" "$mem" ""
        send_to_prometheus "system_disk_usage_percent" "$disk" ""

        log "System Resources - CPU: ${cpu}%, Memory: ${mem}%, Disk: ${disk}%"

        # Monitor database
        read -r query_time connections <<< $(monitor_database)
        if [ "$query_time" != "0" ]; then
            send_to_prometheus "database_query_time_ms" "$query_time" ""
            send_to_prometheus "database_active_connections" "$connections" ""
            log "Database - Query Time: ${query_time}ms, Active Connections: ${connections}"
        fi

        # Monitor cache
        read -r hit_rate cache_memory <<< $(monitor_cache)
        if [ "$hit_rate" != "0" ]; then
            send_to_prometheus "cache_hit_rate_percent" "$hit_rate" ""
            send_to_prometheus "cache_memory_usage_mb" "$cache_memory" ""
            log "Cache - Hit Rate: ${hit_rate}%, Memory Usage: ${cache_memory}MB"
        fi

        # Perform health checks
        health_status=$(perform_health_checks)
        if [ "$health_status" = "true" ]; then
            send_to_prometheus "health_check_status" "1" ""
            log "Health Check: All services healthy"
        else
            send_to_prometheus "health_check_status" "0" ""
            error "Health Check: Some services are unhealthy"
        fi

        # Calculate and report SLI metrics
        # Availability SLI (based on health checks)
        send_to_prometheus "sli_availability" "$([ "$health_status" = "true" ] && echo 1 || echo 0)" ""

        # Performance SLI (based on response time)
        performance_sli=$([ "$duration" -lt 500 ] && echo 1 || echo 0)
        send_to_prometheus "sli_performance" "$performance_sli" ""

        log "Metrics sent to Prometheus successfully"
        log "---"

        sleep "$MONITORING_INTERVAL"
    done
}

# Trap signals for graceful shutdown
trap 'log "Shutting down performance monitor..."; exit 0' SIGINT SIGTERM

# Check dependencies
for cmd in curl jq; do
    if ! command -v $cmd &> /dev/null; then
        error "Required command '$cmd' is not installed"
        exit 1
    fi
done

# Run main monitoring loop
main