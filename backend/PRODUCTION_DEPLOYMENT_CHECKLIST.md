# Production Deployment Checklist

## Pre-Deployment Security Verification

This checklist ensures the Rosier API is properly configured and secured before production deployment.

### Bearer Token Authentication ✓

- [x] Bearer token extraction implemented correctly
  - Location: `app/core/security.py` - `extract_bearer_token()`
  - Validates Authorization header format
  - Returns proper 401 errors for invalid tokens

- [x] All protected endpoints use proper authentication
  - 8 endpoint files updated (auth, profile, cards, dresser, wallpaper, brand_discovery, referral, onboarding)
  - All use proper `Header()` parameter with Bearer token extraction
  - No more `Depends(lambda: "")` anti-patterns

- [x] JWT token validation in place
  - `verify_access_token()` checks token signature and expiry
  - Token type validation (access vs refresh)
  - Proper error handling

### Database & Models ✓

- [x] JSON type used for all array/dict fields
  - `style_archetypes`, `quiz_responses`, `preference_vector`, `settings`
  - Cross-database compatible (PostgreSQL, SQLite, MySQL)
  - No database-specific ARRAY types

- [x] Model relationships properly configured
  - Foreign keys defined correctly
  - Cascade delete/update rules set appropriately
  - Indexes created for performance

### Input Validation ✓

- [x] Pydantic schemas with field validators
  - Email validation (EmailStr)
  - Password length constraints (min_length=8)
  - Numeric range validation (ge, le)
  - String length limits (max_length)

- [x] Rate limiting middleware
  - Location: `app/middleware/rate_limiter.py`
  - Integrated in main app
  - Prevents brute force attacks

- [x] CORS configuration
  - Properly configured in `app/main.py`
  - Uses environment variables for flexibility
  - Credentials support enabled

### Logging & Monitoring ✓

- [x] Structured JSON logging
  - `pythonjsonlogger` configured
  - All operations logged with context
  - Ready for log aggregation services

- [x] Exception handling
  - Validation errors handled
  - General exception handler prevents info leakage
  - Proper HTTP status codes

- [x] Sentry integration
  - Configured in main.py
  - Optional DSN in settings
  - Error tracking ready

---

## Pre-Production Configuration Tasks

### Environment Variables

Before deploying to production, create a `.env` file with these values:

```bash
# Application
APP_NAME=Rosier
ENVIRONMENT=production

# Database - Use production database credentials
DATABASE_URL=postgresql+asyncpg://user:secure_password@prod-db.example.com:5432/rosier

# Redis - Use production Redis instance
REDIS_URL=redis://secure_password@prod-redis.example.com:6379/0

# Elasticsearch - Use production cluster
ELASTICSEARCH_URL=https://prod-elasticsearch.example.com:9200

# JWT Security - CRITICAL: Generate strong random key
JWT_SECRET_KEY=your-very-long-random-secret-key-minimum-32-characters-required
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=30

# Apple Sign-In
APPLE_TEAM_ID=your_team_id
APPLE_KEY_ID=your_key_id
APPLE_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----
APPLE_APP_ID=com.rosierapp.ios

# AWS/S3
AWS_REGION=us-east-1
S3_BUCKET=rosier-assets
CLOUDFRONT_DOMAIN=https://assets.rosierapp.com

# Analytics
MIXPANEL_TOKEN=your_mixpanel_token

# Sentry Error Tracking
SENTRY_DSN=https://your-sentry-dsn@sentry.io/project-id

# APNS Configuration
APNS_KEY_ID=your_apns_key_id
APNS_TEAM_ID=your_apns_team_id
APNS_KEY_PATH=/path/to/apns/AuthKey_XXXXX.p8

# CORS - List your production domains
CORS_ORIGINS=https://rosierapp.com,https://www.rosierapp.com,https://app.rosierapp.com

# Feature Flags
ENABLE_PRICE_MONITORING=true
ENABLE_PERSONALIZATION=true
ENABLE_ANALYTICS=true
```

### JWT Secret Key Generation

Generate a secure JWT secret key (minimum 32 characters):

```bash
# Using Python
python3 -c "import secrets; print(secrets.token_urlsafe(32))"

# Using OpenSSL
openssl rand -base64 32

# Using /dev/urandom
head -c 32 /dev/urandom | base64
```

Example output: `MYzV-K3_N8p9qL2xJ6w5rT4yUiO7pQ8sW1aB3cD5eF6gH9jK0lM2nO4pQ6rS8tU`

**CRITICAL**: Store this securely in your secrets manager (AWS Secrets Manager, HashiCorp Vault, etc.)

### Database Setup

1. **Create database**
   ```bash
   createdb rosier
   ```

2. **Run migrations**
   ```bash
   alembic upgrade head
   ```

3. **Verify tables created**
   ```bash
   # Connect to database and verify tables exist
   psql -d rosier -c "\dt"
   ```

### External Services Configuration

#### Redis
- [ ] Production Redis instance deployed
- [ ] Authentication configured
- [ ] Connection pooling enabled
- [ ] Persistence/backup configured
- [ ] Memory limits set appropriately

#### Elasticsearch
- [ ] Production cluster deployed
- [ ] Security configured (auth, SSL)
- [ ] Index lifecycle policies set
- [ ] Replication configured
- [ ] Monitoring enabled

#### PostgreSQL
- [ ] Production database deployed
- [ ] Backups configured (daily minimum)
- [ ] Replication/failover setup
- [ ] SSL connections enabled
- [ ] Connection pooling configured
- [ ] Monitoring alerts set

#### AWS S3
- [ ] Bucket created and configured
- [ ] IAM user created with S3 access
- [ ] Bucket policies set to private
- [ ] Versioning enabled
- [ ] Lifecycle policies configured
- [ ] CloudFront CDN configured

#### Sentry
- [ ] Project created
- [ ] DSN obtained
- [ ] Team members invited
- [ ] Alerts configured
- [ ] Integration with Slack/teams

---

## Docker Deployment

### Build Docker Image

```bash
# Build image
docker build -t rosier-api:latest .

# Tag for registry
docker tag rosier-api:latest your-registry/rosier-api:latest

# Push to registry
docker push your-registry/rosier-api:latest
```

### Docker Compose Production

Update `docker-compose.yml` for production:

```yaml
version: '3.9'

services:
  api:
    image: your-registry/rosier-api:latest
    ports:
      - "8000:8000"
    environment:
      ENVIRONMENT: production
      DATABASE_URL: postgresql+asyncpg://user:pass@postgres:5432/rosier
      REDIS_URL: redis://redis:6379/0
      ELASTICSEARCH_URL: http://elasticsearch:9200
      JWT_SECRET_KEY: ${JWT_SECRET_KEY}
      SENTRY_DSN: ${SENTRY_DSN}
    depends_on:
      - postgres
      - redis
      - elasticsearch
    restart: always
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: rosier
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: always

  redis:
    image: redis:7-alpine
    restart: always
    volumes:
      - redis_data:/data

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.0.0
    environment:
      discovery.type: single-node
      xpack.security.enabled: false
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
    restart: always

volumes:
  postgres_data:
  redis_data:
  elasticsearch_data:
```

---

## Kubernetes Deployment

### Secrets Management

```bash
# Create secret for JWT key
kubectl create secret generic rosier-secrets \
  --from-literal=JWT_SECRET_KEY="$(python3 -c 'import secrets; print(secrets.token_urlsafe(32))')" \
  --from-literal=DATABASE_URL="postgresql+asyncpg://user:pass@db:5432/rosier" \
  --from-literal=SENTRY_DSN="https://..."
```

### ConfigMap for Configuration

```bash
# Create ConfigMap for non-secret config
kubectl create configmap rosier-config \
  --from-literal=ENVIRONMENT=production \
  --from-literal=CORS_ORIGINS="https://rosierapp.com"
```

### Deployment Manifest Example

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rosier-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: rosier-api
  template:
    metadata:
      labels:
        app: rosier-api
    spec:
      containers:
      - name: api
        image: your-registry/rosier-api:latest
        ports:
        - containerPort: 8000
        env:
        - name: JWT_SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: rosier-secrets
              key: JWT_SECRET_KEY
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: rosier-secrets
              key: DATABASE_URL
        - name: ENVIRONMENT
          valueFrom:
            configMapKeyRef:
              name: rosier-config
              key: ENVIRONMENT
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 5
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
```

---

## SSL/TLS Configuration

### Using NGINX Reverse Proxy

```nginx
upstream api {
    server api:8000;
}

server {
    listen 443 ssl http2;
    server_name api.rosierapp.com;

    ssl_certificate /etc/ssl/certs/rosier.crt;
    ssl_certificate_key /etc/ssl/private/rosier.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name api.rosierapp.com;
    return 301 https://$server_name$request_uri;
}
```

### Using AWS ALB

- [ ] Create Application Load Balancer
- [ ] Configure HTTPS listener (port 443)
- [ ] Add ACM certificate
- [ ] Configure target group pointing to API
- [ ] Enable access logs to S3
- [ ] Configure WAF rules

---

## Monitoring & Alerting

### Application Metrics

```python
# Example metrics to monitor
- Request count and latency (p50, p95, p99)
- Error rate (4xx, 5xx)
- Database connection pool utilization
- Redis memory usage
- JWT token validation success rate
- Authentication failure rate
```

### CloudWatch Alarms (AWS)

```bash
# High error rate alarm
aws cloudwatch put-metric-alarm \
  --alarm-name rosier-api-high-errors \
  --alarm-description "Alert when error rate > 5%" \
  --metric-name ErrorRate \
  --namespace AWS/ApplicationELB \
  --threshold 5 \
  --evaluation-periods 2 \
  --period 300

# Database connection alarm
aws cloudwatch put-metric-alarm \
  --alarm-name rosier-db-connections \
  --metric-name DatabaseConnections \
  --threshold 80 \
  --alarm-actions arn:aws:sns:region:account:topic
```

### Health Check Endpoints

- [ ] `/health` - General health check
- [ ] `/api/v1/docs` - OpenAPI documentation
- [ ] `/api/v1/redoc` - ReDoc documentation

### Log Aggregation

- [ ] Configure CloudWatch Logs, DataDog, or ELK
- [ ] Set up log queries for errors
- [ ] Create dashboards for monitoring
- [ ] Set up alerts for critical errors

---

## Testing Before Production

### Load Testing

```bash
# Using Apache Bench
ab -n 10000 -c 100 -H "Authorization: Bearer $TOKEN" https://api.rosierapp.com/api/v1/profile

# Using k6
k6 run load-test.js
```

### Security Testing

- [ ] Run OWASP ZAP scan
- [ ] Verify no exposed secrets in logs
- [ ] Test SQL injection protection (Pydantic)
- [ ] Test CORS configuration
- [ ] Verify rate limiting works
- [ ] Test authentication boundary cases

### Functional Testing

- [ ] All endpoints respond correctly
- [ ] Token refresh works
- [ ] Token expiry enforced
- [ ] Database migrations applied
- [ ] External services reachable
- [ ] Error handling returns correct codes

---

## Post-Deployment Verification

### Immediate Post-Deployment

- [ ] Health check endpoint returns 200
- [ ] Can authenticate and get token
- [ ] Protected endpoints require valid token
- [ ] Invalid tokens rejected with 401
- [ ] Logs show no errors
- [ ] Monitoring dashboards show traffic

### First 24 Hours

- [ ] Monitor error rates
- [ ] Check database performance
- [ ] Verify external service integrations
- [ ] Monitor memory and CPU usage
- [ ] Review Sentry error reports
- [ ] Monitor authentication patterns

### First Week

- [ ] Performance metrics stable
- [ ] No unusual error patterns
- [ ] Database backups working
- [ ] Monitoring alerts functional
- [ ] Team trained on monitoring
- [ ] Runbook tested

---

## Rollback Procedure

If issues occur post-deployment:

```bash
# 1. Identify issue
# Check logs, metrics, and error reports

# 2. Immediate mitigation
# For critical issues: use previous stable image tag

docker pull your-registry/rosier-api:v1.0.0-stable
# Update deployment

# 3. Database rollback (if needed)
alembic downgrade -1

# 4. Notify team and stakeholders

# 5. Post-incident review
# Determine root cause
# Update deployment checklist if needed
```

---

## Ongoing Maintenance

- [ ] Monthly security updates
- [ ] Database maintenance (VACUUM, ANALYZE)
- [ ] Log rotation and cleanup
- [ ] Backup verification
- [ ] Dependency updates
- [ ] Performance optimization review
- [ ] Cost analysis and optimization

---

## Success Criteria

✓ All items checked
✓ Security verified
✓ Monitoring in place
✓ Team trained
✓ Runbooks documented
✓ Load testing passed
✓ 99.9% uptime SLA met
✓ Error rate < 0.1%
✓ P95 latency < 200ms
