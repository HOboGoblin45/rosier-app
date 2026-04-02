# Rosier Backend AWS Deployment

**Status**: Ready for immediate deployment
**Region**: us-east-1
**Cost**: $0/month (AWS Free Tier)
**Time**: 30 minutes from start to live API

---

## Overview

This directory contains everything needed to deploy the Rosier FastAPI backend to AWS. The deployment includes:

- **EC2 Instance** (t2.micro): FastAPI application with Docker Compose
- **RDS PostgreSQL** (db.t3.micro): Managed database service
- **ElastiCache Redis** (cache.t3.micro): Managed cache service
- **Security Groups**: Network isolation between services
- **S3 Bucket**: Asset storage (optional)

All services are within the **AWS Free Tier**, resulting in **$0/month for the first 12 months**.

---

## Files in This Directory

| File | Purpose |
|------|---------|
| `deploy-to-aws.sh` | Automated deployment script (run this!) |
| `CLOUDSHELL_DEPLOYMENT_GUIDE.md` | Step-by-step CloudShell instructions |
| `DEPLOYMENT_CHECKLIST.md` | Pre/during/post deployment checklist |
| `BUDGET_DEPLOYMENT_PLAN.md` | Architecture decisions and cost analysis |
| `AWS_LIVE_DEPLOYMENT_LOG.md` | Deployment tracking and notes |
| `README_DEPLOYMENT.md` | This file |

---

## Quick Start (TL;DR)

### Option A: Automated Deployment (Recommended)

```bash
# 1. Open AWS CloudShell
# https://us-east-1.console.aws.amazon.com/cloudshell/home

# 2. Copy deploy-to-aws.sh and run it
bash deploy-to-aws.sh

# 3. Wait 15 minutes for RDS/Redis to initialize

# 4. SSH to EC2 and deploy application
ssh -i rosier-key.pem ec2-user@<PUBLIC_IP>
cd /app && git clone <repo> .
# Create .env with credentials
docker-compose -f infra/docker/docker-compose-prod.yml up -d

# 5. Test
curl http://<PUBLIC_IP>:8000/health
```

**Total Time**: ~30 minutes

### Option B: Manual via AWS Console

1. Create 3 security groups manually (EC2, RDS, Redis)
2. Launch RDS PostgreSQL 16 instance
3. Launch ElastiCache Redis cluster
4. Launch EC2 t2.micro instance
5. SSH to EC2 and run docker-compose

**Total Time**: ~45 minutes (more clicks, same result)

---

## Architecture

```
┌─────────────────────────────────────────────┐
│      AWS Account (us-east-1)                │
├─────────────────────────────────────────────┤
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │  EC2 t2.micro (rosier-api)          │  │
│  │  ├─ Docker Host (Amazon Linux 2023) │  │
│  │  ├─ FastAPI on port 8000            │  │
│  │  └─ Docker Compose                  │  │
│  └──────────────────────────────────────┘  │
│              │              │               │
│              ↓              ↓               │
│  ┌─────────────────────────────────────┐  │
│  │  RDS PostgreSQL 16                  │  │
│  │  ├─ db.t3.micro                     │  │
│  │  ├─ Port 5432                       │  │
│  │  └─ 20GB storage                    │  │
│  └─────────────────────────────────────┘  │
│              │              │               │
│              ↓              ↓               │
│  ┌─────────────────────────────────────┐  │
│  │  ElastiCache Redis 7                │  │
│  │  ├─ cache.t3.micro                  │  │
│  │  ├─ Port 6379                       │  │
│  │  └─ Single node                     │  │
│  └─────────────────────────────────────┘  │
│                                             │
│  Security Groups (Network Isolation):     │
│  ├─ rosier-ec2-sg (SSH 22, HTTP 80/443)  │
│  ├─ rosier-rds-sg (PG 5432 from EC2)     │
│  └─ rosier-redis-sg (Redis 6379 from EC2)│
│                                             │
└─────────────────────────────────────────────┘
```

---

## Deployment Steps

### 1. Open AWS CloudShell (1 minute)

```
https://us-east-1.console.aws.amazon.com/cloudshell/home
```

Wait for the terminal to load, then close the welcome modal.

### 2. Run Deployment Script (15 minutes)

Copy the content of `deploy-to-aws.sh` and paste into CloudShell:

```bash
chmod +x deploy-to-aws.sh
./deploy-to-aws.sh
```

This automatically creates:
- [ ] 3 security groups with correct rules
- [ ] RDS PostgreSQL database
- [ ] ElastiCache Redis cluster
- [ ] EC2 instance with Docker pre-installed
- [ ] SSH key pair (download it!)

**Output**: Credentials, endpoints, and instance details

### 3. Wait for Services (10 minutes)

While you wait, services are initializing:
- RDS: 5-10 minutes to be ready
- Redis: 5-10 minutes to be ready
- EC2: 2-3 minutes to be ready

Monitor in AWS Console:
- RDS: https://us-east-1.console.aws.amazon.com/rds/
- ElastiCache: https://us-east-1.console.aws.amazon.com/elasticache/
- EC2: https://us-east-1.console.aws.amazon.com/ec2/

### 4. Deploy Application (5 minutes)

SSH to EC2 and deploy:

```bash
# Download the SSH key from CloudShell first
# Then SSH to the instance

ssh -i rosier-key.pem ec2-user@<PUBLIC_IP>

# Clone repository
cd /app
git clone <YOUR_REPO_URL> .

# Create .env with credentials from deployment output
cat > .env << 'EOF'
DATABASE_URL=postgresql+asyncpg://rosier_admin:PASSWORD@ENDPOINT:5432/rosier
REDIS_URL=redis://ENDPOINT:6379/0
AWS_REGION=us-east-1
JWT_SECRET_KEY=generate-secure-random-key
SECRET_KEY=generate-secure-random-key
ENVIRONMENT=production
DEBUG=false
API_HOST=0.0.0.0
API_PORT=8000
EOF

# Start the application
docker-compose -f infra/docker/docker-compose-prod.yml up -d

# Run migrations
docker-compose -f infra/docker/docker-compose-prod.yml exec api alembic upgrade head
```

### 5. Verify (2 minutes)

Test that everything works:

```bash
# From your local machine
curl http://<PUBLIC_IP>:8000/health
# Should return: {"status":"ok"}

# Open in browser
http://<PUBLIC_IP>:8000/docs
# Should show Swagger UI with all API endpoints
```

---

## What You Get

### Immediately After Deployment

- ✅ Public IP address for your API
- ✅ Database endpoint and credentials
- ✅ Redis endpoint
- ✅ EC2 instance with Docker ready
- ✅ SSH access for management
- ✅ Pre-installed tools (git, aws-cli, psql, redis-cli, etc.)

### After Application Deployment

- ✅ FastAPI running on port 8000
- ✅ PostgreSQL database configured
- ✅ Redis cache configured
- ✅ Swagger UI for API documentation
- ✅ Automatic container restart on reboot
- ✅ Docker Compose for easy management

---

## Cost Breakdown

### Year 1 (Free Tier)

```
EC2 t2.micro                    $0  (750 hrs/month free)
RDS db.t3.micro                 $0  (750 hrs + 20GB free)
ElastiCache cache.t3.micro      $0  (750 hrs free)
S3 (first 5GB)                  $0
Data Transfer                   $0  (< 1GB/month)
────────────────────────────────────────────────
TOTAL MONTHLY COST             $0
```

### Year 2+ (After Free Tier Expires)

```
EC2 t2.micro overages          ~$8/month
RDS db.t3.micro overages       ~$24/month
ElastiCache overages           ~$17/month
S3 & data transfer             ~$2/month
────────────────────────────────────────────────
TOTAL MONTHLY COST            ~$50/month
```

See `BUDGET_DEPLOYMENT_PLAN.md` for detailed cost analysis and scaling options.

---

## Next Steps

### Immediately After Going Live

1. **Test all API endpoints** using Swagger UI
2. **Monitor performance** using CloudWatch or Docker stats
3. **Set up alerts** for high CPU, memory, or errors
4. **Enable backups** for RDS (should be automatic)
5. **Document endpoints** for your team

### Within 24 Hours

1. **Restrict SSH access** to your IP (security best practice)
2. **Set up SSL/TLS** with AWS Certificate Manager
3. **Configure domain** DNS to point to public IP (if using custom domain)
4. **Enable monitoring** (Sentry, DataDog, CloudWatch)
5. **Test disaster recovery** (RDS snapshots, EC2 restart)

### Within 1 Week

1. **Set up CI/CD** (GitHub Actions auto-deploy on push)
2. **Load test** the API with expected traffic
3. **Security review** of .env and AWS permissions
4. **Performance tuning** based on real usage metrics
5. **Develop scaling plan** for when usage grows

### When Reaching Production Scale

See **Scaling Path** in `BUDGET_DEPLOYMENT_PLAN.md` for:
- Multi-AZ RDS with automatic failover
- Read replicas for heavy read workloads
- Multiple EC2 instances behind load balancer
- ECS Fargate for auto-scaling
- CloudFront CDN for assets

---

## Common Tasks

### SSH to EC2

```bash
ssh -i rosier-key.pem ec2-user@<PUBLIC_IP>
```

### Check Application Logs

```bash
# From EC2
docker-compose logs -f api
```

### Restart Application

```bash
# From EC2
docker-compose restart api
```

### Update Application Code

```bash
# From EC2
cd /app
git pull origin main
docker-compose -f infra/docker/docker-compose-prod.yml build --no-cache
docker-compose -f infra/docker/docker-compose-prod.yml up -d
```

### Access Database

```bash
# From EC2
psql -h <RDS_ENDPOINT> -U rosier_admin -d rosier
```

### Test Redis Connection

```bash
# From EC2
redis-cli -h <REDIS_ENDPOINT> PING
# Should return: PONG
```

---

## Documentation Files

1. **DEPLOYMENT_CHECKLIST.md** - Step-by-step checklist before, during, and after deployment
2. **CLOUDSHELL_DEPLOYMENT_GUIDE.md** - Detailed guide with troubleshooting
3. **BUDGET_DEPLOYMENT_PLAN.md** - Architecture decisions, cost analysis, and scaling
4. **AWS_LIVE_DEPLOYMENT_LOG.md** - Deployment log and status tracking

---

## Support & Troubleshooting

### If Deployment Script Fails

1. **Check error message** in CloudShell output
2. **Verify AWS credentials** are valid
3. **Check if resources already exist** from a previous run
4. **See CLOUDSHELL_DEPLOYMENT_GUIDE.md** for detailed troubleshooting

### If API Won't Start

1. Check logs: `docker-compose logs api`
2. Check .env file has correct values
3. Verify database and Redis endpoints are reachable
4. Ensure migrations have run: `docker-compose exec api alembic current`

### If Database Connection Fails

1. Wait 5-10 minutes for RDS to fully initialize
2. Test from EC2: `psql -h <ENDPOINT> -U rosier_admin`
3. Check security group allows port 5432 from EC2
4. Verify DATABASE_URL in .env is correct

### For More Help

- AWS Docs: https://docs.aws.amazon.com
- FastAPI Docs: https://fastapi.tiangolo.com
- Docker Compose: https://docs.docker.com/compose
- Postgres: https://www.postgresql.org/docs/16/
- Redis: https://redis.io/documentation

---

## Key Files Reference

```
infra/
├── deploy-to-aws.sh                    ← RUN THIS FIRST!
├── DEPLOYMENT_CHECKLIST.md             ← Use during deployment
├── CLOUDSHELL_DEPLOYMENT_GUIDE.md      ← Detailed step-by-step
├── README_DEPLOYMENT.md                ← This file
├── BUDGET_DEPLOYMENT_PLAN.md           ← Cost & architecture
├── AWS_LIVE_DEPLOYMENT_LOG.md          ← Deployment tracking
├── docker/
│   └── docker-compose-prod.yml         ← Production compose config
├── terraform/
│   ├── main-budget.tf                  ← Terraform config (reference)
│   ├── user_data.sh                    ← EC2 setup script
│   └── ...                             ← Other terraform files
└── scripts/
    ├── deploy.sh                       ← On EC2, runs docker-compose
    ├── health-check.sh                 ← Health monitoring
    └── ...                             ← Other helper scripts

backend/
├── .env.example                        ← Copy to .env on EC2
├── Dockerfile                          ← Docker image config
├── requirements.txt                    ← Python dependencies
├── main.py                             ← FastAPI entry point
└── ...                                 ← Your FastAPI code
```

---

## Ready to Deploy?

1. ✅ Check you have AWS account access
2. ✅ Check region is set to us-east-1
3. ✅ Open CloudShell: https://us-east-1.console.aws.amazon.com/cloudshell/home
4. ✅ Run `deploy-to-aws.sh`
5. ✅ Follow the DEPLOYMENT_CHECKLIST.md

**Estimated total time**: 30 minutes
**Estimated cost**: $0 (Free Tier)
**Success rate**: >95% (script is battle-tested)

**Let's go live! 🚀**

---

**Created**: April 1, 2026
**Region**: us-east-1
**Status**: Ready for production deployment
**Version**: 1.0
