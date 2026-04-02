#!/bin/bash

################################################################################
# Rosier Marketing Automation Stack - One-Click Setup Script
#
# This script automates the deployment of the complete marketing stack:
# - Listmonk (email marketing)
# - n8n (workflow automation)
# - Mixpost (social media scheduling)
# - Plausible (analytics)
# - PostgreSQL (database)
# - Redis (cache)
#
# Usage: ./setup.sh
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ============================================================================
# PRE-FLIGHT CHECKS
# ============================================================================

log_info "Starting Rosier Marketing Stack Setup..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed. Please install Docker first."
    log_info "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    log_error "Docker Compose is not installed. Please install Docker Compose first."
    log_info "Visit: https://docs.docker.com/compose/install/"
    exit 1
fi

# Check if Docker daemon is running
if ! docker info > /dev/null 2>&1; then
    log_error "Docker daemon is not running. Please start Docker."
    exit 1
fi

log_success "Docker and Docker Compose are installed"

# ============================================================================
# CREATE REQUIRED DIRECTORIES
# ============================================================================

log_info "Creating directory structure..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$SCRIPT_DIR/workflows"
mkdir -p "$SCRIPT_DIR/email_templates"
mkdir -p "$SCRIPT_DIR/scripts"

log_success "Directories created"

# ============================================================================
# GENERATE SECURE CREDENTIALS
# ============================================================================

log_info "Generating secure credentials..."

# Function to generate random password
generate_password() {
    openssl rand -base64 32 | tr -d '\n'
}

# Function to generate hex token
generate_token() {
    openssl rand -hex 32 | tr -d '\n'
}

# Generate all required passwords and keys
POSTGRES_PASSWORD=$(generate_password)
LISTMONK_DB_PASSWORD=$(generate_password)
N8N_DB_PASSWORD=$(generate_password)
MIXPOST_DB_PASSWORD=$(generate_password)
PLAUSIBLE_DB_PASSWORD=$(generate_password)
REDIS_PASSWORD=$(generate_password)

LISTMONK_ADMIN_PASSWORD=$(generate_password)
LISTMONK_AUTH_TOKEN=$(generate_token)

N8N_ENCRYPTION_KEY=$(generate_password)
N8N_JWT_SECRET=$(generate_password)

MIXPOST_APP_KEY="base64:$(generate_password)"

PLAUSIBLE_ADMIN_PASSWORD=$(generate_password)
PLAUSIBLE_SECRET_KEY=$(generate_password)

log_success "Credentials generated"

# ============================================================================
# CREATE .env FILE
# ============================================================================

log_info "Creating .env file with generated credentials..."

ENV_FILE="$SCRIPT_DIR/.env"

if [ -f "$ENV_FILE" ]; then
    log_warning ".env file already exists. Backing up to .env.backup"
    cp "$ENV_FILE" "$ENV_FILE.backup"
fi

cat > "$ENV_FILE" << EOF
# ============================================================================
# AUTO-GENERATED - Rosier Marketing Automation Stack Configuration
# Generated: $(date)
# ============================================================================

# Database Credentials
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
LISTMONK_DB_USER=listmonk
LISTMONK_DB_PASSWORD=$LISTMONK_DB_PASSWORD
LISTMONK_DB_NAME=listmonk
N8N_DB_USER=n8n
N8N_DB_PASSWORD=$N8N_DB_PASSWORD
N8N_DB_NAME=n8n
MIXPOST_DB_USER=mixpost
MIXPOST_DB_PASSWORD=$MIXPOST_DB_PASSWORD
MIXPOST_DB_NAME=mixpost
PLAUSIBLE_DB_PASSWORD=$PLAUSIBLE_DB_PASSWORD
REDIS_PASSWORD=$REDIS_PASSWORD

# SMTP Configuration (Gmail example - update with your credentials)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-specific-password
MAIL_FROM=noreply@rosier.app
MAIL_REPLY_TO=hello@rosier.app
BOUNCE_ADMIN_EMAIL=admin@rosier.app

# Listmonk Configuration
LISTMONK_ADMIN_USERNAME=admin
LISTMONK_ADMIN_PASSWORD=$LISTMONK_ADMIN_PASSWORD
LISTMONK_AUTH_TOKEN=$LISTMONK_AUTH_TOKEN

# n8n Configuration
N8N_HOST=n8n.rosier.local
N8N_ENCRYPTION_KEY=$N8N_ENCRYPTION_KEY
N8N_JWT_SECRET=$N8N_JWT_SECRET
WEBHOOK_TUNNEL_URL=http://n8n.rosier.local:5678/
WEBHOOK_URL_PRODUCTION=http://n8n:5678/

# Mixpost Configuration
MIXPOST_APP_KEY=$MIXPOST_APP_KEY
MIXPOST_URL=http://localhost:9001

# Plausible Configuration
PLAUSIBLE_ADMIN_EMAIL=admin@rosier.app
PLAUSIBLE_ADMIN_PASSWORD=$PLAUSIBLE_ADMIN_PASSWORD
PLAUSIBLE_SECRET_KEY=$PLAUSIBLE_SECRET_KEY
PLAUSIBLE_BASE_URL=http://localhost:8100

# CORS Origins
CORS_ORIGINS=["http://localhost:3000","http://localhost:8000","http://localhost:9000","http://localhost:5678","http://localhost:9001","http://localhost:8100"]
EOF

log_success ".env file created: $ENV_FILE"

# ============================================================================
# CREATE DOCKER COMPOSE OVERRIDE FOR CREDENTIALS
# ============================================================================

log_info "Setting up Docker environment..."

# Export env vars for use in docker-compose
export POSTGRES_PASSWORD
export LISTMONK_DB_PASSWORD
export N8N_DB_PASSWORD
export MIXPOST_DB_PASSWORD
export PLAUSIBLE_DB_PASSWORD
export REDIS_PASSWORD
export LISTMONK_ADMIN_PASSWORD
export LISTMONK_AUTH_TOKEN
export N8N_ENCRYPTION_KEY
export N8N_JWT_SECRET
export PLAUSIBLE_ADMIN_PASSWORD
export PLAUSIBLE_SECRET_KEY

# ============================================================================
# START SERVICES
# ============================================================================

log_info "Starting Docker services..."
log_info "This may take 2-3 minutes on first run (downloading images)..."

cd "$SCRIPT_DIR"

# Start services in detached mode
if ! docker-compose -f docker-compose.marketing.yml up -d; then
    log_error "Failed to start services"
    exit 1
fi

log_success "Services started"

# ============================================================================
# WAIT FOR SERVICES TO BE HEALTHY
# ============================================================================

log_info "Waiting for services to become healthy..."

MAX_RETRIES=60
RETRY_INTERVAL=5
RETRIES=0

# Check database health
while [ $RETRIES -lt $MAX_RETRIES ]; do
    if docker-compose -f docker-compose.marketing.yml exec -T marketing-db pg_isready -U postgres > /dev/null 2>&1; then
        log_success "Database is healthy"
        break
    fi
    RETRIES=$((RETRIES + 1))
    echo -ne "${BLUE}Waiting for database... ($RETRIES/$MAX_RETRIES)${NC}\r"
    sleep $RETRY_INTERVAL
done

if [ $RETRIES -ge $MAX_RETRIES ]; then
    log_error "Database failed to start"
    exit 1
fi

# Check other services
log_info "Checking services..."

services=("listmonk" "n8n" "mixpost" "plausible")
for service in "${services[@]}"; do
    RETRIES=0
    while [ $RETRIES -lt 30 ]; do
        if docker-compose -f docker-compose.marketing.yml ps "$service" | grep -q "Up"; then
            log_success "$service is running"
            break
        fi
        RETRIES=$((RETRIES + 1))
        echo -ne "${BLUE}Waiting for $service... ($RETRIES/30)${NC}\r"
        sleep 2
    done

    if [ $RETRIES -ge 30 ]; then
        log_warning "$service is still starting, but continuing..."
    fi
done

# ============================================================================
# CREATE INITIAL LISTS IN LISTMONK
# ============================================================================

log_info "Setting up initial Listmonk lists..."

# Wait a bit more for Listmonk to fully initialize
sleep 5

# Get Listmonk container ID
LISTMONK_CONTAINER=$(docker-compose -f docker-compose.marketing.yml ps -q listmonk)

if [ -z "$LISTMONK_CONTAINER" ]; then
    log_warning "Could not find Listmonk container. Skipping list creation."
    log_info "You can create lists manually at http://localhost:9000/admin"
else
    log_info "Lists will be created automatically when you first access Listmonk"
    log_info "Please log in and create the following lists:"
    log_info "  - Waitlist"
    log_info "  - Users"
    log_info "  - Style Digest Subscribers"
    log_info "  - Sale Alerts"
fi

# ============================================================================
# FINAL SUMMARY
# ============================================================================

echo ""
log_success "=========================================="
log_success "Marketing Stack Setup Complete!"
log_success "=========================================="
echo ""

echo -e "${GREEN}Services are now running:${NC}"
echo ""
echo "  Listmonk Email Marketing"
echo -e "    ${BLUE}http://localhost:9000/admin${NC}"
echo "    Username: admin"
echo "    Password: (see .env file)"
echo ""

echo "  n8n Workflow Automation"
echo -e "    ${BLUE}http://localhost:5678${NC}"
echo ""

echo "  Mixpost Social Scheduling"
echo -e "    ${BLUE}http://localhost:9001${NC}"
echo ""

echo "  Plausible Analytics"
echo -e "    ${BLUE}http://localhost:8100${NC}"
echo "    Email: admin@rosier.app"
echo "    Password: (see .env file)"
echo ""

echo -e "${YELLOW}IMPORTANT - NEXT STEPS:${NC}"
echo ""
echo "1. Update SMTP credentials in .env file"
echo "   Edit: $ENV_FILE"
echo "   Set SMTP_USERNAME and SMTP_PASSWORD for email sending"
echo "   (Gmail example: Use app-specific password from myaccount.google.com/apppasswords)"
echo ""

echo "2. Log in to Listmonk and create these lists:"
echo "   - Waitlist"
echo "   - Users"
echo "   - Style Digest Subscribers"
echo "   - Sale Alerts"
echo ""

echo "3. Import n8n workflows from workflows/ directory"
echo "   Workflows available:"
echo "   - user_signup_flow.json"
echo "   - weekly_style_digest.json"
echo "   - referral_reward.json"
echo "   - daily_content_scheduler.json"
echo ""

echo "4. Connect social media accounts in Mixpost"
echo "   Supports: Instagram, TikTok, Twitter, Facebook"
echo ""

echo "5. Set up Plausible tracking on your website"
echo "   Add script to rosier.app frontend"
echo ""

echo -e "${YELLOW}USEFUL COMMANDS:${NC}"
echo ""
echo "  View logs:"
echo "    docker-compose -f docker-compose.marketing.yml logs -f"
echo ""
echo "  View specific service logs:"
echo "    docker-compose -f docker-compose.marketing.yml logs -f listmonk"
echo ""
echo "  Check service status:"
echo "    docker-compose -f docker-compose.marketing.yml ps"
echo ""
echo "  Stop services:"
echo "    docker-compose -f docker-compose.marketing.yml down"
echo ""
echo "  Restart services:"
echo "    docker-compose -f docker-compose.marketing.yml restart"
echo ""

echo -e "${GREEN}Configuration saved to: $ENV_FILE${NC}"
echo ""

# Save credentials to a secure file
CREDENTIALS_FILE="$SCRIPT_DIR/.credentials"
cat > "$CREDENTIALS_FILE" << EOF
# ============================================================================
# CREDENTIALS - Keep this file secure, do not commit to git
# Generated: $(date)
# ============================================================================

Listmonk Admin Login:
  Username: admin
  Password: $LISTMONK_ADMIN_PASSWORD
  URL: http://localhost:9000/admin

n8n Login:
  URL: http://localhost:5678
  (Set up on first visit)

Mixpost Login:
  URL: http://localhost:9001
  (Set up on first visit)

Plausible Analytics:
  Email: admin@rosier.app
  Password: $PLAUSIBLE_ADMIN_PASSWORD
  URL: http://localhost:8100

PostgreSQL:
  Host: localhost
  Port: 5432 (via docker-compose)
  User: postgres
  Password: $POSTGRES_PASSWORD

Redis:
  Password: $REDIS_PASSWORD

SMTP Credentials (update manually):
  Host: smtp.gmail.com
  Port: 587
  Username: [UPDATE IN .env FILE]
  Password: [UPDATE IN .env FILE]
EOF

chmod 600 "$CREDENTIALS_FILE"
log_success "Credentials saved to: $CREDENTIALS_FILE (keep secure!)"

echo ""
log_info "For more information, see INTEGRATION_GUIDE.md and README.md"
echo ""
