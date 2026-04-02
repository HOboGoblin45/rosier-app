#!/bin/bash
set -e

# Load testing script for Rosier API
# Runs Locust load tests simulating realistic user behavior

# Configuration
ENVIRONMENT=${1:-staging}
NUM_USERS=${2:-1000}
SPAWN_RATE=${3:-50}
DURATION=${4:-10m}
REPORT_FILE="load_test_report_$(date +%s).html"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to log
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR${NC} $1" >&2
}

# Validate environment
if [ "$ENVIRONMENT" != "staging" ] && [ "$ENVIRONMENT" != "production" ]; then
    log_error "Invalid environment: $ENVIRONMENT. Use 'staging' or 'production'"
    exit 1
fi

# Set API endpoint based on environment
if [ "$ENVIRONMENT" = "staging" ]; then
    API_HOST="https://api-staging.rosier.app"
else
    API_HOST="https://api.rosier.app"
fi

log "Load Testing Configuration"
log "========================="
log "Environment: $ENVIRONMENT"
log "API Host: $API_HOST"
log "Target Users: $NUM_USERS"
log "Spawn Rate: $NUM_USERS per minute"
log "Duration: $DURATION"
log "Report File: $REPORT_FILE"
echo ""

# Verify Locust is installed
if ! command -v locust &> /dev/null; then
    log_error "Locust is not installed. Install with: pip install locust"
    exit 1
fi

# Verify we're in the correct directory
if [ ! -f "locustfile.py" ]; then
    log_error "locustfile.py not found in current directory"
    exit 1
fi

log "Starting load test..."
log "Press Ctrl+C to stop the test"
echo ""

# Run Locust with specified configuration
locust \
    --host="$API_HOST" \
    --users "$NUM_USERS" \
    --spawn-rate "$SPAWN_RATE" \
    --run-time "$DURATION" \
    --csv=load_test_stats \
    --html="$REPORT_FILE" \
    --loglevel INFO \
    2>&1 | tee load_test.log

# Capture exit code
EXIT_CODE=$?

log ""
log "Load test completed with exit code: $EXIT_CODE"
log ""

# Parse and display results
if [ -f "load_test_stats_stats.csv" ]; then
    log "Test Statistics Summary"
    log "======================"

    # Extract key metrics from CSV
    tail -n +2 "load_test_stats_stats.csv" | while IFS=',' read -r name requests fails \
        median average min max content_size requests_per_sec failures_per_sec; do
        if [ "$name" != "Total" ]; then
            printf "%20s | %5s reqs | %5s fails | %6sms avg | %6sms p95\n" \
                "$name" "$requests" "$fails" "$average" "$median"
        fi
    done

    echo ""

    # Print total line
    tail -n 1 "load_test_stats_stats.csv" | while IFS=',' read -r name requests fails \
        median average min max content_size requests_per_sec failures_per_sec; do
        log "TOTAL: $requests requests, $fails failures, ${average}ms average"
    done
else
    log_error "Failed to generate test statistics"
fi

log ""
log "Full report: $REPORT_FILE"

# Check if test was successful based on exit code
if [ $EXIT_CODE -ne 0 ]; then
    log_error "Load test failed or was interrupted"
    exit 1
else
    log "Load test completed successfully"
    exit 0
fi
