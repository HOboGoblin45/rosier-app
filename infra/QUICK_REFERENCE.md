# Rosier Deployment - Quick Reference Card

**Print this or save to your phone!**

---

## Step 1: Run Deployment Script (15 min)

```bash
# Open: https://us-east-1.console.aws.amazon.com/cloudshell/home
# Paste deploy-to-aws.sh and run:

chmod +x deploy-to-aws.sh
./deploy-to-aws.sh

# SAVE THE OUTPUT - you'll need:
# - Database password
# - EC2 public IP
# - RDS endpoint
# - Redis endpoint
```

---

## Step 2: Wait (10 min)

Services initializing. Check status:

- RDS: https://us-east-1.console.aws.amazon.com/rds/
- Redis: https://us-east-1.console.aws.amazon.com/elasticache/
- EC2: https://us-east-1.console.aws.amazon.com/ec2/

Look for Status: **Available** or **Running**

---

## Step 3: SSH to EC2 (from your machine)

```bash
# Replace <IP> with public IP from step 1
ssh -i rosier-key.pem ec2-user@<IP>
```

---

## Step 4: Deploy Application (5 min)

```bash
cd /app

# Clone repo
git clone <REPO_URL> .

# Create .env with credentials from step 1
cat > .env << 'EOF'
DATABASE_URL=postgresql+asyncpg://rosier_admin:<PASSWORD>@<RDS_ENDPOINT>:5432/rosier
REDIS_URL=redis://<REDIS_ENDPOINT>:6379/0
AWS_REGION=us-east-1
JWT_SECRET_KEY=changeme
SECRET_KEY=changeme
ENVIRONMENT=production
DEBUG=false
API_HOST=0.0.0.0
API_PORT=8000
EOF

# Start application
docker-compose -f infra/docker/docker-compose-prod.yml up -d

# Run migrations
docker-compose -f infra/docker/docker-compose-prod.yml exec api alembic upgrade head
```

---

## Step 5: Test (2 min)

```bash
# Test health endpoint
curl http://<IP>:8000/health

# Open in browser for Swagger UI
http://<IP>:8000/docs
```

---

## Useful Commands (while SSH'd to EC2)

```bash
# View logs
docker-compose logs -f api

# Check containers
docker ps

# Restart app
docker-compose restart api

# Test database
psql -h <RDS_ENDPOINT> -U rosier_admin -d rosier

# Test Redis
redis-cli -h <REDIS_ENDPOINT> PING
```

---

## Emergency Commands

```bash
# Stop all containers
docker-compose down

# Start all containers
docker-compose up -d

# Rebuild and restart
docker-compose build --no-cache && docker-compose up -d

# Check disk space
df -h

# Check memory usage
docker stats
```

---

## AWS Console Links

| Service | URL |
|---------|-----|
| **EC2** | https://us-east-1.console.aws.amazon.com/ec2/ |
| **RDS** | https://us-east-1.console.aws.amazon.com/rds/ |
| **ElastiCache** | https://us-east-1.console.aws.amazon.com/elasticache/ |
| **CloudShell** | https://us-east-1.console.aws.amazon.com/cloudshell/home |
| **CloudWatch Logs** | https://us-east-1.console.aws.amazon.com/cloudwatch/ |

---

## Credentials Reference

**Keep these safe! Store in 1Password or similar:**

```
EC2 Public IP:        <FROM STEP 1 OUTPUT>
EC2 SSH Key:          rosier-key.pem (download from CloudShell)
RDS Endpoint:         <FROM STEP 1 OUTPUT>
RDS Username:         rosier_admin
RDS Password:         <FROM STEP 1 OUTPUT>
Redis Endpoint:       <FROM STEP 1 OUTPUT>
Database Name:        rosier
Region:               us-east-1
```

---

## If Something Goes Wrong

| Problem | Solution |
|---------|----------|
| Can't SSH to EC2 | Wait 2 min, check IP is public, check security group |
| Database connection fails | Wait 5-10 min for RDS, test: `psql -h <ENDPOINT>...` |
| API won't start | Check logs: `docker-compose logs api` |
| Port 8000 not responding | Check: `curl http://localhost:8000/health` from EC2 |
| Docker command not found | SSH into EC2 and try again, docker should be installed |

---

## Cost

- **Year 1**: $0/month (Free Tier)
- **Year 2+**: ~$50/month (after Free Tier expires)

---

## Time Estimate

| Phase | Time |
|-------|------|
| Run script | 15 min |
| Wait for services | 10 min |
| SSH and deploy | 5 min |
| Test | 2 min |
| **TOTAL** | **32 min** |

---

## Success Indicators

- [ ] EC2 instance running
- [ ] RDS database available
- [ ] Redis cluster available
- [ ] SSH connection works
- [ ] `curl http://<IP>:8000/health` returns 200
- [ ] Swagger UI loads at `http://<IP>:8000/docs`

---

## Next Steps After Deployment

1. Test all API endpoints
2. Monitor CloudWatch logs
3. Restrict SSH to your IP
4. Set up SSL/TLS certificate
5. Configure domain DNS
6. Set up monitoring alerts
7. Create RDS snapshots

---

## Support

- **Deployment Guide**: `CLOUDSHELL_DEPLOYMENT_GUIDE.md`
- **Checklist**: `DEPLOYMENT_CHECKLIST.md`
- **Full Docs**: `README_DEPLOYMENT.md`
- **Architecture**: `BUDGET_DEPLOYMENT_PLAN.md`

---

**Version**: 1.0
**Date**: April 1, 2026
**Status**: Ready to deploy!

**Questions?** Check the full documentation files.
**Ready to go?** Start at Step 1 above!
