# Rosier Backend: AWS CloudShell Deployment Guide

**Date**: April 1, 2026
**Region**: us-east-1
**Cost**: $0/month (Free Tier)
**Time to Deploy**: ~30 minutes (including RDS/Redis initialization)

---

## Quick Start

This guide walks you through deploying the Rosier backend API to AWS using the automated deployment script.

### Prerequisites

- AWS Account with us-east-1 region enabled
- Access to AWS Console: https://console.aws.amazon.com
- This deployment script: `infra/deploy-to-aws.sh`

### Step 1: Open AWS CloudShell

1. Go to: https://us-east-1.console.aws.amazon.com/cloudshell/home
2. The terminal should open in the bottom half of your screen
3. If prompted, click "Close" on the welcome modal

### Step 2: Download and Run the Deployment Script

In CloudShell, paste these commands:

```bash
# Create a working directory
mkdir -p /tmp/rosier-deploy
cd /tmp/rosier-deploy

# Download the deployment script
wget https://raw.githubusercontent.com/YOUR_REPO/main/infra/deploy-to-aws.sh

# Or copy-paste the script content directly into CloudShell
# (See deploy-to-aws.sh file in infra/ directory)

# Make it executable
chmod +x deploy-to-aws.sh

# Run the deployment
./deploy-to-aws.sh
```

### Step 3: Save the Output

After the script completes, you'll see a deployment summary with:

- Security Group IDs (EC2, RDS, Redis)
- RDS endpoint and credentials
- Redis endpoint
- EC2 instance ID and public IP
- SSH key information

**IMPORTANT**: Copy and save this information somewhere safe (password manager, notes, etc.)

The script also creates a file `rosier-deployment-info.txt` with all this information.

---

## What Gets Deployed

### Phase 1: Security Groups (Instant)

Three security groups are created:

1. **rosier-ec2-sg**: Allows incoming SSH (22), HTTP (80), HTTPS (443), and API (8000)
2. **rosier-rds-sg**: Allows PostgreSQL (5432) from EC2 only
3. **rosier-redis-sg**: Allows Redis (6379) from EC2 only

### Phase 2: RDS PostgreSQL (5-10 minutes)

- **Instance**: db.t3.micro (Free Tier)
- **Engine**: PostgreSQL 16
- **Storage**: 20GB gp2 (Free Tier)
- **Database Name**: rosier
- **Master Username**: rosier_admin
- **Port**: 5432
- **Backups**: 7-day retention

### Phase 3: ElastiCache Redis (5-10 minutes)

- **Instance**: cache.t3.micro (Free Tier)
- **Engine**: Redis 7.0
- **Mode**: Single node (no replication)
- **Port**: 6379

### Phase 4: EC2 Instance (2-5 minutes)

- **Instance Type**: t2.micro (Free Tier)
- **AMI**: Amazon Linux 2023
- **Storage**: 20GB gp2
- **Pre-installed**: Docker, Docker Compose, Git, AWS CLI, PostgreSQL client, Redis CLI
- **Systemd Service**: Auto-starts docker-compose on boot

---

## After Deployment

### 1. Wait for Database and Cache to Initialize

RDS and Redis take 5-10 minutes to be fully available. You'll know they're ready when:

- RDS: The endpoint appears in the RDS console and is reachable on port 5432
- Redis: The cluster shows status "available" in the ElastiCache console

### 2. Connect to Your EC2 Instance

Use the SSH key created during deployment:

```bash
# Download the key from CloudShell
# The key file is: rosier-key.pem (created in /tmp/rosier-deploy/)

# On your local machine, SSH to the instance:
ssh -i rosier-key.pem ec2-user@<PUBLIC_IP>

# Example:
# ssh -i rosier-key.pem ec2-user@203.0.113.25
```

### 3. Configure Environment Variables

On the EC2 instance, create `/app/.env`:

```bash
# Database
DATABASE_URL=postgresql+asyncpg://rosier_admin:<PASSWORD>@<RDS_ENDPOINT>:5432/rosier
POSTGRES_USER=rosier_admin
POSTGRES_PASSWORD=<PASSWORD>
POSTGRES_DB=rosier

# Redis
REDIS_URL=redis://<REDIS_ENDPOINT>:6379/0

# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=<YOUR_AWS_KEY>
AWS_SECRET_ACCESS_KEY=<YOUR_AWS_SECRET>
S3_BUCKET=rosier-assets-<ACCOUNT_ID>

# Application
ENVIRONMENT=production
DEBUG=false

# Security
JWT_SECRET_KEY=<GENERATE_SECURE_KEY>
SECRET_KEY=<GENERATE_SECURE_KEY>

# Monitoring
SENTRY_DSN=<OPTIONAL>
LOG_LEVEL=info

# API Configuration
API_HOST=0.0.0.0
API_PORT=8000
CORS_ORIGINS=["http://localhost:3000","https://yourdomain.com"]
```

### 4. Deploy the Application

```bash
# On the EC2 instance:
cd /app

# Clone the repository
git clone <YOUR_REPO_URL> .

# Copy the .env file
# (or configure using the values from deployment output)

# Build and start the application
docker-compose -f infra/docker/docker-compose-prod.yml up -d

# Check status
docker-compose logs -f api

# Run migrations
docker-compose -f infra/docker/docker-compose-prod.yml exec api alembic upgrade head

# Test the API
curl http://localhost:8000/health
curl http://localhost:8000/docs  # Swagger UI
```

### 5. Verify API is Live

From your local machine:

```bash
curl http://<PUBLIC_IP>:8000/health
curl http://<PUBLIC_IP>:8000/docs
```

You should see:
- Health endpoint returns `{"status":"ok"}`
- Swagger UI loads at `http://<PUBLIC_IP>:8000/docs`

---

## Connecting Services

### EC2 → RDS

The EC2 instance can reach RDS through the rosier-rds-sg security group, which only allows connections from the rosier-ec2-sg security group.

**Connection String**:
```
postgresql+asyncpg://rosier_admin:PASSWORD@<RDS_ENDPOINT>:5432/rosier
```

### EC2 → Redis

The EC2 instance can reach Redis through the rosier-redis-sg security group, which only allows connections from the rosier-ec2-sg security group.

**Connection String**:
```
redis://<REDIS_ENDPOINT>:6379/0
```

---

## Troubleshooting

### RDS Connection Timeout

If you get "connection timeout" when connecting to RDS:

1. **Wait 5-10 minutes** after deployment for RDS to fully initialize
2. **Check RDS status** in the AWS Console:
   - Go to: https://us-east-1.console.aws.amazon.com/rds/
   - Click on "rosier-db"
   - Check "Status" is "Available"
   - Check "Endpoint" has a value

3. **Test from EC2**:
   ```bash
   # On EC2 instance:
   psql -h <RDS_ENDPOINT> -U rosier_admin -d rosier
   # Enter password when prompted
   ```

### Redis Connection Error

Similar to RDS:

1. **Wait 5-10 minutes** after deployment
2. **Check Redis status** in the AWS Console:
   - Go to: https://us-east-1.console.aws.amazon.com/elasticache/
   - Click on "rosier-redis"
   - Check "Status" is "Available"

3. **Test from EC2**:
   ```bash
   # On EC2 instance:
   redis-cli -h <REDIS_ENDPOINT> ping
   # Should return: PONG
   ```

### Docker Compose Issues

```bash
# Check logs
docker-compose logs -f

# Restart containers
docker-compose down
docker-compose up -d

# Full rebuild
docker-compose build --no-cache
docker-compose up -d
```

### API Not Responding

```bash
# Check if container is running
docker ps

# Check container logs
docker logs rosier-api

# Check if port 8000 is listening
netstat -tlnp | grep 8000

# From EC2, test local connection
curl http://localhost:8000/health
```

---

## Security Considerations

### Current Setup (MVP)

The current setup uses:
- Default security groups allowing SSH from anywhere (0.0.0.0/0)
- RDS/Redis accessible only from EC2
- No SSL/TLS yet

### Production Upgrades Needed

Before going to production with real user data:

1. **Restrict SSH access**
   ```bash
   # Update EC2 SG to only allow SSH from your IP
   aws ec2 authorize-security-group-ingress \
     --group-id <EC2_SG> \
     --protocol tcp \
     --port 22 \
     --cidr <YOUR_IP>/32 \
     --region us-east-1

   # Remove rule allowing 0.0.0.0/0 on port 22
   ```

2. **Enable RDS encryption** (new instance, can't enable after creation)
3. **Use AWS Secrets Manager** for database credentials
4. **Enable VPC Flow Logs** for network monitoring
5. **Set up SSL/TLS** for API (using ACM certificate)
6. **Enable CloudWatch** monitoring and alarms

---

## Cost Breakdown

### Monthly Cost (Year 1 - Free Tier)

| Service | Cost |
|---------|------|
| EC2 t2.micro | $0 (750 hrs/month Free Tier) |
| RDS db.t3.micro | $0 (750 hrs + 20GB Free Tier) |
| ElastiCache cache.t3.micro | $0 (750 hrs Free Tier) |
| S3 (first 5GB) | $0 |
| Data transfer | $0 (< 1GB/month) |
| **Total** | **$0/month** |

### After Free Tier Expires (Year 2+)

| Service | Estimated Cost |
|---------|-----------------|
| EC2 t2.micro overages | ~$8/month |
| RDS db.t3.micro overages | ~$24/month |
| ElastiCache overages | ~$17/month |
| S3 & data transfer | ~$2/month |
| **Total** | **~$50/month** |

---

## Scaling Beyond MVP

When you reach $10K MRR or need more performance:

### Stage 1: Add HA Database (3-6 months)
```bash
# Upgrade RDS to db.t3.small with Multi-AZ
# Cost: +$40-50/month
```

### Stage 2: Add Read Replicas (6-12 months)
```bash
# For heavy read workloads
# Cost: +$25-50/month per replica
```

### Stage 3: Switch to ECS Fargate (12+ months)
```bash
# Multiple API instances behind load balancer
# Cost: +$150-300/month
```

---

## Accessing AWS Services

### RDS Console
https://us-east-1.console.aws.amazon.com/rds/

### ElastiCache Console
https://us-east-1.console.aws.amazon.com/elasticache/

### EC2 Console
https://us-east-1.console.aws.amazon.com/ec2/

### CloudWatch Logs
https://us-east-1.console.aws.amazon.com/cloudwatch/

### CloudShell
https://us-east-1.console.aws.amazon.com/cloudshell/home

---

## Support

### Getting Help

- **AWS Documentation**: https://docs.aws.amazon.com
- **Rosier Logs**: `docker logs rosier-api` on EC2 instance
- **Database Logs**: RDS console → Logs & events tab
- **API Endpoints**: `curl http://<IP>:8000/docs` for Swagger UI

### Monitoring

Check system health with these commands on EC2:

```bash
# CPU and memory usage
docker stats

# Database connections
psql -h <RDS_ENDPOINT> -U rosier_admin -d rosier -c "SELECT count(*) FROM pg_stat_activity;"

# Redis info
redis-cli -h <REDIS_ENDPOINT> INFO

# Disk usage
df -h
```

---

## Next Steps

1. **Run the deployment script** in CloudShell
2. **Save all deployment information** (credentials, endpoints, IPs)
3. **Wait 10-15 minutes** for RDS and Redis to initialize
4. **SSH to EC2** and configure the application
5. **Deploy the application** using docker-compose
6. **Test the API** from your local machine
7. **Update DNS** (if using a custom domain)

---

**Deployment created**: April 1, 2026
**Region**: us-east-1
**Status**: Ready for deployment

Good luck! The API should be live at `http://<PUBLIC_IP>:8000/docs` within 30 minutes.
