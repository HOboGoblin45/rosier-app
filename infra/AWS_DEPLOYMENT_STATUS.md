# Rosier Backend AWS Deployment Status

**Date**: April 1, 2026
**Status**: DEPLOYMENT INITIATED
**Region**: us-east-1
**Cost**: FREE (AWS Free Tier - Year 1)

---

## Deployment Overview

The Rosier backend is being deployed to AWS using CloudShell. This document tracks the deployment progress and contains all necessary credentials and endpoints for managing the infrastructure.

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     AWS Infrastructure                       │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────┐                                        │
│  │   EC2 Instance   │ (t2.micro, Amazon Linux 2023)          │
│  │  rosier-api      │                                        │
│  │  Port: 8000      │                                        │
│  └────────┬─────────┘                                        │
│           │                                                  │
│      ┌────┴────────────────────┬─────────────┐              │
│      │                         │             │              │
│  ┌───▼──────┐         ┌───────▼──┐    ┌────▼────┐          │
│  │   RDS    │         │  Redis   │    │ Security │          │
│  │PostgreSQL│         │ElastiCache   │  Groups  │          │
│  │ Port5432 │         │ Port 6379    │          │          │
│  └──────────┘         └──────────┘    └──────────┘          │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## Deployment Progress

### Phase 1: Security Groups ✅ COMPLETE

Three security groups created for network isolation:

| Name | ID | Rules | Purpose |
|------|----|----- -|---------|
| rosier-ec2-sg | sg-... | SSH(22), HTTP(80), HTTPS(443), API(8000) | EC2 instance access |
| rosier-rds-sg | sg-... | PostgreSQL(5432) from EC2 only | Database security |
| rosier-redis-sg | sg-... | Redis(6379) from EC2 only | Cache security |

### Phase 2: RDS PostgreSQL 🔄 IN PROGRESS

Creating managed PostgreSQL database on AWS RDS.

| Property | Value |
|----------|-------|
| DB Instance Identifier | rosier-db |
| Instance Class | db.t3.micro (Free Tier) |
| Engine | PostgreSQL 16.1 |
| Database Name | rosier |
| Master Username | rosier_admin |
| Master Password | [SAVED IN CREDENTIALS SECTION] |
| Storage | 20GB gp2 (Free Tier) |
| Port | 5432 |
| Publicly Accessible | No |
| Backup Retention | 7 days |
| Status | Creating (5-10 min) |

**Endpoint**: rosier-db.xxxxxxxxxxxxx.us-east-1.rds.amazonaws.com (will appear when ready)

### Phase 3: ElastiCache Redis 🔄 IN PROGRESS

Creating managed Redis cluster for session/cache storage.

| Property | Value |
|----------|-------|
| Cache Cluster ID | rosier-redis |
| Node Type | cache.t3.micro (Free Tier) |
| Engine | Redis 7.0 |
| Number of Nodes | 1 |
| Port | 6379 |
| Status | Creating (5-10 min) |

**Endpoint**: rosier-redis.xxxxxxxxxxxxx.ng.0001.cache.amazonaws.com:6379 (will appear when ready)

### Phase 4: EC2 Instance 🔄 IN PROGRESS

Launching compute instance with Docker pre-installed.

| Property | Value |
|----------|-------|
| Instance ID | i-... |
| Instance Type | t2.micro (Free Tier) |
| AMI | Amazon Linux 2023 (Latest) |
| Key Pair | rosier-key |
| Security Group | rosier-ec2-sg |
| Storage | 20GB gp2 |
| Status | Launching (2-5 min) |
| Public IP | [PENDING] |
| Private IP | [PENDING] |

**Pre-installed Software**:
- Docker (running)
- Docker Compose (latest)
- Git
- curl, wget
- /app directory created

---

## AWS Credentials & Endpoints

### VPC & Network

```
VPC ID: vpc-0b3da6b1b61d33197
Region: us-east-1
Availability Zone: us-east-1a (automatic)
```

### RDS PostgreSQL

```
Identifier: rosier-db
Endpoint: [PENDING - Check RDS Console]
Port: 5432
Username: rosier_admin
Password: [STORED SECURELY - See CloudShell output]
Database: rosier
Connection String (when ready):
  postgresql+asyncpg://rosier_admin:PASSWORD@RDS_ENDPOINT:5432/rosier
```

### ElastiCache Redis

```
Cluster ID: rosier-redis
Endpoint: [PENDING - Check ElastiCache Console]
Port: 6379
Connection String (when ready):
  redis://REDIS_ENDPOINT:6379/0
```

### EC2 Instance

```
Instance ID: [PENDING]
Instance Type: t2.micro
Key Pair: rosier-key.pem
Public IP: [PENDING - Check EC2 Console]
Private IP: [PENDING]
Region: us-east-1

SSH Command (when ready):
  ssh -i rosier-key.pem ec2-user@PUBLIC_IP
```

---

## Next Steps (30-45 minutes from now)

### Step 1: Monitor Initialization (10-15 minutes)

Wait for all services to be fully available. Check AWS Console:

1. **RDS Console**: https://us-east-1.console.aws.amazon.com/rds/
   - Look for: DBInstances > rosier-db > Status = "Available"
   - Note the "Endpoint" value when shown

2. **ElastiCache Console**: https://us-east-1.console.aws.amazon.com/elasticache/
   - Look for: Clusters > rosier-redis > Status = "available"
   - Note the endpoint address when shown

3. **EC2 Console**: https://us-east-1.console.aws.amazon.com/ec2/
   - Look for: Instances > rosier-api
   - Note the "Public IPv4 address" when assigned

### Step 2: SSH to EC2 Instance (5 minutes)

Once the instance has a public IP:

```bash
# Download the SSH key (saved in CloudShell output)
# Save as: rosier-key.pem
# Permissions: chmod 400 rosier-key.pem

ssh -i rosier-key.pem ec2-user@PUBLIC_IP

# Verify Docker is running
docker --version
docker-compose --version

# Check /app directory
ls -la /app
```

### Step 3: Deploy the Rosier Application (10 minutes)

On the EC2 instance:

```bash
# Clone the repository
cd /app
git clone <YOUR_REPO_URL> .

# Create .env file with database credentials
cat > .env << 'EOF'
# Database
DATABASE_URL=postgresql+asyncpg://rosier_admin:PASSWORD@RDS_ENDPOINT:5432/rosier
POSTGRES_USER=rosier_admin
POSTGRES_PASSWORD=PASSWORD
POSTGRES_DB=rosier

# Redis
REDIS_URL=redis://REDIS_ENDPOINT:6379/0

# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=<YOUR_AWS_KEY>
AWS_SECRET_ACCESS_KEY=<YOUR_AWS_SECRET>
S3_BUCKET=rosier-assets

# Application
ENVIRONMENT=production
DEBUG=false

# Security
JWT_SECRET_KEY=<GENERATE_SECURE_KEY>
SECRET_KEY=<GENERATE_SECURE_KEY>

# API Configuration
API_HOST=0.0.0.0
API_PORT=8000
CORS_ORIGINS=["http://localhost:3000","https://yourdomain.com"]
EOF

# Build and start the application
docker-compose -f infra/docker/docker-compose-prod.yml up -d

# Check logs
docker-compose logs -f api

# Run database migrations
docker-compose -f infra/docker/docker-compose-prod.yml exec api alembic upgrade head
```

### Step 4: Verify API is Live (2 minutes)

```bash
# From EC2 instance
curl http://localhost:8000/health

# From your local machine
curl http://PUBLIC_IP:8000/health

# Open in browser
# http://PUBLIC_IP:8000/docs  (Swagger UI)
```

Expected response:
```json
{"status":"ok"}
```

---

## Troubleshooting

### RDS Connection Timeout

If you get "connection timeout" when connecting to RDS:

1. **Wait 10 minutes** after deployment - RDS takes time to initialize
2. **Check RDS Status**:
   ```bash
   aws rds describe-db-instances --db-instance-identifier rosier-db --query 'DBInstances[0].DBInstanceStatus'
   ```
   Should return: `available`

3. **Test from EC2**:
   ```bash
   psql -h RDS_ENDPOINT -U rosier_admin -d rosier
   # Enter password when prompted
   ```

4. **Check Security Groups**: RDS security group must allow TCP 5432 from EC2 security group

### Redis Connection Error

Similar debugging steps:

1. **Wait 10 minutes** for Redis to be fully available
2. **Check Redis Status**:
   ```bash
   aws elasticache describe-cache-clusters --cache-cluster-id rosier-redis --query 'CacheClusters[0].CacheClusterStatus'
   ```
   Should return: `available`

3. **Test from EC2**:
   ```bash
   redis-cli -h REDIS_ENDPOINT ping
   ```
   Should return: `PONG`

### API Container Won't Start

```bash
# Check logs
docker logs rosier-api

# Verify environment variables
docker exec rosier-api env

# Check database connectivity
docker exec rosier-api psql -h RDS_ENDPOINT -U rosier_admin -d rosier -c "SELECT 1"
```

### Can't SSH to EC2

1. **Wait 3-5 minutes** after instance launch for SSH to be ready
2. **Verify security group** allows SSH (port 22) from your IP
3. **Check key permissions**: `ls -la rosier-key.pem` should show `-r--------`
4. **Try with verbose output**: `ssh -vvv -i rosier-key.pem ec2-user@PUBLIC_IP`

---

## Cost Breakdown

### Year 1 (FREE Tier)
```
EC2 t2.micro:     $0  (750 hours/month included)
RDS db.t3.micro:  $0  (750 hours + 20GB storage included)
ElastiCache:      $0  (750 hours included)
Data Transfer:    $0  (< 1GB/month)
─────────────────────
TOTAL:            $0/month
```

### Year 2+ (After Free Tier Expires)
```
EC2 t2.micro:     ~$8/month
RDS db.t3.micro:  ~$24/month
ElastiCache:      ~$17/month
S3 + Data:        ~$2/month
─────────────────────
TOTAL:            ~$50/month
```

---

## Production Upgrades (When Needed)

### When to Scale

- **Reaching $10K MRR**: Add RDS read replicas
- **High traffic**: Migrate to ECS Fargate with load balancer
- **Data growth**: Upgrade RDS to larger instance class

### Security Hardening

Before going live with real user data:

1. **Restrict SSH access** to your IP only
2. **Enable RDS encryption** (requires new instance)
3. **Use AWS Secrets Manager** for credentials
4. **Enable VPC Flow Logs** for network monitoring
5. **Set up SSL/TLS** for API (ACM certificate)
6. **Enable CloudWatch** alarms and monitoring
7. **Configure backup strategy** and testing

---

## AWS Console Links

- **RDS**: https://us-east-1.console.aws.amazon.com/rds/
- **ElastiCache**: https://us-east-1.console.aws.amazon.com/elasticache/
- **EC2**: https://us-east-1.console.aws.amazon.com/ec2/
- **CloudWatch**: https://us-east-1.console.aws.amazon.com/cloudwatch/
- **CloudShell**: https://us-east-1.console.aws.amazon.com/cloudshell/

---

## Important Notes

1. **SSH Key**: The key `rosier-key.pem` is generated and displayed in CloudShell. Download and save it securely.
2. **Credentials**: Database password and Redis endpoints are shown in CloudShell output. Save them immediately.
3. **No Downtime**: This deployment doesn't affect existing infrastructure.
4. **Free Tier**: All services qualify for AWS Free Tier (1st 12 months free).
5. **Monitoring**: Check CloudWatch for logs and metrics after deployment.

---

## Version

- **Deployment Script Version**: 1.0
- **Date Created**: April 1, 2026
- **Region**: us-east-1
- **Status**: LIVE DEPLOYMENT IN PROGRESS

---

## Contact & Support

For questions about this deployment:
1. Check CloudShell for the full deployment output
2. Review AWS Console for resource status
3. Check application logs in docker-compose output
4. Refer to deployment documentation: `/infra/CLOUDSHELL_DEPLOYMENT_GUIDE.md`

Last Updated: April 1, 2026
