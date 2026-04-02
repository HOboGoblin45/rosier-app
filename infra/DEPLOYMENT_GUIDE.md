# Rosier Backend: AWS Deployment Guide

**Version**: 1.0
**Date**: April 1, 2026
**Budget**: $20 AWS Explore Credit + $100 Free Tier = $120 Total

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [Step 1: Prepare Local Environment](#step-1-prepare-local-environment)
4. [Step 2: Configure AWS Account](#step-2-configure-aws-account)
5. [Step 3: Deploy Infrastructure with Terraform](#step-3-deploy-infrastructure-with-terraform)
6. [Step 4: Deploy Application](#step-4-deploy-application)
7. [Step 5: Verify Deployment](#step-5-verify-deployment)
8. [Monitoring & Maintenance](#monitoring--maintenance)
9. [Troubleshooting](#troubleshooting)
10. [Teardown (if needed)](#teardown-if-needed)

---

## Prerequisites

### Local Development Machine
- AWS CLI v2 installed and configured
- Terraform v1.5+ installed
- Git installed
- SSH client installed
- Text editor (VS Code, nano, vim)
- Docker installed (for testing)

### AWS Account Requirements
- AWS account with Free Tier eligibility
- $20 Explore AWS credit (already applied)
- Access to us-east-1 region
- IAM user with EC2, RDS, ElastiCache, S3, CloudWatch permissions

### Repository
- Rosier repository cloned locally
- Access to `/infra/terraform/` directory

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS us-east-1                             │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────────────────────────────────────┐       │
│  │         EC2 t2.micro (Free Tier)                │       │
│  │  ┌───────────────────────────────────────────┐  │       │
│  │  │ Docker Compose:                           │  │       │
│  │  │ • FastAPI (8000)                          │  │       │
│  │  │ • Nginx reverse proxy (80, 443)           │  │       │
│  │  └───────────────────────────────────────────┘  │       │
│  │  Security Group: 22, 80, 443                    │       │
│  │  Elastic IP: 203.0.113.x (example)             │       │
│  └──────────────────────────────────────────────────┘       │
│           ↓                    ↓                             │
│  ┌─────────────────┐  ┌──────────────────┐                  │
│  │ RDS PostgreSQL  │  │ ElastiCache      │                  │
│  │ 16 db.t3.micro  │  │ Redis 7 cache.t3 │                  │
│  │ 20GB storage    │  │ Single node      │                  │
│  │ 7-day backups   │  │                  │                  │
│  └─────────────────┘  └──────────────────┘                  │
│           ↓                                                  │
│  ┌───────────────────────────────────────────────┐          │
│  │  S3 Bucket (5GB Free Tier)                    │          │
│  │  rosier-assets-ACCOUNT_ID                     │          │
│  └───────────────────────────────────────────────┘          │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

**Cost**: $0/month for 12 months (all Free Tier services)

---

## Step 1: Prepare Local Environment

### 1.1 Configure AWS Credentials

Create or update `~/.aws/credentials`:

```ini
[default]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_ACCESS_KEY
region = us-east-1
```

Or use AWS SSO:

```bash
aws configure sso
```

### 1.2 Verify AWS Credentials

```bash
aws sts get-caller-identity
```

Expected output:

```json
{
    "UserId": "AIDAI...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/charlie"
}
```

### 1.3 Install Required Tools

```bash
# Install/upgrade AWS CLI
pip install --upgrade awscli

# Install Terraform (macOS with Homebrew)
brew install terraform

# Verify Terraform
terraform -version

# Verify AWS CLI
aws --version
```

### 1.4 Clone Repository (if not done)

```bash
git clone https://github.com/rosier/rosier.git
cd rosier/infra/terraform
```

---

## Step 2: Configure AWS Account

### 2.1 Create EC2 Key Pair

```bash
# Create key pair
aws ec2 create-key-pair \
  --key-name rosier-mvp-key \
  --region us-east-1 \
  --query 'KeyMaterial' \
  --output text > rosier-mvp-key.pem

# Set permissions (required for SSH)
chmod 400 rosier-mvp-key.pem

# Save in safe location
mv rosier-mvp-key.pem ~/.ssh/
```

### 2.2 Create IAM User for Application

```bash
# Create IAM user for app (to access S3, RDS, ElastiCache)
aws iam create-user --user-name rosier-app

# Create access key
aws iam create-access-key --user-name rosier-app
```

Save the `AccessKeyId` and `SecretAccessKey` - you'll need them later.

### 2.3 Attach Policies to Application User

```bash
# S3 access
aws iam attach-user-policy \
  --user-name rosier-app \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

# ElastiCache read-only
aws iam attach-user-policy \
  --user-name rosier-app \
  --policy-arn arn:aws:iam::aws:policy/AmazonElastiCacheReadOnlyAccess
```

### 2.4 Enable Billing Alerts

```bash
# Enable receiving billing alerts
aws ce put-anomaly-monitor \
  --anomaly-monitor '{
    "MonitorName": "RosierBudgetAlert",
    "MonitorType": "DIMENSIONAL",
    "MonitorDimension": "SERVICE"
  }'
```

Or manually in AWS Console:
1. Go to Billing Dashboard
2. Click "Billing Preferences"
3. Enable "Receive Billing Alerts"
4. Create CloudWatch alarm for spend > $50

---

## Step 3: Deploy Infrastructure with Terraform

### 3.1 Prepare Terraform Configuration

```bash
cd /path/to/rosier/infra/terraform

# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

Update these values in `terraform.tfvars`:

```hcl
aws_region              = "us-east-1"
environment             = "development"
app_name                = "rosier"
database_password       = "your-strong-password-here"
s3_bucket_name          = "rosier-assets-$(aws sts get-caller-identity --query 'Account' --output text)"
```

### 3.2 Set Environment Variables

```bash
# Set database password (never commit to git!)
export TF_VAR_database_password="your-strong-password-here"

# Set JWT secret
export TF_VAR_jwt_secret_key="$(openssl rand -base64 32)"

# Set Django secret
export TF_VAR_django_secret_key="$(openssl rand -base64 32)"

# Verify
echo "Database password set: $TF_VAR_database_password"
```

### 3.3 Initialize Terraform

```bash
# Download AWS provider plugin
terraform init

# Expected output:
# Terraform has been successfully configured!
```

### 3.4 Plan Infrastructure

```bash
# Generate plan
terraform plan -out=tfplan

# Review the plan - should show:
# - 1 VPC or use default
# - 3 Security Groups
# - 1 EC2 instance
# - 1 RDS database
# - 1 ElastiCache cluster
# - 1 S3 bucket
# - IAM roles and policies
```

### 3.5 Apply Terraform

```bash
# Create infrastructure
terraform apply tfplan

# This takes ~10-15 minutes
# Terraform will output:
# - EC2 public IP
# - RDS endpoint
# - Redis endpoint
# - S3 bucket name
```

### 3.6 Save Outputs

```bash
# Save connection details
terraform output > deployment-details.txt

# Extract key values
EC2_IP=$(terraform output -raw ec2_public_ip)
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
REDIS_ENDPOINT=$(terraform output -raw elasticache_endpoint)
S3_BUCKET=$(terraform output -raw s3_bucket_name)

# Create environment file for later
cat > .env.production << EOF
EC2_IP=$EC2_IP
RDS_ENDPOINT=$RDS_ENDPOINT
REDIS_ENDPOINT=$REDIS_ENDPOINT
S3_BUCKET=$S3_BUCKET
EOF
```

---

## Step 4: Deploy Application

### 4.1 SSH into EC2 Instance

```bash
# SSH into instance
ssh -i ~/.ssh/rosier-mvp-key.pem ec2-user@$EC2_IP

# Expected welcome screen (Amazon Linux 2023)
# User data script should have run, verifying with:
ls -la /app/

# Check Docker installation
docker --version
docker-compose --version
```

### 4.2 Clone Repository

```bash
# Clone repository (on EC2)
sudo -u ec2-user git clone https://github.com/rosier/rosier.git /app
cd /app

# Or if already in /app, pull latest
git pull origin main
```

### 4.3 Configure Environment

```bash
# Create .env file with values from Terraform
cat > /app/.env << 'EOF'
# From Terraform outputs
DATABASE_URL=postgresql+asyncpg://postgres:PASSWORD@RDS_ENDPOINT:5432/rosier
REDIS_URL=redis://REDIS_ENDPOINT:6379/0
S3_BUCKET=S3_BUCKET_NAME

# From IAM user
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

# Security secrets (from Terraform)
JWT_SECRET_KEY=your-jwt-secret
SECRET_KEY=your-django-secret

# Application
ENVIRONMENT=production
DEBUG=false
LOG_LEVEL=info

# AWS
AWS_REGION=us-east-1
EOF

# Set permissions
chmod 600 /app/.env
```

### 4.4 Deploy with Docker Compose

```bash
# Navigate to backend
cd /app/backend

# Build Docker image
docker-compose -f ../infra/docker/docker-compose-prod.yml build --no-cache

# Start services (API and Nginx)
docker-compose -f ../infra/docker/docker-compose-prod.yml up -d

# Check status
docker-compose -f ../infra/docker/docker-compose-prod.yml ps

# View logs
docker-compose -f ../infra/docker/docker-compose-prod.yml logs -f api
```

### 4.5 Run Database Migrations

```bash
# Wait for database to be ready (10-30 seconds)
sleep 30

# Run migrations
docker-compose -f ../infra/docker/docker-compose-prod.yml exec api alembic upgrade head

# Create superuser (if using Django admin)
docker-compose -f ../infra/docker/docker-compose-prod.yml exec api python -c "
from app.models import User
from app.schemas.auth import UserCreate
from sqlalchemy.orm import Session
# Create admin user
"

# Expected output: "Upgrade to revision XXXXX complete"
```

---

## Step 5: Verify Deployment

### 5.1 API Health Check

```bash
# From local machine
curl http://$EC2_IP:8000/health

# Expected output:
# {"status":"healthy","database":"connected","redis":"connected","timestamp":"2026-04-01T..."}

# Or through Nginx
curl http://$EC2_IP/health
```

### 5.2 Database Connection Test

```bash
# SSH into EC2
ssh -i ~/.ssh/rosier-mvp-key.pem ec2-user@$EC2_IP

# Test PostgreSQL connection
docker-compose -f /app/infra/docker/docker-compose-prod.yml exec api python -c "
from sqlalchemy import create_engine, text
import os
engine = create_engine(os.getenv('DATABASE_URL'))
with engine.connect() as conn:
    result = conn.execute(text('SELECT NOW()'))
    print('Database connected:', result.scalar())
"

# Expected output: Database connected: 2026-04-01 12:00:00.000000
```

### 5.3 Redis Connection Test

```bash
# Test Redis connection
docker-compose -f /app/infra/docker/docker-compose-prod.yml exec api redis-cli -u $REDIS_URL ping

# Expected output: PONG
```

### 5.4 S3 Access Test

```bash
# Test S3 bucket
docker-compose -f /app/infra/docker/docker-compose-prod.yml exec api aws s3 ls s3://$S3_BUCKET

# Expected output: (empty list on first run)
```

### 5.5 API Test

```bash
# Test a sample endpoint
curl -X GET http://$EC2_IP:8000/api/health

# Or use python
python -c "
import requests
response = requests.get('http://$EC2_IP:8000/api/health')
print(response.json())
"
```

---

## Monitoring & Maintenance

### Regular Tasks

#### Daily
- Check EC2 CPU/memory usage (CloudWatch or `docker stats`)
- Review application logs for errors
- Monitor error rate (target: <1%)

#### Weekly
- Review RDS slow query log
- Check database storage growth
- Review Redis memory usage
- Check S3 bucket growth

#### Monthly
- Review AWS Cost Explorer
- Validate Free Tier usage
- Check RDS backups
- Rotate database password (if needed)
- Review security group rules

### Setting Up CloudWatch Alarms

```bash
# Create alarm for high CPU
aws cloudwatch put-metric-alarm \
  --alarm-name rosier-ec2-high-cpu \
  --alarm-description "Alert when EC2 CPU is high" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2

# Create alarm for high memory (requires CloudWatch agent)
aws cloudwatch put-metric-alarm \
  --alarm-name rosier-ec2-high-memory \
  --alarm-description "Alert when memory usage is high" \
  --metric-name MemoryUtilization \
  --namespace CloudWatchAgent \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2

# Create alarm for billing
aws cloudwatch put-metric-alarm \
  --alarm-name rosier-billing-alert \
  --alarm-description "Alert when monthly billing exceeds threshold" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 86400 \
  --threshold 50 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1
```

### Backup Strategy

```bash
# RDS backups are automatic (7-day retention)
# View RDS snapshots
aws rds describe-db-snapshots \
  --db-instance-identifier rosier-db \
  --region us-east-1

# Create manual snapshot
aws rds create-db-snapshot \
  --db-instance-identifier rosier-db \
  --db-snapshot-identifier rosier-db-backup-2026-04-01

# Export RDS snapshot to S3
aws rds start-export-task \
  --export-task-identifier rosier-export-2026-04-01 \
  --source-arn arn:aws:rds:us-east-1:ACCOUNT:db:rosier-db \
  --s3-bucket-name $S3_BUCKET \
  --s3-prefix backups/ \
  --iam-role-arn arn:aws:iam::ACCOUNT:role/...
```

---

## Troubleshooting

### Common Issues

#### Issue: Connection Refused to RDS

**Symptoms**: Docker API fails to connect to database

**Solution**:
1. Verify RDS security group allows EC2 security group
2. Check RDS endpoint is correct
3. Verify DATABASE_URL environment variable
4. Wait for RDS to be fully available (can take 5+ minutes)

```bash
# Check RDS status
aws rds describe-db-instances \
  --db-instance-identifier rosier-db \
  --query 'DBInstances[0].DBInstanceStatus'

# Expected: "available"
```

#### Issue: Redis Connection Timeout

**Symptoms**: Redis operations fail or timeout

**Solution**:
1. Verify ElastiCache security group allows EC2
2. Check REDIS_URL is correct
3. Verify ElastiCache cluster is running

```bash
# Check ElastiCache status
aws elasticache describe-cache-clusters \
  --cache-cluster-id rosier-redis \
  --query 'CacheClusters[0].CacheClusterStatus'

# Expected: "available"
```

#### Issue: Out of Memory on EC2

**Symptoms**: Docker container killed, 137 exit code

**Solution**:
1. Reduce memory limits in docker-compose
2. Optimize database queries
3. Enable more aggressive Redis caching
4. Upgrade EC2 to t2.small (costs extra)

```bash
# Check memory usage
docker stats

# Reduce FastAPI memory limit
# Edit docker-compose-prod.yml, change from 800M to 600M
```

#### Issue: S3 Access Denied

**Symptoms**: S3 upload fails with AccessDenied error

**Solution**:
1. Verify IAM user has S3 permissions
2. Check AWS credentials in .env
3. Verify bucket name is correct

```bash
# Check IAM user permissions
aws iam get-user-policy \
  --user-name rosier-app \
  --policy-name AmazonS3FullAccess

# Re-attach if missing
aws iam attach-user-policy \
  --user-name rosier-app \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
```

#### Issue: API Returns 502 Bad Gateway

**Symptoms**: Nginx shows 502 error

**Solution**:
1. Check API container is running
2. Review API logs for errors
3. Verify API health endpoint

```bash
# Check API container
docker-compose -f /app/infra/docker/docker-compose-prod.yml ps

# View API logs
docker-compose logs api | tail -50

# Restart API
docker-compose -f /app/infra/docker/docker-compose-prod.yml restart api
```

### Debug Commands

```bash
# View all Docker logs
docker-compose logs -f

# View specific service logs with timestamps
docker-compose logs --timestamps api

# Execute command in container
docker-compose exec api bash
docker-compose exec api python -c "import os; print(os.getenv('DATABASE_URL'))"

# Monitor container resource usage
docker stats

# Check network connectivity between containers
docker-compose exec api ping redis
docker-compose exec api ping postgres

# View Docker network
docker network ls
docker network inspect rosier-network

# Check exposed ports
docker-compose ps
netstat -tuln | grep 8000
```

---

## Teardown (if needed)

### Destroy Infrastructure

**WARNING**: This will delete all AWS resources and data!

```bash
# Confirm you want to delete
terraform plan -destroy

# Destroy infrastructure
terraform destroy

# This removes:
# - EC2 instance
# - RDS database (data is deleted)
# - ElastiCache cluster
# - S3 bucket
# - Security groups
# - IAM roles

# Delete SSH key
aws ec2 delete-key-pair --key-name rosier-mvp-key
rm ~/.ssh/rosier-mvp-key.pem

# Delete IAM user and credentials
aws iam delete-access-key --user-name rosier-app --access-key-id AKIAIOSFODNN7EXAMPLE
aws iam detach-user-policy --user-name rosier-app --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
aws iam delete-user --user-name rosier-app
```

---

## Next Steps

### Short-term (Week 1-2)
- [ ] Verify all endpoints are functional
- [ ] Load test with concurrent users
- [ ] Test error scenarios
- [ ] Document API with Swagger/OpenAPI
- [ ] Set up automated backups

### Medium-term (Month 1-2)
- [ ] Enable HTTPS with ACM certificate
- [ ] Set up DNS with Route 53
- [ ] Configure CloudFront CDN for static assets
- [ ] Implement CI/CD pipeline with GitHub Actions
- [ ] Add monitoring dashboards

### Long-term (Month 3+)
- [ ] Plan upgrade to t2.small (if needed)
- [ ] Implement read replicas for RDS
- [ ] Add multi-node Redis cluster
- [ ] Set up Elasticsearch for search
- [ ] Implement auto-scaling groups

---

## Support & Resources

### AWS Documentation
- [EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [RDS Documentation](https://docs.aws.amazon.com/rds/)
- [ElastiCache Documentation](https://docs.aws.amazon.com/elasticache/)
- [S3 Documentation](https://docs.aws.amazon.com/s3/)

### Terraform Documentation
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices.html)

### FastAPI
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [FastAPI + SQLAlchemy](https://fastapi.tiangolo.com/advanced/sql-databases/)

### Docker
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)

---

## Contact & Issues

For questions or issues, contact:
- Charlie (Founder): charlie@rosierapp.com
- Dev Team: dev@rosierapp.com
- Issue tracker: https://github.com/rosier/rosier/issues

---

**Last Updated**: April 1, 2026
**Deployment Status**: Ready for Production MVP
**Budget Status**: $0/month (12-month Free Tier)
