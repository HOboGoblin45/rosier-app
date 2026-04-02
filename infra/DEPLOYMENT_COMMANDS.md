# Rosier AWS Deployment - Command Reference

**Quick reference for all deployment commands**

---

## CloudShell - Running Deployment

### 1. Open CloudShell
```
https://us-east-1.console.aws.amazon.com/cloudshell/home
```

### 2. Run the Deployment Script

The deployment script is ready to use. To run it, execute in CloudShell:

```bash
# Option A: Run the one-click deployment script
bash /tmp/rosier-deployment/one_click_deploy.sh

# Option B: Run AWS CLI commands directly (see sections below)
```

---

## Direct AWS CLI Commands (Step by Step)

If you prefer to run commands manually, execute these in CloudShell in order:

### Setup Variables

```bash
REGION="us-east-1"
APP_NAME="rosier"
DEPLOYMENT_DIR="/tmp/rosier-deployment"

mkdir -p "$DEPLOYMENT_DIR"
cd "$DEPLOYMENT_DIR"
```

### Get Default VPC

```bash
DEFAULT_VPC=$(aws ec2 describe-vpcs --region "$REGION" \
  --query 'Vpcs[?IsDefault==`true`].VpcId' --output text)

echo "VPC: $DEFAULT_VPC"
```

---

## Phase 1: Security Groups

### Create EC2 Security Group

```bash
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

echo "EC2 Security Group: $EC2_SG"
```

### Add EC2 Ingress Rules

```bash
for PORT in 22 80 443 8000; do
  aws ec2 authorize-security-group-ingress \
    --group-id "$EC2_SG" \
    --protocol tcp \
    --port "$PORT" \
    --cidr 0.0.0.0/0 \
    --region "$REGION" 2>/dev/null || true
done

echo "EC2 ingress rules added (SSH, HTTP, HTTPS, API)"
```

### Create RDS Security Group

```bash
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

echo "RDS Security Group: $RDS_SG"
```

### Add RDS Ingress Rule

```bash
aws ec2 authorize-security-group-ingress \
  --group-id "$RDS_SG" \
  --protocol tcp \
  --port 5432 \
  --source-group "$EC2_SG" \
  --region "$REGION" 2>/dev/null || true

echo "RDS PostgreSQL access from EC2 allowed"
```

### Create Redis Security Group

```bash
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

echo "Redis Security Group: $REDIS_SG"
```

### Add Redis Ingress Rule

```bash
aws ec2 authorize-security-group-ingress \
  --group-id "$REDIS_SG" \
  --protocol tcp \
  --port 6379 \
  --source-group "$EC2_SG" \
  --region "$REGION" 2>/dev/null || true

echo "Redis access from EC2 allowed"
```

---

## Phase 2: RDS PostgreSQL

### Create Database

```bash
DB_IDENTIFIER="${APP_NAME}-db"
DB_NAME="rosier"
DB_USERNAME="rosier_admin"
DB_PASSWORD=$(openssl rand -base64 32)

echo "Database Password: $DB_PASSWORD"
echo "SAVE THIS PASSWORD SOMEWHERE SECURE!"

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
  --region "$REGION" 2>/dev/null || \
echo "RDS instance may already exist"
```

### Get RDS Endpoint

```bash
# Wait for endpoint (may take a moment)
sleep 5

RDS_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier "$DB_IDENTIFIER" \
  --region "$REGION" \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text 2>/dev/null) || RDS_ENDPOINT="<pending>"

echo "RDS Endpoint: $RDS_ENDPOINT"
echo "Note: Will be fully available in 5-10 minutes"
```

---

## Phase 3: ElastiCache Redis

### Create Redis Cluster

```bash
REDIS_CLUSTER_ID="${APP_NAME}-redis"

aws elasticache create-cache-cluster \
  --cache-cluster-id "$REDIS_CLUSTER_ID" \
  --cache-node-type cache.t3.micro \
  --engine redis \
  --engine-version 7.0 \
  --num-cache-nodes 1 \
  --port 6379 \
  --security-group-ids "$REDIS_SG" \
  --region "$REGION" 2>/dev/null || \
echo "Redis cluster may already exist"
```

### Get Redis Endpoint

```bash
# Wait for endpoint
sleep 5

REDIS_ENDPOINT=$(aws elasticache describe-cache-clusters \
  --cache-cluster-id "$REDIS_CLUSTER_ID" \
  --region "$REGION" \
  --query 'CacheClusters[0].CacheNodes[0].Endpoint.Address' \
  --output text 2>/dev/null) || REDIS_ENDPOINT="<pending>"

echo "Redis Endpoint: $REDIS_ENDPOINT:6379"
echo "Note: Will be fully available in 5-10 minutes"
```

---

## Phase 4: EC2 Instance

### Create Key Pair

```bash
KEY_NAME="${APP_NAME}-key"

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
  echo "Key pair created: ${KEY_NAME}.pem"
else
  echo "Key pair already exists"
fi
```

### Get Latest AMI

```bash
AMI_ID=$(aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-*" "Name=state,Values=available" \
  --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
  --region "$REGION" \
  --output text)

echo "AMI ID: $AMI_ID (Amazon Linux 2023)"
```

### Launch EC2 Instance

```bash
INSTANCE_TYPE="t2.micro"

USER_DATA='#!/bin/bash
yum update -y
yum install -y docker git curl wget
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
mkdir -p /app
echo "EC2 ready for deployment"'

INSTANCE_ID=$(aws ec2 run-instances \
  --image-id "$AMI_ID" \
  --instance-type "$INSTANCE_TYPE" \
  --key-name "$KEY_NAME" \
  --security-group-ids "$EC2_SG" \
  --user-data "$USER_DATA" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${APP_NAME}-api}]" \
  --region "$REGION" \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Instance launched: $INSTANCE_ID"
```

### Get EC2 Details

```bash
# Wait for details to be available
sleep 10

INSTANCE_INFO=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --region "$REGION" \
  --output json)

PUBLIC_IP=$(echo "$INSTANCE_INFO" | grep -o '"PublicIpAddress":"[^"]*"' | head -1 | cut -d'"' -f4)
PRIVATE_IP=$(echo "$INSTANCE_INFO" | grep -o '"PrivateIpAddress":"[^"]*"' | head -1 | cut -d'"' -f4)

echo "Public IP: $PUBLIC_IP (Status: may be pending)"
echo "Private IP: $PRIVATE_IP"
```

---

## Save Deployment Information

```bash
cat > rosier-deployment-info.txt << EOF
ROSIER AWS DEPLOYMENT INFO
====================================
Date: $(date)

SECURITY GROUPS:
  EC2:   $EC2_SG
  RDS:   $RDS_SG
  Redis: $REDIS_SG

RDS POSTGRESQL:
  Identifier: $DB_IDENTIFIER
  Username:   $DB_USERNAME
  Password:   $DB_PASSWORD
  Endpoint:   $RDS_ENDPOINT
  Port:       5432
  Database:   $DB_NAME

ELASTICACHE REDIS:
  Cluster ID: $REDIS_CLUSTER_ID
  Endpoint:   $REDIS_ENDPOINT:6379

EC2 INSTANCE:
  Instance ID: $INSTANCE_ID
  Type:        $INSTANCE_TYPE
  Public IP:   $PUBLIC_IP
  Private IP:  $PRIVATE_IP
  Key Pair:    $KEY_NAME
  Region:      $REGION

SSH COMMAND:
  ssh -i ${KEY_NAME}.pem ec2-user@${PUBLIC_IP}

DATABASE_URL:
  postgresql+asyncpg://${DB_USERNAME}:${DB_PASSWORD}@${RDS_ENDPOINT}:5432/${DB_NAME}

REDIS_URL:
  redis://${REDIS_ENDPOINT}:6379/0

NEXT STEPS:
1. Wait 5-10 minutes for RDS and Redis to be available
2. Download key: ${KEY_NAME}.pem
3. SSH to EC2 and deploy application
4. Configure .env with credentials above
5. Run: docker-compose -f infra/docker/docker-compose-prod.yml up -d
6. Test: curl http://${PUBLIC_IP}:8000/docs
EOF

echo "Deployment info saved to: rosier-deployment-info.txt"
```

---

## Monitoring Deployment Progress

### Check RDS Status

```bash
aws rds describe-db-instances \
  --db-instance-identifier "$DB_IDENTIFIER" \
  --region "$REGION" \
  --query 'DBInstances[0].[DBInstanceStatus, Endpoint.Address]' \
  --output table
```

Should show: `available` and the endpoint address

### Check Redis Status

```bash
aws elasticache describe-cache-clusters \
  --cache-cluster-id "$REDIS_CLUSTER_ID" \
  --region "$REGION" \
  --query 'CacheClusters[0].[CacheClusterStatus, CacheNodes[0].Endpoint.Address]' \
  --output table
```

Should show: `available` and the endpoint address

### Check EC2 Status

```bash
aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --region "$REGION" \
  --query 'Reservations[0].Instances[0].[InstanceId, State.Name, PublicIpAddress, PublicIpAddress]' \
  --output table
```

Should show: `running` and the public IP address

---

## AWS Console Links

- RDS: https://us-east-1.console.aws.amazon.com/rds/
- ElastiCache: https://us-east-1.console.aws.amazon.com/elasticache/
- EC2: https://us-east-1.console.aws.amazon.com/ec2/

---

## Tips

1. **Copy the key file immediately** after creation
2. **Save all endpoints and passwords** from CloudShell output
3. **Wait 10 minutes** before testing database connections
4. **Check CloudWatch** for instance logs after deployment
5. **Verify security groups** if connection issues occur

---

**Version**: 1.0
**Date**: April 1, 2026
