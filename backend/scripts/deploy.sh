#!/bin/bash
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-staging}
MAX_RETRIES=30
RETRY_INTERVAL=10
HEALTH_CHECK_TIMEOUT=300

# Slack webhook (set via environment variable)
SLACK_WEBHOOK="${SLACK_WEBHOOK_URL:-}"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

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
                \"title\": \"Deployment $status: $ENVIRONMENT\",
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
        "ECR_REGISTRY"
        "ECS_CLUSTER_NAME"
        "ECS_SERVICE_NAME"
        "ENVIRONMENT"
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

    # Validate Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker not installed"
        return 1
    fi

    log "Environment validation passed"
    return 0
}

# Function to run database migrations
run_migrations() {
    log "Running database migrations..."

    cd "$PROJECT_ROOT"

    # Run alembic migrations
    if ! alembic upgrade head; then
        log_error "Database migration failed"
        return 1
    fi

    log "Database migrations completed successfully"
    return 0
}

# Function to build Docker image
build_docker_image() {
    local image_tag=$1

    log "Building Docker image: $image_tag"

    cd "$PROJECT_ROOT"

    if ! docker build -t "$image_tag" -f Dockerfile .; then
        log_error "Docker build failed"
        return 1
    fi

    log "Docker image built successfully"
    return 0
}

# Function to push Docker image to ECR
push_docker_image() {
    local image_tag=$1
    local ecr_uri=$2

    log "Pushing Docker image to ECR: $ecr_uri"

    # Tag image for ECR
    docker tag "$image_tag" "$ecr_uri"

    # Login to ECR
    aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY"

    # Push image
    if ! docker push "$ecr_uri"; then
        log_error "Docker push failed"
        return 1
    fi

    log "Docker image pushed successfully"
    return 0
}

# Function to get current task definition
get_current_task_definition() {
    local cluster=$1
    local service=$2

    aws ecs describe-services \
        --cluster "$cluster" \
        --services "$service" \
        --region "$AWS_REGION" \
        --query 'services[0].taskDefinition' \
        --output text
}

# Function to register new task definition
register_task_definition() {
    local task_def_arn=$1
    local new_image=$2

    log "Registering new task definition with image: $new_image"

    # Get current task definition
    local task_def=$(aws ecs describe-task-definition \
        --task-definition "$task_def_arn" \
        --region "$AWS_REGION" \
        --query 'taskDefinition' \
        --output json)

    # Update image in task definition
    local new_task_def=$(echo "$task_def" | \
        jq --arg IMAGE "$new_image" \
        '.containerDefinitions[0].image = $IMAGE | del(.taskDefinitionArn) | del(.revision) | del(.status) | del(.requiresAttributes)')

    # Register new task definition
    local new_revision=$(aws ecs register-task-definition \
        --region "$AWS_REGION" \
        --cli-input-json "$(echo "$new_task_def" | jq -c .)" \
        --query 'taskDefinition.revision' \
        --output text)

    echo "${task_def_arn%:*}:$new_revision"
}

# Function to update ECS service
update_ecs_service() {
    local cluster=$1
    local service=$2
    local task_def=$3

    log "Updating ECS service: $service"

    aws ecs update-service \
        --cluster "$cluster" \
        --service "$service" \
        --task-definition "$task_def" \
        --region "$AWS_REGION" \
        --force-new-deployment \
        > /dev/null

    log "ECS service update initiated"
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

# Function to check service health
check_service_health() {
    local cluster=$1
    local service=$2

    log "Checking service health..."

    local service_info=$(aws ecs describe-services \
        --cluster "$cluster" \
        --services "$service" \
        --region "$AWS_REGION" \
        --query 'services[0]' \
        --output json)

    # Check if there are any task failures
    local failures=$(echo "$service_info" | jq '.failures | length')
    if [ "$failures" -gt 0 ]; then
        log_error "Service has failed tasks"
        echo "$service_info" | jq '.failures'
        return 1
    fi

    # Check if all tasks are healthy
    local running_count=$(echo "$service_info" | jq '.runningCount')
    local desired_count=$(echo "$service_info" | jq '.desiredCount')

    if [ "$running_count" -lt "$desired_count" ]; then
        log_error "Not all tasks are running (Running: $running_count, Desired: $desired_count)"
        return 1
    fi

    log "Service health check passed"
    return 0
}

# Function to rollback deployment
rollback_deployment() {
    local cluster=$1
    local service=$2
    local previous_task_def=$3

    log_error "Deployment failed, initiating rollback..."

    if [ -z "$previous_task_def" ]; then
        log_warn "No previous task definition available for rollback"
        return 1
    fi

    log "Rolling back to previous task definition: $previous_task_def"

    aws ecs update-service \
        --cluster "$cluster" \
        --service "$service" \
        --task-definition "$previous_task_def" \
        --region "$AWS_REGION" \
        --force-new-deployment \
        > /dev/null

    # Wait for rollback to complete
    if wait_for_service_stability "$cluster" "$service" "$HEALTH_CHECK_TIMEOUT"; then
        log "Rollback completed successfully"
        send_slack_notification "rollback" "Deployment rollback completed for $ENVIRONMENT"
        return 0
    else
        log_error "Rollback failed to complete"
        send_slack_notification "failure" "Rollback failed for $ENVIRONMENT"
        return 1
    fi
}

# Main deployment flow
main() {
    log "Starting deployment to $ENVIRONMENT"

    # Validate inputs
    if [ "$ENVIRONMENT" != "staging" ] && [ "$ENVIRONMENT" != "production" ]; then
        log_error "Invalid environment: $ENVIRONMENT. Must be 'staging' or 'production'"
        exit 1
    fi

    # Set environment-specific variables
    if [ "$ENVIRONMENT" = "staging" ]; then
        ECS_CLUSTER_NAME="${ECS_CLUSTER_NAME_STAGING:-rosier-staging}"
        ECS_SERVICE_NAME="${ECS_SERVICE_NAME_STAGING:-rosier-api-staging}"
        DATABASE_URL="${DATABASE_URL_STAGING}"
    else
        ECS_CLUSTER_NAME="${ECS_CLUSTER_NAME_PRODUCTION:-rosier-production}"
        ECS_SERVICE_NAME="${ECS_SERVICE_NAME_PRODUCTION:-rosier-api}"
        DATABASE_URL="${DATABASE_URL_PRODUCTION}"
    fi

    # Step 1: Validate environment
    if ! validate_environment; then
        log_error "Environment validation failed"
        send_slack_notification "failure" "Environment validation failed"
        exit 1
    fi

    # Step 2: Run database migrations
    if ! run_migrations; then
        log_error "Database migrations failed"
        send_slack_notification "failure" "Database migration failed during deployment to $ENVIRONMENT"
        exit 1
    fi

    # Step 3: Build Docker image
    local git_commit=$(git rev-parse --short HEAD)
    local image_tag="rosier-api:${ENVIRONMENT}-${git_commit}"
    local timestamp=$(date +%s)

    if ! build_docker_image "$image_tag"; then
        log_error "Docker build failed"
        send_slack_notification "failure" "Docker build failed for $ENVIRONMENT"
        exit 1
    fi

    # Step 4: Push to ECR
    local ecr_uri="${ECR_REGISTRY}/rosier-api:${ENVIRONMENT}-${git_commit}-${timestamp}"
    if ! push_docker_image "$image_tag" "$ecr_uri"; then
        log_error "Docker push failed"
        send_slack_notification "failure" "Docker push failed for $ENVIRONMENT"
        exit 1
    fi

    # Step 5: Get current task definition
    local current_task_def=$(get_current_task_definition "$ECS_CLUSTER_NAME" "$ECS_SERVICE_NAME")
    log "Current task definition: $current_task_def"

    # Step 6: Register new task definition
    local new_task_def=$(register_task_definition "$current_task_def" "$ecr_uri")
    if [ $? -ne 0 ]; then
        log_error "Task definition registration failed"
        send_slack_notification "failure" "Task definition registration failed for $ENVIRONMENT"
        exit 1
    fi
    log "New task definition: $new_task_def"

    # Step 7: Update ECS service
    update_ecs_service "$ECS_CLUSTER_NAME" "$ECS_SERVICE_NAME" "$new_task_def"

    # Step 8: Wait for service to stabilize
    if ! wait_for_service_stability "$ECS_CLUSTER_NAME" "$ECS_SERVICE_NAME" "$HEALTH_CHECK_TIMEOUT"; then
        log_error "Service failed to stabilize"
        rollback_deployment "$ECS_CLUSTER_NAME" "$ECS_SERVICE_NAME" "$current_task_def"
        send_slack_notification "failure" "Service failed to stabilize after deployment to $ENVIRONMENT"
        exit 1
    fi

    # Step 9: Check service health
    if ! check_service_health "$ECS_CLUSTER_NAME" "$ECS_SERVICE_NAME"; then
        log_error "Service health check failed"
        rollback_deployment "$ECS_CLUSTER_NAME" "$ECS_SERVICE_NAME" "$current_task_def"
        send_slack_notification "failure" "Service health check failed after deployment to $ENVIRONMENT"
        exit 1
    fi

    # Success
    log "Deployment to $ENVIRONMENT completed successfully!"
    send_slack_notification "success" "Deployment to $ENVIRONMENT completed successfully (Commit: $git_commit)"
    exit 0
}

# Run main function
main "$@"
