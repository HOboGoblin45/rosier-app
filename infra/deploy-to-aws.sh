#!/bin/bash

# ============================================================================
# ROSIER BACKEND - AWS DEPLOYMENT SCRIPT
# ============================================================================
# This script automates the deployment of Rosier backend to AWS
# It creates all necessary infrastructure: Security Groups, RDS, Redis, EC2
# Region: us-east-1
# Run this in AWS CloudShell: https://us-east-1.console.aws.amazon.com/cloudshell/home
#
# Usage:
#   bash deploy-to-aws.sh
# ============================================================================

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# CONFIGURATION
# ============================================================================

REGION="us-east-1"
APP_NAME="rosier"
ENVIRONMENT="production"

# Get default VPC
DEFAULT_VPC=$(aws ec2 describe-vpcs \
  --region "$REGION" \
  --query 'Vpcs[?IsDefault==`true`].VpcId' \
  --output text)

if [ -z "$DEFAULT_VPC" ]; then
  echo -e "${RED}ERROR: No default VPC found in region $REGION${NC}"
  exit 1
fi

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     ROSIER BACKEND - AWS DEPLOYMENT SCRIPT             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "  Region: $REGION"
echo "  App Name: $APP_NAME"
echo "  Environment: $ENVIRONMENT"
echo "  Default VPC: $DEFAULT_VPC"
echo ""

# ============================================================================
# PHASE 1: CREATE SECURITY GROUPS
# ============================================================================

echo -e "${BLUE}[PHASE 1] Creating Security Groups...${NC}"
echo ""

# EC2 Security Group
echo -e "${YELLOW}Creating EC2 Security Group...${NC}"
EC2_SG=$(aws ec2 create-security-group \
  --group-name "${APP_NAME}-ec2-sg" \
  --description "Rosier EC2 instance - allows SSH, HTTP, HTTPS, API (8000)" \
  --vpc-id "$DEFAULT_VPC" \
  --region "$REGION" \
  --query 'GroupId' \
  --output text 2>/dev/null) || true

if [ -z "$EC2_SG" ]; then
  # If security group already exists, get its ID
  EC2_SG=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=${APP_NAME}-ec2-sg" \
    --region "$REGION" \
    --query 'SecurityGroups[0].GroupId' \
    --output text)
fi

echo -e "${GREEN}✓ EC2 SG created: $EC2_SG${NC}"

# Add EC2 inbound rules
echo -e "${YELLOW}Adding EC2 ingress rules (22, 80, 443, 8000)...${NC}"

for PORT in 22 80 443 8000; do
  aws ec2 authorize-security-group-ingress \
    --group-id "$EC2_SG" \
    --protocol tcp \
    --port "$PORT" \
    --cidr 0.0.0.0/0 \
    --region "$REGION" 2>/dev/null || echo "  Port $PORT already exists"
done

echo -e "${GREEN}✓ EC2 SG rules added${NC}"

# RDS Security Group
echo -e "${YELLOW}Creating RDS Security Group...${NC}"
RDS_SG=$(aws ec2 create-security-group \
  --group-name "${APP_NAME}-rds-sg" \
  --description "Rosier RDS PostgreSQL - allows access from EC2 only" \
  --vpc-id "$DEFAULT_VPC" \
  --region "$REGION" \
  --query 'GroupId' \
  --output text 2>/dev/null) || true

if [ -z "$RDS_SG" ]; then
  RDS_SG=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=${APP_NAME}-rds-sg" \
    --region "$REGION" \
    --query 'SecurityGroups[0].GroupId' \
    --output text)
fi

echo -e "${GREEN}✓ RDS SG created: $RDS_SG${NC}"

# Add RDS ingress rule (PostgreSQL from EC2 only)
echo -e "${YELLOW}Adding RDS ingress rule (PostgreSQL from EC2)...${NC}"
aws ec2 authorize-security-group-ingress \
  --group-id "$RDS_SG" \
  --protocol tcp \
  --port 5432 \
  --source-group "$EC2_SG" \
  --region "$REGION" 2>/dev/null || echo "  Rule already exists"

echo -e "${GREEN}✓ RDS SG rules added${NC}"

# ElastiCache (Redis) Security Group
echo -e "${YELLOW}Creating ElastiCache Security Group...${NC}"
REDIS_SG=$(aws ec2 create-security-group \
  --group-name "${APP_NAME}-redis-sg" \
  --description "Rosier ElastiCache Redis - allows access from EC2 only" \
  --vpc-id "$DEFAULT_VPC" \
  --region "$REGION" \
  --query 'GroupId' \
  --output text 2>/dev/null) || true

if [ -z "$REDIS_SG" ]; then
  REDIS_SG=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=${APP_NAME}-redis-sg" \
    --region "$REGION" \
    --query 'SecurityGroups[0].GroupId' \
    --output text)
fi

echo -e "${GREEN}✓ Redis SG created: $REDIS_SG${NC}"

# Add Redis ingress rule
echo -e "${YELLOW}Adding Redis ingress rule (6379 from EC2)...${NC}"
aws ec2 authorize-security-group-ingress \
  --group-id "$REDIS_SG" \
  --protocol tcp \
  --port 6379 \
  --source-group "$EC2_SG" \
  --region "$REGION" 2>/dev/null || echo "  Rule already exists"

echo -e "${GREEN}✓ Redis SG rules added${NC}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Phase 1 Complete: Security Groups${NC}"
echo -e "${GREEN}========================================${NC}"
echo "EC2 SG: $EC2_SG"
echo "RDS SG: $RDS_SG"
echo "Redis SG: $REDIS_SG"
echo ""

# ============================================================================
# PHASE 2: CREATE RDS POSTGRESQL DATABASE
# ============================================================================

echo -e "${BLUE}[PHASE 2] Creating RDS PostgreSQL Instance...${NC}"
echo ""

DB_IDENTIFIER="${APP_NAME}-db"
DB_NAME="rosier"
DB_USERNAME="rosier_admin"
DB_PASSWORD=$(openssl rand -base64 32)

echo -e "${YELLOW}Creating RDS PostgreSQL 16 instance (db.t3.micro)...${NC}"
echo "  Database: $DB_NAME"
echo "  Master username: $DB_USERNAME"
echo "  Instance: db.t3.micro (Free Tier)"
echo ""

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
  --backup-window "03:00-04:00" \
  --maintenance-window "mon:04:00-mon:05:00" \
  --skip-final-snapshot \
  --copy-tags-to-snapshot \
  --enable-iam-database-authentication false \
  --region "$REGION" 2>/dev/null || echo "RDS instance may already exist"

echo -e "${GREEN}✓ RDS instance creation initiated${NC}"
echo "  Database will be available in 5-10 minutes"
echo ""

# Get RDS endpoint (may not be available immediately)
sleep 5
RDS_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier "$DB_IDENTIFIER" \
  --region "$REGION" \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text 2>/dev/null) || RDS_ENDPOINT="<pending-see-console>"

echo -e "${YELLOW}RDS Endpoint: ${RDS_ENDPOINT}${NC}"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Phase 2 Complete: RDS Instance${NC}"
echo -e "${GREEN}========================================${NC}"
echo "DB Identifier: $DB_IDENTIFIER"
echo "DB Name: $DB_NAME"
echo "DB Username: $DB_USERNAME"
echo "DB Password: $DB_PASSWORD (SAVE THIS!)"
echo "DB Endpoint: $RDS_ENDPOINT"
echo ""

# ============================================================================
# PHASE 3: CREATE ELASTICACHE REDIS CLUSTER
# ============================================================================

echo -e "${BLUE}[PHASE 3] Creating ElastiCache Redis Instance...${NC}"
echo ""

REDIS_CLUSTER_ID="${APP_NAME}-redis"
REDIS_NODE_TYPE="cache.t3.micro"

# Get default subnet group for ElastiCache
DEFAULT_SUBNET_GROUP=$(aws elasticache describe-cache-subnet-groups \
  --region "$REGION" \
  --query 'CacheSubnetGroups[0].CacheSubnetGroupName' \
  --output text 2>/dev/null) || DEFAULT_SUBNET_GROUP="default"

echo -e "${YELLOW}Creating ElastiCache Redis cluster (single node, cache.t3.micro)...${NC}"

aws elasticache create-cache-cluster \
  --cache-cluster-id "$REDIS_CLUSTER_ID" \
  --cache-node-type "$REDIS_NODE_TYPE" \
  --engine redis \
  --engine-version 7.0 \
  --num-cache-nodes 1 \
  --port 6379 \
  --cache-subnet-group-name "$DEFAULT_SUBNET_GROUP" 2>/dev/null || {
    # If subnet group doesn't exist, use default cache subnet group
    aws elasticache create-cache-cluster \
      --cache-cluster-id "$REDIS_CLUSTER_ID" \
      --cache-node-type "$REDIS_NODE_TYPE" \
      --engine redis \
      --engine-version 7.0 \
      --num-cache-nodes 1 \
      --port 6379 \
      --security-group-ids "$REDIS_SG" 2>/dev/null || echo "Redis cluster may already exist"
  }

echo -e "${GREEN}✓ Redis cluster creation initiated${NC}"
echo "  Cluster will be available in 5-10 minutes"
echo ""

# Get Redis endpoint
sleep 5
REDIS_ENDPOINT=$(aws elasticache describe-cache-clusters \
  --cache-cluster-id "$REDIS_CLUSTER_ID" \
  --region "$REGION" \
  --query 'CacheClusters[0].CacheNodes[0].Endpoint.Address' \
  --output text 2>/dev/null) || REDIS_ENDPOINT="<pending-see-console>"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Phase 3 Complete: Redis Cluster${NC}"
echo -e "${GREEN}========================================${NC}"
echo "Cluster ID: $REDIS_CLUSTER_ID"
echo "Node Type: $REDIS_NODE_TYPE"
echo "Endpoint: $REDIS_ENDPOINT"
echo ""

# ============================================================================
# PHASE 4: CREATE EC2 KEY PAIR AND INSTANCE
# ============================================================================

echo -e "${BLUE}[PHASE 4] Creating EC2 Key Pair and Instance...${NC}"
echo ""

KEY_NAME="${APP_NAME}-key"
INSTANCE_TYPE="t2.micro"

echo -e "${YELLOW}Creating EC2 key pair: $KEY_NAME${NC}"

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
  echo -e "${GREEN}✓ Key pair created and saved to ${KEY_NAME}.pem${NC}"
else
  echo -e "${YELLOW}  Key pair already exists${NC}"
fi

echo ""
echo -e "${YELLOW}Creating EC2 instance (t2.micro, Amazon Linux 2023)...${NC}"

# Get the latest Amazon Linux 2023 AMI
AMI_ID=$(aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-*" "Name=state,Values=available" \
  --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
  --region "$REGION" \
  --output text)

echo "  AMI: $AMI_ID (Amazon Linux 2023)"
echo "  Instance Type: $INSTANCE_TYPE"
echo "  Key Pair: $KEY_NAME"
echo ""

# Create user data script
USER_DATA_SCRIPT='#!/bin/bash
yum update -y
yum install -y docker git curl wget nano postgresql redis-cli htop tmux python3 python3-pip jq aws-cli

# Start Docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create app directory
mkdir -p /app
cd /app

# Create systemd service for docker-compose
mkdir -p /etc/systemd/system
cat > /etc/systemd/system/rosier.service << '"'"'EOF'"'"'
[Unit]
Description=Rosier Backend Service
After=docker.service network-online.target
Requires=docker.service
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/app
ExecStart=/usr/local/bin/docker-compose -f docker-compose-prod.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose-prod.yml down
Restart=always
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable rosier.service

echo "EC2 instance ready for Rosier deployment!"
'

# Launch EC2 instance
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id "$AMI_ID" \
  --instance-type "$INSTANCE_TYPE" \
  --key-name "$KEY_NAME" \
  --security-group-ids "$EC2_SG" \
  --user-data "$USER_DATA_SCRIPT" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${APP_NAME}-api},{Key=Environment,Value=${ENVIRONMENT}}]" \
  --region "$REGION" \
  --query 'Instances[0].InstanceId' \
  --output text)

echo -e "${GREEN}✓ EC2 instance launched: $INSTANCE_ID${NC}"
echo "  Instance will be ready in 2-5 minutes"
echo ""

# Get instance details
sleep 10
INSTANCE_DATA=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --region "$REGION" \
  --query 'Reservations[0].Instances[0]' \
  --output json)

PUBLIC_IP=$(echo "$INSTANCE_DATA" | jq -r '.PublicIpAddress // "pending"')
PRIVATE_IP=$(echo "$INSTANCE_DATA" | jq -r '.PrivateIpAddress // "pending"')

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Phase 4 Complete: EC2 Instance${NC}"
echo -e "${GREEN}========================================${NC}"
echo "Instance ID: $INSTANCE_ID"
echo "Instance Type: $INSTANCE_TYPE"
echo "Key Pair: $KEY_NAME"
echo "Public IP: $PUBLIC_IP"
echo "Private IP: $PRIVATE_IP"
echo ""

# ============================================================================
# SUMMARY AND NEXT STEPS
# ============================================================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        DEPLOYMENT SUMMARY - SAVE THIS OUTPUT           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}SECURITY GROUPS:${NC}"
echo "  EC2:   $EC2_SG"
echo "  RDS:   $RDS_SG"
echo "  Redis: $REDIS_SG"
echo ""
echo -e "${GREEN}RDS DATABASE:${NC}"
echo "  Identifier: $DB_IDENTIFIER"
echo "  Username:   $DB_USERNAME"
echo "  Password:   $DB_PASSWORD"
echo "  Endpoint:   $RDS_ENDPOINT"
echo ""
echo -e "${GREEN}ELASTICACHE REDIS:${NC}"
echo "  Cluster ID: $REDIS_CLUSTER_ID"
echo "  Endpoint:   $REDIS_ENDPOINT:6379"
echo ""
echo -e "${GREEN}EC2 INSTANCE:${NC}"
echo "  Instance ID: $INSTANCE_ID"
echo "  Public IP:   $PUBLIC_IP"
echo "  Private IP:  $PRIVATE_IP"
echo "  Key Pair:    $KEY_NAME"
echo ""
echo -e "${YELLOW}IMPORTANT: Save the database password and SSH key!${NC}"
echo "  Key file: ./${KEY_NAME}.pem"
echo ""
echo -e "${GREEN}NEXT STEPS:${NC}"
echo "  1. Wait 5-10 minutes for RDS and Redis to be fully available"
echo "  2. SSH to EC2: ssh -i ${KEY_NAME}.pem ec2-user@${PUBLIC_IP}"
echo "  3. Clone the repository and configure .env with:"
echo "     - DATABASE_URL=postgresql+asyncpg://rosier_admin:${DB_PASSWORD}@${RDS_ENDPOINT}:5432/rosier"
echo "     - REDIS_URL=redis://${REDIS_ENDPOINT}:6379/0"
echo "  4. Run: docker-compose -f infra/docker/docker-compose-prod.yml up -d"
echo "  5. Test: curl http://${PUBLIC_IP}:8000/docs"
echo ""

# Save deployment info to file
cat > rosier-deployment-info.txt << 'EOF'
ROSIER BACKEND - AWS DEPLOYMENT INFO
====================================

SECURITY GROUPS:
  EC2:   $EC2_SG
  RDS:   $RDS_SG
  Redis: $REDIS_SG

RDS DATABASE:
  Identifier: $DB_IDENTIFIER
  Username:   $DB_USERNAME
  Password:   $DB_PASSWORD
  Endpoint:   $RDS_ENDPOINT
  Port:       5432
  Database:   $DB_NAME

ELASTICACHE REDIS:
  Cluster ID: $REDIS_CLUSTER_ID
  Endpoint:   $REDIS_ENDPOINT
  Port:       6379

EC2 INSTANCE:
  Instance ID: $INSTANCE_ID
  Public IP:   $PUBLIC_IP
  Private IP:  $PRIVATE_IP
  Key Pair:    $KEY_NAME

SSH Command:
  ssh -i ${KEY_NAME}.pem ec2-user@${PUBLIC_IP}

Environment Variables for .env:
  DATABASE_URL=postgresql+asyncpg://rosier_admin:${DB_PASSWORD}@${RDS_ENDPOINT}:5432/rosier
  REDIS_URL=redis://${REDIS_ENDPOINT}:6379/0
  AWS_REGION=us-east-1
EOF

echo -e "${GREEN}Deployment info saved to: rosier-deployment-info.txt${NC}"
echo ""
