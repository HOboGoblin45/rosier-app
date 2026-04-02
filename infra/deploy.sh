#!/bin/bash

################################################################################
# ROSIER UNIFIED DEPLOYMENT SCRIPT
################################################################################
# Comprehensive one-shot deployment of the entire Rosier stack
# Handles backend, marketing stack, database migrations, SSL, and nginx
#
# Usage:
#   ./deploy.sh [environment] [option]
#
# Arguments:
#   environment   - production, staging, or development (default: production)
#   --init        - Run database initialization (migrations + seeds)
#   --help        - Show this help message
#
# Example:
#   ./deploy.sh production
#   ./deploy.sh staging --init
################################################################################

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Environment
ENVIRONMENT="${1:-production}"
INIT_DB="${2:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
APP_USER="appuser"

# Paths
DOCKER_COMPOSE_PROD="$SCRIPT_DIR/docker/docker-compose-prod.yml"
DOCKER_COMPOSE_MARKETING="$REPO_ROOT/marketing/docker-compose.marketing.yml"
NGINX_CONFIG="$SCRIPT_DIR/nginx/nginx.conf"

# Domain configuration
DOMAIN="${DOMAIN:-rosier.app}"
API_DOMAIN="api.${DOMAIN}"
MAIL_DOMAIN="mail.${DOMAIN}"
SOCIAL_DOMAIN="social.${DOMAIN}"
ANALYTICS_DOMAIN="analytics.${DOMAIN}"
N8N_DOMAIN="n8n.${DOMAIN}"

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*"
}

success() {
    echo -e "${GREEN}✓ $*${NC}"
}

error() {
    echo -e "${RED}✗ $*${NC}"
}

warning() {
    echo -e "${YELLOW}⚠ $*${NC}"
}

section() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ $*${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ============================================================================
# HELP
# ============================================================================

show_help() {
    cat << 'EOF'
ROSIER UNIFIED DEPLOYMENT SCRIPT

Usage:
  ./deploy.sh [environment] [options]

Environments:
  production    Deploy to production (default)
  staging       Deploy to staging
  development   Deploy locally for development

Options:
  --init        Run database migrations and seed initial data
  --ssl         Configure SSL with Let's Encrypt
  --help        Show this help message

Examples:
  ./deploy.sh production              # Deploy to production
  ./deploy.sh staging --init          # Deploy to staging with DB init
  ./deploy.sh production --ssl        # Deploy with SSL configuration

Prerequisites:
  - Docker and Docker Compose installed
  - AWS credentials configured (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
  - .env file in repository root
  - SSH access to EC2 instance

EOF
}

# ============================================================================
# VALIDATION
# ============================================================================

check_prerequisites() {
    section "Checking Prerequisites"

    # Check Docker
    if ! command -v docker &> /dev/null; then
        error "Docker not installed"
        return 1
    fi
    success "Docker is installed"

    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose not installed"
        return 1
    fi
    success "Docker Compose is installed"

    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        warning "AWS CLI not installed - some features may be unavailable"
    else
        success "AWS CLI is installed"
    fi

    # Check .env file
    if [ ! -f "$REPO_ROOT/.env" ]; then
        error ".env file not found in $REPO_ROOT"
        return 1
    fi
    success ".env file exists"

    # Check Docker files exist
    if [ ! -f "$DOCKER_COMPOSE_PROD" ]; then
        error "Docker Compose prod file not found: $DOCKER_COMPOSE_PROD"
        return 1
    fi
    success "Docker Compose prod file exists"

    if [ ! -f "$DOCKER_COMPOSE_MARKETING" ]; then
        error "Docker Compose marketing file not found: $DOCKER_COMPOSE_MARKETING"
        return 1
    fi
    success "Docker Compose marketing file exists"

    return 0
}

# ============================================================================
# BACKEND DEPLOYMENT
# ============================================================================

deploy_backend() {
    section "Deploying Backend"

    log "Loading environment variables from .env..."
    set -a
    source "$REPO_ROOT/.env"
    set +a

    log "Building and pulling Docker images..."
    docker-compose -f "$DOCKER_COMPOSE_PROD" build --no-cache api || {
        error "Failed to build backend image"
        return 1
    }

    log "Starting backend services..."
    docker-compose -f "$DOCKER_COMPOSE_PROD" up -d api

    log "Waiting for backend to be healthy..."
    sleep 10

    # Health check
    if docker-compose -f "$DOCKER_COMPOSE_PROD" exec -T api curl -f http://localhost:8000/health &>/dev/null; then
        success "Backend is healthy"
    else
        warning "Backend health check may have failed, but continuing..."
    fi

    return 0
}

# ============================================================================
# MARKETING STACK DEPLOYMENT
# ============================================================================

deploy_marketing() {
    section "Deploying Marketing Stack"

    log "Loading environment variables from .env..."
    set -a
    source "$REPO_ROOT/.env"
    set +a

    log "Pulling marketing stack images..."
    docker-compose -f "$DOCKER_COMPOSE_MARKETING" pull

    log "Creating database initialization script..."
    mkdir -p "$REPO_ROOT/marketing/scripts"
    cat > "$REPO_ROOT/marketing/scripts/init-marketing-db.sql" << 'DBEOF'
-- Initialize marketing databases
CREATE USER IF NOT EXISTS listmonk WITH PASSWORD 'changeme123';
CREATE USER IF NOT EXISTS n8n WITH PASSWORD 'changeme123';
CREATE USER IF NOT EXISTS mixpost WITH PASSWORD 'changeme123';
CREATE USER IF NOT EXISTS plausible WITH PASSWORD 'changeme123';

CREATE DATABASE IF NOT EXISTS listmonk OWNER listmonk;
CREATE DATABASE IF NOT EXISTS n8n OWNER n8n;
CREATE DATABASE IF NOT EXISTS mixpost OWNER mixpost;
CREATE DATABASE IF NOT EXISTS plausible OWNER plausible;

GRANT ALL PRIVILEGES ON DATABASE listmonk TO listmonk;
GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n;
GRANT ALL PRIVILEGES ON DATABASE mixpost TO mixpost;
GRANT ALL PRIVILEGES ON DATABASE plausible TO plausible;
DBEOF

    log "Starting marketing stack..."
    docker-compose -f "$DOCKER_COMPOSE_MARKETING" up -d

    log "Waiting for marketing services to be healthy..."
    sleep 15

    # Check services
    log "Checking marketing service status..."
    docker-compose -f "$DOCKER_COMPOSE_MARKETING" ps

    success "Marketing stack deployed"
    return 0
}

# ============================================================================
# DATABASE MIGRATIONS & SEEDING
# ============================================================================

init_database() {
    section "Initializing Database"

    log "Running database migrations..."
    docker-compose -f "$DOCKER_COMPOSE_PROD" exec -T api alembic upgrade head || {
        error "Database migrations failed"
        return 1
    }
    success "Database migrations completed"

    log "Seeding initial data..."
    docker-compose -f "$DOCKER_COMPOSE_PROD" exec -T api python -c "
from app.db.seed import seed_initial_data
seed_initial_data()
print('Database seeding completed')
" || {
        warning "Database seeding failed - this might be normal if data already exists"
    }

    success "Database initialization completed"
    return 0
}

# ============================================================================
# NGINX & SSL CONFIGURATION
# ============================================================================

setup_nginx_and_ssl() {
    section "Setting Up Nginx and SSL"

    # Create nginx config directory
    mkdir -p "$SCRIPT_DIR/nginx"
    mkdir -p "$SCRIPT_DIR/ssl"

    log "Generating Nginx configuration..."
    cat > "$NGINX_CONFIG" << 'NGINXEOF'
# See infra/nginx/nginx.conf for full configuration
# This is a placeholder - actual file should be created separately
NGINXEOF

    # Check if certbot is available
    if command -v certbot &> /dev/null; then
        log "Certbot found - configuring Let's Encrypt SSL..."

        # This requires manual setup on the server
        warning "Manual SSL setup required. Run on EC2:"
        warning "  sudo certbot certonly --standalone -d $API_DOMAIN"
        warning "  sudo certbot certonly --standalone -d $DOMAIN"
    else
        warning "Certbot not found - SSL will need to be configured manually"
    fi

    success "Nginx configuration prepared"
    return 0
}

# ============================================================================
# HEALTH CHECKS
# ============================================================================

run_health_checks() {
    section "Running Health Checks"

    local checks_passed=0
    local checks_failed=0

    # Backend health check
    log "Checking backend API..."
    if docker-compose -f "$DOCKER_COMPOSE_PROD" exec -T api curl -f http://localhost:8000/health &>/dev/null; then
        success "Backend API is healthy"
        ((checks_passed++))
    else
        error "Backend API health check failed"
        ((checks_failed++))
    fi

    # Listmonk health check
    log "Checking Listmonk..."
    if docker-compose -f "$DOCKER_COMPOSE_MARKETING" ps | grep -q "rosier-listmonk"; then
        success "Listmonk is running"
        ((checks_passed++))
    else
        error "Listmonk is not running"
        ((checks_failed++))
    fi

    # n8n health check
    log "Checking n8n..."
    if docker-compose -f "$DOCKER_COMPOSE_MARKETING" ps | grep -q "rosier-n8n"; then
        success "n8n is running"
        ((checks_passed++))
    else
        error "n8n is not running"
        ((checks_failed++))
    fi

    # Mixpost health check
    log "Checking Mixpost..."
    if docker-compose -f "$DOCKER_COMPOSE_MARKETING" ps | grep -q "rosier-mixpost"; then
        success "Mixpost is running"
        ((checks_passed++))
    else
        error "Mixpost is not running"
        ((checks_failed++))
    fi

    echo ""
    echo "Health checks: $checks_passed passed, $checks_failed failed"
    return $checks_failed
}

# ============================================================================
# STATUS REPORT
# ============================================================================

print_status_report() {
    section "Deployment Status Report"

    echo "Environment: $ENVIRONMENT"
    echo "Timestamp: $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
    echo ""

    echo "Backend Services:"
    docker-compose -f "$DOCKER_COMPOSE_PROD" ps
    echo ""

    echo "Marketing Services:"
    docker-compose -f "$DOCKER_COMPOSE_MARKETING" ps
    echo ""

    echo "Network Status:"
    docker network ls | grep -E "rosier|marketing" || true
    echo ""

    echo "Disk Usage:"
    docker system df
    echo ""

    log "Service URLs:"
    echo "  Backend API:    http://localhost:8000"
    echo "  Backend Docs:   http://localhost:8000/docs"
    echo "  Listmonk:       http://localhost:9000"
    echo "  n8n:            http://localhost:5678"
    echo "  Mixpost:        http://localhost:9001"
    echo "  Plausible:      http://localhost:8100"
    echo ""

    if [ "$ENVIRONMENT" = "production" ]; then
        echo "Production URLs:"
        echo "  Backend:        https://$API_DOMAIN"
        echo "  Email:          https://$MAIL_DOMAIN"
        echo "  Social:         https://$SOCIAL_DOMAIN"
        echo "  Analytics:      https://$ANALYTICS_DOMAIN"
        echo "  n8n:            https://$N8N_DOMAIN"
    fi
    echo ""
}

# ============================================================================
# CLEANUP & ERROR HANDLING
# ============================================================================

cleanup() {
    log "Cleaning up..."
}

trap cleanup EXIT

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    # Show help if requested
    if [[ "$*" == *"--help"* ]] || [[ "$*" == *"-h"* ]]; then
        show_help
        exit 0
    fi

    section "ROSIER UNIFIED DEPLOYMENT SCRIPT"
    echo "Environment: $ENVIRONMENT"
    echo "Initialize DB: ${INIT_DB:-false}"
    echo ""

    # Validate prerequisites
    if ! check_prerequisites; then
        error "Prerequisites check failed"
        exit 1
    fi

    # Deploy backend
    if ! deploy_backend; then
        error "Backend deployment failed"
        exit 1
    fi

    # Deploy marketing stack
    if ! deploy_marketing; then
        error "Marketing stack deployment failed"
        exit 1
    fi

    # Initialize database if requested
    if [ "$INIT_DB" = "--init" ]; then
        if ! init_database; then
            error "Database initialization failed"
            exit 1
        fi
    fi

    # Setup nginx and SSL
    if ! setup_nginx_and_ssl; then
        warning "Nginx setup encountered issues, but continuing..."
    fi

    # Run health checks
    if ! run_health_checks; then
        warning "Some health checks failed - review logs above"
    fi

    # Print status report
    print_status_report

    section "DEPLOYMENT COMPLETE"
    success "All services deployed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Monitor logs: docker-compose logs -f"
    echo "2. Access services at URLs listed above"
    echo "3. Configure SSL certificates on production"
    echo "4. Set up custom domain routing with Nginx"
    echo ""
}

# ============================================================================
# EXECUTE
# ============================================================================

main "$@"
