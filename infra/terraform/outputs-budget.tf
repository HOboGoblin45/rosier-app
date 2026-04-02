# Budget deployment outputs

# ============================================================================
# EC2 OUTPUTS
# ============================================================================

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.api.id
}

output "ec2_public_ip" {
  description = "EC2 public IP address"
  value       = aws_eip.api.public_ip
}

output "ec2_public_dns" {
  description = "EC2 public DNS hostname"
  value       = aws_instance.api.public_dns
}

output "ec2_private_ip" {
  description = "EC2 private IP address"
  value       = aws_instance.api.private_ip
}

output "ec2_instance_type" {
  description = "EC2 instance type"
  value       = aws_instance.api.instance_type
}

output "ec2_security_group_id" {
  description = "EC2 security group ID"
  value       = aws_security_group.ec2.id
}

# ============================================================================
# RDS OUTPUTS
# ============================================================================

output "rds_endpoint" {
  description = "RDS endpoint address"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_hostname" {
  description = "RDS hostname"
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "RDS port"
  value       = aws_db_instance.postgres.port
}

output "rds_database_name" {
  description = "RDS database name"
  value       = aws_db_instance.postgres.db_name
}

output "rds_username" {
  description = "RDS master username"
  value       = aws_db_instance.postgres.username
  sensitive   = true
}

output "rds_connection_string" {
  description = "PostgreSQL connection string (from EC2)"
  value       = "postgresql+asyncpg://${aws_db_instance.postgres.username}:PASSWORD@${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}/${aws_db_instance.postgres.db_name}"
  sensitive   = true
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}

# ============================================================================
# ELASTICACHE OUTPUTS
# ============================================================================

output "elasticache_endpoint" {
  description = "ElastiCache Redis endpoint"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "elasticache_port" {
  description = "ElastiCache Redis port"
  value       = aws_elasticache_cluster.redis.port
}

output "elasticache_connection_string" {
  description = "Redis connection string (from EC2)"
  value       = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:${aws_elasticache_cluster.redis.port}/0"
}

output "elasticache_security_group_id" {
  description = "ElastiCache security group ID"
  value       = aws_security_group.elasticache.id
}

# ============================================================================
# S3 OUTPUTS
# ============================================================================

output "s3_bucket_name" {
  description = "S3 bucket name for assets"
  value       = aws_s3_bucket.assets.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.assets.arn
}

output "s3_bucket_region" {
  description = "S3 bucket region"
  value       = aws_s3_bucket.assets.region
}

# ============================================================================
# DEPLOYMENT INSTRUCTIONS
# ============================================================================

output "deployment_guide" {
  description = "Quick deployment guide"
  value = <<-EOT

    ╔════════════════════════════════════════════════════════════════════╗
    ║                   ROSIER DEPLOYMENT COMPLETE                       ║
    ║                     (Budget-Optimized MVP)                         ║
    ╚════════════════════════════════════════════════════════════════════╝

    1. SSH INTO EC2 INSTANCE:
       ssh -i <your-key.pem> ec2-user@${aws_eip.api.public_ip}

    2. CLONE REPOSITORY AND CONFIGURE:
       git clone <repo-url> /app
       cd /app/backend

    3. CREATE ENVIRONMENT FILE:
       cat > .env << 'EOF'
       DATABASE_URL=postgresql+asyncpg://${aws_db_instance.postgres.username}:PASSWORD@${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}/${aws_db_instance.postgres.db_name}
       REDIS_URL=redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:${aws_elasticache_cluster.redis.port}/0
       JWT_SECRET_KEY=your-secret-key-here
       S3_BUCKET=${aws_s3_bucket.assets.id}
       AWS_REGION=${var.aws_region}
       ENVIRONMENT=production
       EOF

    4. DEPLOY WITH DOCKER COMPOSE:
       docker-compose -f docker-compose-prod.yml up -d

    5. RUN DATABASE MIGRATIONS:
       docker-compose -f docker-compose-prod.yml exec api alembic upgrade head

    6. CHECK HEALTH:
       curl http://${aws_eip.api.public_ip}:8000/health

    7. VIEW LOGS:
       docker-compose logs -f api

    ════════════════════════════════════════════════════════════════════

    INFRASTRUCTURE SUMMARY:
    ├─ Compute: EC2 t2.micro (Free Tier)
    ├─ Database: RDS PostgreSQL 16 db.t3.micro (Free Tier)
    ├─ Cache: ElastiCache Redis 7 cache.t3.micro (Free Tier)
    ├─ Storage: S3 bucket (5GB Free Tier)
    ├─ Network: Default VPC, Security Groups
    └─ Monitoring: CloudWatch Logs (5GB Free Tier)

    MONTHLY COST: $0.00 (all Free Tier services)
    CREDIT BUFFER: $20 (Explore AWS) + $100 (Free Tier) = $120 total

    ════════════════════════════════════════════════════════════════════

    NEXT STEPS:
    [ ] Update security group SSH rule to your IP (replace 0.0.0.0/0)
    [ ] Create Route 53 DNS record pointing to ${aws_eip.api.public_ip}
    [ ] Set up ACM certificate for HTTPS
    [ ] Configure CloudWatch alarms for cost monitoring
    [ ] Enable VPC Flow Logs for security monitoring
    [ ] Back up RDS credentials to AWS Secrets Manager
    [ ] Set up automated RDS backups (already configured)

    COST MONITORING:
    - Visit: https://us-east-1.console.aws.amazon.com/billing/
    - Alert threshold: Set to $10 to catch any overages
    - Review monthly: AWS Cost Explorer

    ════════════════════════════════════════════════════════════════════
  EOT
}

# ============================================================================
# COST SUMMARY
# ============================================================================

output "cost_summary" {
  description = "Monthly cost breakdown"
  value = <<-EOT

    ESTIMATED MONTHLY COST (Year 1):

    Service                    | Monthly Cost | Free Tier Limit
    ──────────────────────────────────────────────────────────────
    EC2 t2.micro              | $0.00        | 750 hours/month
    RDS db.t3.micro           | $0.00        | 750 hours + 20GB
    ElastiCache cache.t3.micro| $0.00        | 750 hours
    S3 Standard               | $0.00        | 5GB/month
    CloudWatch Logs           | $0.00        | 5GB/month
    Data Transfer (egress)    | $0.00        | 1GB/month
    ──────────────────────────────────────────────────────────────
    TOTAL                     | $0.00        |

    AVAILABLE CREDITS:
    - Explore AWS Credit: $20.00
    - AWS Free Tier Credit: $100.00
    - TOTAL BUFFER: $120.00

    This budget allows for experimentation and cost validation.
    When Free Tier expires (month 13), estimated cost becomes $40-60/month.

    Cost escalation triggers:
    ✓ EC2 overages: ~$0.0116/hour per t2.micro
    ✓ RDS overages: ~$0.168/hour per db.t3.micro
    ✓ Data transfer: $0.09 per GB out (after 1GB free)

    Set CloudWatch alarms to detect these early!
  EOT
}
