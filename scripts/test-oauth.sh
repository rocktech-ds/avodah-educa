#!/bin/bash

# =============================================================================
# QUICK GOOGLE OAUTH TEST FOR AVODAH DOMAINS
# =============================================================================

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Your domains
AUTH_DOMAIN="avodah.auth"
API_DOMAIN="avodah.api"
STUDIO_DOMAIN="avodah.studio"

echo "🧪 Testing Avodah Supabase OAuth Endpoints"
echo "=========================================="
echo ""

# Test function
test_endpoint() {
    local url=$1
    local description=$2
    
    echo -n "Testing $description... "
    
    if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "$url" | grep -q "200\|302\|401\|403"; then
        echo -e "${GREEN}✅ Accessible${NC}"
        return 0
    else
        echo -e "${RED}❌ Not accessible${NC}"
        return 1
    fi
}

# Test domain resolution
echo "🌐 Testing domain resolution:"
for domain in $AUTH_DOMAIN $API_DOMAIN $STUDIO_DOMAIN; do
    echo -n "  $domain... "
    if nslookup $domain >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Resolves${NC}"
    else
        echo -e "${RED}❌ DNS not found${NC}"
    fi
done

echo ""

# Test HTTPS endpoints
echo "🔐 Testing HTTPS endpoints:"
test_endpoint "https://$AUTH_DOMAIN/auth/v1/settings" "Auth Settings"
test_endpoint "https://$API_DOMAIN/rest/v1/" "API Health"
test_endpoint "https://$STUDIO_DOMAIN" "Studio Interface"

echo ""

# Test OAuth specific endpoints
echo "🔑 Testing OAuth endpoints:"
test_endpoint "https://$AUTH_DOMAIN/auth/v1/authorize?provider=google" "Google OAuth"
test_endpoint "https://$AUTH_DOMAIN/auth/v1/callback" "OAuth Callback"

echo ""

# Show OAuth URLs
echo "📋 OAuth URLs for Google Cloud Console:"
echo "  Authorized redirect URIs:"
echo "    https://$AUTH_DOMAIN/auth/v1/callback"
echo "    http://localhost:3000/auth/callback"
echo ""
echo "  Authorized JavaScript origins:"
echo "    https://$AUTH_DOMAIN"
echo "    https://$API_DOMAIN"  
echo "    http://localhost:3000"

echo ""

# Test with curl and show response
echo "🔍 OAuth Authorization Test:"
echo "URL: https://$AUTH_DOMAIN/auth/v1/authorize?provider=google"
echo ""
echo "Response:"
curl -s -I "https://$AUTH_DOMAIN/auth/v1/authorize?provider=google" | head -5 || echo "Connection failed"

echo ""
echo "✅ Test completed!"
echo ""
echo "Next steps:"
echo "1. If endpoints are accessible, configure Google OAuth:"
echo "   export VPS_HOST=your-vps-ip"
echo "   ./scripts/configure-google-oauth.sh"
echo ""
echo "2. Update your Google Cloud Console with the URLs shown above"
echo ""
echo "3. Test OAuth login in your application"