#!/bin/bash
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
API_URL=${1:-"http://localhost:8000"}
TIMEOUT=10
VERBOSE=${VERBOSE:-0}

# Exit codes
EXIT_HEALTHY=0
EXIT_UNHEALTHY=1
EXIT_PARTIAL=2

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

# Function to log
log() {
    if [ "$VERBOSE" = "1" ]; then
        echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
    fi
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
}

log_error() {
    echo -e "${RED}✗${NC} $1"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    CHECKS_WARNING=$((CHECKS_WARNING + 1))
}

# Function to check API health
check_api_health() {
    log "Checking API health endpoint..."

    local response=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT" \
        "$API_URL/health" 2>/dev/null || echo "000")

    if [ "$response" = "200" ]; then
        log_success "API health endpoint: OK"
        return 0
    else
        log_error "API health endpoint returned: $response"
        return 1
    fi
}

# Function to check database connectivity
check_database() {
    log "Checking database connectivity..."

    # Try via API endpoint if available
    local response=$(curl -s --max-time "$TIMEOUT" "$API_URL/health" 2>/dev/null || echo "{}")
    local db_status=$(echo "$response" | grep -o '"database":\s*\("ok"\|"failed"\)' | grep -o '\(ok\|failed\)' || echo "unknown")

    if [ "$db_status" = "ok" ]; then
        log_success "Database connectivity: OK"
        return 0
    elif [ "$db_status" = "failed" ]; then
        log_error "Database connectivity: FAILED"
        return 1
    else
        log_warn "Database connectivity: UNKNOWN (unable to determine status)"
        return 2
    fi
}

# Function to check Redis connectivity
check_redis() {
    log "Checking Redis connectivity..."

    # Try via API endpoint if available
    local response=$(curl -s --max-time "$TIMEOUT" "$API_URL/health" 2>/dev/null || echo "{}")
    local redis_status=$(echo "$response" | grep -o '"redis":\s*\("ok"\|"failed"\)' | grep -o '\(ok\|failed\)' || echo "unknown")

    if [ "$redis_status" = "ok" ]; then
        log_success "Redis connectivity: OK"
        return 0
    elif [ "$redis_status" = "failed" ]; then
        log_warn "Redis connectivity: DEGRADED (cache unavailable, service still operational)"
        return 2
    else
        log_warn "Redis connectivity: UNKNOWN (unable to determine status)"
        return 2
    fi
}

# Function to check Elasticsearch connectivity
check_elasticsearch() {
    log "Checking Elasticsearch connectivity..."

    # Try via API endpoint if available
    local response=$(curl -s --max-time "$TIMEOUT" "$API_URL/health" 2>/dev/null || echo "{}")
    local es_status=$(echo "$response" | grep -o '"elasticsearch":\s*\("ok"\|"failed"\)' | grep -o '\(ok\|failed\)' || echo "unknown")

    if [ "$es_status" = "ok" ]; then
        log_success "Elasticsearch connectivity: OK"
        return 0
    elif [ "$es_status" = "failed" ]; then
        log_warn "Elasticsearch connectivity: DEGRADED (search unavailable, service still operational)"
        return 2
    else
        log_warn "Elasticsearch connectivity: UNKNOWN (unable to determine status)"
        return 2
    fi
}

# Function to check API response time
check_api_latency() {
    log "Checking API response time..."

    local response_time=$(curl -s -o /dev/null -w "%{time_total}" --max-time "$TIMEOUT" \
        "$API_URL/health" 2>/dev/null || echo "999")

    local response_ms=$(echo "$response_time * 1000" | bc)

    if (( $(echo "$response_ms < 500" | bc -l) )); then
        log_success "API response time: ${response_ms}ms"
        return 0
    elif (( $(echo "$response_ms < 1000" | bc -l) )); then
        log_warn "API response time: ${response_ms}ms (slower than expected)"
        return 2
    else
        log_error "API response time: ${response_ms}ms (critical latency)"
        return 1
    fi
}

# Function to check HTTP connectivity
check_http_connectivity() {
    log "Checking HTTP connectivity..."

    if ! command -v curl &> /dev/null; then
        log_warn "curl not installed - skipping HTTP connectivity check"
        return 2
    fi

    local response=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT" \
        "$API_URL/" 2>/dev/null || echo "000")

    if [ "$response" = "200" ] || [ "$response" = "307" ] || [ "$response" = "308" ]; then
        log_success "HTTP connectivity: OK (status $response)"
        return 0
    else
        log_error "HTTP connectivity: FAILED (status $response)"
        return 1
    fi
}

# Function to display summary
display_summary() {
    echo ""
    echo "=== Health Check Summary ==="
    echo "API URL: $API_URL"
    echo "Checks Passed: $CHECKS_PASSED"
    echo "Checks Failed: $CHECKS_FAILED"
    echo "Checks Warning: $CHECKS_WARNING"
    echo ""

    if [ $CHECKS_FAILED -eq 0 ] && [ $CHECKS_WARNING -eq 0 ]; then
        echo -e "${GREEN}Status: HEALTHY${NC}"
        return $EXIT_HEALTHY
    elif [ $CHECKS_FAILED -eq 0 ]; then
        echo -e "${YELLOW}Status: PARTIALLY HEALTHY${NC} (with warnings)"
        return $EXIT_PARTIAL
    else
        echo -e "${RED}Status: UNHEALTHY${NC}"
        return $EXIT_UNHEALTHY
    fi
}

# Function to display usage
show_usage() {
    echo "Usage: $0 [API_URL] [OPTIONS]"
    echo ""
    echo "Arguments:"
    echo "  API_URL     - API endpoint URL (default: http://localhost:8000)"
    echo ""
    echo "Environment Variables:"
    echo "  VERBOSE     - Set to 1 to show detailed logging"
    echo "  TIMEOUT     - Request timeout in seconds (default: 10)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Check local API"
    echo "  $0 https://api.rosier.app            # Check production API"
    echo "  VERBOSE=1 $0 https://api-staging.rosier.app"
    echo ""
}

# Main health check flow
main() {
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_usage
        exit 0
    fi

    echo "Rosier Health Check"
    echo "Time: $(date)"
    echo ""

    # Run health checks
    check_http_connectivity
    check_api_health
    check_api_latency
    check_database
    check_redis
    check_elasticsearch

    # Display summary and return appropriate exit code
    display_summary
    local exit_code=$?

    exit $exit_code
}

# Run main function
main "$@"
