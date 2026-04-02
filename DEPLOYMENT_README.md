# Rosier Backend - AWS Deployment Guide

**Status**: Ready to Deploy
**Date**: April 1, 2026
**Goal**: Get FastAPI backend live at `http://<PUBLIC_IP>:8000/docs`
**Time to Deploy**: 30-45 minutes

---

## Quick Start (TL;DR)

1. Open CloudShell: https://us-east-1.console.aws.amazon.com/cloudshell/home
2. Run deployment script (see `infra/DEPLOYMENT_COMMANDS.md`)
3. Wait 10-15 minutes for AWS services to initialize
4. SSH to EC2 instance
5. Deploy docker-compose application
6. Access API at `http://PUBLIC_IP:8000/docs`

---

## What Gets Deployed

### Infrastructure (Fully Automated)

- **VPC**: Default AWS VPC (us-east-1)
- **Security Groups**: 3 groups (EC2, RDS, Redis) with proper isolation
- **RDS PostgreSQL**: db.t3.micro, 20GB storage, FREE tier
- **ElastiCache Redis**: cache.t3.micro, single node, FREE tier
- **EC2 Instance**: t2.micro, Amazon Linux 2023, Docker pre-installed, FREE tier

### Application (Manual Deployment)

- Clone Rosier repository to EC2
- Configure `.env` with RDS and Redis endpoints
- Run `docker-compose up -d`
- Access via public IP on port 8000

### Cost

- **Year 1**: $0 (AWS Free Tier)
- **Year 2+**: ~$50/month (after free tier expires)

---

## Documentation Files

Read these in order for your deployment:

### 1. **DEPLOYMENT_COMMANDS.md** (10 min read)
   - All AWS CLI commands for deployment
   - Copy-paste ready
   - Step-by-step instructions

### 2. **AWS_DEPLOYMENT_STATUS.md** (Reference)
   - Current deployment progress
   - Resource IDs and endpoints
   - Troubleshooting guide
   - Cost breakdown

### 3. **infra/CLOUDSHELL_DEPLOYMENT_GUIDE.md** (Reference)
   - Detailed step-by-step
   - Screenshots and explanations
   - Post-deployment steps

### 4. **infra/START_HERE.md** (Quick reference)
   - 30-minute deployment overview
   - Key files and next steps

---

## Step-by-Step Deployment

### Phase 1: Open AWS Console (1 minute)

1. Go to AWS Console: https://console.aws.amazon.com
2. Verify region is `us-east-1`
3. Open CloudShell: https://us-east-1.console.aws.amazon.com/cloudshell/home

### Phase 2: Run Deployment Script (20 minutes)

In CloudShell, run the commands from `infra/DEPLOYMENT_COMMANDS.md`:

```bash
# Setup
REGION="us-east-1"
APP_NAME="rosier"
cd /tmp

# Get VPC
DEFAULT_VPC=$(aws ec2 describe-vpcs --region "$REGION" \
  --query 'Vpcs[?IsDefault==`true`].VpcId' --output text)

# Create security groups
# ... (see DEPLOYMENT_COMMANDS.md for full commands)

# Create RDS PostgreSQL
# ... (see DEPLOYMENT_COMMANDS.md)

# Create Redis
# ... (see DEPLOYMENT_COMMANDS.md)

# Create EC2 instance
# ... (see DEPLOYMENT_COMMANDS.md)
```

**Save the output** - it contains:
- Security group IDs
- RDS endpoint and password
- Redis endpoint
- EC2 public IP
- SSH key

### Phase 3: Wait for Services (10-15 minutes)

Monitor AWS Console:

1. **RDS Console**: Check status = "Available"
2. **ElastiCache Console**: Check status = "available"
3. **EC2 Console**: Check public IP is assigned

### Phase 4: SSH to EC2 (2 minutes)

```bash
# Download the SSH key from CloudShell output
# Save as: rosier-key.pem
chmod 400 rosier-key.pem

# SSH to instance
ssh -i rosier-key.pem ec2-user@PUBLIC_IP
```

### Phase 5: Deploy Application (10 minutes)

On the EC2 instance:

```bash
cd /app

# Clone the repository
git clone <YOUR_REPO_URL> .

# Create .env file with credentials from CloudShell output
cat > .env << 'EOF'
DATABASE_URL=postgresql+asyncpg://rosier_admin:PASSWORD@RDS_ENDPOINT:5432/rosier
REDIS_URL=redis://REDIS_ENDPOINT:6379/0
AWS_REGION=us-east-1
ENVIRONMENT=production
DEBUG=false
JWT_SECRET_KEY=<GENERATE_SECURE_KEY>
SECRET_KEY=<GENERATE_SECURE_KEY>
API_HOST=0.0.0.0
API_PORT=8000
EOF

# Start application
docker-compose -f infra/docker/docker-compose-prod.yml up -d

# Run migrations
docker-compose -f infra/docker/docker-compose-prod.yml exec api alembic upgrade head

# Check logs
docker-compose logs -f api
```

### Phase 6: Test API (2 minutes)

```bash
# From your local machine
curl http://PUBLIC_IP:8000/health

# Should return: {"status":"ok"}

# Open in browser
# http://PUBLIC_IP:8000/docs
```

You should see Swagger UI with all API endpoints!

---

## Key Information to Save

### From CloudShell Output

1. **Security Groups**
   - EC2 SG: sg-...
   - RDS SG: sg-...
   - Redis SG: sg-...

2. **RDS Credentials**
   - Endpoint: rosier-db.xxxxxxxxxxxxx.us-east-1.rds.amazonaws.com
   - Username: rosier_admin
   - Password: (random string - SAVE THIS!)
   - Database: rosier

3. **Redis Endpoint**
   - Endpoint: rosier-redis.xxxxxxxxxxxxx.ng.0001.cache.amazonaws.com:6379

4. **EC2 Details**
   - Instance ID: i-...
   - Public IP: xxx.xxx.xxx.xxx
   - Key Pair: rosier-key.pem (DOWNLOAD THIS!)

### Environment Variables for .env

```
DATABASE_URL=postgresql+asyncpg://rosier_admin:PASSWORD@RDS_ENDPOINT:5432/rosier
REDIS_URL=redis://REDIS_ENDPOINT:6379/0
AWS_REGION=us-east-1
API_HOST=0.0.0.0
API_PORT=8000
```

---

## Troubleshooting

### RDS Connection Timeout

**Symptom**: Can't connect to database after SSH

**Solution**:
1. Wait 10 minutes from deployment
2. Check RDS status in AWS Console
3. Verify RDS security group allows traffic from EC2

```bash
# Test from EC2
psql -h RDS_ENDPOINT -U rosier_admin -d rosier
```

### Redis Connection Error

**Symptom**: Redis connection refused

**Solution**:
1. Wait 10 minutes from deployment
2. Check ElastiCache console - should show "available"
3. Test from EC2:

```bash
redis-cli -h REDIS_ENDPOINT ping
# Should return: PONG
```

### API Container Won't Start

**Symptom**: `docker ps` shows no container running

**Solution**:
1. Check logs: `docker logs rosier-api`
2. Verify .env file has correct credentials
3. Check database connectivity from container

```bash
docker exec rosier-api \
  psql -h RDS_ENDPOINT -U rosier_admin -d rosier -c "SELECT 1"
```

### Can't SSH to EC2

**Symptom**: Connection timeout or "Permission denied"

**Solution**:
1. Wait 3-5 minutes after instance launch
2. Verify key permissions: `ls -la rosier-key.pem`
3. Check security group allows SSH (port 22)
4. Try with verbose: `ssh -vvv -i rosier-key.pem ec2-user@PUBLIC_IP`

---

## Monitoring & Maintenance

### Check Service Health

```bash
# From EC2
docker ps              # Check running containers
docker logs api        # View application logs
docker stats           # View resource usage

# Database
psql -h RDS_ENDPOINT -U rosier_admin -d rosier \
  -c "SELECT count(*) FROM pg_stat_activity"

# Redis
redis-cli -h REDIS_ENDPOINT INFO
```

### View AWS Metrics

- **RDS Console**: Monitor CPU, connections, storage
- **ElastiCache Console**: Monitor CPU, memory, connections
- **EC2 Console**: Monitor CPU, network, disk I/O
- **CloudWatch**: Set up alarms and dashboards

### Database Backups

RDS is configured with 7-day backup retention:
- Automated backups enabled
- Point-in-time recovery available
- No additional configuration needed

---

## Scaling Path

### Phase 1 (MVP - Now)
- Single EC2 t2.micro
- Single RDS db.t3.micro
- Single Redis cache.t3.micro
- Cost: $0 (Free Tier)

### Phase 2 (At $10K MRR)
- Keep EC2 same
- Upgrade RDS to db.t3.small
- Add read replicas for scale
- Cost: +$40-50/month

### Phase 3 (12+ Months)
- Switch to ECS Fargate for multiple instances
- Load balancer (ALB)
- RDS Multi-AZ
- Cost: +$150-300/month

---

## Security Notes

### Current Setup (MVP)
- SSH allowed from anywhere (0.0.0.0/0)
- RDS/Redis accessible only from EC2
- No encryption in transit (HTTP)
- No SSL/TLS for API

### Recommended for Production
1. Restrict SSH to your IP only
2. Enable RDS encryption
3. Use AWS Secrets Manager for credentials
4. Set up SSL/TLS certificate (AWS ACM)
5. Enable CloudWatch monitoring
6. Enable VPC Flow Logs

---

## Files Reference

```
rosier/
├── infra/
│   ├── START_HERE.md                 ← Read this first
│   ├── CLOUDSHELL_DEPLOYMENT_GUIDE.md ← Detailed steps
│   ├── DEPLOYMENT_COMMANDS.md         ← All commands
│   ├── AWS_DEPLOYMENT_STATUS.md       ← Progress tracker
│   ├── one_click_deploy.sh            ← Automated script
│   ├── deploy-to-aws.sh               ← Original script
│   └── docker/
│       └── docker-compose-prod.yml    ← Production config
├── backend/
│   ├── .env.example                   ← Example config
│   └── ...
└── DEPLOYMENT_README.md               ← This file
```

---

## Need Help?

1. **Deployment Issues**: Check `AWS_DEPLOYMENT_STATUS.md` troubleshooting section
2. **Command Questions**: See `DEPLOYMENT_COMMANDS.md` for all AWS CLI commands
3. **Post-Deployment**: Refer to `CLOUDSHELL_DEPLOYMENT_GUIDE.md`
4. **Quick Reference**: Print out `START_HERE.md`

---

## Success Criteria

Your deployment is successful when:

✅ RDS shows "Available" in AWS Console
✅ Redis shows "available" in AWS Console
✅ EC2 has a public IP assigned
✅ You can SSH to EC2 instance
✅ `docker ps` shows running containers
✅ `curl http://PUBLIC_IP:8000/health` returns `{"status":"ok"}`
✅ Swagger UI loads at `http://PUBLIC_IP:8000/docs`

---

## Next Steps After Deployment

1. **Test API endpoints** in Swagger UI
2. **Monitor logs** in CloudWatch
3. **Set up DNS** (if using custom domain)
4. **Configure CORS** for frontend
5. **Enable SSL/TLS** for production
6. **Set up alarms** for monitoring

---

## Support

For issues or questions:
1. Check CloudShell output for full deployment logs
2. Review AWS Console for resource status
3. Check application logs: `docker-compose logs api`
4. Refer to deployment documentation

---

**Deployment Version**: 1.0
**Date**: April 1, 2026
**Status**: READY TO DEPLOY
**Next Step**: Run DEPLOYMENT_COMMANDS.md in CloudShell

Good luck! You've got this!
