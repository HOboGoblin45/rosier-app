# Rosier Backend Infrastructure

Production-ready AWS deployment for FastAPI backend + PostgreSQL + Redis on a budget.

## Overview

This infrastructure deploys the complete Rosier backend to AWS using the Free Tier, maintaining **$0/month costs** for the first 12 months.

```
EC2 t2.micro (Docker)
├── FastAPI API (8000)
├── Nginx Reverse Proxy (80/443)
└── Health Checks

PostgreSQL 16 (RDS db.t3.micro)
├── Main application database
├── 20GB storage
└── 7-day automated backups

Redis 7 (ElastiCache cache.t3.micro)
├── Session cache
├── Job queue
└── Rate limiting

S3 (Standard)
├── Asset storage
├── Profile images
└── User uploads
```

## Files in This Directory

### Documentation
- **QUICK_START.md** - 5-minute overview (start here!)
- **BUDGET_DEPLOYMENT_PLAN.md** - Detailed budget analysis
- **DEPLOYMENT_GUIDE.md** - Step-by-step deployment instructions
- **COST_TRACKING.md** - Monthly cost monitoring & budget alerts
- **README.md** - This file

### Terraform Infrastructure
- **terraform/** - Infrastructure as Code
  - `main-budget.tf` - Core infrastructure definition
  - `variables-budget.tf` - Configuration variables
  - `outputs-budget.tf` - Output values (IPs, endpoints)
  - `terraform.tfvars.example` - Configuration template
  - `user_data.sh` - EC2 initialization script

### Docker
- **docker/** - Container configuration
  - `docker-compose-prod.yml` - Production compose file

### Monitoring & Logs (Future)
- **monitoring/** - Monitoring setup
  - `cloudwatch-alarms.tf` - CloudWatch alarms
  - `sentry_config.py` - Sentry error tracking

## Quick Start

### For the Impatient (5 minutes)

```bash
# 1. Prepare
export TF_VAR_database_password="strong-password"
export TF_VAR_jwt_secret_key="$(openssl rand -base64 32)"

# 2. Deploy
cd terraform
terraform init
terraform apply

# 3. Get outputs
terraform output ec2_public_ip
```

### For the Thorough (80 minutes)

See **DEPLOYMENT_GUIDE.md** for comprehensive step-by-step instructions.

## Cost Summary

| Service | Monthly Cost | Free Tier Limit | Status |
|---------|--------|---------|--------|
| EC2 t2.micro | $0.00 | 750 hrs | ✓ Safe |
| RDS db.t3.micro | $0.00 | 750 hrs + 20GB | ✓ Safe |
| ElastiCache cache.t3.micro | $0.00 | 750 hrs | ✓ Safe |
| S3 Standard | $0.00 | 5GB + 1GB out | ✓ Safe |
| CloudWatch | $0.00 | 5GB logs | ✓ Safe |
| **TOTAL** | **$0.00** | — | **✓ GREEN** |

**Credit Buffer**: $20 (Explore AWS) + $100 (Free Tier) = **$120 available**

## Architecture Decision

### Why EC2 + Docker Compose? (Not ECS/Fargate)

| Factor | EC2 | Fargate |
|--------|-----|--------|
| Cost | $0/mo (Free) | $30/mo |
| Setup | 30 min (Terraform) | 2+ hrs (Complex) |
| Learning | Easy | Hard |
| Production-ready | ✓ Yes | ✓ Yes |
| **Best for** | MVP (now) | Scale (later) |

**Decision**: Start with EC2, upgrade to ECS/Fargate when cost becomes non-issue (Series A).

## Key Files to Edit

### 1. Configure Terraform
```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars with your values
```

### 2. Set Environment Variables
```bash
export TF_VAR_database_password="your-password"
export TF_VAR_jwt_secret_key="your-jwt-secret"
export TF_VAR_django_secret_key="your-django-secret"
```

### 3. Initialize & Deploy
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## Post-Deployment

### SSH into EC2
```bash
EC2_IP=$(terraform output -raw ec2_public_ip)
ssh -i ~/.ssh/rosier-mvp-key.pem ec2-user@$EC2_IP
```

### Deploy Application
```bash
# On EC2
cd /app
git clone https://github.com/rosier/rosier.git
docker-compose -f infra/docker/docker-compose-prod.yml up -d
docker-compose -f infra/docker/docker-compose-prod.yml exec api alembic upgrade head
```

### Verify Deployment
```bash
curl http://$EC2_IP:8000/health
```

## Monitoring

### Check Costs
- **Daily**: CloudWatch metrics in AWS console
- **Weekly**: AWS Cost Explorer
- **Monthly**: Detailed cost breakdown

### Set Up Alerts
```bash
# Alert if billing exceeds $50/month
aws cloudwatch put-metric-alarm \
  --alarm-name rosier-billing-alert \
  --metric-name EstimatedCharges \
  --threshold 50 \
  --comparison-operator GreaterThanThreshold
```

### View Logs
```bash
# On EC2
docker-compose logs -f api

# Via CloudWatch
aws logs tail /rosier/ec2/development --follow
```

## Troubleshooting

### Can't SSH?
```bash
# Check key permissions
chmod 400 ~/.ssh/rosier-mvp-key.pem

# Check security group
aws ec2 describe-security-groups --filters "Name=group-name,Values=rosier-ec2-sg"
```

### Database won't connect?
```bash
# Wait for RDS (takes ~5 min)
sleep 30

# Check status
aws rds describe-db-instances \
  --db-instance-identifier rosier-db \
  --query 'DBInstances[0].DBInstanceStatus'
```

### API not responding?
```bash
# Check containers
docker-compose ps

# View logs
docker-compose logs api

# Restart
docker-compose restart api
```

For more, see **DEPLOYMENT_GUIDE.md** troubleshooting section.

## Upgrading Infrastructure

### When to Upgrade?

**Scale Up to t2.small EC2**: When CPU > 80% consistently
- Cost: +$8/month
- CPU: 1 vCPU → 1 vCPU (same, but higher burst)
- RAM: 1GB → 2GB

**Scale Up to db.t3.small RDS**: When storage > 15GB
- Cost: +$24/month
- Storage: 20GB → (as much as needed)
- Compute: Slightly faster

**Add ElastiCache Replication**: When cache misses > 10%
- Cost: +$24/month (2 nodes)
- Availability: Single → Multi-AZ
- Throughput: Same, but more reliable

### How to Upgrade

```bash
# Edit terraform.tfvars
vim terraform/terraform.tfvars

# Change:
# ec2_instance_type = "t2.small"
# rds_instance_class = "db.t3.small"
# elasticache_num_cache_nodes = 2

# Apply changes
terraform plan
terraform apply
```

## Teardown (Careful!)

```bash
# Backup database first
aws rds create-db-snapshot \
  --db-instance-identifier rosier-db \
  --db-snapshot-identifier rosier-db-backup-2026-04-01

# Destroy infrastructure
cd terraform
terraform destroy

# Delete SSH key
aws ec2 delete-key-pair --key-name rosier-mvp-key
rm ~/.ssh/rosier-mvp-key.pem
```

## Security Notes

### Current Setup (MVP)
- ✓ RDS restricted to EC2 only
- ✓ Redis restricted to EC2 only
- ✓ S3 bucket not public
- ⚠️ SSH port 22 open to world (use IP whitelist in production)
- ⚠️ No encryption at rest (costs extra)

### Production Upgrades
- [ ] Restrict SSH to specific IP/VPN
- [ ] Enable RDS encryption
- [ ] Enable ElastiCache encryption
- [ ] Use AWS Secrets Manager for credentials
- [ ] Enable VPC Flow Logs
- [ ] Add WAF rules to ALB
- [ ] Enable S3 versioning and MFA delete

## Timeline

| Phase | Time | Tasks |
|-------|------|-------|
| Prep | 5 min | Set up credentials, variables |
| Deploy | 15 min | terraform init, plan, apply |
| Configure | 10 min | SSH, clone repo, set .env |
| Deploy App | 10 min | docker-compose up, migrations |
| Verify | 5 min | Health checks, basic tests |
| **TOTAL** | **45 min** | Production ready |

## Success Criteria

- [ ] EC2 instance running
- [ ] RDS database available
- [ ] ElastiCache cluster online
- [ ] API health endpoint responds
- [ ] Database migrations pass
- [ ] API reads/writes database
- [ ] Redis cache works
- [ ] S3 uploads work
- [ ] CloudWatch logs appear
- [ ] Monthly cost = $0.00

## What's Next?

### Week 1
- Load test with production traffic
- Monitor for errors
- Optimize slow queries
- Verify backups work

### Month 1
- Set up HTTPS with ACM
- Point custom domain
- Enable comprehensive monitoring
- Document API

### Month 3
- Plan infrastructure upgrades
- Consider moving to ECS/Fargate
- Add read replicas for RDS
- Implement CI/CD pipeline

## Support & Resources

### Documentation
- QUICK_START.md - Start here!
- DEPLOYMENT_GUIDE.md - Step-by-step
- BUDGET_DEPLOYMENT_PLAN.md - Detailed analysis
- COST_TRACKING.md - Cost monitoring

### External Resources
- [AWS Free Tier](https://aws.amazon.com/free/)
- [Terraform Docs](https://www.terraform.io/docs/)
- [FastAPI Docs](https://fastapi.tiangolo.com/)
- [Docker Compose Docs](https://docs.docker.com/compose/)

### Contact
- Email: charlie@rosierapp.com
- Slack: #infrastructure
- Issues: https://github.com/rosier/rosier/issues

## Environment Variables

### Required for Terraform
```bash
TF_VAR_database_password     # PostgreSQL password
TF_VAR_jwt_secret_key       # JWT secret for auth
TF_VAR_django_secret_key    # Django secret key
```

### Required for Application (.env)
```bash
DATABASE_URL                # PostgreSQL connection string
REDIS_URL                   # Redis connection string
JWT_SECRET_KEY              # JWT secret (same as above)
SECRET_KEY                  # Django secret (same as above)
AWS_REGION                  # AWS region (us-east-1)
AWS_ACCESS_KEY_ID          # IAM user access key
AWS_SECRET_ACCESS_KEY      # IAM user secret key
S3_BUCKET                   # S3 bucket name
ENVIRONMENT                 # "production" or "development"
```

## Tags

All resources are tagged for cost allocation:
```hcl
Project     = "Rosier"
Environment = "mvp"
ManagedBy   = "Terraform"
CostCenter  = "Bootstrap"
```

View costs by tag:
```bash
aws ce get-cost-and-usage \
  --time-period Start=2026-04-01,End=2026-04-30 \
  --granularity MONTHLY \
  --metrics UnblendedCost \
  --group-by Type=TAG,Key=Project
```

## License

Infrastructure code is private to Rosier project.

## Status

**Last Updated**: April 1, 2026
**Status**: Production Ready ✓
**Cost**: $0/month (Free Tier)
**Budget**: $120 available ($20 + $100)
**Next Review**: May 1, 2026

---

**Questions?** Start with QUICK_START.md, then DEPLOYMENT_GUIDE.md
