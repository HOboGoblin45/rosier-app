# Rosier AWS Deployment Log

**Date**: April 1, 2026
**Region**: us-east-1
**Budget**: $20 (Explore credits) + Free Tier (12 months)
**Cost Target**: $0/month

---

## Deployment Status

### Phase 1: Infrastructure Planning (COMPLETE)
- Reviewed AWS Free Tier eligibility
- Confirmed us-east-1 region for optimal Free Tier support
- Designed architecture: EC2 t2.micro + RDS db.t3.micro + ElastiCache cache.t3.micro

### Phase 2: Security Groups Configuration (IN PROGRESS - Ready for Creation)

The following security groups need to be created in AWS:

#### 1. **rosier-ec2-sg** (EC2 Security Group)
**Description**: Security group for Rosier EC2 instance - allows SSH, HTTP, HTTPS, API

**Inbound Rules**:
| Type | Protocol | Port Range | Source | Purpose |
|------|----------|-----------|---------|---------|
| SSH | TCP | 22 | 0.0.0.0/0 | SSH access for deployment |
| HTTP | TCP | 80 | 0.0.0.0/0 | Web traffic |
| HTTPS | TCP | 443 | 0.0.0.0/0 | Encrypted web traffic |
| Custom TCP | TCP | 8000 | 0.0.0.0/0 | Direct API access (dev) |

**Outbound Rules**:
- All traffic allowed (default)

---

#### 2. **rosier-rds-sg** (RDS Security Group)
**Description**: Security group for RDS PostgreSQL database

**Inbound Rules**:
| Type | Protocol | Port Range | Source | Purpose |
|------|----------|-----------|---------|---------|
| PostgreSQL | TCP | 5432 | rosier-ec2-sg | DB access from EC2 only |

**Outbound Rules**:
- All traffic allowed (default)

---

#### 3. **rosier-elasticache-sg** (ElastiCache Security Group)
**Description**: Security group for ElastiCache Redis cluster

**Inbound Rules**:
| Type | Protocol | Port Range | Source | Purpose |
|------|----------|-----------|---------|---------|
| Custom TCP | TCP | 6379 | rosier-ec2-sg | Redis access from EC2 only |

**Outbound Rules**:
- All traffic allowed (default)

---

### Phase 3: VPC & Networking
- **VPC**: Using default VPC (vpc-0b3ad661bd51d5197)
- **Region**: us-east-1
- **Availability Zones**: us-east-1a, us-east-1b, us-east-1c, us-east-1d, us-east-1e, us-east-1f

---

### Phase 4: EC2 Instance (NOT YET CREATED)

**Configuration**:
- **Instance Type**: t2.micro (Free Tier eligible)
- **AMI**: Amazon Linux 2023 (al2023-ami)
- **Storage**: 30GB gp3 EBS volume (Free Tier limit)
- **Key Pair**: rosier-mvp-key (needs to be created)
- **Security Group**: rosier-ec2-sg
- **Elastic IP**: Will allocate (free while attached)
- **Monitoring**: Disabled (to save costs)

**User Data Script**: Will install Docker and Docker Compose on launch

---

### Phase 5: RDS PostgreSQL 16 (NOT YET CREATED)

**Configuration**:
- **Instance Class**: db.t3.micro (Free Tier eligible)
- **Engine**: PostgreSQL 16.1
- **Storage**: 20GB gp3 (Free Tier limit)
- **Database Name**: rosier
- **Master Username**: rosier_admin
- **Multi-AZ**: Disabled (single AZ to save costs)
- **Backup Retention**: 7 days (default)
- **Encryption**: Disabled (to save costs in MVP phase)
- **Public Access**: NO (only accessible from EC2 SG)
- **Security Group**: rosier-rds-sg
- **Skip Final Snapshot**: true (for development)

**Connection String Pattern**:
```
postgresql+asyncpg://rosier_admin:{PASSWORD}@{ENDPOINT}:5432/rosier
```

---

### Phase 6: ElastiCache Redis 7 (NOT YET CREATED)

**Configuration**:
- **Node Type**: cache.t3.micro (Free Tier eligible)
- **Engine**: Redis 7.0
- **Number of Nodes**: 1 (single node, no replication)
- **Automatic Failover**: Disabled
- **Multi-AZ**: Disabled
- **Encryption at Rest**: Disabled
- **Encryption in Transit**: Disabled
- **Security Group**: rosier-elasticache-sg
- **Snapshots**: Disabled (to save costs)

**Connection String Pattern**:
```
redis://{ENDPOINT}:6379
```

---

### Phase 7: S3 Bucket (NOT YET CREATED)

**Configuration**:
- **Bucket Name**: rosier-assets-{ACCOUNT_ID}
- **Region**: us-east-1
- **Versioning**: Disabled
- **Encryption**: AES256 (free)
- **Public Access**: Blocked
- **CORS**: Enabled for app access
- **Storage Class**: Standard

---

## Next Steps (Terraform Deployment)

### How to Deploy Using Terraform

1. **Install Terraform** (if not already installed):
   ```bash
   # macOS
   brew install terraform

   # Linux
   curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
   sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
   sudo apt-get update && sudo apt-get install terraform
   ```

2. **Generate secrets**:
   ```bash
   export TF_VAR_database_password="$(openssl rand -base64 32)"
   export TF_VAR_jwt_secret_key="$(openssl rand -base64 32)"
   ```

3. **Navigate to Terraform directory**:
   ```bash
   cd /path/to/rosier/infra/terraform
   ```

4. **Initialize Terraform**:
   ```bash
   terraform init
   ```

5. **Plan deployment**:
   ```bash
   terraform plan -out=tfplan
   ```

6. **Apply the plan**:
   ```bash
   terraform apply tfplan
   ```

7. **Save outputs**:
   ```bash
   terraform output > deployment-outputs.txt
   ```

---

## Environment Variables for .env.production

Once infrastructure is created, you'll need these values:

```bash
# RDS Connection
DATABASE_URL=postgresql+asyncpg://rosier_admin:{PASSWORD}@{RDS_ENDPOINT}:5432/rosier

# Redis Connection
REDIS_URL=redis://{ELASTICACHE_ENDPOINT}:6379

# S3 Configuration
AWS_S3_BUCKET=rosier-assets-{ACCOUNT_ID}
AWS_REGION=us-east-1

# Application Secrets
JWT_SECRET_KEY={JWT_SECRET_KEY}
DJANGO_SECRET_KEY={DJANGO_SECRET_KEY}

# EC2 Instance Details
EC2_PUBLIC_IP={ELASTIC_IP}
EC2_INSTANCE_ID={INSTANCE_ID}
```

---

## AWS Free Tier Usage Estimates

### Monthly Consumption (estimated)
| Service | Free Tier Limit | Estimated Usage | Cost |
|---------|-----------------|-----------------|------|
| EC2 t2.micro | 750 hours/month | 720 hours | $0 |
| RDS db.t3.micro | 750 hours + 20GB storage | 720 hours + 10GB | $0 |
| ElastiCache cache.t3.micro | 750 hours | 720 hours | $0 |
| S3 Standard | 5GB storage + 1GB egress | 1GB + 0.5GB | $0 |
| CloudWatch Logs | 5GB/month | 2GB | $0 |
| **TOTAL MONTHLY COST** | | | **$0** |

**Buffer**: $20 (Explore credits) + additional Free Tier coverage provides safety margin

---

## Security Notes

### Current (Development) Settings
- SSH open to 0.0.0.0/0 (development only)
- Port 8000 (API) open to 0.0.0.0/0 (for testing)
- No encryption at rest or in transit (development)
- Single AZ (no high availability)
- No automated backups to snapshots

### Production Recommendations
- Restrict SSH to specific IP ranges using Systems Manager Session Manager
- Enable RDS encryption at rest (KMS)
- Enable Redis encryption in transit
- Enable Multi-AZ for high availability
- Enable automated backups with 7-30 day retention
- Add AWS WAF to ALB if needed
- Implement VPC Flow Logs for security monitoring
- Use Secrets Manager for sensitive credentials

---

## Monitoring & Cost Tracking

### CloudWatch Setup (Free Tier)
- EC2 instance status checks (enabled by default)
- RDS performance insights (basic tier, free)
- CloudWatch Logs for application logs
- Custom metrics for API response times

### Cost Alerts
- Set billing alert at $5/month (early warning)
- Monitor Free Tier usage daily for first week
- Check AWS Cost Explorer weekly

---

## Troubleshooting

### If Resources Already Exist
If you see "already exists" errors during deployment:
1. Check AWS Console to find resource IDs
2. Update terraform.tfvars with existing resource IDs
3. Import resources: `terraform import aws_instance.api {INSTANCE_ID}`

### If Terraform Apply Fails
1. Check region is us-east-1: `aws configure get region`
2. Verify AWS credentials: `aws sts get-caller-identity`
3. Check Free Tier eligibility in Billing console
4. Review CloudTrail for API errors

### If EC2 Fails to Launch
1. Wait 2-3 minutes for image to be available
2. Check EC2 limits in Service Quotas
3. Verify security groups exist before instance launch
4. Review user data script logs: `cat /var/log/cloud-init-output.log`

---

## Rollback Procedure

If needed to destroy all infrastructure:

```bash
cd rosier/infra/terraform
terraform plan -destroy -out=destroy.tfplan
terraform apply destroy.tfplan
```

This will delete:
- EC2 instance and Elastic IP
- RDS database (snapshot created if not disabled)
- ElastiCache cluster
- S3 bucket (must be empty)
- Security groups
- VPC if created (not default VPC)

---

## Success Criteria

Your deployment is successful when:

- [ ] EC2 instance is running (t2.micro)
- [ ] RDS database is available (db.t3.micro)
- [ ] ElastiCache cluster is available (cache.t3.micro)
- [ ] Security groups are configured with correct rules
- [ ] Elastic IP is associated with EC2
- [ ] Can SSH to EC2 using key pair
- [ ] API health endpoint responds (200 OK)
- [ ] Database migrations complete successfully
- [ ] Redis cache is accessible
- [ ] CloudWatch logs are streaming
- [ ] Monthly cost shows $0.00

---

## Contact & Support

For issues with deployment:
1. Check AWS Console > Service Health Dashboard
2. Review CloudTrail for API errors
3. Check application logs in CloudWatch
4. Consult Rosier documentation in infra/

---

**Last Updated**: April 1, 2026
**Deployment Plan Version**: 1.0
**Status**: Infrastructure Planning Complete - Ready for Terraform Deployment
