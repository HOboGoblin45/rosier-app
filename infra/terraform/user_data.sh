#!/bin/bash
# EC2 User Data Script - Installs Docker and Docker Compose
# This script runs on EC2 startup to prepare the instance

set -e

# Log output for debugging
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting EC2 user data script..."
echo "App Name: ${app_name}"
echo "Region: ${region}"

# ============================================================================
# UPDATE SYSTEM
# ============================================================================

echo "Updating system packages..."
yum update -y
yum upgrade -y

# ============================================================================
# INSTALL DOCKER
# ============================================================================

echo "Installing Docker..."
yum install -y docker

# Start and enable Docker service
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -aG docker ec2-user

# ============================================================================
# INSTALL DOCKER COMPOSE
# ============================================================================

echo "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Verify installations
echo "Verifying Docker installation..."
docker --version
docker-compose --version

# ============================================================================
# INSTALL ADDITIONAL TOOLS
# ============================================================================

echo "Installing additional tools..."
yum install -y \
  git \
  curl \
  wget \
  nano \
  postgresql \
  redis-cli \
  htop \
  tmux \
  python3 \
  python3-pip \
  jq

# ============================================================================
# SETUP APPLICATION DIRECTORY
# ============================================================================

echo "Creating application directory..."
mkdir -p /app
cd /app

# Create docker-compose directory
mkdir -p docker-configs

# ============================================================================
# INSTALL AWSCLI AND CONFIGURE
# ============================================================================

echo "Installing AWS CLI..."
yum install -y aws-cli

# ============================================================================
# SETUP CLOUDWATCH AGENT (Optional - for monitoring)
# ============================================================================

echo "Installing CloudWatch agent..."
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm
rm amazon-cloudwatch-agent.rpm

# ============================================================================
# CREATE ENVIRONMENT TEMPLATE
# ============================================================================

echo "Creating environment template..."
cat > /app/.env.example << 'EOF'
# Database Configuration
DATABASE_URL=postgresql+asyncpg://postgres:PASSWORD@rosier-db.xxxx.us-east-1.rds.amazonaws.com:5432/rosier
POSTGRES_USER=postgres
POSTGRES_PASSWORD=PASSWORD
POSTGRES_DB=rosier

# Redis Configuration
REDIS_URL=redis://rosier-redis.xxxx.ng.0001.cache.amazonaws.com:6379/0

# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
S3_BUCKET=rosier-assets-ACCOUNT_ID

# Application Configuration
ENVIRONMENT=production
DEBUG=false

# Security
JWT_SECRET_KEY=your-secret-key-here-change-in-production
SECRET_KEY=your-secret-key-here-change-in-production

# Monitoring
SENTRY_DSN=
LOG_LEVEL=info

# API Configuration
API_HOST=0.0.0.0
API_PORT=8000
CORS_ORIGINS=["http://localhost:3000", "https://yourdomain.com"]
EOF

echo "Environment template created at /app/.env.example"

# ============================================================================
# CREATE DEPLOYMENT SCRIPT
# ============================================================================

echo "Creating deployment script..."
cat > /app/deploy.sh << 'DEPLOY_SCRIPT'
#!/bin/bash
set -e

echo "Deploying Rosier backend..."

# Pull latest changes
echo "Pulling latest code..."
git pull origin main

# Build Docker image
echo "Building Docker image..."
docker-compose -f docker-compose-prod.yml build --no-cache

# Stop and remove old containers
echo "Stopping old containers..."
docker-compose -f docker-compose-prod.yml down

# Start new containers
echo "Starting new containers..."
docker-compose -f docker-compose-prod.yml up -d

# Run migrations
echo "Running database migrations..."
docker-compose -f docker-compose-prod.yml exec -T api alembic upgrade head

# Verify health
echo "Checking health status..."
sleep 5
curl -f http://localhost:8000/health || exit 1

echo "Deployment complete!"
DEPLOY_SCRIPT

chmod +x /app/deploy.sh

# ============================================================================
# CREATE HEALTH CHECK SCRIPT
# ============================================================================

echo "Creating health check script..."
cat > /app/health-check.sh << 'HEALTH_SCRIPT'
#!/bin/bash

echo "Checking API health..."
curl -s http://localhost:8000/health | jq . || echo "API unavailable"

echo ""
echo "Checking database connection..."
docker-compose -f docker-compose-prod.yml exec -T api python -c "
from sqlalchemy import create_engine, text
engine = create_engine(os.getenv('DATABASE_URL'))
with engine.connect() as conn:
    result = conn.execute(text('SELECT 1'))
    print('Database: OK')
" || echo "Database unavailable"

echo ""
echo "Checking Redis connection..."
redis-cli -h ${REDIS_HOST} -p 6379 ping || echo "Redis unavailable"
HEALTH_SCRIPT

chmod +x /app/health-check.sh

# ============================================================================
# CREATE SYSTEMD SERVICE (OPTIONAL - for auto-restart)
# ============================================================================

echo "Creating systemd service for Docker Compose..."
cat > /etc/systemd/system/rosier.service << 'SYSTEMD_SERVICE'
[Unit]
Description=Rosier Backend Service
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/app
ExecStart=/usr/local/bin/docker-compose -f docker-compose-prod.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose-prod.yml down
Restart=always
RestartSec=10s
StandardOutput=journal

[Install]
WantedBy=multi-user.target
SYSTEMD_SERVICE

systemctl daemon-reload
systemctl enable rosier.service

echo "Systemd service created and enabled"

# ============================================================================
# SETUP LOG ROTATION
# ============================================================================

echo "Setting up log rotation..."
cat > /etc/logrotate.d/rosier << 'LOGROTATE'
/app/logs/*.log {
  daily
  rotate 7
  compress
  delaycompress
  notifempty
  create 0640 root root
  sharedscripts
  postrotate
    /usr/bin/systemctl reload rosier > /dev/null 2>&1 || true
  endscript
}
LOGROTATE

# ============================================================================
# FINAL SETUP
# ============================================================================

echo "Creating logs directory..."
mkdir -p /app/logs

echo "Setting permissions..."
chown -R ec2-user:ec2-user /app

echo "Creating cron job for backups..."
echo "0 2 * * * cd /app && ./backup-db.sh" | crontab -u ec2-user -

# ============================================================================
# COMPLETION
# ============================================================================

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║           EC2 Instance Setup Complete!                        ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "1. SSH into the instance: ssh -i key.pem ec2-user@<public-ip>"
echo "2. Update /app/.env with your configuration"
echo "3. Clone the repository: git clone <repo> /app"
echo "4. Deploy: cd /app && docker-compose -f docker-compose-prod.yml up -d"
echo ""
echo "Useful commands:"
echo "  - View logs: docker-compose logs -f"
echo "  - Check health: curl http://localhost:8000/health"
echo "  - Docker stats: docker stats"
echo ""
echo "Setup completed at: $(date)"
