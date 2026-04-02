# Rosier Backend: Cost Tracking & Budget Management

**Account**: AWS us-east-1
**Budget Period**: April 1, 2026 - March 31, 2027
**Total Available**: $120.00 ($20 Explore + $100 Free Tier)

---

## Cost Summary (as of April 1, 2026)

| Service | Limit | Usage | Cost | Status |
|---------|-------|-------|------|--------|
| **EC2 t2.micro** | 750 hrs/mo | 0 hrs | $0.00 | ✓ Available |
| **RDS db.t3.micro** | 750 hrs + 20GB | 0 hrs + 0GB | $0.00 | ✓ Available |
| **ElastiCache cache.t3.micro** | 750 hrs | 0 hrs | $0.00 | ✓ Available |
| **S3 Standard** | 5GB + 1GB/mo egress | 0GB | $0.00 | ✓ Available |
| **CloudWatch** | 5GB logs | 0GB | $0.00 | ✓ Available |
| **TOTAL** | — | — | **$0.00** | **✓ GREEN** |

---

## Monthly Cost Forecast

### Scenario 1: Normal Operation (Expected)

| Service | Monthly Usage | Cost | Free Tier? |
|---------|---------------|------|-----------|
| EC2 t2.micro | 720 hrs | $0.00 | Yes (750 hrs) |
| RDS db.t3.micro | 720 hrs + 10GB | $0.00 | Yes (750 hrs + 20GB) |
| ElastiCache cache.t3.micro | 720 hrs | $0.00 | Yes (750 hrs) |
| S3 | 2GB storage + 500MB egress | $0.00 | Yes (5GB + 1GB) |
| CloudWatch | 1GB logs | $0.00 | Yes (5GB) |
| | | **$0.00** | ✓ SAFE |

**Breakdown**:
- 720 hours/month assumes instance runs 24/7
- 10GB RDS storage is normal for MVP
- 500MB S3 egress is moderate traffic
- 1GB CloudWatch logs is verbose logging

### Scenario 2: Heavy Usage (if not careful)

| Service | Monthly Usage | Cost | Reason |
|---------|---------------|------|--------|
| EC2 t2.micro overage | 50 hrs over limit | $0.58 | Left running 24/7 |
| RDS db.t3.micro overage | 30GB data | $15.00 | Database bloat |
| Data transfer out | 10GB | $0.90 | Inefficient API |
| | | **$16.48** | ⚠️ OVER BUDGET |

**How to prevent**:
- Don't store unnecessary data
- Implement aggressive caching
- Optimize database queries
- Monitor data transfer

### Scenario 3: Worst Case (if everything breaks)

| Service | Monthly Usage | Cost | Reason |
|---------|---------------|------|--------|
| EC2 t2.micro overage | 30 days × 24 hrs | $8.70 | Always-on |
| RDS db.t3.micro overage | 500GB | $24.00 | Full database |
| Data transfer out | 50GB | $4.50 | No caching |
| Elastic IP (unused) | 1 IP | $3.60 | Not in use |
| Extra storage | various | $10.00 | Snapshots, etc |
| | | **$50.80** | 🔴 EXCEEDS BUDGET |

**Available buffer**: $120.00 covers this scenario 2.4x over

---

## Cost Monitoring Checklist

### Weekly Tasks
- [ ] Check EC2 CPU & memory usage
  ```bash
  aws cloudwatch get-metric-statistics \
    --namespace AWS/EC2 \
    --metric-name CPUUtilization \
    --dimensions Name=InstanceId,Value=i-xxx \
    --start-time 2026-04-01T00:00:00Z \
    --end-time 2026-04-07T00:00:00Z \
    --period 86400 \
    --statistics Average
  ```

- [ ] Check RDS storage usage
  ```bash
  aws cloudwatch get-metric-statistics \
    --namespace AWS/RDS \
    --metric-name FreeStorageSpace \
    --dimensions Name=DBInstanceIdentifier,Value=rosier-db \
    --start-time 2026-04-01T00:00:00Z \
    --end-time 2026-04-07T00:00:00Z \
    --period 86400 \
    --statistics Average
  ```

- [ ] Check S3 bucket size
  ```bash
  aws s3api list-objects-v2 \
    --bucket rosier-assets-ACCOUNT_ID \
    --summarize \
    --human-readable-summary
  ```

- [ ] Review CloudWatch logs volume
  ```bash
  aws logs describe-log-streams \
    --log-group-name /rosier/ec2/development \
    --query 'logStreams[*].[logStreamName,storedBytes]'
  ```

### Monthly Tasks
- [ ] Review AWS Cost Explorer
  ```bash
  # Visit:
  # https://us-east-1.console.aws.amazon.com/cost-management/home
  ```

- [ ] Compare actual vs forecast
  ```bash
  aws ce get-cost-and-usage \
    --time-period Start=2026-04-01,End=2026-04-30 \
    --granularity MONTHLY \
    --metrics UnblendedCost \
    --group-by Type=DIMENSION,Key=SERVICE
  ```

- [ ] Review billing notifications
  ```bash
  # Check AWS Billing email
  # Look for cost anomaly alerts
  ```

- [ ] Audit resource usage
  ```bash
  # Check for unused resources
  # Review security group rules
  # Look for orphaned volumes
  ```

---

## Cost Breakdown by Service

### EC2 (t2.micro)

**Free Tier Limit**:
- 750 hours/month
- 30GB EBS storage
- 1 Elastic IP (if attached)

**Monthly Cost Calculation**:
```
Hours/month = 30 days × 24 hrs = 720 hrs (within 750 limit)
On-demand price = $0.0116/hour (if over limit)
Cost if within limit = $0.00
Cost if over limit = (730 - 750) × $0.0116 = $0.23

Risk: Only if instance runs > 750 hours (30+ days)
```

**Tips to stay in Free Tier**:
- Set automatic start/stop schedules (if not 24/7)
- Monitor CPU usage (should be < 10% idle)
- Check for runaway processes (`docker stats`)

### RDS PostgreSQL (db.t3.micro)

**Free Tier Limit**:
- 750 hours/month
- 20GB storage
- 7-day automated backups (free)

**Monthly Cost Calculation**:
```
Storage = Allocated storage in GB
Hours = 750 (typically within limit if running 24/7)

Standard pricing if over 20GB:
$0.168/hour (db.t3.micro on-demand)
$0.12/GB-month (standard storage overage)

Example: 30GB = (30-20) × $0.12 = $1.20/month
```

**Tips to stay in Free Tier**:
- Monitor database size (`SELECT pg_database.datname, pg_size_pretty(pg_database.datsize)...`)
- Delete old data regularly
- Compress backups
- Don't keep development data in production

### ElastiCache Redis (cache.t3.micro)

**Free Tier Limit**:
- 750 hours/month
- Single-node cluster

**Monthly Cost Calculation**:
```
Single-node = within Free Tier
Multi-node = $0.168/hour per node (additional cost)

If over 750 hours:
Cost = (hours - 750) × $0.168

Example: 730 hours = within limit = $0.00
Example: 800 hours = (800 - 750) × $0.168 = $8.40
```

**Tips to stay in Free Tier**:
- Keep as single-node (no replication)
- Monitor memory usage (`redis-cli info`)
- Evict old cache entries
- Don't store permanent data

### S3 Storage

**Free Tier Limit**:
- 5GB/month standard storage
- 20,000 GET requests free
- 2,000 PUT requests free
- 1GB/month data egress (outside AWS)

**Monthly Cost Calculation**:
```
Storage = $0.023 per GB (if over 5GB)
Requests = $0.0000004 per GET, $0.000005 per PUT
Data out = $0.09 per GB (if over 1GB/month)

Example: 10GB storage = (10-5) × $0.023 = $0.115/month
Example: 50GB egress = (50-1) × $0.09 = $4.41/month
```

**Tips to stay in Free Tier**:
- Keep uploads < 5GB
- Use CloudFront for static assets (future)
- Don't download S3 data constantly
- Enable versioning carefully (not needed for MVP)

### CloudWatch & Logs

**Free Tier Limit**:
- 5GB/month logs
- 1M custom metrics
- Alarms: no limit

**Monthly Cost Calculation**:
```
Logs stored = $0.50 per GB-month (if over 5GB)

Example: 10GB logs = (10-5) × $0.50 = $2.50/month
```

**Tips to stay in Free Tier**:
- Set log retention to 30 days (default)
- Don't log every request (sample logs)
- Use INFO level, not DEBUG
- Delete old log groups

---

## Budget Allocation

### Total Available
- Explore AWS credit: $20.00
- Free Tier credit: $100.00
- **Total buffer**: $120.00

### Allocation Strategy

```
$120.00 total
├── Year 1 (12 months): $0/month = $0 total (Free Tier)
├── Overage buffer: $30.00 (for unexpected costs)
├── Testing/experimentation: $20.00
├── Reserved instance upgrade: $70.00 (future)
└── Contingency: $0.00 (all allocated)
```

### Spend Timeline

```
Month 1-12: $0/month (Free Tier)
Month 13+: ~$40-60/month (after Free Tier expires)

Year 1 total: ~$0
Year 2+ annual: ~$500-700

Break-even: Month 13-14
(Free Tier expires, need to pay for services)
```

---

## Escalation Procedures

### Cost Alert Triggers

**Alert 1: Month-to-date cost > $5**
- Review AWS Cost Explorer
- Identify service causing overage
- Check for accidental resource creation
- Verify no runaway queries

**Alert 2: Month-to-date cost > $20**
- Immediately investigate
- Review EC2, RDS, and S3 usage
- Check for orphaned resources
- Consider temporary shutdown
- Notify team lead

**Alert 3: Month-to-date cost > $50**
- CRITICAL: Implement cost controls immediately
- Shut down non-essential services
- Restrict API access (rate limiting)
- Scale down instances
- Emergency team meeting

### Automatic Alerts

Set up CloudWatch alarms:

```bash
# Alert if monthly bill exceeds $50
aws cloudwatch put-metric-alarm \
  --alarm-name rosier-billing-50 \
  --alarm-description "Alert if monthly billing > $50" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 86400 \
  --threshold 50 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --alarm-actions arn:aws:sns:us-east-1:ACCOUNT:alerts
```

---

## Cost Optimization Tips

### Quick Wins (Immediate)
- Use default VPC (saves NAT Gateway costs)
- Single-node ElastiCache (no replication)
- No Multi-AZ RDS (single AZ only)
- Disabled detailed monitoring
- No encryption at rest (saves KMS costs)

### Medium-term Optimizations
- Implement aggressive Redis caching
- Optimize slow database queries
- Compress old data
- Delete unused resources
- Set up lifecycle policies for S3

### Long-term Strategies
- Switch to Reserved Instances (1-year)
- Implement auto-scaling (future)
- Use read replicas for load distribution
- Move cold data to S3 Glacier
- Implement CDN for static assets

---

## Free Tier Expiration Plan

### Month 12 (March 31, 2027)

Free Tier expires. Costs become:

| Service | Monthly Cost |
|---------|--------|
| EC2 t2.micro | ~$8.70 |
| RDS db.t3.micro | ~$24.00 |
| ElastiCache cache.t3.micro | ~$24.00 |
| S3 (2GB) | ~$0.05 |
| CloudWatch | ~$0.50 |
| **Total** | **~$57.25** |

### Optimization Options

**Option A: Keep as-is**
- Cost: $57.25/month = $687/year
- Pros: Simple, no changes needed
- Cons: Expensive for MVP

**Option B: Switch to Reserved Instances**
- 1-year t2.small RI: ~$11/month
- 1-year db.t3.small RI: ~$33/month
- **Total**: ~$44/month = $528/year
- Savings: ~$159/year vs on-demand

**Option C: Right-size for production**
- t2.small EC2: ~$8/month
- db.t3.small RDS: ~$33/month
- cache.r6g.large Redis: ~$80/month
- **Total**: ~$121/month = $1,452/year
- Needed for: 10K-100K requests/day

**Recommendation**: Option B (Reserved Instances)
- Break-even: Month 13-14
- Saves money long-term
- Minimal performance impact

---

## Monthly Checklist

- [ ] **Week 1**: Review cost explorer
- [ ] **Week 2**: Check RDS storage
- [ ] **Week 3**: Monitor S3 bucket
- [ ] **Week 4**: Validate Free Tier usage
- [ ] **End of month**: Generate cost report

## Cost Report Template

```markdown
# Monthly Cost Report

**Period**: April 1-30, 2026
**Status**: GREEN / YELLOW / RED

## Costs by Service
- EC2: $0.00 (720 hrs / 750 limit)
- RDS: $0.00 (720 hrs + 10GB / 750 hrs + 20GB)
- ElastiCache: $0.00 (720 hrs / 750 limit)
- S3: $0.00 (2GB / 5GB limit)
- CloudWatch: $0.00 (1GB / 5GB limit)

## Total: $0.00

## Actual vs Forecast
- Forecast: $0.00
- Actual: $0.00
- Variance: $0.00 (0%)

## Alerts
- None

## Action Items
- None

## Notes
- All services within Free Tier
- No optimization needed
- Status: HEALTHY
```

---

## References

### AWS Free Tier
- https://aws.amazon.com/free/

### AWS Cost Management
- https://aws.amazon.com/aws-cost-management/

### AWS Pricing
- EC2: https://aws.amazon.com/ec2/pricing/on-demand/
- RDS: https://aws.amazon.com/rds/pricing/
- ElastiCache: https://aws.amazon.com/elasticache/pricing/
- S3: https://aws.amazon.com/s3/pricing/

### Cost Optimization
- AWS Well-Architected Framework: https://aws.amazon.com/architecture/well-architected/
- Cost Optimization Pillar: https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/

---

## Support

### Questions?
- Email: charlie@rosierapp.com
- Slack: #infrastructure
- Issue tracker: https://github.com/rosier/rosier/issues

### Emergency Cost Issues
- Immediate action: Terraform destroy
- Then: Root cause analysis
- Finally: Plan for next attempt

---

**Last Updated**: April 1, 2026
**Status**: All systems GREEN ✓
**Budget Status**: $0.00 spent / $120.00 available
