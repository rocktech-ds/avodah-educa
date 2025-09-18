#!/bin/bash

# =============================================================================
# SYNC MULTI-TENANT MIGRATIONS TO VPS
# =============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VPS_HOST="your-vps-host"  # Replace with your VPS IP or hostname
VPS_USER="root"
VPS_PATH="/root/avodah-educa"
LOCAL_PATH="$(pwd)"

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

# Function to check if we're in the right directory
check_directory() {
    if [ ! -f "supabase/config.toml" ]; then
        print_error "Must be run from project root directory (where supabase/config.toml exists)"
        exit 1
    fi
}

# Function to sync migration files
sync_migrations() {
    print_status "Syncing migration files to VPS..."
    
    # Create remote directory structure if it doesn't exist
    ssh ${VPS_USER}@${VPS_HOST} "mkdir -p ${VPS_PATH}/supabase/migrations"
    
    # Copy migration files
    rsync -avz --progress \
        ./supabase/migrations/ \
        ${VPS_USER}@${VPS_HOST}:${VPS_PATH}/supabase/migrations/
    
    print_success "Migration files synced successfully"
}

# Function to sync seed file
sync_seed() {
    print_status "Syncing seed file to VPS..."
    
    rsync -avz --progress \
        ./supabase/seed.sql \
        ${VPS_USER}@${VPS_HOST}:${VPS_PATH}/supabase/
    
    print_success "Seed file synced successfully"
}

# Function to sync config
sync_config() {
    print_status "Syncing Supabase config to VPS..."
    
    rsync -avz --progress \
        ./supabase/config.toml \
        ${VPS_USER}@${VPS_HOST}:${VPS_PATH}/supabase/
    
    print_success "Config synced successfully"
}

# Function to update VPS Supabase container
update_vps_supabase() {
    print_status "Updating Supabase container on VPS..."
    
    ssh ${VPS_USER}@${VPS_HOST} << 'ENDSSH'
        cd /root/avodah-educa
        
        echo "Stopping Supabase..."
        supabase stop 2>/dev/null || true
        
        echo "Starting Supabase with new migrations..."
        supabase start
        
        echo "Applying database migrations..."
        supabase db reset --linked
        
        echo "Checking status..."
        supabase status
ENDSSH
    
    print_success "VPS Supabase container updated successfully!"
}

# Function to show VPS connection info
show_connection_info() {
    print_status "Getting VPS Supabase connection info..."
    
    ssh ${VPS_USER}@${VPS_HOST} << 'ENDSSH'
        cd /root/avodah-educa
        echo "==================================="
        echo "VPS Supabase Connection Info:"
        echo "==================================="
        supabase status
        echo ""
        echo "Multi-tenant tables check:"
        supabase db psql -c "SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename LIKE '%organization%' ORDER BY tablename;"
ENDSSH
}

# Main function
main() {
    echo "🚀 Syncing Multi-Tenant SaaS to VPS"
    echo "===================================="
    echo ""
    
    # Check if VPS_HOST is set
    if [ "$VPS_HOST" = "your-vps-host" ]; then
        print_error "Please update VPS_HOST in this script with your actual VPS hostname/IP"
        exit 1
    fi
    
    check_directory
    
    # Sync files
    sync_migrations
    sync_seed
    sync_config
    
    # Update VPS
    update_vps_supabase
    
    # Show connection info
    show_connection_info
    
    echo ""
    print_success "Multi-tenant SaaS successfully deployed to VPS!"
    echo ""
    echo "Next steps:"
    echo "1. Update your frontend .env.local with VPS Supabase URLs"
    echo "2. Test organization creation with signup_organization() function"
    echo "3. Create sample organizations and users"
}

# Show help
show_help() {
    echo "VPS Sync Script - Deploy Multi-Tenant SaaS to VPS"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  sync-only       Only sync files, don't restart Supabase"
    echo "  update-only     Only update Supabase container (no file sync)"
    echo "  status         Show VPS Supabase status"
    echo "  help           Show this help message"
    echo ""
    echo "Default: sync files and update Supabase container"
    echo ""
    echo "Before running:"
    echo "1. Update VPS_HOST variable in this script"
    echo "2. Ensure SSH key access to your VPS"
    echo "3. Ensure Supabase CLI is installed on VPS"
}

# Handle command line arguments
case "$1" in
    "sync-only")
        check_directory
        sync_migrations
        sync_seed
        sync_config
        ;;
    "update-only")
        update_vps_supabase
        show_connection_info
        ;;
    "status")
        show_connection_info
        ;;
    "help"|"")
        show_help
        ;;
    *)
        main
        ;;
esac