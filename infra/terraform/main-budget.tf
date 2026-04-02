# Budget-optimized AWS infrastructure for Rosier MVP
# Uses Free Tier: EC2 t2.micro + RDS db.t3.micro + ElastiCache cache.t3.micro
# Total cost: $0/month for 12 months

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Note: Use local backend for development, migrate to S3 for team usage
  # backend "s3" {
  #   bucket         = "rosier-terraform-state"
  #   key            = "dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

# ============================================================================
# VPC & NETWORKING (Using Default VPC for cost savings)
# ============================================================================

data "aws_vpc" "default" {
  count   = var.use_default_vpc ? 1 : 0
  default = true
}

data "aws_subnets" "default" {
  count = var.use_default_vpc ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default[0].id]
  }
}

# If creating custom VPC (not recommended for cost savings)
resource "aws_vpc" "main" {
  count            = var.use_default_vpc ? 0 : 1
  cidr_block       = var.vpc_cidr
  enable_dns_names = true
  enable_dns_support = true

  tags = {
    Name = "${var.app_name}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  count  = var.use_default_vpc ? 0 : 1
  vpc_id = aws_vpc.main[0].id

  tags = {
    Name = "${var.app_name}-igw"
  }
}

# ============================================================================
# SECURITY GROUPS
# ============================================================================

# EC2 Security Group - Allow SSH, HTTP, HTTPS
resource "aws_security_group" "ec2" {
  name_prefix = "${var.app_name}-ec2-"
  description = "Security group for EC2 instance"
  vpc_id      = var.use_default_vpc ? data.aws_vpc.default[0].id : aws_vpc.main[0].id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # TODO: Restrict to your IP in production
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # For direct API access during dev
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-ec2-sg"
  }
}

# RDS Security Group - Allow PostgreSQL from EC2 only
resource "aws_security_group" "rds" {
  name_prefix = "${var.app_name}-rds-"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = var.use_default_vpc ? data.aws_vpc.default[0].id : aws_vpc.main[0].id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-rds-sg"
  }
}

# ElastiCache Security Group - Allow Redis from EC2 only
resource "aws_security_group" "elasticache" {
  name_prefix = "${var.app_name}-elasticache-"
  description = "Security group for ElastiCache Redis"
  vpc_id      = var.use_default_vpc ? data.aws_vpc.default[0].id : aws_vpc.main[0].id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-elasticache-sg"
  }
}

# ============================================================================
# EC2 INSTANCE (t2.micro - Free Tier eligible)
# ============================================================================

# Get the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# IAM Role for EC2 (to access RDS, ElastiCache, S3)
resource "aws_iam_role" "ec2_role" {
  name_prefix = "${var.app_name}-ec2-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.app_name}-ec2-role"
  }
}

# Allow EC2 to access S3
resource "aws_iam_role_policy" "ec2_s3_policy" {
  name_prefix = "${var.app_name}-ec2-s3-"
  role        = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ]
      Resource = [
        "arn:aws:s3:::${aws_s3_bucket.assets.id}",
        "arn:aws:s3:::${aws_s3_bucket.assets.id}/*"
      ]
    }]
  })
}

# Allow EC2 to write CloudWatch logs
resource "aws_iam_role_policy" "ec2_logs_policy" {
  name_prefix = "${var.app_name}-ec2-logs-"
  role        = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ]
      Resource = "arn:aws:logs:${var.aws_region}:*:*"
    }]
  })
}

# Allow EC2 to put CloudWatch metrics
resource "aws_iam_role_policy" "ec2_cloudwatch_policy" {
  name_prefix = "${var.app_name}-ec2-cw-"
  role        = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "cloudwatch:PutMetricData"
      ]
      Resource = "*"
    }]
  })
}

# Instance profile for EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name_prefix = "${var.app_name}-profile-"
  role        = aws_iam_role.ec2_role.name
}

# User data script to install Docker and Docker Compose
resource "aws_instance" "api" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.ec2_instance_type
  subnet_id                   = var.use_default_vpc ? data.aws_subnets.default[0].ids[0] : null
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  root_block_device {
    volume_type           = var.ec2_root_volume_type
    volume_size           = var.ec2_root_volume_size
    delete_on_termination = true
    encrypted             = false  # Encryption costs extra
  }

  monitoring = var.enable_ec2_detailed_monitoring  # Detailed monitoring costs extra

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    docker_image_uri = var.docker_image_uri
    app_name         = var.app_name
    region           = var.aws_region
  }))

  tags = {
    Name = "${var.app_name}-ec2"
  }

  depends_on = [
    aws_db_instance.postgres,
    aws_elasticache_cluster.redis
  ]
}

# Elastic IP for EC2 (free while attached)
resource "aws_eip" "api" {
  instance = aws_instance.api.id
  domain   = "vpc"

  tags = {
    Name = "${var.app_name}-eip"
  }

  depends_on = [aws_instance.api]
}

# ============================================================================
# RDS POSTGRESQL 16 (db.t3.micro - Free Tier eligible)
# ============================================================================

resource "aws_db_subnet_group" "default" {
  name       = "${var.app_name}-db-subnet-group"
  subnet_ids = var.use_default_vpc ? data.aws_subnets.default[0].ids : []

  tags = {
    Name = "${var.app_name}-db-subnet-group"
  }
}

resource "aws_db_instance" "postgres" {
  identifier              = "${var.app_name}-db"
  allocated_storage       = var.rds_allocated_storage
  storage_type            = var.rds_storage_type
  engine                  = "postgres"
  engine_version          = var.rds_engine_version
  instance_class          = var.rds_instance_class
  db_name                 = var.database_name
  username                = var.database_username
  password                = var.database_password
  db_subnet_group_name    = aws_db_subnet_group.default.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  publicly_accessible     = var.rds_publicly_accessible
  multi_az                = var.rds_multi_az
  backup_retention_period = var.rds_backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"
  skip_final_snapshot     = true  # For MVP; set to false in production
  storage_encrypted       = false  # Encryption costs extra

  parameter_group_name = "default.postgres16"

  # Disable cloudwatch enhanced monitoring to save costs
  monitoring_interval = 0

  # Copy tags to snapshots
  copy_tags_to_snapshot = true

  tags = {
    Name = "${var.app_name}-postgres"
  }

  depends_on = [
    aws_db_subnet_group.default
  ]
}

# ============================================================================
# ELASTICACHE REDIS 7 (cache.t3.micro - Free Tier eligible)
# ============================================================================

resource "aws_elasticache_subnet_group" "default" {
  name       = "${var.app_name}-elasticache-subnet-group"
  subnet_ids = var.use_default_vpc ? data.aws_subnets.default[0].ids : []

  tags = {
    Name = "${var.app_name}-elasticache-subnet-group"
  }
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.app_name}-redis"
  engine               = "redis"
  engine_version       = var.elasticache_engine_version
  node_type            = var.elasticache_instance_class
  num_cache_nodes      = var.elasticache_num_cache_nodes
  parameter_group_name = var.elasticache_param_group_name
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.default.name
  security_group_ids   = [aws_security_group.elasticache.id]
  snapshot_window      = "03:00-05:00"
  snapshot_retention_limit = 0  # No snapshots to save costs
  automatic_failover_enabled = var.elasticache_automatic_failover
  multi_az_enabled     = false  # Multi-AZ costs extra
  at_rest_encryption_enabled = false  # Encryption costs extra
  transit_encryption_enabled = false  # Encryption costs extra

  tags = {
    Name = "${var.app_name}-redis"
  }

  depends_on = [
    aws_elasticache_subnet_group.default
  ]
}

# ============================================================================
# S3 BUCKET (for assets/uploads)
# ============================================================================

resource "aws_s3_bucket" "assets" {
  bucket = var.s3_bucket_name != "" ? var.s3_bucket_name : "${var.app_name}-assets-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${var.app_name}-assets"
  }
}

resource "aws_s3_bucket_versioning" "assets" {
  count  = var.s3_enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.assets.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  count  = var.s3_enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"  # Free alternative to KMS
    }
  }
}

# Block public access to S3 (security best practice)
resource "aws_s3_bucket_public_access_block" "assets" {
  bucket = aws_s3_bucket.assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CORS configuration for S3 (allow app to access images)
resource "aws_s3_bucket_cors_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = ["*"]  # TODO: Restrict to app domain in production
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# ============================================================================
# CLOUDWATCH LOGS
# ============================================================================

resource "aws_cloudwatch_log_group" "ec2" {
  count             = var.enable_cloudwatch_logs ? 1 : 0
  name              = "/rosier/ec2/${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.app_name}-ec2-logs"
  }
}

resource "aws_cloudwatch_log_group" "rds" {
  count             = var.enable_cloudwatch_logs ? 1 : 0
  name              = "/rosier/rds/${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.app_name}-rds-logs"
  }
}

# ============================================================================
# DATA SOURCES
# ============================================================================

data "aws_caller_identity" "current" {}
