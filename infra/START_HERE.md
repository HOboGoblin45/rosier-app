# Rosier Backend AWS Deployment - START HERE

**Status**: READY TO DEPLOY NOW
**Time**: 30 minutes
**Cost**: FREE (AWS Free Tier)
**Goal**: Get FastAPI backend live at `http://<IP>:8000/docs`

---

## Your 30-Minute Deployment Plan

### The TL;DR Version

1. Open CloudShell: https://us-east-1.console.aws.amazon.com/cloudshell/home
2. Copy and run `deploy-to-aws.sh`
3. Wait 10 minutes
4. SSH to EC2 and deploy docker-compose
5. Test the API

**That's it. You're done.**

---

## Which Document Should I Read?

### I'm in a hurry (2 min read)
→ **Read**: `QUICK_REFERENCE.md`
- One page, has all commands
- Print it out
- Follow the steps

### I want step-by-step instructions (10 min read)
→ **Read**: `README_DEPLOYMENT.md`
- Overview and quick start
- Architecture diagram
- Cost breakdown
- Next steps

### I want detailed, hand-holding instructions (20 min read)
→ **Read**: `CLOUDSHELL_DEPLOYMENT_GUIDE.md`
- Every step explained
- Screenshots descriptions
- Troubleshooting section
- Detailed explanations

### I want a checklist I can tick off (15 min read)
→ **Read**: `DEPLOYMENT_CHECKLIST.md`
- Pre-deployment checklist
- During deployment checklist
- Post-deployment checklist
- Success criteria

### I want to understand the architecture and costs (30 min read)
→ **Read**: `BUDGET_DEPLOYMENT_PLAN.md`
- Why we chose this architecture
- Cost breakdown (free Year 1!)
- Scaling path for the future
- Alternative approaches

---

## Files You Need to Know About

### Most Important
```
deploy-to-aws.sh              ← THE MAIN SCRIPT - RUN THIS!
QUICK_REFERENCE.md            ← Print this
README_DEPLOYMENT.md          ← Start here for overview
```

### For Detailed Guidance
```
CLOUDSHELL_DEPLOYMENT_GUIDE.md  ← Step-by-step
DEPLOYMENT_CHECKLIST.md         ← Tick off each step
```

### For Understanding
```
BUDGET_DEPLOYMENT_PLAN.md       ← Why this architecture?
README.md                       ← Infrastructure repo readme
```

---

## The Actual Deployment (Copy-Paste This)

### Step 1: Open CloudShell (1 minute)
```
https://us-east-1.console.aws.amazon.com/cloudshell/home
```
Wait for the terminal to load. Close the welcome modal.

### Step 2: Get the Script (1 minute)

**Option A**: Copy from the file
- Open the `deploy-to-aws.sh` file in the infra/ directory
- Copy all contents
- Paste into CloudShell

**Option B**: Download via wget (if available)
```bash
cd /tmp
wget https://raw.githubusercontent.com/<YOUR_REPO>/main/infra/deploy-to-aws.sh
chmod +x deploy-to-aws.sh
```

### Step 3: Run the Script (15 minutes)
```bash
./deploy-to-aws.sh
```

**Watch the output!** You'll see:
- Security groups being created ✓ (instant)
- RDS database being created (2-3 min)
- Redis cluster being created (2-3 min)
- EC2 instance being launched (2-3 min)
- Final summary with all credentials

### Step 4: Save the Output (1 minute)

Copy this from the output and save somewhere safe:
```
EC2 Public IP:     203.0.113.xxx
RDS Endpoint:      rosier-db.xxxxxxxxxxxxx.us-east-1.rds.amazonaws.com
Redis Endpoint:    rosier-redis.xxxxxxxxxxxxx.ng.0001.cache.amazonaws.com
Database Password: [LONG_STRING_HERE]
```

Also download the SSH key:
```bash
# In CloudShell, the key is saved as: rosier-key.pem
# Download it to your local machine (use browser downloads)
```

### Step 5: Wait 10 Minutes

Services are initializing. Grab coffee ☕

Monitor progress:
- RDS Console: https://us-east-1.console.aws.amazon.com/rds/
- Redis Console: https://us-east-1.console.aws.amazon.com/elasticache/
- EC2 Console: https://us-east-1.console.aws.amazon.com/ec2/

Look for Status = "Available" or "Running"

### Step 6: Deploy Application (5 minutes)

From your local machine:
```bash
# SSH to EC2 (replace <IP> with public IP from step 4)
ssh -i rosier-key.pem ec2-user@203.0.113.xxx

# Once connected to EC2:
cd /app

# Clone your repository
git clone <YOUR_REPO_URL> .

# Create environment file with credentials from step 4
cat > .env << 'EOF'
DATABASE_URL=postgresql+asyncpg://rosier_admin:<PASSWORD>@<RDS_ENDPOINT>:5432/rosier
REDIS_URL=redis://<REDIS_ENDPOINT>:6379/0
AWS_REGION=us-east-1
ENVIRONMENT=production
DEBUG=false
JWT_SECRET_KEY=please-change-me
SECRET_KEY=please-change-me
API_HOST=0.0.0.0
API_PORT=8000
EOF

# Start the application
docker-compose -f infra/docker/docker-compose-prod.yml up -d

# Run database migrations
docker-compose -f infra/docker/docker-compose-prod.yml exec api alembic upgrade head
```

### Step 7: Test (2 minutes)

From your local machine:
```bash
# Test health endpoint
curl http://203.0.113.xxx:8000/health
# Should return: {"status":"ok"}
```

Open in browser:
```
http://203.0.113.xxx:8000/docs
```

You should see Swagger UI with all your API endpoints.

---

## Success! You're Done

Your API is now live! The URL is: `http://<PUBLIC_IP>:8000`

- Swagger UI: `http://<PUBLIC_IP>:8000/docs`
- Health Check: `http://<PUBLIC_IP>:8000/health`

---

## What Just Happened

### Infrastructure Created (Automatically)

**Security Groups** (network firewall rules):
- `rosier-ec2-sg` - Allows SSH, HTTP, HTTPS, and port 8000
- `rosier-rds-sg` - Allows database access from EC2 only
- `rosier-redis-sg` - Allows Redis access from EC2 only

**Database**:
- AWS RDS PostgreSQL 16
- Database name: `rosier`
- User: `rosier_admin`
- 20GB storage (Free Tier)

**Cache**:
- AWS ElastiCache Redis 7
- Single node (Free Tier)
- Port 6379

**Compute**:
- AWS EC2 t2.micro instance
- Amazon Linux 2023
- Docker pre-installed
- SSH key: `rosier-key.pem`
- 20GB storage

### Application Deployed (Manually)

**Docker Containers**:
- FastAPI application on port 8000
- Nginx reverse proxy (optional, in compose)

**Database**:
- Alembic migrations run automatically
- Connection pooling configured

**Cache**:
- Redis configured for session/cache storage

---

## Cost Breakdown

### Year 1: FREE
```
All services use AWS Free Tier benefits
Total: $0/month
```

### Year 2+: ~$50/month
```
After free tier expires (12 months of operation)
See BUDGET_DEPLOYMENT_PLAN.md for details
```

---

## Troubleshooting Quick Links

**CloudShell commands fail?**
→ Verify credentials: `aws sts get-caller-identity`

**Can't SSH to EC2?**
→ Wait 2 minutes for instance to fully start

**Database connection fails?**
→ Wait 5-10 minutes for RDS to initialize

**API won't start?**
→ Check logs: `docker-compose logs api`

**More detailed help?**
→ See `CLOUDSHELL_DEPLOYMENT_GUIDE.md` → Troubleshooting section

---

## After Deployment (Next 24 Hours)

1. **Monitor** the application using CloudWatch
2. **Test** all API endpoints from Swagger UI
3. **Verify** database connectivity
4. **Check** logs for any errors
5. **Configure** DNS (if using custom domain)

See `README_DEPLOYMENT.md` → "Next Steps" for the full list.

---

## Need More Help?

Read these in order:

1. **Quick overview?** → `README_DEPLOYMENT.md` (10 min)
2. **Detailed steps?** → `CLOUDSHELL_DEPLOYMENT_GUIDE.md` (20 min)
3. **Checklist?** → `DEPLOYMENT_CHECKLIST.md` (use while deploying)
4. **Architecture?** → `BUDGET_DEPLOYMENT_PLAN.md` (understand costs)
5. **One-page ref?** → `QUICK_REFERENCE.md` (print this)

---

## Summary

| What | When |
|------|------|
| **Read this file** | NOW (2 min) |
| **Read QUICK_REFERENCE.md** | Before deployment (2 min) |
| **Run deploy-to-aws.sh** | Within 5 minutes (15 min runtime) |
| **Wait for services** | Next 10 minutes (grab coffee) |
| **SSH and deploy app** | Next 5 minutes |
| **Test API** | Final 2 minutes |

**Total time from now: 34 minutes**

---

## Ready?

1. ✅ Go to: https://us-east-1.console.aws.amazon.com/cloudshell/home
2. ✅ Copy `deploy-to-aws.sh`
3. ✅ Paste into CloudShell
4. ✅ Run it
5. ✅ Wait
6. ✅ SSH to EC2
7. ✅ Deploy app
8. ✅ Test

**Let's get Rosier live! 🚀**

---

**Version**: 1.0
**Date**: April 1, 2026
**Status**: READY TO DEPLOY
**Next step**: Open CloudShell and run the script
