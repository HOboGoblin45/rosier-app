#!/bin/bash
set -e

# ROSIER ONE-CLICK AWS DEPLOYMENT SCRIPT
# This script deploys Rosier backend to AWS using CloudShell
# Region: us-east-1
# Cost: FREE (AWS Free Tier)

REGION="us-east-1"
APP_NAME="rosier"
DEPLOYMENT_DIR="/tmp/rosier-deployment"

echo ""
echo "========================================"
echo "ROSIER AWS DEPLOYMENT - PHASE 1: SETUP"
echo "========================================"
echo ""

# Create deployment directory
mkdir -p "$DEPLOYMENT_DIR"
cd "$DEPLOYMENT_DIR"

echo "Region: $REGION"
echo "App Name: $APP_NAME"
echo ""

# Get default VPC
echo "Fetching default VPC..."
DEFAULT_VPC=$(aws ec2 describe-vpcs --region "$REGION" --query 'Vpcs[?IsDefault==`true`].VpcId' --output text)
if [ -z "$DEFAULT_VPC" ]; then
  echo "ERROR: No default VPC found!"
  exit 1
fi
echo "VPC: $DEFAULT_VPC"
echo ""

# ============================================================================
# PHASE 1: SECURITY GROUPS
# ============================================================================

echo "========================================"
echo "ROSIER AWS DEPLOYMENT - PHASE 1: SECURITY GROUPS"
echo "========================================"
echo ""

# EC2 Security Group
echo "Creating EC2 security group..."
EC2_SG=$(aws ec2 create-security-group \
  --group-name "${APP_NAME}-ec2-sg" \
  --description "Rosier EC2 - SSH, HTTP, HTTPS, API 8000" \
  --vpc-id "$DEFAULT_VPC" \
  --region "$REGION" \
  --query 'GroupId' \
  --output text 2>/dev/null) || \
EC2_SG=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=${APP_NAME}-ec2-sg" --region "$REGION" --query 'SecurityGroups[0].GroupId' --output text)
echo "EC2 Security Group: $EC2_SG"

# Add EC2 ingress rules
for PORT in 22 80 443 8000; do
  aws ec2 authorize-security-group-ingress \
    --group-id "$EC2_SG" \
    --protocol tcp \
    --port "$PORT" \
    --cidr 0.0.0.0/0 \
    --region "$REGION" 2>/dev/null || true
done
echo "EC2 ingress rules added (22, 80, 443, 8000)"

# RDS Security Group
echo "Creating RDS security group..."
RDS_SG=$(aws ec2 create-security-group \
  --group-name "${APP_NAME}-rds-sg" \
  --description "Rosier RDS - PostgreSQL from EC2 only" \
  --vpc-id "$DEFAULT_VPC" \
  --region "$REGION" \
  --query 'GroupId' \
  --output text 2>/dev/null) || \
RDS_SG=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=${APP_NAME}-rds-sg" --region "$REGION" --query 'SecurityGroups[0].GroupId' --output text)
echo "RDS Security Group: $RDS_SG"

# Add RDS ingress rule
aws ec2 authorize-security-group-ingress \
  --group-id "$RDS_SG" \
  --protocol tcp \
  --port 5432 \
  --source-group "$EC2_SG" \
  --region "$REGION" 2>/dev/null || true
echo "RDS ingress rule added (5432 from EC2)"

# Redis Security Group
echo "Creating Redis security group..."
REDIS_SG=$(aws ec2 create-security-group \
  --group-name "${APP_NAME}-redis-sg" \
  --description "Rosier Redis - ElastiCache from EC2 only" \
  --vpc-id "$DEFAULT_VPC" \
  --region "$REGION" \
  --query 'GroupId' \
  --output text 2>/dev/null) || \
REDIS_SG=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=${APP_NAME}-redis-sg" --region "$REGION" --query 'SecurityGroups[0].GroupId' --output text)
echo "Redis Security Group: $REDIS_SG"

# Add Redis ingress rule
aws ec2 authorize-security-group-ingress \
  --group-id "$REDIS_SG" \
  --protocol tcp \
  --port 6379 \
  --source-group "$EC2_SG" \
  --region "$REGION" 2>/dev/null || true
echo "Redis ingress rule added (6379 from EC2)"
echo ""

# ============================================================================
# PHASE 2: RDS POSTGRESQL
# ============================================================================

echo "========================================"
echo "ROSIER AWS DEPLOYMENT - PHASE 2: RDS"
echo "========================================"
echo ""

DB_IDENTIFIER="${APP_NAME}-db"
DB_NAME="rosier"
DB_USERNAME="rosier_admin"
DB_PASSWORD=$(openssl rand -base64 32)

echo "Creating RDS PostgreSQL instance..."
aws rds create-db-instance \
  --db-instance-identifier "$DB_IDENTIFIER" \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 16.1 \
  --master-username "$DB_USERNAME" \
  --master-user-password "$DB_PASSWORD" \
  --allocated-storage 20 \
  --storage-type gp2 \
  --vpc-security-group-ids "$RDS_SG" \
  --db-name "$DB_NAME" \
  --port 5432 \
  --publicly-accessible false \
  --backup-retention-period 7 \
  --skip-final-snapshot \
  --region "$REGION" 2>/dev/null || echo "RDS instance may already exist"

echo "RDS instance creation initiated..."
echo "Waiting for endpoint information..."
sleep 5

RDS_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier "$DB_IDENTIFIER" \
  --region "$REGION" \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text 2>/dev/null) || RDS_ENDPOINT="<pending>"
echo "RDS Endpoint: $RDS_ENDPOINT (Status: creating)"
echo "Note: RDS will be fully available in 5-10 minutes"
echo ""

# ============================================================================
# PHASE 3: ELASTICACHE REDIS
# ============================================================================

echo "========================================"
echo "ROSIER AWS DEPLOYMENT - PHASE 3: REDIS"
echo "========================================"
echo ""

REDIS_CLUSTER_ID="${APP_NAME}-redis"

echo "Creating ElastiCache Redis cluster..."
aws elasticache create-cache-cluster \
  --cache-cluster-id "$REDIS_CLUSTER_ID" \
  --cache-node-type cache.t3.micro \
  --engine redis \
  --engine-version 7.0 \
  --num-cache-nodes 1 \
  --port 6379 \
  --security-group-ids "$REDIS_SG" \
  --region "$REGION" 2>/dev/null || echo "Redis cluster may already exist"

echo "Redis cluster creation initiated..."
echo "Waiting for endpoint information..."
sleep 5

REDIS_ENDPOINT=$(aws elasticache describe-cache-clusters \
  --cache-cluster-id "$REDIS_CLUSTER_ID" \
  --region "$REGION" \
  --query 'CacheClusters[0].CacheNodes[0].Endpoint.Address' \
  --output text 2>/dev/null) || REDIS_ENDPOINT="<pending>"
echo "Redis Endpoint: $REDIS_ENDPOINT:6379 (Status: creating)"
echo "Note: Redis will be fully available in 5-10 minutes"
echo ""

# ============================================================================
# PHASE 4: EC2 INSTANCE
# ============================================================================

echo "========================================"
echo "ROSIER AWS DEPLOYMENT - PHASE 4: EC2"
echo "========================================"
echo ""

KEY_NAME="${APP_NAME}-key"
INSTANCE_TYPE="t2.micro"

# Create key pair
echo "Creating EC2 key pair..."
KEY_EXISTS=$(aws ec2 describe-key-pairs --region "$REGION" --query "KeyPairs[?KeyName=='$KEY_NAME'].KeyName" --output text 2>/dev/null) || true

if [ -z "$KEY_EXISTS" ]; then
  aws ec2 create-key-pair \
    --key-name "$KEY_NAME" \
    --region "$REGION" \
    --query 'KeyMaterial' \
    --output text > "${KEY_NAME}.pem"
  chmod 400 "${KEY_NAME}.pem"
  echo "Key pair created: ${KEY_NAME}.pem"
else
  echo "Key pair already exists"
fi

# Get latest Amazon Linux 2023 AMI
echo "Getting latest Amazon Linux 2023 AMI..."
AMI_ID=$(aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-*" "Name=state,Values=available" \
  --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
  --region "$REGION" \
  --output text)
echo "AMI ID: $AMI_ID"

# User data script for EC2
USER_DATA_SCRIPT='#!/bin/bash
yum update -y
yum install -y docker git curl wget
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
mkdir -p /app
echo "EC2 instance ready for Rosier deployment"'

# Launch EC2 instance
echo "Launching EC2 instance (t2.micro, Amazon Linux 2023)..."
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id "$AMI_ID" \
  --instance-type "$INSTANCE_TYPE" \
  --key-name "$KEY_NAME" \
  --security-group-ids "$EC2_SG" \
  --user-data "$USER_DATA_SCRIPT" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${APP_NAME}-api}]" \
  --region "$REGION" \
  --query 'Instances[0].InstanceId' \
  --output text)
echo "EC2 Instance ID: $INSTANCE_ID"

echo "Waiting for instance details..."
sleep 10

# Get instance details
INSTANCE_INFO=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --region "$REGION" --output json)
PUBLIC_IP=$(echo "$INSTANCE_INFO" | grep -o '"PublicIpAddress":"[^"]*"' | head -1 | cut -d'"' -f4)
PRIVATE_IP=$(echo "$INSTANCE_INFO" | grep -o '"PrivateIpAddress":"[^"]*"' | head -1 | cut -d'"' -f4)

echo "Public IP: $PUBLIC_IP (Status: pending assignment)"
echo "Private IP: $PRIVATE_IP"
echo ""

# ============================================================================
# SUMMARY AND SAVE DEPLOYMENT INFO
# ============================================================================

echo "=========================================="
echo "DEPLOYMENT COMPLETE!"
echo "=========================================="
echo ""
echo "SAVE THIS INFORMATION:"
echo ""
echo "SECURITY GROUPS:"
echo "  EC2 SG:   $EC2_SG"
echo "  RDS SG:   $RDS_SG"
echo "  Redis SG: $REDIS_SG"
echo ""
echo "RDS DATABASE:"
echo "  Identifier: $DB_IDENTIFIER"
echo "  Username:   $DB_USERNAME"
echo "  Password:   $DB_PASSWORD"
echo "  Endpoint:   $RDS_ENDPOINT"
echo "  Port:       5432"
echo "  Database:   $DB_NAME"
echo ""
echo "ELASTICACHE REDIS:"
echo "  Cluster ID: $REDIS_CLUSTER_ID"
echo "  Endpoint:   $REDIS_ENDPOINT:6379"
echo ""
echo "EC2 INSTANCE:"
echo "  Instance ID: $INSTANCE_ID"
echo "  Public IP:   $PUBLIC_IP"
echo "  Private IP:  $PRIVATE_IP"
echo "  Key Pair:    $KEY_NAME"
echo "  Region:      $REGION"
echo ""
echo "SSH COMMAND:"
echo "  ssh -i ${KEY_NAME}.pem ec2-user@${PUBLIC_IP}"
echo ""
echo "DATABASE_URL for .env:"
echo "  postgresql+asyncpg://${DB_USERNAME}:${DB_PASSWORD}@${RDS_ENDPOINT}:5432/${DB_NAME}"
echo ""
echo "REDIS_URL for .env:"
echo "  redis://${REDIS_ENDPOINT}:6379/0"
echo ""

# Save to deployment info file
cat > rosier-deployment-info.txt << 'ENDINFO'
ROSIER AWS DEPLOYMENT INFORMATION
===================================
Generated: $(date)
Region: us-east-1
Free Tier: YES (1st 12 months free)

SECURITY GROUPS:
  EC2:   EC2_SG_PLACEHOLDER
  RDS:   RDS_SG_PLACEHOLDER
  Redis: REDIS_SG_PLACEHOLDER

RDS POSTGRESQL 16:
  Identifier: DB_ID_PLACEHOLDER
  Master User: DB_USER_PLACEHOLDER
  Password:    DB_PASS_PLACEHOLDER
  Endpoint:    RDS_ENDPOINT_PLACEHOLDER
  Port:        5432
  Database:    rosier
  Backup:      7-day retention

ELASTICACHE REDIS 7.0:
  Cluster ID: REDIS_ID_PLACEHOLDER
  Endpoint:   REDIS_ENDPOINT_PLACEHOLDER
  Port:       6379
  Mode:       Single node

EC2 INSTANCE (Amazon Linux 2023):
  Instance ID: INSTANCE_ID_PLACEHOLDER
  Type:        t2.micro (Free Tier)
  Public IP:   PUBLIC_IP_PLACEHOLDER
  Private IP:  PRIVATE_IP_PLACEHOLDER
  Key Pair:    KEY_NAME_PLACEHOLDER
  Region:      us-east-1

PRE-CONFIGURED:
  - Docker
  - Docker Compose
  - Git
  - /app directory created

NEXT STEPS:
1. Wait 5-10 minutes for RDS and Redis to initialize
2. Download SSH key: KEY_NAME_PLACEHOLDER.pem
3. SSH to instance: ssh -i KEY_NAME_PLACEHOLDER.pem ec2-user@PUBLIC_IP_PLACEHOLDER
4. Clone repository: git clone <repo> /app && cd /app
5. Create .env file with credentials above
6. Deploy: docker-compose -f infra/docker/docker-compose-prod.yml up -d
7. Verify: curl http://PUBLIC_IP_PLACEHOLDER:8000/docs

IMPORTANT SECURITY NOTES:
- SSH key file is saved: KEY_NAME_PLACEHOLDER.pem
- Database password: DB_PASS_PLACEHOLDER
- RDS endpoint: RDS_ENDPOINT_PLACEHOLDER
- Save these credentials in a secure location!

MONITORING:
- RDS Console: https://us-east-1.console.aws.amazon.com/rds/
- ElastiCache Console: https://us-east-1.console.aws.amazon.com/elasticache/
- EC2 Console: https://us-east-1.console.aws.amazon.com/ec2/

COST ESTIMATE:
Year 1: FREE (AWS Free Tier)
Year 2+: ~$50/month after free tier expires
ENDINFO

# Replace placeholders in the file
sed -i "s|EC2_SG_PLACEHOLDER|$EC2_SG|g" rosier-deployment-info.txt
sed -i "s|RDS_SG_PLACEHOLDER|$RDS_SG|g" rosier-deployment-info.txt
sed -i "s|REDIS_SG_PLACEHOLDER|$REDIS_SG|g" rosier-deployment-info.txt
sed -i "s|DB_ID_PLACEHOLDER|$DB_IDENTIFIER|g" rosier-deployment-info.txt
sed -i "s|DB_USER_PLACEHOLDER|$DB_USERNAME|g" rosier-deployment-info.txt
sed -i "s|DB_PASS_PLACEHOLDER|$DB_PASSWORD|g" rosier-deployment-info.txt
sed -i "s|RDS_ENDPOINT_PLACEHOLDER|$RDS_ENDPOINT|g" rosier-deployment-info.txt
sed -i "s|REDIS_ID_PLACEHOLDER|$REDIS_CLUSTER_ID|g" rosier-deployment-info.txt
sed -i "s|REDIS_ENDPOINT_PLACEHOLDER|$REDIS_ENDPOINT|g" rosier-deployment-info.txt
sed -i "s|INSTANCE_ID_PLACEHOLDER|$INSTANCE_ID|g" rosier-deployment-info.txt
sed -i "s|PUBLIC_IP_PLACEHOLDER|$PUBLIC_IP|g" rosier-deployment-info.txt
sed -i "s|PRIVATE_IP_PLACEHOLDER|$PRIVATE_IP|g" rosier-deployment-info.txt
sed -i "s|KEY_NAME_PLACEHOLDER|$KEY_NAME|g" rosier-deployment-info.txt

echo "Deployment information saved to: rosier-deployment-info.txt"
echo ""
echo "IMPORTANT: Keep this file safe - it contains database credentials!"
echo ""
echo "Deployment initiated successfully!"
echo "Watch the AWS console to monitor resource creation."
