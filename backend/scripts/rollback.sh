#!/bin/bash
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-staging}
MAX_ROLLBACK_WAIT=300
RETRY_INTERVAL=10

# Slack webhook (set via environment variable)
SLACK_WEBHOOK="${SLACK_WEBHOOK_URL:-}"

# Function to log
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING${NC} $1"
}

# Function to send Slack notification
send_slack_notification() {
    local status=$1
    local message=$2

    if [ -z "$SLACK_WEBHOOK" ]; then
        return
    fi

    local color="good"
    if [ "$status" = "failure" ]; then
        color="danger"
    fi

    curl -X POST "$SLACK_WEBHOOK" \
        -H 'Content-Type: application/json' \
        -d "{
            \"attachments\": [{
                \"color\": \"$color\",
                \"title\": \"Rollback $status: $ENVIRONMENT\",
                \"text\": \"$message\",
                \"ts\": $(date +%s)
            }]
        }" \
        2>/dev/null || log_warn "Failed to send Slack notification"
}

# Function to validate environment
validate_environment() {
    log "Validating environment..."

    local required_vars=(
        "AWS_REGION"
        "AWS_ACCOUNT_ID"
        "ECS_CLUSTER_NAME"
        "ECS_SERVICE_NAME"
    )

    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            log_error "Required environment variable not set: $var"
            return 1
        fi
    done

    # Validate AWS CLI
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI not installed"
        return 1
    fi

    log "Environment validation passed"
    return 0
}

# Function to get task definition history
get_task_definition_history() {
    local cluster=$1
    local service=$2
    local limit=${3:-5}

    log "Fetching task definition history (last $limit)..."

    # Get current task definition
    local current_task_def=$(aws ecs describe-services \
        --cluster "$cluster" \
        --services "$service" \
        --region "$AWS_REGION" \
        --query 'services[0].taskDefinition' \
        --output text)

    local family=$(echo "$current_task_def" | cut -d':' -f6 | cut -d'/' -f2)

    # List task definition revisions
    aws ecs list-task-definitions \
        --family-prefix "$family" \
        --region "$AWS_REGION" \
        --max-items "$limit" \
        --sort DESCENDING \
        --query 'taskDefinitionArns' \
        --output text
}

# Function to get previous task definition
get_previous_task_definition() {
    local cluster=$1
    local service=$2

    log "Finding previous stable task definition..."

    local current_task_def=$(aws ecs describe-services \
        --cluster "$cluster" \
        --services "$service" \
        --region "$AWS_REGION" \
        --query 'services[0].taskDefinition' \
        --output text)

    log "Current task definition: $current_task_def"

    # Get task definition family
    local family=$(echo "$current_task_def" | cut -d':' -f6 | cut -d'/' -f2)

    # Get all revisions (desc order)
    local revisions=$(aws ecs list-task-definitions \
        --family-prefix "$family" \
        --region "$AWS_REGION" \
        --sort DESCENDING \
        --query 'taskDefinitionArns' \
        --output text)

    # Find the previous different revision
    local prev_found=false
    for revision in $revisions; do
        if [ "$revision" != "$current_task_def" ]; then
            echo "$revision"
            return 0
        fi
    done

    log_error "Could not find a previous task definition to rollback to"
    return 1
}

# Function to update service to task definition
update_service() {
    local cluster=$1
    local service=$2
    local task_def=$3

    log "Updating service to task definition: $task_def"

    aws ecs update-service \
        --cluster "$cluster" \
        --service "$service" \
        --task-definition "$task_def" \
        --region "$AWS_REGION" \
        --force-new-deployment \
        > /dev/null

    log "Service update initiated"
}

# Function to wait for service stability
wait_for_service_stability() {
    local cluster=$1
    local service=$2
    local timeout=$3
    local elapsed=0

    log "Waiting for service to stabilize (max ${timeout}s)..."

    while [ $elapsed -lt "$timeout" ]; do
        local service_info=$(aws ecs describe-services \
            --cluster "$cluster" \
            --services "$service" \
            --region "$AWS_REGION" \
            --query 'services[0]' \
            --output json)

        local running_count=$(echo "$service_info" | jq '.runningCount')
        local desired_count=$(echo "$service_info" | jq '.desiredCount')
        local pending_count=$(echo "$service_info" | jq '.pendingCount')

        log "Status - Running: $running_count, Desired: $desired_count, Pending: $pending_count"

        if [ "$running_count" -eq "$desired_count" ] && [ "$pending_count" -eq 0 ]; then
            log "Service has stabilized successfully"
            return 0
        fi

        sleep $RETRY_INTERVAL
        elapsed=$((elapsed + RETRY_INTERVAL))
    done

    log_error "Service failed to stabilize within ${timeout}s"
    return 1
}

# Function to get service status details
get_service_status() {
    local cluster=$1
    local service=$2

    log "Service Status Details:"

    aws ecs describe-services \
        --cluster "$cluster" \
        --services "$service" \
        --region "$AWS_REGION" \
        --query 'services[0].[taskDefinition,runningCount,desiredCount,pendingCount]' \
        --output table
}

# Main rollback flow
main() {
    log "Starting rollback for $ENVIRONMENT"

    # Validate inputs
    if [ "$ENVIRONMENT" != "staging" ] && [ "$ENVIRONMENT" != "production" ]; then
        log_error "Invalid environment: $ENVIRONMENT. Must be 'staging' or 'production'"
        exit 1
    fi

    # Set environment-specific variables
    if [ "$ENVIRONMENT" = "staging" ]; then
        ECS_CLUSTER_NAME="${ECS_CLUSTER_NAME_STAGING:-rosier-staging}"
        ECS_SERVICE_NAME="${ECS_SERVICE_NAME_STAGING:-rosier-api-staging}"
    else
        ECS_CLUSTER_NAME="${ECS_CLUSTER_NAME_PRODUCTION:-rosier-production}"
        ECS_SERVICE_NAME="${ECS_SERVICE_NAME_PRODUCTION:-rosier-api}"
    fi

    # Step 1: Validate environment
    if ! validate_environment; then
        log_error "Environment validation failed"
        send_slack_notification "failure" "Environment validation failed for rollback"
        exit 1
    fi

    # Step 2: Find previous task definition
    local previous_task_def=$(get_previous_task_definition "$ECS_CLUSTER_NAME" "$ECS_SERVICE_NAME")
    if [ $? -ne 0 ]; then
        log_error "Failed to find previous task definition"
        send_slack_notification "failure" "No previous task definition found for rollback to $ENVIRONMENT"
        exit 1
    fi

    log "Previous task definition: $previous_task_def"

    # Step 3: Update service to previous task definition
    update_service "$ECS_CLUSTER_NAME" "$ECS_SERVICE_NAME" "$previous_task_def"

    # Step 4: Wait for service stability
    if ! wait_for_service_stability "$ECS_CLUSTER_NAME" "$ECS_SERVICE_NAME" "$MAX_ROLLBACK_WAIT"; then
        log_error "Service failed to stabilize after rollback"
        send_slack_notification "failure" "Rollback failed to stabilize for $ENVIRONMENT"
        exit 1
    fi

    # Step 5: Display final status
    get_service_status "$ECS_CLUSTER_NAME" "$ECS_SERVICE_NAME"

    # Success
    log "Rollback to $ENVIRONMENT completed successfully!"
    send_slack_notification "success" "Rollback to $ENVIRONMENT completed successfully. Task definition: $previous_task_def"
    exit 0
}

# Run main function
main "$@"
