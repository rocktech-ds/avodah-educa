# VPS Deployment Guide - Avodah Educa Multi-Tenant SaaS

This guide will help you deploy your complete multi-tenant SaaS platform to a VPS using Docker containers and optionally Supabase CLI.

## 🎯 What Gets Deployed

✅ **Multi-Tenant Database Schema** - All 8 migration files with organizations, RLS policies, and tenant isolation  
✅ **PostgreSQL Container** - With automatic migration execution  
✅ **Supabase API** - Authentication, REST API, Realtime, and Storage  
✅ **MinIO S3 Storage** - Tenant-scoped file storage with bucket policies  
✅ **Redis Cache** - Session management and caching  
✅ **Nginx Reverse Proxy** - SSL termination and routing  
✅ **Auto-Updates** - Watchtower for container updates  

## 📋 Prerequisites

Before deploying, ensure you have:

1. **VPS Access**: SSH key-based access to your VPS
2. **VPS Requirements**: Minimum 2GB RAM, 20GB storage
3. **Local Setup**: All migration files in `supabase/migrations/`
4. **Network**: Open ports 80, 443 on your VPS

## 🚀 Quick Deployment

### 1. Set Your VPS Details
```bash
export VPS_HOST=192.168.1.100  # Replace with your VPS IP
export VPS_USER=root           # Optional: defaults to root
```

### 2. Run Complete Deployment
```bash
./scripts/deploy-to-vps.sh
```

This will:
- ✅ Install Docker & Docker Compose on VPS
- ✅ Sync all migration files and configurations
- ✅ Generate SSL certificates (self-signed for dev)
- ✅ Create secure environment variables
- ✅ Deploy all containers with Docker Compose
- ✅ Verify deployment health
- ✅ Show access URLs and next steps

## 📦 Alternative Deployment Options

### Option 1: Supabase CLI (Recommended for Development)
```bash
./scripts/deploy-to-vps.sh supabase-cli
```
Uses local Supabase CLI instead of Docker containers.

### Option 2: Docker Only
```bash
./scripts/deploy-to-vps.sh docker-only
```
Only deploys Docker containers without full setup.

### Option 3: Files Sync Only
```bash
./scripts/deploy-to-vps.sh sync-only
```
Only syncs files without deploying services.

## 🔧 Manual Configuration

If you prefer manual setup or need to customize:

### 1. Sync Files Only
```bash
./scripts/sync-to-vps.sh sync-only
```

### 2. SSH to VPS and Configure
```bash
ssh root@your-vps-ip
cd /root/avodah-educa/docker

# Edit environment variables
cp vps.env.template .env
nano .env

# Deploy with Docker Compose
docker-compose -f vps-docker-compose.yml up -d
```

## 📊 Post-Deployment

After successful deployment, you'll get access to:

### 🌐 Web Interfaces
- **Application**: `http://your-vps-ip`
- **MinIO Console**: `http://your-vps-ip:9001`
- **Database**: `your-vps-ip:5432`

### 🧪 Testing Multi-Tenancy
```sql
-- Connect to PostgreSQL and test
SELECT * FROM organizations;
SELECT * FROM organization_users;

-- Test RLS policies are active
SELECT current_setting('rls.organization_id', true);
```

### 📊 Monitoring
```bash
# Check container status
docker-compose -f vps-docker-compose.yml ps

# View logs
docker-compose -f vps-docker-compose.yml logs -f

# Health checks
curl http://your-vps-ip/health
```

## 🔐 Production Security

For production deployment, update these:

### 1. SSL Certificates
```bash
# Replace self-signed certs with Let's Encrypt
certbot certonly --standalone -d your-domain.com
```

### 2. Environment Variables
Edit `/root/avodah-educa/docker/.env`:
```env
# Use strong, unique passwords
POSTGRES_PASSWORD=your_super_secure_password
JWT_SECRET=your_jwt_secret_64_chars_minimum
MINIO_ROOT_PASSWORD=your_minio_password

# Update domain
DOMAIN=your-domain.com
```

### 3. Firewall Configuration
```bash
# Allow only necessary ports
ufw allow 22    # SSH
ufw allow 80    # HTTP
ufw allow 443   # HTTPS
ufw enable
```

## 🗂️ File Structure on VPS

```
/root/avodah-educa/
├── docker/
│   ├── vps-docker-compose.yml    # Main Docker Compose
│   ├── .env                      # Environment variables
│   ├── nginx/
│   │   └── nginx.conf           # Reverse proxy config
│   └── sql-scripts/
│       └── 01-combined-migrations.sql
├── supabase/
│   ├── config.toml              # Supabase config
│   ├── seed.sql                 # Seed data
│   └── migrations/              # All migration files
└── logs/                        # Application logs
```

## 🔄 Updates and Maintenance

### Update Application
```bash
# Re-run deployment script
export VPS_HOST=your-vps-ip
./scripts/deploy-to-vps.sh
```

### Update Containers Only
```bash
ssh root@your-vps-ip
cd /root/avodah-educa/docker
docker-compose -f vps-docker-compose.yml pull
docker-compose -f vps-docker-compose.yml up -d
```

### Database Backup
```bash
# Manual backup
ssh root@your-vps-ip
docker exec avodah-postgres pg_dump -U postgres avodah_educa > backup.sql
```

## 🚨 Troubleshooting

### Check Service Health
```bash
./scripts/deploy-to-vps.sh verify
```

### Common Issues

**PostgreSQL not starting:**
```bash
docker logs avodah-postgres
# Check if ports are available and disk space sufficient
```

**Migration errors:**
```bash
# Check combined migration file
docker exec avodah-postgres psql -U postgres -d avodah_educa -c "\dt"
```

**Nginx SSL errors:**
```bash
# Regenerate certificates
ssh root@your-vps-ip
cd /root/avodah-educa/docker/nginx/ssl
rm *.pem
./scripts/deploy-to-vps.sh  # Will regenerate certs
```

## 📞 Support

If you encounter issues:

1. Check logs: `docker-compose logs servicename`
2. Verify network connectivity: `ping your-vps-ip`
3. Ensure SSH key access works
4. Check VPS resources: `htop`, `df -h`

## 🎉 Success!

Your multi-tenant SaaS is now running on your VPS with:
- ✅ Complete tenant isolation
- ✅ Secure authentication and storage
- ✅ Auto-scaling container architecture
- ✅ Production-ready infrastructure
- ✅ Comprehensive monitoring and logging

Next: Set up your frontend to connect to the VPS Supabase instance!