# Budget-optimized variables for Free Tier AWS deployment

variable "aws_region" {
  description = "AWS region (must be us-east-1 for optimal Free Tier)"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "rosier"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC (use default VPC if not specified)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "use_default_vpc" {
  description = "Use default VPC to save costs (recommended for MVP)"
  type        = bool
  default     = true
}

variable "availability_zones" {
  description = "Availability zones (single AZ for cost savings)"
  type        = list(string)
  default     = ["us-east-1a"]
}

# EC2 Configuration - t2.micro (Free Tier)
variable "ec2_instance_type" {
  description = "EC2 instance type (t2.micro is Free Tier eligible)"
  type        = string
  default     = "t2.micro"
}

variable "ec2_root_volume_size" {
  description = "Root volume size in GB (30GB is Free Tier limit)"
  type        = number
  default     = 30
}

variable "ec2_root_volume_type" {
  description = "EBS volume type"
  type        = string
  default     = "gp3"
}

variable "enable_ec2_detailed_monitoring" {
  description = "Enable detailed EC2 monitoring (costs extra, not recommended)"
  type        = bool
  default     = false
}

# RDS Configuration - db.t3.micro (Free Tier)
variable "rds_instance_class" {
  description = "RDS instance class (db.t3.micro is Free Tier eligible)"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16.1"
}

variable "rds_allocated_storage" {
  description = "Allocated storage in GB (20GB is Free Tier limit)"
  type        = number
  default     = 20
}

variable "rds_storage_type" {
  description = "Storage type (gp3 is cheaper than gp2)"
  type        = string
  default     = "gp3"
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ (costs extra, not recommended for MVP)"
  type        = bool
  default     = false
}

variable "rds_backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "rds_publicly_accessible" {
  description = "Make RDS publicly accessible (not recommended)"
  type        = bool
  default     = false
}

variable "database_name" {
  description = "Initial database name"
  type        = string
  default     = "rosier"
}

variable "database_username" {
  description = "RDS master username"
  type        = string
  sensitive   = true
  default     = "postgres"
}

variable "database_password" {
  description = "RDS master password (must be set via environment variable)"
  type        = string
  sensitive   = true
}

# ElastiCache Configuration - cache.t3.micro (Free Tier)
variable "elasticache_instance_class" {
  description = "ElastiCache instance class (cache.t3.micro is Free Tier eligible)"
  type        = string
  default     = "cache.t3.micro"
}

variable "elasticache_engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.0"
}

variable "elasticache_num_cache_nodes" {
  description = "Number of cache nodes (1 for single-node, no replication for cost savings)"
  type        = number
  default     = 1
}

variable "elasticache_automatic_failover" {
  description = "Enable automatic failover (requires 2+ nodes)"
  type        = bool
  default     = false
}

variable "elasticache_param_group_name" {
  description = "Parameter group name for Redis"
  type        = string
  default     = "default.redis7"
}

# S3 Configuration
variable "s3_bucket_name" {
  description = "S3 bucket name for assets (must be globally unique)"
  type        = string
  default     = ""
}

variable "s3_enable_versioning" {
  description = "Enable S3 versioning (not required for MVP)"
  type        = bool
  default     = false
}

variable "s3_enable_encryption" {
  description = "Enable S3 encryption"
  type        = bool
  default     = true
}

# Networking Configuration
variable "domain_name" {
  description = "Domain name (optional, for future DNS setup)"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ACM certificate ARN (optional)"
  type        = string
  default     = ""
}

# Monitoring Configuration
variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch logs"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days (30 days is within Free Tier)"
  type        = number
  default     = 30
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring (costs extra)"
  type        = bool
  default     = false
}

# Common tags
variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "Rosier"
    Environment = "mvp"
    ManagedBy   = "Terraform"
    CostCenter  = "Bootstrap"
  }
}

# Application Configuration
variable "container_port" {
  description = "Container port for FastAPI"
  type        = number
  default     = 8000
}

variable "docker_image_uri" {
  description = "Docker image URI (can be built from source)"
  type        = string
  default     = "python:3.12-slim"
}

variable "django_secret_key" {
  description = "Django secret key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "jwt_secret_key" {
  description = "JWT secret key for authentication"
  type        = string
  sensitive   = true
  default     = ""
}

variable "sentry_dsn" {
  description = "Sentry DSN for error tracking (optional)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "enable_sentry" {
  description = "Enable Sentry error tracking"
  type        = bool
  default     = false
}
