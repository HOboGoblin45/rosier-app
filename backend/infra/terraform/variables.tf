"""Terraform variables for AWS infrastructure."""

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "rosier"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "container_port" {
  description = "Container port"
  type        = number
  default     = 8000
}

variable "container_cpu" {
  description = "CPU units for ECS task"
  type        = number
  default     = 2048
}

variable "container_memory" {
  description = "Memory for ECS task in MB"
  type        = number
  default     = 4096
}

variable "desired_task_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 2
}

variable "database_name" {
  description = "RDS database name"
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
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "database_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.r6g.large"
}

variable "database_multi_az" {
  description = "Enable RDS Multi-AZ"
  type        = bool
  default     = true
}

variable "redis_instance_class" {
  description = "ElastiCache instance class"
  type        = string
  default     = "cache.r6g.large"
}

variable "redis_engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.0"
}

variable "redis_num_cache_nodes" {
  description = "Number of Redis cache nodes"
  type        = number
  default     = 2
}

variable "s3_bucket_name" {
  description = "S3 bucket name for assets"
  type        = string
  default     = "rosier-assets"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "api.rosierapp.com"
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
  default     = ""
}

variable "docker_image_uri" {
  description = "Docker image URI for ECS"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention days"
  type        = number
  default     = 30
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default = {
    Project     = "Rosier"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
