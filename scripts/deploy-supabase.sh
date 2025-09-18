#!/bin/bash

# =============================================================================
# AVODAH EDUCA - SUPABASE DEPLOYMENT SCRIPT
# =============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command_exists "supabase"; then
        print_error "Supabase CLI is not installed. Please install it first:"
        echo "  npm install -g supabase"
        echo "  or visit: https://supabase.com/docs/guides/cli"
        exit 1
    fi
    
    if ! command_exists "docker"; then
        print_warning "Docker is not installed. You won't be able to run Supabase locally."
        echo "  Visit: https://www.docker.com/get-started"
    fi
    
    print_success "Prerequisites check completed"
}

# Function to setup local development
setup_local() {
    print_status "Setting up local Supabase development environment..."
    
    # Check if Supabase is already initialized
    if [ ! -f "supabase/config.toml" ]; then
        print_error "Supabase is not initialized. Config file not found."
        exit 1
    fi
    
    # Start Supabase locally
    print_status "Starting Supabase local development server..."
    supabase start
    
    # Check status
    print_status "Checking Supabase status..."
    supabase status
    
    # Reset database with migrations
    print_status "Applying database migrations..."
    supabase db reset
    
    print_success "Local Supabase environment is ready!"
    echo ""
    echo "Local URLs:"
    echo "  Studio URL: http://localhost:54323"
    echo "  API URL: http://localhost:54321"
    echo "  Anon key: $(supabase status | grep 'anon key' | awk '{print $3}')"
    echo ""
}

# Function to deploy to production
deploy_production() {
    print_status "Deploying to production Supabase..."
    
    # Check if project is linked
    if [ ! -f ".supabase/config.toml" ]; then
        print_error "Project is not linked to Supabase. Please link it first:"
        echo "  supabase link --project-ref YOUR_PROJECT_ID"
        exit 1
    fi
    
    # Push database changes
    print_status "Pushing database migrations..."
    supabase db push
    
    print_success "Production deployment completed!"
}

# Function to seed database
seed_database() {
    local environment=$1
    
    print_status "Seeding database with sample data..."
    
    if [ "$environment" = "local" ]; then
        supabase db seed
    else
        supabase db seed --remote
    fi
    
    print_success "Database seeded successfully!"
}

# Function to validate environment
validate_environment() {
    print_status "Validating environment configuration..."
    
    if [ ! -f ".env.local" ]; then
        print_warning ".env.local file not found. Creating from template..."
        cp .env.local.example .env.local
        print_warning "Please update .env.local with your actual Supabase credentials"
    fi
    
    # Check if required environment variables are set
    if ! grep -q "https://.*\.supabase\.co" .env.local 2>/dev/null; then
        print_warning "Please update NEXT_PUBLIC_SUPABASE_URL in .env.local"
    fi
    
    print_success "Environment validation completed"
}

# Function to check database schema
check_schema() {
    print_status "Checking database schema..."
    
    # List tables
    echo "Tables in database:"
    supabase db remote ls
    
    print_success "Schema check completed"
}

# Function to backup database
backup_database() {
    local backup_file="backup_$(date +%Y%m%d_%H%M%S).sql"
    
    print_status "Creating database backup..."
    supabase db dump --data-only > "backups/$backup_file"
    
    print_success "Backup created: backups/$backup_file"
}

# Function to show help
show_help() {
    echo "Avodah Educa - Supabase Deployment Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  local           Setup local development environment"
    echo "  deploy          Deploy to production"
    echo "  seed [env]      Seed database (env: local|remote)"
    echo "  validate        Validate environment configuration"
    echo "  check           Check database schema"
    echo "  backup          Create database backup"
    echo "  help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 local        # Setup local development"
    echo "  $0 deploy       # Deploy to production"
    echo "  $0 seed local   # Seed local database"
    echo "  $0 seed remote  # Seed production database"
    echo ""
}

# Main script logic
main() {
    echo "🚀 Avodah Educa - Supabase Deployment Script"
    echo "=============================================="
    echo ""
    
    # Check prerequisites for all commands except help
    if [ "$1" != "help" ] && [ "$1" != "" ]; then
        check_prerequisites
        validate_environment
        echo ""
    fi
    
    case "$1" in
        "local")
            setup_local
            ;;
        "deploy")
            deploy_production
            ;;
        "seed")
            if [ "$2" = "remote" ]; then
                seed_database "remote"
            else
                seed_database "local"
            fi
            ;;
        "validate")
            # Already done above
            print_success "Environment validation completed"
            ;;
        "check")
            check_schema
            ;;
        "backup")
            mkdir -p backups
            backup_database
            ;;
        "help"|"")
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Create backups directory if it doesn't exist
mkdir -p backups

# Run main function
main "$@"