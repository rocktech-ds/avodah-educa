#!/bin/bash

# =============================================================================
# GOOGLE OAUTH CONFIGURATION FOR VPS SUPABASE
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VPS_HOST="${VPS_HOST:-your-vps-host}"
VPS_USER="${VPS_USER:-root}"
VPS_PATH="/root/avodah-educa"

# Google OAuth credentials - Set via environment variables
GOOGLE_CLIENT_ID="${GOOGLE_CLIENT_ID:-your-google-client-id-here}"
GOOGLE_CLIENT_SECRET="${GOOGLE_CLIENT_SECRET:-your-google-client-secret-here}"

# Your domains
AUTH_DOMAIN="avodah.auth"
API_DOMAIN="avodah.api"
STUDIO_DOMAIN="avodah.studio"

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

# Function to update Supabase config with Google OAuth
configure_google_oauth() {
    print_header "CONFIGURING GOOGLE OAUTH"
    
    print_status "Creating Google OAuth configuration..."
    
    # Create temporary config file with Google OAuth enabled
    cat > /tmp/google_oauth_config.toml << EOF
# Google OAuth Configuration
[auth.external.google]
enabled = true
client_id = "${GOOGLE_CLIENT_ID}"
secret = "${GOOGLE_CLIENT_SECRET}"
redirect_uri = "https://${AUTH_DOMAIN}/auth/v1/callback"
# Enable skip_nonce_check for local development if needed
skip_nonce_check = false

EOF

    print_success "Google OAuth configuration created!"
}

# Function to update VPS Supabase config
update_vps_config() {
    print_header "UPDATING VPS SUPABASE CONFIG"
    
    print_status "Backing up current config..."
    ssh ${VPS_USER}@${VPS_HOST} "cd ${VPS_PATH} && cp supabase/config.toml supabase/config.toml.backup"
    
    print_status "Updating config.toml with Google OAuth..."
    ssh ${VPS_USER}@${VPS_HOST} << ENDSSH
        cd ${VPS_PATH}
        
        # Add Google OAuth configuration to config.toml
        if ! grep -q "auth.external.google" supabase/config.toml; then
            echo "" >> supabase/config.toml
            echo "# Google OAuth Configuration" >> supabase/config.toml
            echo "[auth.external.google]" >> supabase/config.toml
            echo "enabled = true" >> supabase/config.toml
            echo "client_id = \"${GOOGLE_CLIENT_ID}\"" >> supabase/config.toml
            echo "secret = \"${GOOGLE_CLIENT_SECRET}\"" >> supabase/config.toml
            echo "redirect_uri = \"https://${AUTH_DOMAIN}/auth/v1/callback\"" >> supabase/config.toml
            echo "skip_nonce_check = false" >> supabase/config.toml
            echo "" >> supabase/config.toml
        else
            echo "Google OAuth already configured in config.toml"
        fi
ENDSSH
    
    print_success "VPS Supabase config updated!"
}

# Function to update environment variables
update_environment_variables() {
    print_header "UPDATING ENVIRONMENT VARIABLES"
    
    print_status "Adding Google OAuth environment variables..."
    ssh ${VPS_USER}@${VPS_HOST} << ENDSSH
        cd ${VPS_PATH}/docker
        
        # Add Google OAuth variables to .env if not already present
        if ! grep -q "GOOGLE_CLIENT_ID" .env; then
            echo "" >> .env
            echo "# Google OAuth Configuration" >> .env
            echo "GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID}" >> .env
            echo "GOOGLE_CLIENT_SECRET=${GOOGLE_CLIENT_SECRET}" >> .env
        else
            # Update existing values
            sed -i "s/GOOGLE_CLIENT_ID=.*/GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID}/g" .env
            sed -i "s/GOOGLE_CLIENT_SECRET=.*/GOOGLE_CLIENT_SECRET=${GOOGLE_CLIENT_SECRET}/g" .env
        fi
ENDSSH
    
    print_success "Environment variables updated!"
}

# Function to restart Supabase services
restart_supabase() {
    print_header "RESTARTING SUPABASE SERVICES"
    
    print_status "Restarting Supabase to apply OAuth changes..."
    ssh ${VPS_USER}@${VPS_HOST} << 'ENDSSH'
        cd /root/avodah-educa
        
        export PATH=$PATH:/root/.local/bin
        
        # If using Supabase CLI
        if command -v supabase &> /dev/null; then
            echo "Restarting Supabase CLI..."
            supabase stop 2>/dev/null || true
            supabase start
            supabase status
        fi
        
        # If using Docker Compose
        if [ -f "docker/vps-docker-compose.yml" ]; then
            echo "Restarting Docker services..."
            cd docker
            docker-compose -f vps-docker-compose.yml restart supabase 2>/dev/null || echo "Supabase container not found in Docker"
            docker-compose -f vps-docker-compose.yml ps
        fi
ENDSSH
    
    print_success "Supabase services restarted!"
}

# Function to test Google OAuth
test_google_oauth() {
    print_header "TESTING GOOGLE OAUTH"
    
    print_status "Testing OAuth configuration..."
    
    # Test the OAuth endpoints
    echo "Testing OAuth endpoints:"
    echo "🔗 Auth URL: https://${AUTH_DOMAIN}/auth/v1/authorize?provider=google"
    echo "🔗 Callback URL: https://${AUTH_DOMAIN}/auth/v1/callback"
    echo "🔗 API URL: https://${API_DOMAIN}"
    echo "🔗 Studio URL: https://${STUDIO_DOMAIN}"
    echo ""
    
    print_status "Checking if OAuth endpoint is accessible..."
    
    # Test if the OAuth endpoint responds
    if curl -s -o /dev/null -w "%{http_code}" "https://${AUTH_DOMAIN}/auth/v1/authorize?provider=google" | grep -q "302\|200"; then
        print_success "OAuth endpoint is accessible!"
    else
        print_warning "OAuth endpoint might not be accessible yet. Check your domain configuration."
    fi
}

# Function to create frontend environment file
create_frontend_env() {
    print_header "CREATING FRONTEND ENVIRONMENT FILE"
    
    print_status "Creating .env.local for frontend..."
    
    cat > .env.local << EOF
# =============================================================================
# AVODAH EDUCA - VPS SUPABASE CONFIGURATION
# =============================================================================

# VPS Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=https://${API_DOMAIN}
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key-here

# Service role key (keep this secret!)
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here

# Application Configuration
NODE_ENV=development
NEXT_PUBLIC_APP_URL=http://localhost:3000

# Google OAuth (already configured on server)
GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID}

# VPS URLs
NEXT_PUBLIC_AUTH_URL=https://${AUTH_DOMAIN}
NEXT_PUBLIC_API_URL=https://${API_DOMAIN}
NEXT_PUBLIC_STUDIO_URL=https://${STUDIO_DOMAIN}

# Multi-tenant configuration
NEXT_PUBLIC_ENABLE_MULTI_TENANT=true
NEXT_PUBLIC_DEFAULT_ORGANIZATION=avodah-demo
EOF
    
    print_success "Frontend .env.local created!"
    print_warning "Please update the SUPABASE_ANON_KEY and SERVICE_ROLE_KEY with actual values from your VPS Supabase instance."
}

# Function to show OAuth testing instructions
show_oauth_test_instructions() {
    print_header "GOOGLE OAUTH TESTING INSTRUCTIONS"
    
    echo "🧪 To test Google OAuth:"
    echo ""
    echo "1. 📝 Update Google Cloud Console:"
    echo "   - Go to: https://console.cloud.google.com/apis/credentials"
    echo "   - Edit OAuth 2.0 Client ID: ${GOOGLE_CLIENT_ID}"
    echo "   - Add these Authorized redirect URIs:"
    echo "     ✅ https://${AUTH_DOMAIN}/auth/v1/callback"
    echo "     ✅ http://localhost:3000/auth/callback (for local development)"
    echo "   - Add these Authorized JavaScript origins:"
    echo "     ✅ https://${AUTH_DOMAIN}"
    echo "     ✅ https://${API_DOMAIN}"
    echo "     ✅ http://localhost:3000"
    echo ""
    echo "2. 🔗 Test OAuth Flow:"
    echo "   - Direct test: https://${AUTH_DOMAIN}/auth/v1/authorize?provider=google"
    echo "   - With redirect: https://${AUTH_DOMAIN}/auth/v1/authorize?provider=google&redirect_to=https://${STUDIO_DOMAIN}"
    echo ""
    echo "3. 🖥️  Frontend Integration:"
    echo "   - Use the created .env.local file"
    echo "   - Install Supabase client: npm install @supabase/supabase-js"
    echo "   - Test with: supabase.auth.signInWithOAuth({ provider: 'google' })"
    echo ""
    echo "4. 🛠️  Debug if needed:"
    echo "   - Check logs: ssh ${VPS_USER}@${VPS_HOST} 'cd ${VPS_PATH} && docker-compose logs -f supabase'"
    echo "   - Verify config: ssh ${VPS_USER}@${VPS_HOST} 'cat ${VPS_PATH}/supabase/config.toml | grep -A 10 google'"
    echo ""
    print_success "OAuth configuration completed!"
}

# Main function
main() {
    echo "🔐 GOOGLE OAUTH SETUP FOR VPS SUPABASE"
    echo "======================================"
    echo "Configuring Google OAuth for domains:"
    echo "  🔑 Auth: ${AUTH_DOMAIN}"
    echo "  📡 API: ${API_DOMAIN}"
    echo "  🎨 Studio: ${STUDIO_DOMAIN}"
    echo ""
    
    # Check prerequisites
    if [ "$VPS_HOST" = "your-vps-host" ]; then
        print_error "Please set VPS_HOST environment variable"
        echo "Example: export VPS_HOST=your-actual-vps-ip"
        exit 1
    fi
    
    if [ "$GOOGLE_CLIENT_ID" = "your-google-client-id-here" ]; then
        print_error "Please set GOOGLE_CLIENT_ID environment variable"
        echo "1. Copy scripts/.env.oauth.example to scripts/.env.oauth"
        echo "2. Edit .env.oauth with your actual Google OAuth credentials"
        echo "3. Source the file: source scripts/.env.oauth"
        exit 1
    fi
    
    if [ "$GOOGLE_CLIENT_SECRET" = "your-google-client-secret-here" ]; then
        print_error "Please set GOOGLE_CLIENT_SECRET environment variable"
        echo "1. Copy scripts/.env.oauth.example to scripts/.env.oauth"
        echo "2. Edit .env.oauth with your actual Google OAuth credentials"
        echo "3. Source the file: source scripts/.env.oauth"
        exit 1
    fi
    
    # Execute configuration steps
    configure_google_oauth
    update_vps_config
    update_environment_variables
    restart_supabase
    test_google_oauth
    create_frontend_env
    show_oauth_test_instructions
}

# Handle command line arguments
case "$1" in
    "test-only")
        test_google_oauth
        ;;
    "config-only")
        configure_google_oauth
        update_vps_config
        update_environment_variables
        ;;
    "restart-only")
        restart_supabase
        ;;
    "help"|"-h"|"--help")
        echo "Google OAuth Configuration Script"
        echo ""
        echo "Usage: $0 [COMMAND]"
        echo ""
        echo "Commands:"
        echo "  test-only      Only test OAuth endpoints"
        echo "  config-only    Only update configuration files"
        echo "  restart-only   Only restart Supabase services"
        echo "  help          Show this help message"
        echo ""
        echo "Environment Variables:"
        echo "  VPS_HOST              VPS hostname or IP address (required)"
        echo "  VPS_USER              VPS username (default: root)"
        echo "  GOOGLE_CLIENT_ID      Google OAuth 2.0 Client ID (required)"
        echo "  GOOGLE_CLIENT_SECRET  Google OAuth 2.0 Client Secret (required)"
        echo ""
        echo "Setup:"
        echo "  1. Copy scripts/.env.oauth.example to scripts/.env.oauth"
        echo "  2. Edit .env.oauth with your actual credentials"
        echo "  3. Source the file: source scripts/.env.oauth"
        echo "  4. Run this script"
        ;;
    *)
        main
        ;;
esac