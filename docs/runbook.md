# Rosier Operational Runbook

**Production Operations Guide for Rosier Backend & Infrastructure**

Last Updated: April 2026

This runbook provides step-by-step procedures for common operations, incident response, and troubleshooting of the Rosier platform.

---

## 1. Service Architecture Overview

### 1.1 System Components

```
┌─────────────────────────────────────────────────────────────┐
│                    iOS App (Production)                      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  CloudFront (CDN)                            │
│              (Asset distribution & caching)                 │
└────────────────┬────────────────────────────┬────────────────┘
                 │                            │
                 ▼                            ▼
        ┌────────────────┐          ┌─────────────────┐
        │   S3 Bucket    │          │ Application ALB │
        │  (Static Assets)          │                 │
        └────────────────┘          └────────┬────────┘
                                             │
                                    ┌────────▼────────┐
                                    │  ECS Cluster    │
                                    │  (API Services) │
                                    └────────┬────────┘
                                             │
                    ┌────────────────────────┼────────────────────────┐
                    │                        │                        │
                    ▼                        ▼                        ▼
            ┌──────────────┐         ┌──────────────┐        ┌──────────────┐
            │  RDS Database│         │ ElastiCache  │        │ Elasticsearch│
            │ (PostgreSQL) │         │   (Redis)    │        │              │
            └──────────────┘         └──────────────┘        └──────────────┘
```

### 1.2 Key Services

| Service | Purpose | Technology |
|---------|---------|-----------|
| **ECS Fargate** | API and backend services | Docker containers |
| **RDS PostgreSQL** | Primary database | PostgreSQL 16.2 |
| **ElastiCache Redis** | Caching and session store | Redis 7 |
| **Elasticsearch** | Product search indexing | Elasticsearch 8.10 |
| **ALB** | Load balancing | AWS Application Load Balancer |
| **CloudFront** | Static asset delivery | CDN |
| **S3** | Asset storage | Object storage |
| **CloudWatch** | Monitoring and logs | AWS monitoring service |
| **EventBridge** | Scheduled tasks | Event scheduling |
| **Secrets Manager** | Credentials management | AWS Secrets Manager |

---

## 2. Common Operations

### 2.1 Deploy New Version

**Objective:** Deploy a new backend version to production with health checks and rollback capability.

**Prerequisites:**
- Code merged to main branch
- CI/CD pipeline passed
- Deployment approved

**Steps:**

1. **Trigger Deployment**
   ```bash
   cd backend/scripts
   ./deploy.sh production
   ```

2. **Monitor Deployment**
   - Watch CloudWatch dashboard for metrics
   - Check ECS service for task status
   - Verify API responding to health checks

3. **Verify Deployment**
   ```bash
   ./health_check.sh https://api.rosier.app
   ```

4. **Expected Output**
   - All health checks pass
   - API latency < 500ms p95
   - Zero errors from health endpoint

5. **Rollback if Needed**
   ```bash
   ./rollback.sh production
   ```

**Monitoring After Deployment:**
- Watch ECS task metrics for 15 minutes
- Monitor error rate in CloudWatch
- Check application logs for exceptions
- Verify affiliate links still functional

### 2.2 Rollback a Deployment

**Objective:** Quickly revert to previous version if issues detected.

**Prerequisites:**
- Issue identified and verified
- Decision to rollback made
- Previous version known to be stable

**Steps:**

1. **Initiate Rollback**
   ```bash
   cd backend/scripts
   ./rollback.sh production
   ```

2. **Monitor Rollback**
   - Watch ECS task replacement
   - Verify health checks passing
   - Monitor for continued errors

3. **Verify Rollback**
   ```bash
   ./health_check.sh https://api.rosier.app
   ```

4. **Post-Rollback Actions**
   - Check if errors resolved
   - Gather logs and information
   - Schedule incident review
   - Notify stakeholders

**Important:**
- Rollback is fast (typically 5-10 minutes)
- No data loss occurs
- Previous users sessions preserved

### 2.3 Run Database Migration

**Objective:** Execute pending database migrations safely.

**Prerequisites:**
- Migration code reviewed
- Backup created (automatic via RDS)
- Deployment window scheduled

**Steps:**

1. **List Pending Migrations**
   ```bash
   cd backend/scripts
   ./migrate.sh staging status
   ```

2. **Preview Migration**
   ```bash
   ./migrate.sh staging upgrade
   ```

3. **Confirm Migration**
   - Review the SQL preview
   - Check estimated impact
   - Type "yes" to proceed

4. **Monitor Migration**
   - Watch RDS in CloudWatch
   - Monitor connection count
   - Check query performance

5. **Verify Success**
   ```bash
   ./migrate.sh staging current
   ```

**Rollback Migration if Needed:**
```bash
./migrate.sh staging downgrade 1
```

**Important:**
- Always test migrations in staging first
- Run during low-traffic windows
- Have rollback plan ready
- Monitor database performance

### 2.4 Scale ECS Tasks Up/Down

**Objective:** Adjust API server capacity to handle load.

**Prerequisites:**
- Understand current load
- Know traffic patterns
- Permission to modify infrastructure

**Scale Up (Add Tasks):**

1. **Via AWS Console**
   - Go to ECS > Clusters > rosier-production
   - Select rosier-api service
   - Update desired count (default 2, max 4)
   - Click "Update Service"

2. **Via AWS CLI**
   ```bash
   aws ecs update-service \
     --cluster rosier-production \
     --service rosier-api \
     --desired-count 4 \
     --region us-east-1
   ```

3. **Monitor New Tasks**
   - Watch CloudWatch for new tasks starting
   - Verify health checks passing
   - Monitor CPU/memory metrics

**Scale Down (Remove Tasks):**
- Only during low traffic periods
- Same process, set desired-count lower
- Existing users not affected (graceful shutdown)

**Auto-Scaling:**
- Auto-scaling enabled: scales 2-4 tasks
- CPU > 70% triggers scale-up
- Scales up at rate of 1 task/minute

### 2.5 Flush Redis Cache

**Objective:** Clear all cached data to reset system state.

**Prerequisites:**
- Understand impact (performance may degrade temporarily)
- Low traffic period preferred

**Steps:**

1. **Connect to Redis**
   ```bash
   aws elasticache describe-cache-clusters \
     --cache-cluster-id rosier-redis \
     --region us-east-1
   ```

2. **Via Redis CLI (if connected to private subnet)**
   ```bash
   redis-cli -h rosier-redis.xxxxx.ng.0001.use1.cache.amazonaws.com -p 6379
   > FLUSHALL
   > QUIT
   ```

3. **Via AWS Console**
   - ElastiCache > Memcache/Redis
   - Select rosier-redis
   - Actions > Flush Cache
   - Confirm warning

4. **Monitor Impact**
   - Watch request latency increase temporarily
   - Monitor cache miss rate
   - Verify system recovers within 5 minutes

**Important:**
- Only flush if absolutely necessary
- Coordinates with team before flushing
- Performance impact: 10-15% slower for 5 mins

### 2.6 Reindex Elasticsearch

**Objective:** Rebuild search indices to refresh product data.

**Prerequisites:**
- Elasticsearch cluster healthy
- Planned during low traffic

**Steps:**

1. **Create New Index**
   ```bash
   curl -X POST "api.rosier.app/search/reindex" \
     -H "Authorization: Bearer $(aws secretsmanager get-secret-value \
       --secret-id rosier-api-token --query 'SecretString' -o text)"
   ```

2. **Monitor Reindexing**
   - Check Elasticsearch metrics in CloudWatch
   - Verify indexing rate
   - Monitor disk usage

3. **Switch to New Index**
   ```bash
   curl -X POST "api.rosier.app/search/activate-index"
   ```

4. **Verify Search Works**
   - Test search functionality in app
   - Check response times
   - Verify accurate results

**Reindexing Duration:**
- Full reindex: 30-60 minutes
- During reindex: searches use old index
- No user-facing downtime

### 2.7 Rotate Secrets

**Objective:** Update API keys, database passwords, and credentials.

**Prerequisites:**
- Coordination with engineering team
- Secrets securely generated
- Rollback plan understood

**Steps:**

1. **Generate New Secret**
   ```bash
   openssl rand -base64 32
   ```

2. **Update in Secrets Manager**
   ```bash
   aws secretsmanager create-secret-version \
     --secret-id rosier-secrets \
     --secret-string '{"JWT_SECRET_KEY":"new-secret-key"}' \
     --region us-east-1
   ```

3. **Update ECS Task Definition**
   - Go to ECS Task Definitions
   - Create new revision
   - Update secret references
   - Register new revision

4. **Force Redeployment**
   ```bash
   aws ecs update-service \
     --cluster rosier-production \
     --service rosier-api \
     --force-new-deployment \
     --region us-east-1
   ```

5. **Monitor Deployment**
   - Watch tasks redeploy
   - Verify health checks pass
   - Monitor for auth errors

### 2.8 Add New Retailer to Affiliate Feeds

**Objective:** Integrate a new retailer's product feed into Rosier.

**Prerequisites:**
- Affiliate agreement signed
- API credentials obtained
- Product feed format documented

**Steps:**

1. **Add Retailer Configuration**
   ```python
   # backend/app/config/retailers.py
   RETAILERS = {
       "new_retailer": {
           "name": "New Retailer",
           "affiliate_network": "Rakuten",
           "api_endpoint": "https://api.newretailer.com/v1/products",
           "api_key": "***from-secrets***",
           "commission_rate": 0.08,
           "active": False,  # Start disabled
           "categories": ["footwear", "handbags", "accessories"]
       }
   }
   ```

2. **Deploy Configuration Change**
   ```bash
   ./deploy.sh staging
   ./deploy.sh production
   ```

3. **Sync Product Feed**
   ```bash
   # Manually trigger via EventBridge
   aws events put-events \
     --entries '[{"Source":"manual","DetailType":"sync-feed","Detail":"{\"retailer\":\"new_retailer\"}"}]'
   ```

4. **Monitor Feed Sync**
   - Check CloudWatch logs for ingestion
   - Verify products indexed in Elasticsearch
   - Spot check product data quality

5. **Enable in Production**
   - Update configuration: `active: True`
   - Deploy change
   - Monitor for 1 hour
   - Verify affiliate links working

### 2.9 Add Brand to Fashion Roster

**Objective:** Add a new brand to Rosier's curated selection.

**Prerequisites:**
- Brand approved for inclusion
- Brand meets quality standards
- Affiliate feed available

**Steps:**

1. **Create Brand Profile**
   ```python
   # backend/app/models/brands.py
   brand = Brand(
       name="New Designer Brand",
       slug="new-designer-brand",
       description="Premium niche fashion brand",
       logo_url="https://assets.rosier.app/brands/...",
       website="https://newbrand.com",
       aesthetic_tags=["minimalist", "sustainable"],
       price_range="premium",
       active=True
   )
   db.session.add(brand)
   db.session.commit()
   ```

2. **Run Database Migration**
   ```bash
   ./migrate.sh production
   ```

3. **Index in Elasticsearch**
   ```bash
   curl -X POST "api.rosier.app/brands/sync" \
     -H "Authorization: Bearer $API_TOKEN"
   ```

4. **Verify in App**
   - Test filters show new brand
   - Verify products appear in recommendations
   - Check brand page loads correctly

### 2.10 Pause/Unpause Brand

**Objective:** Temporarily disable a brand from being shown to users.

**Prerequisites:**
- Reason for pause documented
- Users with saved items notified

**Steps:**

1. **Update Brand Status**
   ```bash
   curl -X PATCH "api.rosier.app/brands/{brand_id}" \
     -H "Authorization: Bearer $API_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"active": false}'
   ```

2. **Clear Cache**
   ```bash
   curl -X POST "api.rosier.app/cache/clear" \
     -H "Authorization: Bearer $API_TOKEN" \
     -d '{"brand_id": "brand_id"}'
   ```

3. **Reindex Search**
   ```bash
   curl -X POST "api.rosier.app/search/reindex"
   ```

4. **Verify in App**
   - Brand no longer appears in discovery
   - Products hidden from search
   - Users' saved items remain (just hidden)

5. **Resume When Ready**
   - Same process, set `active: true`
   - Re-enable in caches
   - Reindex

---

## 3. Incident Response

### 3.1 API Latency Spike

**Symptoms:**
- p95 latency > 500ms
- User reports slow app
- CloudWatch alarm triggered

**Diagnosis Steps:**

1. **Check Current Metrics**
   ```bash
   # Via CloudWatch dashboard
   # Look at: API latency, error rate, ECS metrics
   ```

2. **Check RDS Performance**
   ```bash
   # RDS dashboard - look for:
   # - Database connections (should be < 80)
   # - Query latency
   # - CPU utilization
   ```

3. **Check Redis Performance**
   ```bash
   # ElastiCache - look for:
   # - Memory usage
   # - Hit rate (should be > 90%)
   # - Network bandwidth
   ```

4. **Check ECS Task Metrics**
   ```bash
   # ECS - look for:
   # - CPU utilization
   # - Memory utilization
   # - Task count
   ```

**Resolution (Choose Based on Root Cause):**

**If High Database Load:**
- Scale RDS up (through console)
- Kill long-running queries
- Check slow query logs
- Optimize N+1 queries if found

**If High Cache Misses:**
- Check Redis for memory pressure
- Increase Redis node size
- Verify cache hit-rate strategy
- Check for cache invalidation bugs

**If High CPU/Memory on ECS:**
- Scale ECS tasks up
- Check for memory leaks (application logs)
- Profile application if needed
- Consider code optimization

**Immediate Actions (All Cases):**
1. Page on-call engineer
2. Notify stakeholders
3. Scale ECS up (usually helps)
4. Monitor for recovery

### 3.2 Database Connection Exhaustion

**Symptoms:**
- "Too many connections" errors
- API returning 503 errors
- Connection pool warnings in logs

**Diagnosis:**
```bash
# Check current connections
aws rds describe-db-instances \
  --db-instance-identifier rosier-db \
  --query 'DBInstances[0].DBInstanceStatus'

# View connection count in CloudWatch
# DatabaseConnections metric > 80 (of max 100)
```

**Resolution:**

1. **Kill Idle Connections (Temporary)**
   ```bash
   # Via RDS console or psql if you have access
   # Select * FROM pg_stat_activity;
   # SELECT pg_terminate_backend(pid) FROM pg_stat_activity
   #   WHERE state = 'idle' AND pid <> pg_backend_pid();
   ```

2. **Check for Connection Leaks**
   - Look for unclosed database connections in code
   - Check if thread pool is misconfigured
   - Review recent code changes

3. **Scale Database**
   - Increase max_connections in parameter group
   - Scale RDS instance class up
   - Enable read replicas for read-heavy workloads

4. **Long-Term Fix**
   - Implement connection pooling (PgBouncer)
   - Review and fix connection leaks in code
   - Add metrics/alerts for connection usage

### 3.3 Redis Out of Memory (OOM)

**Symptoms:**
- Redis eviction errors
- Cache misses spiking
- Recommendation quality degrading

**Diagnosis:**
```bash
# Check Redis memory usage
aws elasticache describe-cache-nodes \
  --cache-cluster-id rosier-redis \
  --query 'CacheNodes[0].CacheNodeCreateTime'
```

**Resolution:**

1. **Immediate:**
   - Scale Redis node size up
   - Clear low-priority caches (flush expired keys)
   - Reduce TTL on non-critical cache keys

2. **Investigate What's Using Memory:**
   - Check what's being cached
   - Identify large cache values
   - Look for memory leaks in caching code

3. **Long-Term:**
   - Implement cache eviction policy (LRU recommended)
   - Add memory monitoring and alerts
   - Review cache key patterns
   - Consider tiered caching strategy

### 3.4 Affiliate Links Returning 404

**Symptoms:**
- Users report "product not found" on retailer site
- Affiliate links broken
- Error spike in logs

**Diagnosis:**
1. **Test Affiliate Link**
   - Click link in app
   - Verify destination URL
   - Check if product exists on retailer site

2. **Check Product Feed**
   - Review affiliate feed freshness
   - Verify product was in last sync
   - Check feed update schedule

**Resolution:**

1. **Immediate (Temporary Fix):**
   - Mark affected products as inactive
   - Remove from recommendations
   - Alert users via notification

2. **Investigate Root Cause:**
   - Check if retailer changed product URLs
   - Verify affiliate feed sync running
   - Look for pattern (specific brand, category)

3. **Permanent Fix:**
   - Update product feed handling for URL changes
   - Implement product availability checking
   - Add alert for high 404 rate

4. **Contact Retailer/Affiliate Network:**
   - Notify of issue
   - Request investigation
   - Update feed format if changed

### 3.5 Card Queue Empty

**Symptoms:**
- Users see "No more products" message
- Empty card queue warning in logs
- Recommendation service might be down

**Diagnosis:**
1. **Check Recommendation Service**
   ```bash
   # Check if recommendation generation running
   # Check CloudWatch logs for errors
   ```

2. **Check Product Count**
   - Verify products in database
   - Check Elasticsearch index health
   - Verify feed sync recent

**Resolution:**

1. **Immediate Fallback:**
   - Switch to popularity-based sorting
   - Show previously-unseen products
   - Show products from favorite brands

2. **Fix Recommendation Service:**
   - Restart recommendation generation job
   - Check for errors in generation code
   - Verify feature store data available

3. **Verify Product Data:**
   - Check product count trending
   - Verify feed imports running
   - Check for data quality issues

4. **Long-Term:**
   - Implement queue buffer/backlog
   - Add predictive alerts for low queue
   - Improve recommendation generation efficiency

### 3.6 App Store Rejection

**Symptoms:**
- App rejected by Apple review team
- Message in App Store Connect

**Common Rejection Reasons & Fixes:**

**Reason: Functionality Issues**
- Fix: Test thoroughly, provide detailed testing notes
- Check: Works on iOS 14.0+, no crashes

**Reason: Misleading Metadata**
- Fix: Update description to match actual features
- Check: Screenshots match actual app UI

**Reason: Privacy/Tracking Not Disclosed**
- Fix: Update Privacy Policy with complete disclosures
- Check: Privacy Nutrition Label accurate

**Reason: Affiliate Links Not Disclosed**
- Fix: Add prominent affiliate disclosure
- Check: FTC compliance clear

**Response Process:**
1. Read rejection reason carefully
2. Identify root cause
3. Fix the specific issue
4. Update version/build
5. Resubmit with detailed explanation
6. Wait for re-review (typically 24-48 hours)

---

## 4. Scheduled Maintenance

### 4.1 Product Ingestion (Hourly)

**Schedule:** Every hour via EventBridge

**Steps:**
1. Trigger feed sync for all active retailers
2. Download latest product feeds
3. Update product database
4. Reindex Elasticsearch
5. Clear product cache

**Monitoring:**
- Check CloudWatch for ingestion errors
- Verify product count increasing over time
- Monitor feed sync duration (should be < 15 minutes)

### 4.2 Price Monitoring (Every 4 Hours)

**Schedule:** Every 4 hours via EventBridge

**Steps:**
1. Check prices for active products
2. Identify significant changes
3. Flag suspiciously low prices
4. Update affiliate links if products moved

**Alerts:**
- Large price drops (> 50%)
- Price increases on popular items
- Products unavailable/discontinued

### 4.3 ML Model Retraining (Nightly)

**Schedule:** 2 AM UTC daily

**Process:**
1. Collect user interaction data (past 7 days)
2. Retrain recommendation models
3. Evaluate model performance
4. Deploy if improvement detected
5. Monitor prediction accuracy

**Checks:**
- Verify training job completion
- Validate model metrics
- Monitor new model performance in production

### 4.4 Database Backups

**Automated by RDS:**
- Daily automated backups at 3 AM UTC
- 7-day retention
- Multi-AZ snapshots
- Point-in-time recovery enabled

**Manual Backups:**
- Monthly snapshot on 1st of month
- Retention: 30 days
- Before major deployments

**Restore Procedure:**
- Restore from automated backup in AWS console
- Or from manual snapshot
- Typical restore time: 5-10 minutes

### 4.5 Log Rotation

**API Logs:**
- Retention: 30 days
- Rotation: Daily
- Storage: CloudWatch Logs

**Ingestion/ML Logs:**
- Retention: 90 days
- Rotation: Daily
- Storage: S3

**Access Logs:**
- Retention: 30 days
- Location: S3

---

## 5. Contacts and Escalation

### 5.1 PagerDuty Escalation Policy

**On-Call Engineer:**
- Primary: Engineering Lead
- Escalation (15 min): Backend Team Lead
- Escalation (30 min): VP Engineering

**Alert Routing:**
- P1 (Critical): Immediate page
- P2 (High): Page after 10 minutes
- P3 (Medium): Daily digest

### 5.2 Slack Channels

| Channel | Purpose | Members |
|---------|---------|---------|
| #alerts | Real-time production alerts | All engineers |
| #deploys | Deployment notifications | Backend, DevOps |
| #builds | CI/CD pipeline status | All engineers |
| #incidents | Incident tracking | All engineers |

### 5.3 Key Contacts

| Role | Name | Email | Phone |
|------|------|-------|-------|
| Engineering Lead | [Name] | [Email] | [Phone] |
| DevOps Lead | [Name] | [Email] | [Phone] |
| Backend Lead | [Name] | [Email] | [Phone] |
| CTO | [Name] | [Email] | [Phone] |

### 5.4 External Contacts

| Service | Contact | Phone | Email |
|---------|---------|-------|-------|
| AWS Support | AWS TAM | [Number] | [Email] |
| Sentry Support | Support Team | [Number] | [Email] |
| DataDog | Support Team | [Number] | [Email] |

---

## 6. Quick Reference

### Common Commands

**Check System Health:**
```bash
./health_check.sh https://api.rosier.app
```

**Deploy:**
```bash
./deploy.sh production
```

**Rollback:**
```bash
./rollback.sh production
```

**Run Migrations:**
```bash
./migrate.sh production upgrade
```

**View Logs:**
```bash
# Via CloudWatch Console
# Or: aws logs tail /ecs/rosier --follow
```

### Important URLs

- **AWS Console:** https://console.aws.amazon.com
- **App Store Connect:** https://appstoreconnect.apple.com
- **CloudWatch:** https://console.aws.amazon.com/cloudwatch
- **PagerDuty:** https://rosier.pagerduty.com
- **Sentry:** https://sentry.io/organizations/rosier

### Useful Dashboards

- Production Dashboard: CloudWatch > Dashboards > Rosier-Production
- ECS Service: ECS > Clusters > rosier-production > Services > rosier-api
- RDS Database: RDS > Databases > rosier-db
- Logs: CloudWatch Logs > /ecs/rosier

---

## 7. Troubleshooting Guide

### API Not Responding

**Quick Checks:**
1. Check ALB health in EC2 > Load Balancers
2. Check ECS tasks running: ECS > rosier-production > rosier-api
3. Check CloudWatch logs for exceptions
4. Check RDS connection pool exhaustion

**Resolution:**
- Restart ECS service: `aws ecs update-service --cluster rosier-production --service rosier-api --force-new-deployment`
- Scale up ECS tasks if CPU high
- Check database connections

### High Error Rate

**First Steps:**
1. Check error type in CloudWatch logs
2. Check if related to specific endpoint
3. Check if new deployment caused it

**If Recent Deployment:**
- Rollback immediately: `./rollback.sh production`

**If Database Issues:**
- Check connection count
- Check slow query log
- Run migrations if needed

### Performance Issues

**Check (In Order):**
1. ECS CPU/Memory utilization
2. RDS connections and latency
3. Redis hit rate
4. Elasticsearch query performance
5. ALB response time

**Scale Appropriately:**
- High CPU: Scale ECS tasks up
- High DB connections: Kill idle, scale DB
- High Redis memory: Scale Redis up

---

**Last Updated:** April 2026
**Next Review:** July 2026
**Owner:** Engineering Team
