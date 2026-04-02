# Rosier Backend: Budget-Conscious AWS Deployment Plan

**Date**: April 1, 2026
**Account**: AWS (us-east-1)
**Budget**: $20.00 (Explore AWS credits) + $100.00 (Free Tier) = $120 total available

---

## Executive Summary

Given the $20 AWS Explore credit and unlimited AWS Free Tier eligibility, the most cost-effective approach is to:

1. **Run the entire backend on a single EC2 t2.micro instance** (Free Tier eligible)
2. **Use RDS PostgreSQL 16 db.t3.micro** (Free Tier eligible - 750 hrs/month)
3. **Use ElastiCache Redis 7 cache.t3.micro** (Free Tier eligible - 750 hrs/month)
4. **Skip Elasticsearch for now** (requires 2GB+ RAM, better to start without it)
5. **Skip ECS/Fargate entirely** (would cost $30+/month)

This approach keeps us within **$0/month for the first 12 months** (thanks to Free Tier), with the $20 credit as a safety buffer.

---

## Architecture Decision

### Why EC2 t2.micro + Docker Compose (not ECS/Fargate)?

| Aspect | ECS Fargate | EC2 t2.micro |
|--------|-----------|------------|
| **Cost/month** | ~$30 (0.25 vCPU + storage) | $0 (Free Tier) |
| **Setup complexity** | High (requires ECR, task definitions, load balancers) | Low (Docker Compose) |
| **Learning curve** | Steep | Shallow |
| **Good for MVP?** | No - too expensive | Yes - fast iteration |
| **Scaling** | Automatic | Manual, but sufficient for MVP |
| **Downside** | Cost-prohibitive | Single point of failure |

**Decision**: Start with **EC2 t2.micro** running Docker Compose. This is the only way to ship within the $20 budget while maintaining all 3 backend services (API, DB, Cache).

---

## Infrastructure Components

### 1. Compute: EC2 t2.micro
- **Instance type**: t2.micro (1 vCPU, 1GB RAM, Free Tier)
- **AMI**: Amazon Linux 2023 (free, optimized)
- **Uptime**: 750 hours/month (Free Tier eligible)
- **Disk**: 30GB EBS gp3 (Free Tier: 30GB/month)
- **Cost**: **$0/month**

### 2. Database: RDS PostgreSQL 16
- **Instance class**: db.t3.micro
- **Storage**: 20GB gp3 (Free Tier: 20GB/month)
- **Multi-AZ**: No (would cost extra)
- **Backups**: 7-day retention (default)
- **Cost**: **$0/month** (750 hrs Free Tier)

### 3. Cache: ElastiCache Redis 7
- **Instance class**: cache.t3.micro
- **Nodes**: 1 (single-node, no replication)
- **Engine version**: 7.0
- **Cost**: **$0/month** (750 hrs Free Tier)

### 4. Storage: S3
- **Bucket**: rosier-assets
- **Tier**: Standard (5GB Free Tier)
- **Purpose**: Asset uploads, profile images
- **Cost**: **$0/month** (for first 5GB)

### 5. Networking
- **VPC**: Default VPC (free)
- **Security Groups**: Allow SSH (22), HTTP (80), HTTPS (443), PostgreSQL (5432 internal), Redis (6379 internal)
- **Elastic IP**: 1 for EC2 instance ($0 while attached)
- **Cost**: **$0/month**

### 6. Monitoring & Logs
- **CloudWatch**: 5GB logs/month (Free Tier)
- **Cost**: **$0/month**

---

## Total Monthly Cost Analysis

| Service | Free Tier Limit | Actual Usage | Cost |
|---------|-----------------|--------------|------|
| **EC2 t2.micro** | 750 hrs/month | 720 hrs/month | $0 |
| **RDS db.t3.micro** | 750 hrs + 20GB | 720 hrs + 10GB (est.) | $0 |
| **ElastiCache cache.t3.micro** | 750 hrs | 720 hrs | $0 |
| **S3 (standard)** | 5GB | 0.5GB (est.) | $0 |
| **CloudWatch** | 5GB logs | 1GB (est.) | $0 |
| **Data Transfer** | 1GB/month egress | <1GB | $0 |
| **TOTAL** | — | — | **$0/month** |

**Credit Buffer**: $20 + $100 Free Tier credit available for overage or paid features.

---

## What This Supports

### Supported Features
- Full FastAPI backend with 59 API endpoints
- PostgreSQL 16 with async SQLAlchemy
- Redis 7 for caching, sessions, and job queues
- JWT authentication
- S3-based asset uploads
- Sentry error monitoring (with free tier)
- Email notifications
- WebSocket support for real-time features

### NOT Supported (MVP Phase)
- Elasticsearch (search/analytics) - Skip for now
- Multi-AZ failover (single node)
- Auto-scaling (manual scaling only)
- CDN/CloudFront (costs extra)
- Advanced monitoring (use basic CloudWatch)

### Elasticsearch Migration Path
If needed later, deploy Elasticsearch as a separate service or use managed OpenSearch (evaluate cost at that time).

---

## Deployment Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS Account (us-east-1)                   │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │            EC2 t2.micro (Free Tier)                  │   │
│  │  ┌──────────────────────────────────────────────┐    │   │
│  │  │      Docker Host (Amazon Linux 2023)         │    │   │
│  │  ├──────────────────────────────────────────────┤    │   │
│  │  │  Docker Compose Services:                     │    │   │
│  │  │  ├─ FastAPI API (port 8000)                  │    │   │
│  │  │  ├─ PostgreSQL (local, port 5432)            │    │   │
│  │  │  ├─ Redis (local, port 6379)                 │    │   │
│  │  │  └─ Nginx Reverse Proxy (port 80/443)        │    │   │
│  │  └──────────────────────────────────────────────┘    │   │
│  │                                                        │   │
│  │  Security Groups:                                      │   │
│  │  ├─ Inbound: 22 (SSH), 80 (HTTP), 443 (HTTPS)       │   │
│  │  └─ Outbound: All traffic                            │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  RDS PostgreSQL 16 (db.t3.micro - Free Tier)         │   │
│  │  ├─ Endpoint: rosier-db.xxxx.us-east-1.rds.....     │   │
│  │  ├─ Port: 5432                                       │   │
│  │  └─ Backups: 7-day retention                         │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  ElastiCache Redis 7 (cache.t3.micro - Free Tier)    │   │
│  │  ├─ Endpoint: rosier-cache.xxxx.ng.0001.....        │   │
│  │  ├─ Port: 6379                                       │   │
│  │  └─ Automatic failover: No                           │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  S3 Bucket (rosier-assets)                           │   │
│  │  └─ Region: us-east-1                               │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  CloudWatch Logs & Monitoring                        │   │
│  │  └─ Log retention: 30 days                           │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
└─────────────────────────────────────────────────────────────┘

                          Internet
                             ▲
                             │
                    ┌────────┴────────┐
                    │  Route 53 DNS   │
                    │ (external only) │
                    └─────────────────┘
```

---

## Setup Roadmap

### Phase 1: Core Infrastructure (Today)
- [ ] Create EC2 security group with SSH, HTTP, HTTPS access
- [ ] Create RDS security group for PostgreSQL
- [ ] Create ElastiCache security group for Redis
- [ ] Launch EC2 t2.micro instance
- [ ] Allocate and associate Elastic IP
- [ ] Launch RDS PostgreSQL 16 instance
- [ ] Launch ElastiCache Redis 7 cluster

### Phase 2: Application Setup (Manual on EC2)
- [ ] SSH into EC2 instance
- [ ] Install Docker and Docker Compose
- [ ] Clone repository and configure environment variables
- [ ] Build and push Docker image (or use pre-built)
- [ ] Deploy via Docker Compose
- [ ] Test API endpoints
- [ ] Configure CloudWatch agent for monitoring

### Phase 3: Networking & SSL (Optional for MVP)
- [ ] Register domain (external)
- [ ] Set up SSL certificate (ACM or self-signed for testing)
- [ ] Configure nginx reverse proxy on EC2
- [ ] Point DNS to EC2 Elastic IP

### Phase 4: CI/CD (Future Optimization)
- [ ] Set up GitHub Actions for automated deploys
- [ ] Push Docker images to ECR (optional)
- [ ] Implement blue-green deployment script

---

## Cost Watch & Escalation Plan

### Monthly Cost Targets
- **Year 1**: $0/month (Free Tier)
- **Year 2+**: ~$40-60/month once Free Tier expires (t2.micro → t2.small upgrade)

### Escalation Scenarios

**If Free Tier quota exceeded:**
- EC2 t2.micro overage: ~$0.0116/hour (~$8/month)
- RDS db.t3.micro overage: ~$0.033/hour (~$24/month)
- Total overage impact: ~$32/month (triggers the $20 credit buffer)

**If we exceed $20 in a month:**
- Immediately investigate via CloudWatch metrics
- Options:
  - Optimize database queries
  - Scale down RDS storage (not compute)
  - Implement aggressive caching in Redis
  - Use cost anomaly detection

**If we need to scale:**
- EC2 upgrade path: t2.micro → t2.small → t2.medium
- RDS upgrade path: db.t3.micro → db.t3.small → db.t3.medium
- Use Reserved Instances after 3+ months of stable usage

---

## Implementation Notes

### Why Not Alternative Approaches?

**Option A: Lambda + API Gateway** ❌
- Requires API Gateway ($3.50/million requests minimum)
- Cold start latency issues
- FastAPI not optimized for Lambda (requires middleware)
- Cost: $15-30/month for small traffic

**Option B: Lightsail** ❌
- Fixed $3.50/month for micro, but requires separate databases
- Less flexible than EC2
- Higher cost when adding managed RDS/ElastiCache
- Cost: $20-30/month for equivalent setup

**Option C: App Runner** ❌
- Managed container service
- Good for serverless, but overkill for MVP
- Minimum $1/day = $30/month
- Cost: Too expensive for budget

**Option D: EC2 t2.micro + Docker Compose** ✅
- **Cost**: $0/month (Free Tier)
- **Complexity**: Low (Terraform + Docker Compose)
- **Flexibility**: Full control, easy to add services
- **Scalability path**: Clear upgrade path to ECS/Fargate later

---

## Security Considerations

### Current Setup
- All services in same VPC (default)
- Database not exposed to internet (security group restricted)
- Redis not exposed to internet (security group restricted)
- SSH access on port 22 (restrict by IP in production)

### Production Upgrades Needed
- [ ] Restrict SSH to specific IP ranges
- [ ] Enable RDS encryption
- [ ] Enable VPC Flow Logs
- [ ] Use Secrets Manager for credentials
- [ ] Enable AWS Systems Manager Session Manager (instead of SSH)
- [ ] Add WAF rules to ALB (if adding ALB)
- [ ] Enable S3 bucket versioning and encryption

---

## Monitoring & Alerts

### Free Tier Monitoring
- CloudWatch Metrics (basic, 5 minute resolution)
- CloudWatch Logs (5GB/month)
- EC2 instance status checks
- RDS performance insights (basic tier)

### Recommended Custom Metrics
- API response times
- Database connection pool usage
- Redis memory usage
- Error rates by endpoint
- S3 upload volume

### Alert Setup
- High CPU usage on EC2 (>80%)
- RDS storage usage (>80%)
- Redis memory usage (>80%)
- API error rates (>1%)

---

## Migration Path to Production

When ready to scale beyond MVP (estimated 6+ months or $10K MRR):

### Stage 1: Add HA Database
- Upgrade RDS to db.t3.small with Multi-AZ
- Cost impact: +$24/month (on top of single-AZ)

### Stage 2: Add Caching Layer
- Keep ElastiCache, but upgrade to cache.r6g.large for replication
- Cost impact: +$80/month

### Stage 3: Add Load Balancer
- Migrate to ECS Fargate with ALB
- Scale to 2-4 replicas of the API
- Add dedicated RDS endpoint for read replicas
- Cost impact: +$100-150/month

### Stage 4: Add CDN
- CloudFront for static assets
- Cost impact: +$20-50/month depending on traffic

**Estimated cost at Series A scale (10K MRR)**: $400-600/month for full HA setup with auto-scaling.

---

## File Structure After Deployment

```
infra/
├── docker/
│   ├── Dockerfile                    # (backend Dockerfile, unchanged)
│   └── docker-compose-prod.yml       # Production compose file
├── terraform/
│   ├── main.tf                       # Main infrastructure
│   ├── variables.tf                  # Variables
│   ├── outputs.tf                    # Output values
│   ├── ec2.tf                        # EC2-specific config
│   ├── rds.tf                        # RDS-specific config
│   ├── elasticache.tf                # ElastiCache-specific config
│   ├── s3.tf                         # S3-specific config
│   ├── iam.tf                        # IAM roles/policies
│   ├── security-groups.tf            # Security groups
│   └── terraform.tfvars.example      # Example variables
├── scripts/
│   ├── deploy.sh                     # Deployment script
│   ├── init-db.sh                    # Database initialization
│   ├── backup-db.sh                  # Database backup
│   └── health-check.sh               # Health check script
├── nginx/
│   ├── nginx.conf                    # Nginx configuration
│   └── ssl/                          # SSL certificates
├── monitoring/
│   ├── cloudwatch-alarms.tf          # CloudWatch alarm definitions
│   └── sentry_config.py              # Sentry configuration
└── BUDGET_DEPLOYMENT_PLAN.md         # This file
```

---

## Next Steps

1. **Approve this plan** with Charlie
2. **Create Terraform infrastructure** (30 minutes to deploy)
3. **SSH into EC2 and install Docker** (10 minutes)
4. **Deploy application** via docker-compose (5 minutes)
5. **Run migrations** and health checks (5 minutes)
6. **Configure monitoring** (20 minutes)
7. **Update API domain/DNS** (10 minutes)

**Total time to production: ~80 minutes**

---

## Cost Validation

Run this query in AWS Cost Explorer to validate we're within budget:

```sql
SELECT service, SUM(unblended_cost) as cost
FROM costs
WHERE time >= '2026-04-01' AND time < '2026-05-01'
GROUP BY service
ORDER BY cost DESC
```

**Expected result**: $0.00 (all services within Free Tier)

---

## Assumptions & Constraints

### Assumptions
- Traffic volume < 100K requests/day (within t2.micro capability)
- Database < 20GB (RDS free storage limit)
- Peak concurrent connections < 50 (t2.micro limitation)
- Data transfer < 1GB/month egress (Free Tier limit)

### When to Re-evaluate
- Traffic exceeds 500K requests/day
- Database grows > 50GB
- Concurrent connections exceed 100
- Data transfer > 5GB/month
- Team grows to 3+ engineers (need better staging env)

---

## References

- AWS Free Tier: https://aws.amazon.com/free/
- EC2 t2.micro pricing: https://aws.amazon.com/ec2/pricing/on-demand/
- RDS pricing: https://aws.amazon.com/rds/pricing/
- ElastiCache pricing: https://aws.amazon.com/elasticache/pricing/
- Docker Compose: https://docs.docker.com/compose/
- Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
