#!/bin/bash
#
# ROSIER BACKEND - ONE-CLICK AWS CLOUDSHELL DEPLOYMENT
# =====================================================
# Designed for AWS CloudShell (Amazon Linux, AWS CLI pre-installed)
# Creates all infrastructure automatically in FREE TIER
#
# Time: ~15 minutes to complete
# Cost: $0/month for Year 1 (AWS Free Tier)
#

set -e

# Color codes for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================================================
# CONFIGURATION
# ============================================================================

REGION="us-east-1"
APP_NAME="rosier"
DEPLOYMENT_DIR="/tmp/rosier-cloudshell-${RANDOM}"
GITHUB_REPO="${GITHUB_REPO:-https://github.com/rosier/backend.git}"

# ============================================================================
# LOGGING & PROGRESS
# ============================================================================

log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

progress() {
  echo ""
  echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║ $1${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

cleanup_on_error() {
  log_error "Deployment failed. Rolling back..."

  if [ ! -z "$EC2_SG" ]; then
    log_warning "Cleaning up security groups (this may take a moment)..."
    aws ec2 delete-security-group --group-id "$EC2_SG" --region "$REGION" 2>/dev/null || true
    aws ec2 delete-security-group --group-id "$RDS_SG" --region "$REGION" 2>/dev/null || true
    aws ec2 delete-security-group --group-id "$REDIS_SG" --region "$REGION" 2>/dev/null || true
  fi

  exit 1
}

trap cleanup_on_error ERR

# ============================================================================
# PHASE 0: VALIDATION & SETUP
# ============================================================================

progress "PHASE 0: Validating AWS Credentials & VPC"

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
  log_error "AWS credentials not configured. Run this in AWS CloudShell or configure credentials."
  exit 1
fi

log_success "AWS credentials verified"

# Get account ID for logging
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
log_info "AWS Account: $ACCOUNT_ID"
log_info "AWS Region: $REGION"

# Get default VPC
DEFAULT_VPC=$(aws ec2 describe-vpcs \
  --region "$REGION" \
  --query 'Vpcs[?IsDefault==`true`].VpcId' \
  --output text)

if [ -z "$DEFAULT_VPC" ]; then
  log_error "No default VPC found in region $REGION"
  exit 1
fi

log_success "Default VPC: $DEFAULT_VPC"

# Create deployment directory
mkdir -p "$DEPLOYMENT_DIR"
cd "$DEPLOYMENT_DIR"

log_success "Working directory: $DEPLOYMENT_DIR"
echo ""

# ============================================================================
# PHASE 1: SECURITY GROUPS
# ============================================================================

progress "PHASE 1: Creating Security Groups"

# EC2 Security Group
log_info "Creating EC2 security group..."
EC2_SG=$(aws ec2 create-security-group \
  --group-name "${APP_NAME}-ec2-sg" \
  --description "Rosier EC2 - SSH, HTTP, HTTPS, API 8000" \
  --vpc-id "$DEFAULT_VPC" \
  --region "$REGION" \
  --query 'GroupId' \
  --output text 2>/dev/null) || \
EC2_SG=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=${APP_NAME}-ec2-sg" \
  --region "$REGION" \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

log_success "EC2 Security Group: $EC2_SG"

# Add EC2 ingress rules
log_info "Adding EC2 ingress rules (SSH, HTTP, HTTPS, API)..."
for PORT in 22 80 443 8000; do
  aws ec2 authorize-security-group-ingress \
    --group-id "$EC2_SG" \
    --protocol tcp \
    --port "$PORT" \
    --cidr 0.0.0.0/0 \
    --region "$REGION" 2>/dev/null || true
done
log_success "EC2 ingress rules configured"

# RDS Security Group
log_info "Creating RDS security group..."
RDS_SG=$(aws ec2 create-security-group \
  --group-name "${APP_NAME}-rds-sg" \
  --description "Rosier RDS - PostgreSQL from EC2 only" \
  --vpc-id "$DEFAULT_VPC" \
  --region "$REGION" \
  --query 'GroupId' \
  --output text 2>/dev/null) || \
RDS_SG=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=${APP_NAME}-rds-sg" \
  --region "$REGION" \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

log_success "RDS Security Group: $RDS_SG"

# Add RDS ingress rule
log_info "Adding RDS ingress rule (PostgreSQL from EC2)..."
aws ec2 authorize-security-group-ingress \
  --group-id "$RDS_SG" \
  --protocol tcp \
  --port 5432 \
  --source-group "$EC2_SG" \
  --region "$REGION" 2>/dev/null || true
log_success "RDS ingress rule configured"

# Redis Security Group
log_info "Creating Redis security group..."
REDIS_SG=$(aws ec2 create-security-group \
  --group-name "${APP_NAME}-redis-sg" \
  --description "Rosier Redis - ElastiCache from EC2 only" \
  --vpc-id "$DEFAULT_VPC" \
  --region "$REGION" \
  --query 'GroupId' \
  --output text 2>/dev/null) || \
REDIS_SG=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=${APP_NAME}-redis-sg" \
  --region "$REGION" \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

log_success "Redis Security Group: $REDIS_SG"

# Add Redis ingress rule
log_info "Adding Redis ingress rule (6379 from EC2)..."
aws ec2 authorize-security-group-ingress \
  --group-id "$REDIS_SG" \
  --protocol tcp \
  --port 6379 \
  --source-group "$EC2_SG" \
  --region "$REGION" 2>/dev/null || true
log_success "Redis ingress rule configured"

echo ""

# ============================================================================
# PHASE 2: RDS POSTGRESQL
# ============================================================================

progress "PHASE 2: Creating RDS PostgreSQL Database"

DB_IDENTIFIER="${APP_NAME}-db"
DB_NAME="rosier"
DB_USERNAME="rosier_admin"
DB_PASSWORD=$(openssl rand -base64 32)

log_info "Database Details:"
log_info "  Identifier: $DB_IDENTIFIER"
log_info "  Database Name: $DB_NAME"
log_info "  Master Username: $DB_USERNAME"
log_info "  Instance Type: db.t3.micro (FREE TIER)"

log_info "Creating RDS PostgreSQL 16 instance..."

aws rds create-db-instance \
  --db-instance-identifier "$DB_IDENTIFIER" \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 16.1 \
  --master-username "$DB_USERNAME" \
  --master-user-password "$DB_PASSWORD" \
  --allocated-storage 20 \
  --storage-type gp2 \
  --storage-encrypted false \
  --vpc-security-group-ids "$RDS_SG" \
  --db-name "$DB_NAME" \
  --port 5432 \
  --publicly-accessible false \
  --multi-az false \
  --backup-retention-period 7 \
  --skip-final-snapshot \
  --region "$REGION" 2>/dev/null || log_warning "RDS instance may already exist (checking...)"

log_info "RDS creation initiated. Waiting for endpoint..."
sleep 8

RDS_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier "$DB_IDENTIFIER" \
  --region "$REGION" \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text 2>/dev/null) || RDS_ENDPOINT="<pending>"

log_success "RDS Instance: $DB_IDENTIFIER"
log_info "RDS Endpoint: $RDS_ENDPOINT (Status: initializing, 5-10 min)"

echo ""

# ============================================================================
# PHASE 3: ELASTICACHE REDIS
# ============================================================================

progress "PHASE 3: Creating ElastiCache Redis Cluster"

REDIS_CLUSTER_ID="${APP_NAME}-redis"

log_info "Creating ElastiCache Redis cluster..."
log_info "  Cluster Type: Single Node (cache.t3.micro, FREE TIER)"
log_info "  Engine: Redis 7.0"

# Try to create without subnet group (CloudShell may not have EC2-Classic)
aws elasticache create-cache-cluster \
  --cache-cluster-id "$REDIS_CLUSTER_ID" \
  --cache-node-type cache.t3.micro \
  --engine redis \
  --engine-version 7.0 \
  --num-cache-nodes 1 \
  --port 6379 \
  --region "$REGION" 2>/dev/null || log_warning "Redis cluster may already exist (checking...)"

log_info "Redis creation initiated. Waiting for endpoint..."
sleep 8

REDIS_ENDPOINT=$(aws elasticache describe-cache-clusters \
  --cache-cluster-id "$REDIS_CLUSTER_ID" \
  --region "$REGION" \
  --query 'CacheClusters[0].CacheNodes[0].Endpoint.Address' \
  --output text 2>/dev/null) || REDIS_ENDPOINT="<pending>"

log_success "Redis Cluster: $REDIS_CLUSTER_ID"
log_info "Redis Endpoint: $REDIS_ENDPOINT:6379 (Status: initializing, 5-10 min)"

echo ""

# ============================================================================
# PHASE 4: EC2 KEY PAIR
# ============================================================================

progress "PHASE 4: Creating EC2 Key Pair"

KEY_NAME="${APP_NAME}-key"

log_info "Creating EC2 key pair..."

# Check if key already exists
KEY_EXISTS=$(aws ec2 describe-key-pairs \
  --region "$REGION" \
  --query "KeyPairs[?KeyName=='$KEY_NAME'].KeyName" \
  --output text 2>/dev/null) || true

if [ -z "$KEY_EXISTS" ]; then
  aws ec2 create-key-pair \
    --key-name "$KEY_NAME" \
    --region "$REGION" \
    --query 'KeyMaterial' \
    --output text > "${KEY_NAME}.pem"
  chmod 400 "${KEY_NAME}.pem"
  log_success "Key pair created: ${KEY_NAME}.pem"
  log_warning "DOWNLOAD THIS FILE - You'll need it to SSH to the instance"
else
  log_warning "Key pair already exists"
fi

echo ""

# ============================================================================
# PHASE 5: EC2 INSTANCE
# ============================================================================

progress "PHASE 5: Launching EC2 Instance"

INSTANCE_TYPE="t2.micro"

log_info "Fetching latest Amazon Linux 2023 AMI..."
AMI_ID=$(aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-*" "Name=state,Values=available" \
  --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
  --region "$REGION" \
  --output text)

log_success "AMI: $AMI_ID (Amazon Linux 2023)"

# Create comprehensive user data script
USER_DATA_SCRIPT='#!/bin/bash
set -e

# Update system
yum update -y
yum install -y docker git curl wget nano postgresql15 redis-cli htop tmux python3 python3-pip jq aws-cli

# Start Docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create app directory
mkdir -p /app
chmod 755 /app

# Create setup log file
touch /var/log/rosier-setup.log
chmod 666 /var/log/rosier-setup.log

echo "[$(date)] EC2 instance initialization complete" >> /var/log/rosier-setup.log
'

log_info "Launching EC2 instance (t2.micro)..."

INSTANCE_ID=$(aws ec2 run-instances \
  --image-id "$AMI_ID" \
  --instance-type "$INSTANCE_TYPE" \
  --key-name "$KEY_NAME" \
  --security-group-ids "$EC2_SG" \
  --user-data "$USER_DATA_SCRIPT" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${APP_NAME}-api},{Key=Environment,Value=production}]" \
  --region "$REGION" \
  --query 'Instances[0].InstanceId' \
  --output text)

log_success "EC2 instance launched: $INSTANCE_ID"
log_info "Instance is initializing (2-3 minutes for Docker setup)..."

# Wait for instance and get details
sleep 15

INSTANCE_JSON=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --region "$REGION" \
  --output json)

PUBLIC_IP=$(echo "$INSTANCE_JSON" | grep -o '"PublicIpAddress": "[^"]*"' | head -1 | cut -d'"' -f4)
PRIVATE_IP=$(echo "$INSTANCE_JSON" | grep -o '"PrivateIpAddress": "[^"]*"' | head -1 | cut -d'"' -f4)

# If jq is available, use it for cleaner extraction
if command -v jq &> /dev/null; then
  PUBLIC_IP=$(echo "$INSTANCE_JSON" | jq -r '.Reservations[0].Instances[0].PublicIpAddress // "pending"')
  PRIVATE_IP=$(echo "$INSTANCE_JSON" | jq -r '.Reservations[0].Instances[0].PrivateIpAddress // "pending"')
fi

log_success "EC2 Instance: $INSTANCE_ID"
log_info "Public IP: $PUBLIC_IP (assigning...)"
log_info "Private IP: $PRIVATE_IP"

echo ""

# ============================================================================
# PHASE 6: SAVE DEPLOYMENT INFO
# ============================================================================

progress "PHASE 6: Saving Deployment Configuration"

# Create deployment info file
cat > rosier-deploy-info.txt << EOF
╔════════════════════════════════════════════════════════╗
║       ROSIER BACKEND - AWS DEPLOYMENT INFO             ║
╚════════════════════════════════════════════════════════╝

Generated: $(date)
Region: $REGION
Account: $ACCOUNT_ID
Free Tier: YES (12 months)

SECURITY GROUPS:
  EC2:   $EC2_SG
  RDS:   $RDS_SG
  Redis: $REDIS_SG

RDS POSTGRESQL 16:
  Identifier: $DB_IDENTIFIER
  Username:   $DB_USERNAME
  Password:   $DB_PASSWORD
  Endpoint:   $RDS_ENDPOINT
  Port:       5432
  Database:   $DB_NAME

ELASTICACHE REDIS 7.0:
  Cluster ID: $REDIS_CLUSTER_ID
  Endpoint:   $REDIS_ENDPOINT:6379

EC2 INSTANCE (Amazon Linux 2023):
  Instance ID: $INSTANCE_ID
  Type:        $INSTANCE_TYPE (FREE TIER)
  Public IP:   $PUBLIC_IP
  Private IP:  $PRIVATE_IP
  Key Pair:    $KEY_NAME

NEXT STEPS:

1. DOWNLOAD YOUR SSH KEY
   - Download the key file: ${KEY_NAME}.pem
   - Keep it safe - you'll need it to access the instance

2. WAIT FOR SERVICES TO INITIALIZE
   - RDS: 5-10 minutes
   - Redis: 5-10 minutes
   - EC2: 2-3 minutes

3. SSH TO INSTANCE (once Public IP is assigned)
   ssh -i ${KEY_NAME}.pem ec2-user@${PUBLIC_IP}

4. DEPLOY THE APPLICATION
   Once connected to EC2:

   cd /app
   git clone $GITHUB_REPO .

   # Create .env file
   cat > .env << 'ENVEOF'
DATABASE_URL=postgresql+asyncpg://${DB_USERNAME}:${DB_PASSWORD}@${RDS_ENDPOINT}:5432/${DB_NAME}
REDIS_URL=redis://${REDIS_ENDPOINT}:6379/0
AWS_REGION=${REGION}
JWT_SECRET_KEY=$(openssl rand -base64 32)
SECRET_KEY=$(openssl rand -base64 32)
ENVIRONMENT=production
DEBUG=false
LOG_LEVEL=info
CORS_ORIGINS=["*"]
ENVEOF

   # Deploy with docker-compose
   docker-compose -f infra/docker/docker-compose-prod.yml up -d

   # Run migrations
   docker-compose -f infra/docker/docker-compose-prod.yml exec api alembic upgrade head

   # Seed initial data (brands, wallpapers)
   docker-compose -f infra/docker/docker-compose-prod.yml exec api python scripts/seed_data.py

5. VERIFY DEPLOYMENT
   curl http://${PUBLIC_IP}:8000/health
   curl http://${PUBLIC_IP}:8000/docs  # Swagger UI

6. MONITOR LOGS
   docker-compose -f infra/docker/docker-compose-prod.yml logs -f api

IMPORTANT SECURITY NOTES:
- Protect the .pem key file - anyone with it can access your instance
- Store the database password securely
- Don't commit .env file with credentials to git
- Later: Migrate to AWS Secrets Manager for production

COST ESTIMATE:
Year 1: FREE (AWS Free Tier)
Year 2+: ~$50-75/month (after free tier expires)

TROUBLESHOOTING:
- Check instance status: aws ec2 describe-instances --instance-ids $INSTANCE_ID
- View RDS status: aws rds describe-db-instances --db-instance-identifier $DB_IDENTIFIER
- View Redis status: aws elasticache describe-cache-clusters --cache-cluster-id $REDIS_CLUSTER_ID
EOF

log_success "Deployment info saved to: rosier-deploy-info.txt"
log_info "Download this file for reference"

echo ""

# ============================================================================
# FINAL SUMMARY
# ============================================================================

progress "DEPLOYMENT COMPLETE!"

echo -e "${GREEN}Your Rosier backend infrastructure is being created!${NC}"
echo ""
echo -e "${CYAN}IMMEDIATE ACTIONS NEEDED:${NC}"
echo "1. Download ${KEY_NAME}.pem from CloudShell"
echo "2. Download rosier-deploy-info.txt for your credentials"
echo "3. Wait 5-10 minutes for RDS and Redis to initialize"
echo ""

echo -e "${CYAN}QUICK REFERENCE:${NC}"
echo "  EC2 Instance ID: $INSTANCE_ID"
echo "  EC2 Public IP: $PUBLIC_IP"
echo "  SSH Command: ssh -i ${KEY_NAME}.pem ec2-user@${PUBLIC_IP}"
echo ""

echo -e "${CYAN}DATABASE CONNECTION:${NC}"
echo "  HOST: $RDS_ENDPOINT"
echo "  USER: $DB_USERNAME"
echo "  DB:   $DB_NAME"
echo "  Port: 5432"
echo ""

echo -e "${CYAN}REDIS CONNECTION:${NC}"
echo "  HOST: $REDIS_ENDPOINT"
echo "  PORT: 6379"
echo ""

echo -e "${YELLOW}⏱ Estimated time to full deployment:${NC}"
echo "  - Now: Infrastructure created"
echo "  - 2-3 min: EC2 instance ready"
echo "  - 5-10 min: RDS & Redis accessible"
echo "  - 15 min total: Everything operational"
echo ""

echo -e "${GREEN}Full deployment details saved to:${NC}"
echo "  ${DEPLOYMENT_DIR}/rosier-deploy-info.txt"
echo ""

log_success "CloudShell deployment script completed!"
log_info "Watch AWS Console for resource status updates"
echo ""
