# GitHub Secrets Setup Guide

This document lists all GitHub Secrets required for Rosier's CI/CD pipeline to function end-to-end.

## Overview

GitHub Secrets must be configured in your repository settings before any GitHub Actions workflows can deploy successfully. These secrets are used by:
1. **iOS CI/CD Pipeline** (.github/workflows/ios.yml)
2. **Backend CI/CD Pipeline** (.github/workflows/backend.yml)
3. **Marketing Stack Deploy** (.github/workflows/marketing.yml)

## Required Secrets

### AWS Credentials
Required for EC2, RDS, ElastiCache, ECR access.

| Secret Name | Description | Example | Required |
|-------------|-------------|---------|----------|
| `AWS_ACCESS_KEY_ID` | AWS IAM access key | `AKIAIOSFODNN7EXAMPLE` | ✓ All workflows |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM secret key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` | ✓ All workflows |
| `AWS_REGION` | AWS region (optional) | `us-east-1` | For backend deploy |
| `ECR_REGISTRY` | AWS ECR registry URL | `123456789012.dkr.ecr.us-east-1.amazonaws.com` | For backend Docker build |

### EC2 SSH Access
Required for deploying to EC2 instances via SSH.

| Secret Name | Description | Value | Required |
|-------------|-------------|-------|----------|
| `EC2_SSH_KEY` | Private SSH key (PEM format) | `-----BEGIN RSA PRIVATE KEY-----\n...` | ✓ Marketing deploy |
| `EC2_HOST` | EC2 instance public IP or hostname | `12.34.56.78` or `api.rosier.app` | For manual deployments |

**How to generate EC2_SSH_KEY:**
```bash
# If you have the .pem file (from deploy-to-aws.sh)
cat rosier-key.pem | base64 | tr -d '\n'
# Then paste into GitHub secret with newlines: \n between each line
# Or use this Python one-liner:
python3 -c "import sys; print(repr(open('rosier-key.pem').read()))"
```

### Apple App Store Connect
Required for iOS build signing and TestFlight/App Store deployment.

| Secret Name | Description | Value | Required |
|-------------|-------------|-------|----------|
| `APPLE_DEVELOPER_ID` | Apple Team ID | `52SKBHZK3L` | ✓ iOS builds |
| `IOS_CERTIFICATE_BASE64` | Base64-encoded signing certificate | See below | ✓ iOS builds |
| `IOS_CERT_PASSWORD` | Password for signing certificate | `your-cert-password` | ✓ iOS builds |
| `IOS_PROVISIONING_PROFILE_BASE64` | Base64-encoded provisioning profile | See below | ✓ iOS builds |

**How to generate Apple certificates:**

1. Export certificate from Keychain
2. Convert to base64:
```bash
# Certificate
base64 -i Certificates.p12 | tr -d '\n'

# Provisioning Profile
base64 -i Rosier.mobileprovision | tr -d '\n'
```

### App Store Connect API Key
Required for uploading builds to TestFlight and App Store.

| Secret Name | Description | Value | Required |
|-------------|-------------|-------|----------|
| `APP_STORE_CONNECT_KEY_ID` | ASC key ID | `ABC123DEFG` | ✓ iOS TestFlight/release |
| `APP_STORE_CONNECT_ISSUER_ID` | ASC issuer ID (team) | `12345678-1234-1234-1234-123456789012` | ✓ iOS TestFlight/release |
| `APP_STORE_CONNECT_PRIVATE_KEY` | ASC private key (p8 format) | `-----BEGIN PRIVATE KEY-----\n...` | ✓ iOS TestFlight/release |

**How to generate ASC API Key:**
1. Go to [App Store Connect](https://appstoreconnect.apple.com/access/api)
2. Create new API key
3. Download the .p8 file
4. For the private key secret:
```bash
cat AuthKey_ABC123DEFG.p8 | tr -d '\n' | sed 's/\\n/\n/g'
# Or base64 it:
base64 -i AuthKey_ABC123DEFG.p8 | tr -d '\n'
```

### Docker Registry
Required for pushing Docker images (either ECR or Docker Hub).

| Secret Name | Description | Value | Required |
|-------------|-------------|-------|----------|
| `DOCKER_USERNAME` | Docker Hub username | `your-dockerhub-user` | For Docker Hub |
| `DOCKER_TOKEN` | Docker Hub access token or ECR token | `dckr_pat_xxxxx` | For Docker Hub |

### Database & Cache URLs
Environment variables for backend (stored as secrets for production).

| Secret Name | Description | Example | Where Used |
|-------------|-------------|---------|-----------|
| `DATABASE_URL` | Production PostgreSQL connection | `postgresql+asyncpg://user:pass@rds-endpoint:5432/rosier` | Backend production |
| `REDIS_URL` | Production Redis connection | `redis://redis-endpoint:6379/0` | Backend production |
| `JWT_SECRET_KEY` | JWT signing key (32+ chars) | `your-super-secret-key-min-32-chars-long` | Backend |
| `SECRET_KEY` | Django/app secret key (32+ chars) | `another-secret-key-min-32-chars-long` | Backend |

**Generate secrets securely:**
```bash
# Generate cryptographically secure keys
openssl rand -base64 32  # For JWT_SECRET_KEY
python3 -c "import secrets; print(secrets.token_urlsafe(32))"
```

### Monitoring & Observability

| Secret Name | Description | Example | Required |
|-------------|-------------|---------|----------|
| `SENTRY_DSN` | Sentry error tracking | `https://key@sentry.io/123456` | Optional |
| `SLACK_WEBHOOK_URL` | Slack notifications | `https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX` | Optional |

## Setup Instructions

### Via GitHub Web UI

1. Go to your repository Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. For each secret below, enter:
   - **Name:** (exact secret name from tables above)
   - **Value:** (the secret value)
4. Click "Add secret"

### Via GitHub CLI

```bash
# Install GitHub CLI: https://cli.github.com

# Create all secrets at once
gh secret set AWS_ACCESS_KEY_ID --body "YOUR_ACCESS_KEY"
gh secret set AWS_SECRET_ACCESS_KEY --body "YOUR_SECRET_KEY"
gh secret set AWS_REGION --body "us-east-1"
gh secret set ECR_REGISTRY --body "123456789012.dkr.ecr.us-east-1.amazonaws.com"

gh secret set EC2_SSH_KEY --body "$(cat rosier-key.pem)"
gh secret set EC2_HOST --body "12.34.56.78"

# Apple secrets
gh secret set APPLE_DEVELOPER_ID --body "52SKBHZK3L"
gh secret set IOS_CERTIFICATE_BASE64 --body "$(base64 -i Certificates.p12 | tr -d '\n')"
gh secret set IOS_CERT_PASSWORD --body "cert_password"
gh secret set IOS_PROVISIONING_PROFILE_BASE64 --body "$(base64 -i Rosier.mobileprovision | tr -d '\n')"

# App Store Connect
gh secret set APP_STORE_CONNECT_KEY_ID --body "ABC123DEFG"
gh secret set APP_STORE_CONNECT_ISSUER_ID --body "12345678-1234-1234-1234-123456789012"
gh secret set APP_STORE_CONNECT_PRIVATE_KEY --body "$(cat AuthKey_ABC123DEFG.p8)"

# Backend/Database
gh secret set DATABASE_URL --body "postgresql+asyncpg://user:pass@rds-endpoint:5432/rosier"
gh secret set REDIS_URL --body "redis://redis-endpoint:6379/0"
gh secret set JWT_SECRET_KEY --body "$(openssl rand -base64 32)"
gh secret set SECRET_KEY --body "$(openssl rand -base64 32)"
```

## Validation Checklist

Before running workflows, verify all required secrets are set:

```bash
# List all secrets (shows names but not values)
gh secret list

# Required secrets for backend.yml:
# ✓ AWS_ACCESS_KEY_ID
# ✓ AWS_SECRET_ACCESS_KEY
# ✓ ECR_REGISTRY (optional, can use Docker Hub)
# ✓ DATABASE_URL
# ✓ REDIS_URL
# ✓ JWT_SECRET_KEY
# ✓ SECRET_KEY

# Required secrets for ios.yml:
# ✓ APPLE_DEVELOPER_ID
# ✓ IOS_CERTIFICATE_BASE64
# ✓ IOS_CERT_PASSWORD
# ✓ IOS_PROVISIONING_PROFILE_BASE64
# ✓ APP_STORE_CONNECT_KEY_ID
# ✓ APP_STORE_CONNECT_ISSUER_ID
# ✓ APP_STORE_CONNECT_PRIVATE_KEY

# Required secrets for marketing.yml:
# ✓ AWS_ACCESS_KEY_ID
# ✓ AWS_SECRET_ACCESS_KEY
# ✓ EC2_SSH_KEY
```

## Environment-Specific Secrets

For multiple environments (staging, production), you can:

1. **Option A:** Use GitHub Environments
   - Go to Settings → Environments
   - Create "staging" and "production" environments
   - Add environment-specific secrets to each

2. **Option B:** Naming convention
   - `AWS_ACCESS_KEY_ID_PROD`
   - `AWS_ACCESS_KEY_ID_STAGING`

## Security Best Practices

1. **Rotation Schedule:**
   - Rotate database passwords: Every 90 days
   - Rotate API keys: Every 180 days
   - Rotate JWT secrets: On every major deployment

2. **Principle of Least Privilege:**
   - AWS IAM user should only have permissions needed for deployments
   - Don't use root AWS credentials
   - Use ECR for Docker images (more secure than Docker Hub)

3. **Secret Storage:**
   - Never commit `.env` files to git
   - Use AWS Secrets Manager for runtime secrets
   - Use GitHub Secrets only for CI/CD

4. **Audit & Monitoring:**
   - Enable GitHub Actions audit logs
   - Monitor CloudTrail for AWS secret access
   - Rotate secrets immediately if leaked

## Troubleshooting

### "Secrets not found" error in workflow
- Ensure secret names match exactly (case-sensitive)
- Check secret is added to the correct repository
- For environment-specific secrets, verify the environment is correct

### Base64 encoding issues
If multi-line secrets fail (like PEM keys):
```bash
# Ensure newlines are preserved
cat key.pem | base64 -w 0  # No line wrapping
```

### SSH key authentication fails
- Ensure EC2_SSH_KEY includes the full PEM header/footer
- Test locally: `ssh -i key.pem ec2-user@host`
- Check EC2 security group allows SSH (port 22)

## References

- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [AWS IAM Setup for CI/CD](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html)
- [Apple Developer Account Setup](https://developer.apple.com/account/)
- [App Store Connect API Documentation](https://developer.apple.com/documentation/appstoreconnectapi)
