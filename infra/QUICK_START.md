# Rosier Backend: Quick Start (5-Minute Overview)

**TL;DR**: Deploy FastAPI + PostgreSQL + Redis on AWS for $0/month using Free Tier

---

## In 80 Minutes, You Will Have:

```
Internet → EC2 t2.micro (Docker) → PostgreSQL 16 + Redis 7 + S3
                ↓
        All costs: $0/month
```

---

## Quick Reference

### Budget
- **Spend**: $0/month (all Free Tier)
- **Credit Buffer**: $20 (Explore AWS) + $100 (Free Tier) = $120 total
- **Risk**: Low - costs locked to Free Tier limits

### What's Deployed
| Service | Type | Cost |
|---------|------|------|
| **EC2** | t2.micro | Free (750 hrs/mo) |
| **RDS** | db.t3.micro PostgreSQL 16 | Free (750 hrs + 20GB) |
| **ElastiCache** | cache.t3.micro Redis 7 | Free (750 hrs) |
| **S3** | Standard storage | Free (5GB) |
| **Total** | | **$0/month** |

---

## Prerequisites Checklist

- [ ] AWS Account (Free Tier eligible)
- [ ] AWS CLI installed (`aws --version`)
- [ ] Terraform installed (`terraform --version`)
- [ ] SSH key pair created
- [ ] Git repository cloned
- [ ] Environment variables set up

---

## Three-Step Deployment

### Step 1: Prepare (5 min)

```bash
# Create EC2 key pair
aws ec2 create-key-pair --key-name rosier-mvp-key \
  --output text > ~/.ssh/rosier-mvp-key.pem
chmod 400 ~/.ssh/rosier-mvp-key.pem

# Set environment variables
export TF_VAR_database_password="strong-password-123"
export TF_VAR_jwt_secret_key="$(openssl rand -base64 32)"
export TF_VAR_django_secret_key="$(openssl rand -base64 32)"
```

### Step 2: Deploy Infrastructure (15 min)

```bash
cd rosier/infra/terraform

# Initialize and deploy
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# Save outputs
terraform output > deployment-details.txt
EC2_IP=$(terraform output -raw ec2_public_ip)
```

### Step 3: Deploy Application (10 min)

```bash
# SSH into EC2
ssh -i ~/.ssh/rosier-mvp-key.pem ec2-user@$EC2_IP

# Clone repo and configure
git clone https://github.com/rosier/rosier.git /app
cd /app

# Create environment file
cat > .env << EOF
DATABASE_URL=postgresql+asyncpg://...
REDIS_URL=redis://...
JWT_SECRET_KEY=...
EOF

# Deploy with Docker
docker-compose -f infra/docker/docker-compose-prod.yml up -d

# Run migrations
docker-compose -f infra/docker/docker-compose-prod.yml exec api alembic upgrade head

# Test
curl http://localhost:8000/health
```

---

## Post-Deployment (5 min)

```bash
# From local machine
curl http://$EC2_IP:8000/health

# Expected response:
# {"status":"healthy","database":"connected",...}
```

---

## Key Commands

### Access EC2
```bash
ssh -i ~/.ssh/rosier-mvp-key.pem ec2-user@$EC2_IP
```

### View Logs
```bash
docker-compose -f infra/docker/docker-compose-prod.yml logs -f api
```

### Database Access
```bash
# From EC2, via docker
docker-compose exec api psql -h $RDS_ENDPOINT -U postgres -d rosier
```

### Redeploy (after code changes)
```bash
cd /app
git pull origin main
docker-compose -f infra/docker/docker-compose-prod.yml build --no-cache
docker-compose -f infra/docker/docker-compose-prod.yml up -d
```

### Destroy (if needed)
```bash
cd rosier/infra/terraform
terraform destroy
```

---

## Monitoring

### Check Cost
```bash
# AWS Billing Dashboard
# https://us-east-1.console.aws.amazon.com/billing/

# CLI command
aws ce get-cost-and-usage \
  --time-period Start=2026-04-01,End=2026-04-30 \
  --granularity DAILY \
  --metrics UnblendedCost
```

### Check Logs
```bash
# CloudWatch
# https://us-east-1.console.aws.amazon.com/cloudwatch/

# Or via CLI
aws logs tail /rosier/ec2/development --follow
```

### Check Resources
```bash
# EC2 status
aws ec2 describe-instances --instance-ids i-xxx

# RDS status
aws rds describe-db-instances --db-instance-identifier rosier-db

# ElastiCache status
aws elasticache describe-cache-clusters --cache-cluster-id rosier-redis
```

---

## Common Issues

### Can't SSH to EC2
```bash
# Check key permissions
ls -la ~/.ssh/rosier-mvp-key.pem  # Should be 400

# Check security group allows port 22
aws ec2 describe-security-groups --filters "Name=group-name,Values=rosier-ec2-sg"

# Try with verbose output
ssh -v -i ~/.ssh/rosier-mvp-key.pem ec2-user@$EC2_IP
```

### Database Connection Failed
```bash
# Wait for RDS to be ready (can take 5+ minutes)
sleep 30

# Check RDS is available
aws rds describe-db-instances --query 'DBInstances[0].DBInstanceStatus'
# Should return: "available"

# Check database password matches
grep DATABASE_URL /app/.env
```

### API Not Responding
```bash
# Check if API container is running
docker-compose -f infra/docker/docker-compose-prod.yml ps

# View API logs
docker-compose -f infra/docker/docker-compose-prod.yml logs api | tail -50

# Restart API
docker-compose -f infra/docker/docker-compose-prod.yml restart api
```

---

## Files Created

### Terraform Files
- `variables-budget.tf` - Budget-optimized variables
- `main-budget.tf` - Infrastructure definition
- `outputs-budget.tf` - Output values
- `terraform.tfvars.example` - Configuration template
- `user_data.sh` - EC2 initialization script

### Docker Files
- `docker/docker-compose-prod.yml` - Production compose file

### Documentation
- `BUDGET_DEPLOYMENT_PLAN.md` - Detailed plan (this doc)
- `DEPLOYMENT_GUIDE.md` - Step-by-step guide
- `QUICK_START.md` - This file

---

## Architecture at a Glance

```
Mobile App (iOS)
       ↓
   Internet
       ↓
Elastic IP: 203.0.113.x
       ↓
  EC2 t2.micro
  (1 vCPU, 1GB RAM)
       ├→ FastAPI (8000)
       ├→ Nginx (80/443)
       └→ Docker
            ├→ API service
            └→ Healthcheck
       ↓
  Security Group
  (SSH, HTTP, HTTPS)
       ↓
  ┌──────────────────┐
  │ RDS PostgreSQL   │ ← Database reads/writes
  │ db.t3.micro      │
  │ 20GB storage     │
  └──────────────────┘
       ↓
  ┌──────────────────┐
  │ ElastiCache Redis│ ← Session cache, job queue
  │ cache.t3.micro   │
  │ Single node      │
  └──────────────────┘
       ↓
  ┌──────────────────┐
  │ S3 Bucket        │ ← Asset uploads, images
  │ 5GB free tier    │
  └──────────────────┘
```

---

## Timeline

| Time | Task | Duration |
|------|------|----------|
| 0:00 | Prepare environment | 5 min |
| 0:05 | Deploy infrastructure | 15 min |
| 0:20 | SSH to EC2 | 2 min |
| 0:22 | Clone and configure | 5 min |
| 0:27 | Deploy application | 10 min |
| 0:37 | Run migrations | 3 min |
| 0:40 | Verify deployment | 5 min |
| 0:45 | Complete! | — |

**Total**: ~45 minutes from start to production

---

## Cost Validation

### What Makes This $0?

1. **EC2 t2.micro**: Free Tier = 750 hours/month
   - 30 days × 24 hours = 720 hours used
   - Stays within limit ✓

2. **RDS db.t3.micro**: Free Tier = 750 hours + 20GB
   - 720 hours + ~10GB storage used
   - Stays within limit ✓

3. **ElastiCache cache.t3.micro**: Free Tier = 750 hours
   - 720 hours used
   - Stays within limit ✓

4. **S3**: Free Tier = 5GB + 1GB data transfer
   - ~1GB used (images, uploads)
   - Stays within limit ✓

5. **CloudWatch**: Free Tier = 5GB logs
   - ~1GB used
   - Stays within limit ✓

**Total Cost**: $0.00/month ✓

### When Does Cost Exceed $0?

Only if you:
- Run instances > 750 hours/month (don't turn it off)
- Store > 20GB in RDS (compress old data)
- Store > 5GB in S3 (delete old uploads)
- Transfer > 1GB out of AWS (implement caching)

All of these have **clear limits** you can monitor.

---

## Success Criteria

Your deployment is successful when:

- [ ] EC2 instance is running
- [ ] RDS database is available
- [ ] ElastiCache cluster is available
- [ ] API health endpoint responds (200 OK)
- [ ] Database migrations pass
- [ ] API can read/write to database
- [ ] Redis cache works
- [ ] S3 uploads work
- [ ] CloudWatch logs appear
- [ ] Monthly cost shows $0.00

---

## What's Next?

### Immediate (Week 1)
- [ ] Load test with real traffic
- [ ] Monitor logs for errors
- [ ] Verify database performance
- [ ] Test S3 uploads

### Short-term (Month 1)
- [ ] Set up HTTPS with ACM
- [ ] Point custom domain with Route 53
- [ ] Enable CloudWatch alarms
- [ ] Document API with Swagger

### Medium-term (Month 2-3)
- [ ] Implement CI/CD pipeline
- [ ] Add Elasticsearch (if needed)
- [ ] Optimize database queries
- [ ] Plan infrastructure upgrades

---

## Support

| Issue | Solution |
|-------|----------|
| Can't SSH | Check key permissions & security group |
| DB connection failed | Wait for RDS to be ready (~5 min) |
| API not responding | Check Docker logs, restart container |
| Out of memory | Reduce memory limits or upgrade EC2 |
| S3 access denied | Verify IAM user permissions |

For detailed troubleshooting, see **DEPLOYMENT_GUIDE.md**

---

## Key Takeaways

1. **Cost**: $0/month for 12 months
2. **Setup**: 45 minutes total
3. **Complexity**: Low (Terraform + Docker)
4. **Scalability**: Clear upgrade path
5. **Reliability**: AWS managed services
6. **Monitoring**: CloudWatch included

**You are production-ready!** 🚀

---

**Created**: April 1, 2026
**Budget**: $120 total ($20 + $100 Free Tier)
**Status**: Ready to deploy
