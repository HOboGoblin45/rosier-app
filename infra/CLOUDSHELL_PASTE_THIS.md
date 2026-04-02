# Rosier AWS CloudShell One-Click Deploy

## TL;DR - Just Paste This

Open [AWS CloudShell](https://us-east-1.console.aws.amazon.com/cloudshell/home) and paste:

```bash
curl -s https://raw.githubusercontent.com/rosier/backend/main/infra/cloudshell-deploy.sh | bash
```

**Or if cloning locally first:**

```bash
git clone https://github.com/rosier/backend.git && cd backend/infra && bash cloudshell-deploy.sh
```

That's it! The script does everything automatically.

---

## What You'll See

### Stage 1: Starting (Immediate)
```
[INFO] AWS credentials verified
[SUCCESS] Default VPC: vpc-xxxxx
[INFO] Creating EC2 security group...
[SUCCESS] EC2 Security Group: sg-xxxxx
```

### Stage 2: Database & Cache Creation (30-45 seconds)
```
[SUCCESS] RDS Instance: rosier-db
[INFO] RDS Endpoint: rosier-db.xxxxx.us-east-1.rds.amazonaws.com
[SUCCESS] Redis Cluster: rosier-redis
[INFO] Redis Endpoint: rosier-redis.xxxxx.ng.0001.cache.amazonaws.com
```

### Stage 3: EC2 Instance (1-2 minutes)
```
[SUCCESS] Key pair created: rosier-key.pem
[SUCCESS] EC2 instance launched: i-0xxxxx
[SUCCESS] Public IP: 54.123.45.67
```

### Stage 4: Deployment Complete (2-3 minutes)
```
╔════════════════════════════════════════════════════════╗
║        DEPLOYMENT COMPLETE!                            ║
╚════════════════════════════════════════════════════════╝

IMMEDIATE ACTIONS NEEDED:
1. Download rosier-key.pem from CloudShell
2. Download rosier-deploy-info.txt
3. Wait 5-10 minutes for RDS & Redis to initialize
```

---

## What Gets Created

| Resource | Type | Free Tier | Status |
|----------|------|-----------|--------|
| **EC2** | t2.micro | ✓ Free 12 months | Running immediately |
| **RDS PostgreSQL** | db.t3.micro | ✓ Free 12 months | Ready in 5-10 min |
| **ElastiCache Redis** | cache.t3.micro | ✓ Free 12 months | Ready in 5-10 min |
| **Security Groups** | 3x (EC2, RDS, Redis) | ✓ Always free | Created immediately |
| **Key Pair** | SSH key | ✓ Always free | Downloaded to CloudShell |

---

## After Deployment: Next Steps

### 1. Download Files from CloudShell (Right Now!)

In CloudShell, you'll see two files:
- `rosier-key.pem` - Your SSH private key
- `rosier-deploy-info.txt` - All credentials and connection info

**Download these immediately before closing CloudShell.**

### 2. Wait for Services to Fully Initialize

While RDS and Redis are starting:
- Check [RDS Console](https://us-east-1.console.aws.amazon.com/rds/home?region=us-east-1#databases:)
- Check [ElastiCache Console](https://us-east-1.console.aws.amazon.com/elasticache/home?region=us-east-1#clusters:)
- Check [EC2 Console](https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#Instances:)

Wait until:
- RDS: Status = "Available" (green)
- ElastiCache: Status = "Available" (green)
- EC2: Status Checks = "2/2 passed" (green)

This takes 5-10 minutes.

### 3. SSH to Your Instance

Once EC2 shows "Running" and has a public IP:

```bash
chmod 600 rosier-key.pem  # Secure the key first
ssh -i rosier-key.pem ec2-user@54.123.45.67  # Use YOUR IP from rosier-deploy-info.txt
```

### 4. Deploy the Application

On the EC2 instance:

```bash
cd /app

# Clone the repository
git clone https://github.com/rosier/backend.git .
cd backend

# Create .env file (copy from rosier-deploy-info.txt)
cat > .env << 'EOF'
DATABASE_URL=postgresql+asyncpg://rosier_admin:YOUR_PASSWORD@rosier-db.xxxxx.us-east-1.rds.amazonaws.com:5432/rosier
REDIS_URL=redis://rosier-redis.xxxxx.ng.0001.cache.amazonaws.com:6379/0
AWS_REGION=us-east-1
JWT_SECRET_KEY=$(openssl rand -base64 32)
SECRET_KEY=$(openssl rand -base64 32)
ENVIRONMENT=production
DEBUG=false
CORS_ORIGINS=["*"]
EOF

# Start the application
docker-compose -f infra/docker/docker-compose-prod.yml up -d

# Run database migrations
docker-compose -f infra/docker/docker-compose-prod.yml exec api alembic upgrade head

# Seed initial data (brands, wallpaper patterns)
docker-compose -f infra/docker/docker-compose-prod.yml exec api python scripts/seed_data.py

# Verify it's running
curl http://localhost:8000/health
# Should return: {"status": "ok"}
```

### 5. Check Your API

From your local computer (or anywhere):

```bash
# View API documentation
curl http://54.123.45.67:8000/docs

# Health check
curl http://54.123.45.67:8000/health

# View logs
docker-compose -f infra/docker/docker-compose-prod.yml logs -f api
```

---

## How to Get Your Credentials

Your deployment info file contains everything. From CloudShell:

```bash
cat rosier-deploy-info.txt
```

You'll see:
- **Database password** - For connecting to PostgreSQL
- **Database endpoint** - The RDS hostname
- **Redis endpoint** - The ElastiCache hostname
- **EC2 IP address** - For SSH access
- **SSH key name** - The key pair to download

---

## Pricing Guarantee

### Year 1: $0/month (AWS Free Tier)
- EC2 t2.micro: Free
- RDS db.t3.micro: Free
- ElastiCache cache.t3.micro: Free
- Total: **$0/month**

### Year 2 and beyond: ~$50-75/month
(After free tier expires. You can upgrade or manage costs then.)

---

## Troubleshooting

### "Can't SSH - Connection refused"
- **Cause:** EC2 still initializing or security group misconfigured
- **Fix:** Wait 3-5 minutes, then try again
- **Check:** Instance Status Checks = 2/2 passed in AWS Console

### "RDS endpoint shows as pending"
- **Cause:** Database still initializing
- **Fix:** Wait 5-10 minutes, check RDS Console
- **Check:** AWS RDS Console -> DB Instances -> rosier-db -> Status = Available

### "Can't connect to PostgreSQL from EC2"
- **Cause:** RDS not initialized yet OR security group misconfigured
- **Fix:** Wait 10 minutes, verify RDS is available
- **Test:** `psql -h ENDPOINT -U rosier_admin -d rosier` (on EC2)

### "Docker-compose: command not found"
- **Cause:** Docker installation hasn't completed
- **Fix:** Wait 2-3 minutes from initial EC2 launch
- **Check:** `docker --version` and `docker-compose --version`

### "No space left on device"
- **Cause:** t2.micro has limited storage and logs can fill up
- **Fix:** Clean Docker logs: `docker system prune -a --volumes`
- **Better:** Monitor with `df -h` and set up log rotation

---

## Key Files

### CloudShell Directory Contents:

```
/tmp/rosier-cloudshell-12345/
├── cloudshell-deploy.sh          # The deployment script
├── rosier-key.pem                # SSH private key (DOWNLOAD THIS!)
├── rosier-deploy-info.txt        # All credentials (DOWNLOAD THIS!)
└── [other temporary files]
```

### Keep Safe:
- **rosier-key.pem** - Anyone with this can SSH to your instance
- **rosier-deploy-info.txt** - Contains database password
- Back them up in a secure location!

---

## Monitoring Your Deployment

### Real-time Status

```bash
# From CloudShell or local terminal
aws ec2 describe-instances \
  --instance-ids i-0xxxxx \
  --query 'Reservations[0].Instances[0].State.Name' \
  --output text

aws rds describe-db-instances \
  --db-instance-identifier rosier-db \
  --query 'DBInstances[0].DBInstanceStatus' \
  --output text

aws elasticache describe-cache-clusters \
  --cache-cluster-id rosier-redis \
  --query 'CacheClusters[0].CacheClusterStatus' \
  --output text
```

### AWS Console Links

- [EC2 Instances](https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#Instances:)
- [RDS Databases](https://us-east-1.console.aws.amazon.com/rds/home?region=us-east-1#databases:)
- [ElastiCache Clusters](https://us-east-1.console.aws.amazon.com/elasticache/home?region=us-east-1#clusters:)

---

## First API Call

Once the API is running (check health first):

```bash
# Get all brands
curl -H "Content-Type: application/json" \
  http://YOUR_IP:8000/api/v1/brands

# Get wallpapers
curl -H "Content-Type: application/json" \
  http://YOUR_IP:8000/api/v1/wallpapers

# View interactive docs
# Open in browser: http://YOUR_IP:8000/docs
```

---

## Cost Management Tips

1. **Monitor usage** in AWS Billing Dashboard
2. **Set billing alerts** in CloudWatch
3. **Free Tier stays free if:**
   - EC2 instance stays t2.micro
   - RDS stays db.t3.micro
   - ElastiCache stays cache.t3.micro
   - No outbound data transfer beyond free allowance

4. **If costs rise:**
   - Check for accidental large resources
   - Review data transfer charges
   - Consider RDS read replicas later (not needed now)

---

## Support & Questions

If something goes wrong, check:

1. **CloudShell terminal output** - Detailed error messages
2. **AWS Console** - Check service status and configurations
3. **EC2 instance logs** - SSH in and check `/var/log/rosier-setup.log`
4. **Docker logs** - `docker-compose logs api` (on EC2)
5. **RDS events** - AWS RDS Console -> rosier-db -> Events

---

## That's It!

Your production-ready Rosier backend is deploying right now!

Questions? Check the logs, monitor the consoles, and it should be fully operational in 15 minutes.
