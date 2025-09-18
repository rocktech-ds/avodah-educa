#!/bin/bash

# =============================================================================
# COMPLETE VPS DEPLOYMENT SCRIPT - AVODAH EDUCA MULTI-TENANT SAAS
# =============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VPS_HOST="${VPS_HOST:-your-vps-host}"  # Can be set via environment variable
VPS_USER="${VPS_USER:-root}"
VPS_PATH="/root/avodah-educa"
LOCAL_PATH="$(pwd)"
DOCKER_COMPOSE_FILE="vps-docker-compose.yml"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo ""
    echo "=============================================="
    echo "  $1"
    echo "=============================================="
    echo ""
}

# Function to check prerequisites
check_prerequisites() {
    print_header "CHECKING PREREQUISITES"
    
    # Check if we're in the right directory
    if [ ! -f "supabase/config.toml" ]; then
        print_error "Must be run from project root directory (where supabase/config.toml exists)"
        exit 1
    fi
    
    # Check if VPS_HOST is set
    if [ "$VPS_HOST" = "your-vps-host" ]; then
        print_error "Please set VPS_HOST environment variable or update it in the script"
        echo "Example: export VPS_HOST=192.168.1.100"
        exit 1
    fi
    
    # Check if Docker Compose file exists
    if [ ! -f "docker/$DOCKER_COMPOSE_FILE" ]; then
        print_error "Docker Compose file not found at docker/$DOCKER_COMPOSE_FILE"
        exit 1
    fi
    
    # Test SSH connection
    print_status "Testing SSH connection to VPS..."
    if ! ssh -o BatchMode=yes -o ConnectTimeout=5 ${VPS_USER}@${VPS_HOST} echo "SSH OK" >/dev/null 2>&1; then
        print_error "Cannot connect to VPS via SSH. Please check your SSH keys and VPS_HOST."
        exit 1
    fi
    
    print_success "Prerequisites check passed!"
}

# Function to prepare migration scripts
prepare_migration_scripts() {
    print_header "PREPARING MIGRATION SCRIPTS"
    
    # Create a combined migration script for Docker
    local COMBINED_SCRIPT="docker/sql-scripts/01-combined-migrations.sql"
    mkdir -p docker/sql-scripts
    
    print_status "Creating combined migration script..."
    {
        echo "-- ============================================================================="
        echo "-- AVODAH EDUCA MULTI-TENANT SAAS - COMBINED MIGRATIONS"
        echo "-- Generated on: $(date)"
        echo "-- ============================================================================="
        echo ""
        
        # Combine all migration files in order
        for migration in supabase/migrations/*.sql; do
            if [ -f "$migration" ]; then
                echo "-- Migration: $(basename "$migration")"
                echo "-- ============================================================================="
                cat "$migration"
                echo ""
                echo ""
            fi
        done
        
        # Add seed data
        if [ -f "supabase/seed.sql" ]; then
            echo "-- ============================================================================="
            echo "-- SEED DATA"
            echo "-- ============================================================================="
            cat "supabase/seed.sql"
        fi
    } > "$COMBINED_SCRIPT"
    
    print_success "Combined migration script created at $COMBINED_SCRIPT"
}

# Function to setup VPS environment
setup_vps_environment() {
    print_header "SETTING UP VPS ENVIRONMENT"
    
    print_status "Creating directory structure on VPS..."
    ssh ${VPS_USER}@${VPS_HOST} << 'ENDSSH'
        # Create directory structure
        mkdir -p /root/avodah-educa/{docker,supabase/migrations,nginx/ssl,logs,backups}
        
        # Install Docker and Docker Compose if not already installed
        if ! command -v docker &> /dev/null; then
            echo "Installing Docker..."
            curl -fsSL https://get.docker.com -o get-docker.sh
            sh get-docker.sh
            systemctl start docker
            systemctl enable docker
        fi
        
        if ! command -v docker-compose &> /dev/null; then
            echo "Installing Docker Compose..."
            curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            chmod +x /usr/local/bin/docker-compose
        fi
        
        # Install Supabase CLI if not already installed
        if ! command -v supabase &> /dev/null; then
            echo "Installing Supabase CLI..."
            curl -fsSL https://cli.supabase.com/install.sh | sh
            export PATH=$PATH:/root/.local/bin
            echo 'export PATH=$PATH:/root/.local/bin' >> /root/.bashrc
        fi
        
        echo "VPS environment setup completed!"
ENDSSH
    
    print_success "VPS environment setup completed!"
}

# Function to sync all files to VPS
sync_files_to_vps() {
    print_header "SYNCING FILES TO VPS"
    
    print_status "Syncing Docker Compose configuration..."
    rsync -avz --progress \
        ./docker/ \
        ${VPS_USER}@${VPS_HOST}:${VPS_PATH}/docker/
    
    print_status "Syncing Supabase configuration..."
    rsync -avz --progress \
        ./supabase/ \
        ${VPS_USER}@${VPS_HOST}:${VPS_PATH}/supabase/
    
    print_success "All files synced successfully!"
}

# Function to generate SSL certificates (self-signed for development)
generate_ssl_certificates() {
    print_header "GENERATING SSL CERTIFICATES"
    
    print_status "Generating self-signed SSL certificates for development..."
    ssh ${VPS_USER}@${VPS_HOST} << 'ENDSSH'
        cd /root/avodah-educa/docker/nginx/ssl
        
        # Generate self-signed certificate for development
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout key.pem \
            -out cert.pem \
            -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
        
        chmod 600 key.pem
        chmod 644 cert.pem
        
        echo "SSL certificates generated!"
ENDSSH
    
    print_warning "Using self-signed certificates for development. For production, use Let's Encrypt or proper certificates."
}

# Function to create environment file
create_environment_file() {
    print_header "CREATING ENVIRONMENT FILE"
    
    print_status "Creating .env file on VPS..."
    ssh ${VPS_USER}@${VPS_HOST} << ENDSSH
        cd /root/avodah-educa/docker
        
        # Create .env file from template
        if [ ! -f .env ]; then
            cp vps.env.template .env
            
            # Replace placeholders with generated values
            POSTGRES_PASSWORD=\$(openssl rand -base64 32)
            JWT_SECRET=\$(openssl rand -base64 64)
            MINIO_PASSWORD=\$(openssl rand -base64 24)
            NEXTAUTH_SECRET=\$(openssl rand -base64 32)
            
            sed -i "s/your_super_secure_postgres_password_here/\$POSTGRES_PASSWORD/g" .env
            sed -i "s/your-super-secret-jwt-token-with-at-least-32-characters-long/\$JWT_SECRET/g" .env
            sed -i "s/your_secure_minio_password_here/\$MINIO_PASSWORD/g" .env
            sed -i "s/your-nextauth-secret-key-here/\$NEXTAUTH_SECRET/g" .env
            sed -i "s/your-vps-ip/$(curl -s ifconfig.me)/g" .env
            
            echo "Environment file created with secure random passwords!"
        else
            echo "Environment file already exists, skipping..."
        fi
ENDSSH
    
    print_success "Environment file created!"
}

# Function to update Nginx configuration
update_nginx_config() {
    print_header "UPDATING NGINX CONFIGURATION"
    
    print_status "Updating Nginx configuration with VPS IP..."
    ssh ${VPS_USER}@${VPS_HOST} << 'ENDSSH'
        cd /root/avodah-educa/docker/nginx
        
        VPS_IP=$(curl -s ifconfig.me)
        
        # Replace domain placeholders with VPS IP (for development)
        sed -i "s/your-domain.com/$VPS_IP/g" nginx.conf
        sed -i "s/s3.your-domain.com/s3.$VPS_IP/g" nginx.conf
        sed -i "s/minio.your-domain.com/minio.$VPS_IP/g" nginx.conf
        
        echo "Nginx configuration updated with VPS IP: $VPS_IP"
ENDSSH
    
    print_success "Nginx configuration updated!"
}

# Function to deploy with Docker Compose
deploy_with_docker() {
    print_header "DEPLOYING WITH DOCKER COMPOSE"
    
    print_status "Starting services with Docker Compose..."
    ssh ${VPS_USER}@${VPS_HOST} << 'ENDSSH'
        cd /root/avodah-educa/docker
        
        # Stop any existing containers
        docker-compose -f vps-docker-compose.yml down 2>/dev/null || true
        
        # Pull latest images
        docker-compose -f vps-docker-compose.yml pull
        
        # Start services
        docker-compose -f vps-docker-compose.yml up -d
        
        # Wait for PostgreSQL to be ready
        echo "Waiting for PostgreSQL to be ready..."
        sleep 30
        
        # Check service status
        docker-compose -f vps-docker-compose.yml ps
        
        echo "Docker deployment completed!"
ENDSSH
    
    print_success "Docker deployment completed!"
}

# Function to setup Supabase with CLI (alternative to Docker Supabase)
setup_supabase_cli() {
    print_header "SETTING UP SUPABASE CLI (ALTERNATIVE)"
    
    print_status "Initializing Supabase project on VPS..."
    ssh ${VPS_USER}@${VPS_HOST} << 'ENDSSH'
        cd /root/avodah-educa
        
        export PATH=$PATH:/root/.local/bin
        
        # Initialize Supabase project
        if [ ! -f "supabase/config.toml" ]; then
            supabase init
        fi
        
        # Start Supabase
        supabase start
        
        # Apply migrations
        supabase db reset
        
        # Show status
        supabase status
        
        echo "Supabase CLI setup completed!"
ENDSSH
    
    print_success "Supabase CLI setup completed!"
}

# Function to verify deployment
verify_deployment() {
    print_header "VERIFYING DEPLOYMENT"
    
    print_status "Checking service status..."
    ssh ${VPS_USER}@${VPS_HOST} << 'ENDSSH'
        cd /root/avodah-educa/docker
        
        echo "=== Docker Container Status ==="
        docker-compose -f vps-docker-compose.yml ps
        
        echo ""
        echo "=== Service Health Checks ==="
        
        # Check PostgreSQL
        if docker exec avodah-postgres pg_isready -U postgres >/dev/null 2>&1; then
            echo "✅ PostgreSQL: Healthy"
        else
            echo "❌ PostgreSQL: Not healthy"
        fi
        
        # Check Redis
        if docker exec avodah-redis redis-cli ping >/dev/null 2>&1; then
            echo "✅ Redis: Healthy"
        else
            echo "❌ Redis: Not healthy"
        fi
        
        # Check MinIO
        if curl -s http://localhost:9000/minio/health/live >/dev/null 2>&1; then
            echo "✅ MinIO: Healthy"
        else
            echo "❌ MinIO: Not healthy"
        fi
        
        echo ""
        echo "=== Database Tables Check ==="
        docker exec avodah-postgres psql -U postgres -d avodah_educa -c "
            SELECT 
                schemaname, 
                tablename 
            FROM pg_tables 
            WHERE schemaname = 'public' 
                AND tablename LIKE '%organization%' 
            ORDER BY tablename;
        " 2>/dev/null || echo "Could not check database tables"
        
        echo ""
        VPS_IP=$(curl -s ifconfig.me)
        echo "=== Access Information ==="
        echo "🌐 Application URL: http://$VPS_IP"
        echo "🔧 MinIO Console: http://$VPS_IP:9001"
        echo "🗄️  PostgreSQL: $VPS_IP:5432"
        echo "📊 Redis: $VPS_IP:6379"
        
ENDSSH
    
    print_success "Deployment verification completed!"
}

# Function to show post-deployment instructions
show_post_deployment_instructions() {
    print_header "POST-DEPLOYMENT INSTRUCTIONS"
    
    local VPS_IP=$(ssh ${VPS_USER}@${VPS_HOST} 'curl -s ifconfig.me')
    
    echo "🎉 Multi-Tenant SaaS deployment completed successfully!"
    echo ""
    echo "📋 Next Steps:"
    echo ""
    echo "1. 🔐 Security Setup:"
    echo "   - Update passwords in /root/avodah-educa/docker/.env"
    echo "   - Setup proper SSL certificates for production"
    echo "   - Configure firewall rules"
    echo ""
    echo "2. 🌍 Domain Setup (Optional):"
    echo "   - Point your domain to: $VPS_IP"
    echo "   - Update nginx.conf with your actual domain"
    echo "   - Get Let's Encrypt certificates"
    echo ""
    echo "3. 🧪 Testing:"
    echo "   - Access application: http://$VPS_IP"
    echo "   - MinIO Console: http://$VPS_IP:9001"
    echo "   - Test organization signup"
    echo ""
    echo "4. 📊 Monitoring:"
    echo "   - Check logs: docker-compose -f vps-docker-compose.yml logs"
    echo "   - Monitor resource usage"
    echo ""
    echo "5. 🔄 Updates:"
    echo "   - Re-run this script to deploy updates"
    echo "   - Use 'docker-compose pull && docker-compose up -d' for image updates"
    echo ""
    print_success "Deployment guide completed!"
}

# Main deployment function
main_deployment() {
    echo "🚀 AVODAH EDUCA - VPS DEPLOYMENT"
    echo "=================================="
    echo "Deploying Multi-Tenant SaaS to VPS: $VPS_HOST"
    echo ""
    
    check_prerequisites
    prepare_migration_scripts
    setup_vps_environment
    sync_files_to_vps
    generate_ssl_certificates
    create_environment_file
    update_nginx_config
    deploy_with_docker
    verify_deployment
    show_post_deployment_instructions
}

# Handle command line arguments
case "$1" in
    "docker-only")
        print_header "DOCKER-ONLY DEPLOYMENT"
        deploy_with_docker
        verify_deployment
        ;;
    "supabase-cli")
        print_header "SUPABASE CLI SETUP"
        setup_supabase_cli
        ;;
    "sync-only")
        print_header "FILES SYNC ONLY"
        check_prerequisites
        sync_files_to_vps
        ;;
    "verify")
        print_header "DEPLOYMENT VERIFICATION"
        verify_deployment
        ;;
    "help"|"-h"|"--help")
        echo "VPS Deployment Script - Avodah Educa Multi-Tenant SaaS"
        echo ""
        echo "Usage: $0 [COMMAND]"
        echo ""
        echo "Commands:"
        echo "  docker-only     Deploy only with Docker Compose"
        echo "  supabase-cli    Setup using Supabase CLI instead of Docker"
        echo "  sync-only       Only sync files to VPS"
        echo "  verify          Only verify existing deployment"
        echo "  help           Show this help message"
        echo ""
        echo "Environment Variables:"
        echo "  VPS_HOST       VPS hostname or IP address (required)"
        echo "  VPS_USER       VPS username (default: root)"
        echo ""
        echo "Example:"
        echo "  export VPS_HOST=192.168.1.100"
        echo "  ./scripts/deploy-to-vps.sh"
        ;;
    *)
        main_deployment
        ;;
esac