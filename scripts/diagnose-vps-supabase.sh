#!/bin/bash

# =============================================================================
# VPS SUPABASE DIAGNOSIS AND GOOGLE OAUTH SETUP
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration - Update these with your actual VPS details
VPS_HOST="${VPS_HOST:-your-vps-ip}"
VPS_USER="${VPS_USER:-root}"

# Google OAuth credentials - Set via environment variables
GOOGLE_CLIENT_ID="${GOOGLE_CLIENT_ID:-your-google-client-id-here}"
GOOGLE_CLIENT_SECRET="${GOOGLE_CLIENT_SECRET:-your-google-client-secret-here}"

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

# Function to check VPS connectivity
check_vps_connectivity() {
    print_header "CHECKING VPS CONNECTIVITY"
    
    if [ "$VPS_HOST" = "your-vps-ip" ]; then
        print_error "Please set VPS_HOST environment variable with your actual VPS IP"
        echo "Example: export VPS_HOST=192.168.1.100"
        return 1
    fi
    
    print_status "Testing SSH connection to VPS: $VPS_HOST"
    if ssh -o BatchMode=yes -o ConnectTimeout=5 ${VPS_USER}@${VPS_HOST} echo "SSH connection successful" 2>/dev/null; then
        print_success "SSH connection to VPS is working"
    else
        print_error "Cannot connect to VPS via SSH"
        return 1
    fi
}

# Function to check what's running on VPS
check_vps_services() {
    print_header "CHECKING VPS SERVICES"
    
    print_status "Checking running services on VPS..."
    ssh ${VPS_USER}@${VPS_HOST} << 'ENDSSH'
        echo "=== Docker containers ==="
        docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}" 2>/dev/null || echo "Docker not found or no containers running"
        
        echo ""
        echo "=== Supabase CLI status ==="
        export PATH=$PATH:/root/.local/bin
        if command -v supabase &> /dev/null; then
            echo "Supabase CLI found, checking status..."
            supabase status 2>/dev/null || echo "Supabase not started"
        else
            echo "Supabase CLI not found"
        fi
        
        echo ""
        echo "=== Open ports ==="
        netstat -tlnp 2>/dev/null | grep -E ":(80|443|3000|8000|54321)" || echo "No common web ports open"
        
        echo ""
        echo "=== Domain/IP information ==="
        echo "VPS IP: $(curl -s ifconfig.me 2>/dev/null || echo "Could not determine IP")"
        
ENDSSH
}

# Function to find Supabase URL and keys
find_supabase_credentials() {
    print_header "FINDING SUPABASE CREDENTIALS"
    
    print_status "Looking for Supabase configuration and credentials..."
    ssh ${VPS_USER}@${VPS_HOST} << 'ENDSSH'
        echo "=== Checking for Supabase status ==="
        export PATH=$PATH:/root/.local/bin
        
        if command -v supabase &> /dev/null; then
            echo "Getting Supabase status..."
            supabase status 2>/dev/null || echo "Supabase not running"
        fi
        
        echo ""
        echo "=== Checking environment files ==="
        find /root -name "*.env*" -type f 2>/dev/null | head -5 | while read file; do
            echo "Found: $file"
            if grep -l "SUPABASE\|supabase" "$file" 2>/dev/null; then
                echo "  Contains Supabase config"
            fi
        done
        
        echo ""
        echo "=== Checking Docker Compose services ==="
        find /root -name "*docker-compose*.yml" -type f 2>/dev/null | head -3 | while read file; do
            echo "Found Docker Compose: $file"
            grep -E "(supabase|postgres|kong)" "$file" 2>/dev/null || echo "  No Supabase services found"
        done
        
        echo ""
        echo "=== Checking for avodah-educa directory ==="
        if [ -d "/root/avodah-educa" ]; then
            echo "Found /root/avodah-educa directory"
            ls -la /root/avodah-educa/ 2>/dev/null | head -10
        else
            echo "No /root/avodah-educa directory found"
        fi
        
ENDSSH
}

# Function to setup Google OAuth based on found configuration
setup_google_oauth() {
    print_header "SETTING UP GOOGLE OAUTH"
    
    # Skip OAuth setup if credentials are not provided
    if [ "$GOOGLE_CLIENT_ID" = "your-google-client-id-here" ] || [ "$GOOGLE_CLIENT_SECRET" = "your-google-client-secret-here" ]; then
        print_warning "Google OAuth credentials not provided, skipping OAuth setup"
        print_status "To configure OAuth later:"
        print_status "1. Copy scripts/.env.oauth.example to scripts/.env.oauth"
        print_status "2. Edit .env.oauth with your actual Google OAuth credentials"
        print_status "3. Source the file: source scripts/.env.oauth"
        print_status "4. Run this script again"
        return 0
    fi
    
    print_status "Configuring Google OAuth with found Supabase setup..."
    ssh ${VPS_USER}@${VPS_HOST} << ENDSSH
        export PATH=\$PATH:/root/.local/bin
        
        # Find Supabase directory
        SUPABASE_DIR=""
        if [ -d "/root/avodah-educa" ]; then
            SUPABASE_DIR="/root/avodah-educa"
        elif [ -d "/root/supabase" ]; then
            SUPABASE_DIR="/root/supabase"
        fi
        
        if [ -n "\$SUPABASE_DIR" ]; then
            echo "Using Supabase directory: \$SUPABASE_DIR"
            cd "\$SUPABASE_DIR"
            
            # Update config.toml if exists
            if [ -f "supabase/config.toml" ]; then
                echo "Updating supabase/config.toml with Google OAuth..."
                
                # Backup original
                cp supabase/config.toml supabase/config.toml.backup
                
                # Add Google OAuth if not present
                if ! grep -q "auth.external.google" supabase/config.toml; then
                    cat >> supabase/config.toml << EOF

# Google OAuth Configuration - Added $(date)
[auth.external.google]
enabled = true
client_id = "${GOOGLE_CLIENT_ID}"
secret = "${GOOGLE_CLIENT_SECRET}"
# Will be updated with actual domain
redirect_uri = ""
skip_nonce_check = false
EOF
                    echo "✅ Google OAuth configuration added to config.toml"
                else
                    echo "ℹ️  Google OAuth already configured in config.toml"
                fi
                
                # Show current config
                echo ""
                echo "Current Google OAuth config:"
                grep -A 10 "auth.external.google" supabase/config.toml || echo "No Google OAuth config found"
            else
                echo "❌ No supabase/config.toml found"
            fi
            
            # Update environment files
            if [ -f "docker/.env" ]; then
                echo ""
                echo "Updating Docker environment file..."
                
                # Add Google OAuth env vars if not present
                if ! grep -q "GOOGLE_CLIENT_ID" docker/.env; then
                    echo "" >> docker/.env
                    echo "# Google OAuth - Added \$(date)" >> docker/.env
                    echo "GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID}" >> docker/.env
                    echo "GOOGLE_CLIENT_SECRET=${GOOGLE_CLIENT_SECRET}" >> docker/.env
                    echo "✅ Google OAuth environment variables added"
                else
                    echo "ℹ️  Google OAuth environment variables already present"
                fi
            fi
            
            # Restart services if possible
            echo ""
            echo "Attempting to restart Supabase services..."
            
            # Try Supabase CLI first
            if command -v supabase &> /dev/null; then
                echo "Restarting Supabase CLI..."
                supabase stop 2>/dev/null || true
                supabase start
                echo ""
                echo "Supabase status after restart:"
                supabase status
            fi
            
            # Try Docker Compose
            if [ -f "docker/vps-docker-compose.yml" ]; then
                echo "Restarting Docker Compose services..."
                cd docker
                docker-compose -f vps-docker-compose.yml restart 2>/dev/null || echo "Could not restart Docker services"
            fi
        else
            echo "❌ No Supabase directory found. Please run VPS deployment first."
        fi
ENDSSH
    
    print_success "Google OAuth setup completed!"
}

# Function to create local environment file
create_local_env() {
    print_header "CREATING LOCAL ENVIRONMENT FILE"
    
    print_status "Getting Supabase URLs and keys from VPS..."
    
    # Get Supabase info from VPS
    SUPABASE_INFO=$(ssh ${VPS_USER}@${VPS_HOST} << 'ENDSSH'
        export PATH=$PATH:/root/.local/bin
        if command -v supabase &> /dev/null; then
            supabase status 2>/dev/null | grep -E "(API URL|anon key|service_role key)" || echo "Could not get Supabase info"
        else
            echo "Supabase CLI not available"
        fi
ENDSSH
    )
    
    # Extract URLs and keys (this is a basic extraction, might need adjustment)
    API_URL=$(echo "$SUPABASE_INFO" | grep "API URL" | awk '{print $3}' || echo "http://your-vps-ip:54321")
    ANON_KEY=$(echo "$SUPABASE_INFO" | grep "anon key" | awk '{print $3}' || echo "your-anon-key-here")
    SERVICE_KEY=$(echo "$SUPABASE_INFO" | grep "service_role key" | awk '{print $3}' || echo "your-service-role-key-here")
    
    # Create .env.local file
    print_status "Creating .env.local file..."
    cat > .env.local << EOF
# =============================================================================
# AVODAH EDUCA - VPS SUPABASE CONFIGURATION
# =============================================================================
# Generated on $(date)

# VPS Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=${API_URL}
NEXT_PUBLIC_SUPABASE_ANON_KEY=${ANON_KEY}

# Service role key (keep this secret!)
SUPABASE_SERVICE_ROLE_KEY=${SERVICE_KEY}

# Application Configuration
NODE_ENV=development
NEXT_PUBLIC_APP_URL=http://localhost:3000

# Google OAuth Configuration
GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID}
GOOGLE_CLIENT_SECRET=${GOOGLE_CLIENT_SECRET}

# Multi-tenant configuration
NEXT_PUBLIC_ENABLE_MULTI_TENANT=true
NEXT_PUBLIC_DEFAULT_ORGANIZATION=avodah-demo

# VPS Information
VPS_HOST=${VPS_HOST}
EOF
    
    print_success "Local .env.local file created!"
    print_warning "Please verify the Supabase URLs and keys are correct"
}

# Function to show testing instructions
show_testing_instructions() {
    print_header "GOOGLE OAUTH TESTING INSTRUCTIONS"
    
    # Get actual Supabase URL
    local SUPABASE_URL=$(ssh ${VPS_USER}@${VPS_HOST} << 'ENDSSH'
        export PATH=$PATH:/root/.local/bin
        if command -v supabase &> /dev/null; then
            supabase status 2>/dev/null | grep "API URL" | awk '{print $3}' || echo "http://$(curl -s ifconfig.me):54321"
        else
            echo "http://$(curl -s ifconfig.me):54321"
        fi
ENDSSH
    )
    
    echo "🔧 Google Cloud Console Setup:"
    echo "1. Go to: https://console.cloud.google.com/apis/credentials"
    echo "2. Edit OAuth 2.0 Client ID: ${GOOGLE_CLIENT_ID}"
    echo "3. Add these Authorized redirect URIs:"
    echo "   ✅ ${SUPABASE_URL}/auth/v1/callback"
    echo "   ✅ http://localhost:3000/auth/callback"
    echo "4. Add these Authorized JavaScript origins:"
    echo "   ✅ ${SUPABASE_URL}"
    echo "   ✅ http://localhost:3000"
    echo ""
    
    echo "🧪 Test OAuth Flow:"
    echo "1. Direct URL test:"
    echo "   curl -I '${SUPABASE_URL}/auth/v1/authorize?provider=google'"
    echo ""
    echo "2. Frontend integration test (create a test page):"
    echo "   import { createClient } from '@supabase/supabase-js'"
    echo "   const supabase = createClient('${SUPABASE_URL}', 'your-anon-key')"
    echo "   await supabase.auth.signInWithOAuth({ provider: 'google' })"
    echo ""
    
    print_success "Setup complete! Test the OAuth flow with the instructions above."
}

# Main execution
main() {
    echo "🔍 VPS SUPABASE & GOOGLE OAUTH DIAGNOSIS"
    echo "========================================"
    echo "VPS Host: ${VPS_HOST}"
    echo "Google Client ID: ${GOOGLE_CLIENT_ID}"
    echo ""
    
    if ! check_vps_connectivity; then
        echo "Cannot proceed without VPS connectivity. Please check your VPS_HOST and SSH access."
        exit 1
    fi
    
    check_vps_services
    find_supabase_credentials
    setup_google_oauth
    create_local_env
    show_testing_instructions
}

# Handle command line arguments
case "$1" in
    "check-only")
        check_vps_connectivity
        check_vps_services
        find_supabase_credentials
        ;;
    "oauth-only")
        setup_google_oauth
        ;;
    "help"|"-h"|"--help")
        echo "VPS Supabase Diagnosis and OAuth Setup Script"
        echo ""
        echo "Usage: $0 [COMMAND]"
        echo ""
        echo "Commands:"
        echo "  check-only     Only check VPS and find Supabase setup"
        echo "  oauth-only     Only setup Google OAuth configuration"
        echo "  help          Show this help message"
        echo ""
        echo "Environment Variables:"
        echo "  VPS_HOST              Your VPS IP address (required)"
        echo "  VPS_USER              VPS username (default: root)"
        echo "  GOOGLE_CLIENT_ID      Google OAuth 2.0 Client ID (optional)"
        echo "  GOOGLE_CLIENT_SECRET  Google OAuth 2.0 Client Secret (optional)"
        echo ""
        echo "OAuth Setup:"
        echo "  1. Copy scripts/.env.oauth.example to scripts/.env.oauth"
        echo "  2. Edit .env.oauth with your actual credentials"
        echo "  3. Source the file: source scripts/.env.oauth"
        echo ""
        echo "Example:"
        echo "  export VPS_HOST=192.168.1.100"
        echo "  $0"
        ;;
    *)
        main
        ;;
esac