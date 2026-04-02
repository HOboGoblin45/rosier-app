# Rosier Backend AWS Deployment Checklist

**Target**: Get the FastAPI backend live at `http://<EC2_PUBLIC_IP>:8000/docs` on AWS
**Time**: 30 minutes total
**Cost**: Free (AWS Free Tier)
**Region**: us-east-1

---

## Pre-Deployment Checklist

- [x] AWS Account access (crescic)
- [x] Region: us-east-1 selected
- [x] Deployment script created: `/infra/deploy-to-aws.sh`
- [x] Documentation created: `/infra/CLOUDSHELL_DEPLOYMENT_GUIDE.md`
- [x] Docker Compose config ready: `/infra/docker/docker-compose-prod.yml`
- [x] Backend .env.example available: `/backend/.env.example`
- [x] User data script ready: `/infra/terraform/user_data.sh`

---

## Phase 1: Infrastructure Deployment (15 minutes)

### Step 1a: Open AWS CloudShell
- [ ] Navigate to: https://us-east-1.console.aws.amazon.com/cloudshell/home
- [ ] Wait for terminal to load (2-3 seconds)
- [ ] Close the "Welcome to AWS CloudShell" modal
- [ ] Verify prompt is showing: `~ $ `

### Step 1b: Run Deployment Script
- [ ] Copy entire content of `/infra/deploy-to-aws.sh`
- [ ] Paste into CloudShell terminal
- [ ] Press Enter to execute

### Step 1c: Monitor Deployment Progress
The script will output:

**First (should be instant)**:
- [ ] EC2 Security Group created
- [ ] RDS Security Group created
- [ ] Redis Security Group created
- [ ] Phase 1 Complete message

**Next (5-10 minutes, shows "pending")**:
- [ ] RDS instance creation initiated
- [ ] ElastiCache cluster creation initiated
- [ ] EC2 instance launched

**End Result**:
- [ ] Summary shows all resource IDs and endpoints
- [ ] Database password displayed
- [ ] Key pair file created: `rosier-key.pem`
- [ ] Deployment info saved to: `rosier-deployment-info.txt`

### Step 1d: Save Critical Information

Copy and save these from the deployment output:

**Security Groups**:
```
EC2 SG ID:    sg-xxxxxxxxxxxxx
RDS SG ID:    sg-xxxxxxxxxxxxx
Redis SG ID:  sg-xxxxxxxxxxxxx
```

**Database**:
```
DB Endpoint:  rosier-db.xxxxxxxxxxxxx.us-east-1.rds.amazonaws.com
DB Username:  rosier_admin
DB Password:  [AUTO-GENERATED - SAVE THIS]
```

**Redis**:
```
Redis Endpoint: rosier-redis.xxxxxxxxxxxxx.ng.0001.cache.amazonaws.com
Redis Port:    6379
```

**EC2 Instance**:
```
Instance ID:   i-xxxxxxxxxxxxx
Public IP:     203.0.113.xxx
Key Pair:      rosier-key.pem
```

### Step 1e: Download SSH Key

- [ ] In CloudShell, run: `ls -la rosier-key.pem`
- [ ] Verify file size is > 1000 bytes
- [ ] Download file to your local machine (use browser's download feature or `scp`)
- [ ] Set permissions: `chmod 400 rosier-key.pem`

---

## Phase 2: Wait for Services (10 minutes)

### Step 2a: Verify RDS is Ready

While waiting, check RDS status in AWS Console:
- [ ] Navigate to: https://us-east-1.console.aws.amazon.com/rds/
- [ ] Find "rosier-db" instance
- [ ] Check Status shows "Available" (not "Creating")
- [ ] Note down Endpoint URL

### Step 2b: Verify Redis is Ready

- [ ] Navigate to: https://us-east-1.console.aws.amazon.com/elasticache/
- [ ] Find "rosier-redis" cluster
- [ ] Check Status shows "Available" (not "Creating")
- [ ] Note down Endpoint address

### Step 2c: Verify EC2 is Ready

- [ ] Navigate to: https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#Instances:
- [ ] Find "rosier-api" instance
- [ ] Check State is "Running" (green)
- [ ] Check Status Checks: 2/2 passed (may take 2-3 minutes)
- [ ] Note down Public IPv4 address

---

## Phase 3: Deploy Application (5-10 minutes)

### Step 3a: SSH into EC2 Instance

From your local machine:

```bash
# Navigate to where you saved the key
cd ~/Downloads  # or wherever you saved rosier-key.pem

# SSH to EC2
ssh -i rosier-key.pem ec2-user@<PUBLIC_IP>
# Replace <PUBLIC_IP> with the actual public IP from deployment output
# Example: ssh -i rosier-key.pem ec2-user@203.0.113.25
```

- [ ] You should see the Amazon Linux prompt
- [ ] Run: `docker --version` to verify Docker is installed
- [ ] Run: `docker-compose --version` to verify Docker Compose is installed

### Step 3b: Clone Repository

On the EC2 instance:

```bash
# Clone the repository
git clone <YOUR_REPO_URL> /app
cd /app

# Or if already in /app:
git clone <YOUR_REPO_URL> .
```

- [ ] Verify repository files are present
- [ ] Check: `ls -la infra/docker/docker-compose-prod.yml`

### Step 3c: Configure Environment Variables

Create `/app/.env` file with credentials from deployment output:

```bash
# Edit the file
nano /app/.env

# Or create directly
cat > /app/.env << 'EOF'
# Database
DATABASE_URL=postgresql+asyncpg://rosier_admin:<DB_PASSWORD>@<RDS_ENDPOINT>:5432/rosier
POSTGRES_USER=rosier_admin
POSTGRES_PASSWORD=<DB_PASSWORD>
POSTGRES_DB=rosier

# Redis
REDIS_URL=redis://<REDIS_ENDPOINT>:6379/0

# AWS (optional for S3 uploads)
AWS_REGION=us-east-1
# AWS_ACCESS_KEY_ID=xxxx
# AWS_SECRET_ACCESS_KEY=xxxx
# S3_BUCKET=rosier-assets-xxxx

# Application
ENVIRONMENT=production
DEBUG=false

# Security (generate random strings)
JWT_SECRET_KEY=$(openssl rand -base64 32)
SECRET_KEY=$(openssl rand -base64 32)

# Monitoring
SENTRY_DSN=
LOG_LEVEL=info

# API Configuration
API_HOST=0.0.0.0
API_PORT=8000
CORS_ORIGINS=["http://localhost:3000"]
EOF
```

- [ ] `.env` file created in `/app` directory
- [ ] File contains DATABASE_URL pointing to RDS_ENDPOINT
- [ ] File contains REDIS_URL pointing to REDIS_ENDPOINT
- [ ] Verify: `cat /app/.env | head -5`

### Step 3d: Start Docker Containers

```bash
cd /app

# Start the application
docker-compose -f infra/docker/docker-compose-prod.yml up -d

# Check status
docker-compose ps
```

- [ ] API container is running (`rosier-api` status is "Up")
- [ ] Nginx container is running (if enabled)
- [ ] No errors in output

### Step 3e: Check Logs

```bash
# View real-time logs
docker-compose logs -f api

# Wait for output like:
# "Application startup complete"
# "Uvicorn running on 0.0.0.0:8000"
```

- [ ] No ERROR messages
- [ ] See "Uvicorn running on 0.0.0.0:8000" or similar

### Step 3f: Run Database Migrations

```bash
# Run migrations
docker-compose -f infra/docker/docker-compose-prod.yml exec api alembic upgrade head

# Check result
docker-compose logs api | tail -20
```

- [ ] Migrations complete without errors
- [ ] No "ERROR" messages in logs

---

## Phase 4: Verification (2-5 minutes)

### Step 4a: Test API Health Endpoint

From EC2 or your local machine:

```bash
# Test local connection (from EC2)
curl http://localhost:8000/health

# Test remote connection (from your machine)
curl http://<PUBLIC_IP>:8000/health
```

Expected response:
```json
{"status":"ok"}
```

- [ ] Health endpoint returns 200 OK
- [ ] Response body shows `{"status":"ok"}` or similar

### Step 4b: Test Swagger UI

Open in browser:
```
http://<PUBLIC_IP>:8000/docs
```

- [ ] Swagger UI loads without errors
- [ ] Can see all API endpoints listed
- [ ] "Try it out" button is available on endpoints

### Step 4c: Test Sample Endpoint

Try a simple GET endpoint from Swagger UI:

- [ ] Click "Try it out" on any endpoint (e.g., `/health`)
- [ ] Click "Execute"
- [ ] See response code 200
- [ ] See response body

### Step 4d: Verify Services are Connected

```bash
# From EC2, test database connection
docker-compose -f infra/docker/docker-compose-prod.yml exec api \
  psql -h <RDS_ENDPOINT> -U rosier_admin -d rosier -c "SELECT 1;"

# Test Redis connection
docker-compose -f infra/docker/docker-compose-prod.yml exec api \
  redis-cli -h <REDIS_ENDPOINT> PING
```

- [ ] Database returns: "1"
- [ ] Redis returns: "PONG"

---

## Post-Deployment Checklist

### Monitoring

- [ ] Set up CloudWatch alarms for:
  - [ ] High CPU usage on EC2
  - [ ] High memory usage
  - [ ] RDS storage usage
  - [ ] API errors

### Logging

- [ ] Check CloudWatch Logs:
  - Navigate to: https://us-east-1.console.aws.amazon.com/cloudwatch/
  - Look for log groups: `/rosier/api`, `/rosier/rds`

### Backup

- [ ] Verify RDS automated backups are enabled (should be default)
- [ ] Test database backup: https://us-east-1.console.aws.amazon.com/rds/

### DNS (if applicable)

- [ ] Update DNS records to point to `<PUBLIC_IP>`
- [ ] Test: `nslookup yourdomain.com`

### Documentation

- [ ] Share endpoints and credentials with team
- [ ] Update project README with:
  - API endpoint: `http://<PUBLIC_IP>:8000`
  - Docs: `http://<PUBLIC_IP>:8000/docs`
  - SSH: `ssh -i rosier-key.pem ec2-user@<PUBLIC_IP>`

---

## Troubleshooting

### Issue: "Connection refused" when testing API

**Solution**:
1. Check EC2 status: https://us-east-1.console.aws.amazon.com/ec2/
2. SSH into instance and check: `docker ps`
3. If container not running: `docker-compose up -d`
4. Check logs: `docker-compose logs api`
5. Ensure security group allows port 8000: https://us-east-1.console.aws.amazon.com/ec2/#SecurityGroups:

### Issue: "Cannot connect to database"

**Solution**:
1. Wait 5-10 minutes for RDS to fully initialize
2. Check RDS status: https://us-east-1.console.aws.amazon.com/rds/
3. Test from EC2: `psql -h <RDS_ENDPOINT> -U rosier_admin`
4. Check .env has correct DATABASE_URL
5. Check RDS security group allows port 5432 from EC2 SG

### Issue: "Cannot connect to Redis"

**Solution**:
1. Wait 5-10 minutes for ElastiCache to fully initialize
2. Check Redis status: https://us-east-1.console.aws.amazon.com/elasticache/
3. Test from EC2: `redis-cli -h <REDIS_ENDPOINT> PING`
4. Check .env has correct REDIS_URL
5. Check Redis security group allows port 6379 from EC2 SG

### Issue: Database migration fails

**Solution**:
1. Check database connectivity first
2. Look at specific error in logs: `docker-compose logs api`
3. May need to review migration files in `backend/alembic/versions/`
4. Roll back and retry: `docker-compose down && docker-compose up -d`

---

## Success Criteria

- [x] Security groups created with correct rules
- [x] RDS PostgreSQL instance running
- [x] ElastiCache Redis instance running
- [x] EC2 instance running with Docker installed
- [x] Docker containers up and healthy
- [x] Database migrations completed
- [x] API health endpoint responds (200 OK)
- [x] Swagger UI accessible and loads
- [x] Sample endpoint works

**Status**: Ready for production use
**Estimated Cost**: $0/month (Year 1, Free Tier)

---

## Next Steps (After This Checklist)

1. **Set up CI/CD**: GitHub Actions to auto-deploy on push
2. **Configure SSL**: Use AWS Certificate Manager for HTTPS
3. **Set up monitoring**: Sentry, DataDog, or CloudWatch dashboards
4. **Performance testing**: Load test with artillery or JMeter
5. **Security review**: Run AWS Security Hub scan
6. **Disaster recovery**: Set up RDS snapshots and backup strategy
7. **Scaling plan**: Plan for when you reach usage limits

---

## Getting Help

- **AWS Documentation**: https://docs.aws.amazon.com
- **Deployment Guide**: See `CLOUDSHELL_DEPLOYMENT_GUIDE.md`
- **Docker Compose Docs**: https://docs.docker.com/compose/
- **FastAPI Docs**: https://fastapi.tiangolo.com/
- **API Logs**: `docker-compose logs api` on EC2

---

**Deployment Date**: April 1, 2026
**Estimated Time**: 30 minutes
**Status**: Ready to deploy
**All systems go!**
