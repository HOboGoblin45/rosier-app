#!/bin/bash
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-staging}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Function to log
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING${NC} $1"
}

# Function to validate environment
validate_environment() {
    log "Validating migration environment..."

    # Check if alembic is installed
    if ! command -v alembic &> /dev/null; then
        log_error "alembic not installed"
        return 1
    fi

    # Check if DATABASE_URL is set
    if [ -z "$DATABASE_URL" ]; then
        log_error "DATABASE_URL environment variable not set"
        return 1
    fi

    log "Environment validation passed"
    return 0
}

# Function to check database connectivity
check_database() {
    log "Checking database connectivity..."

    # Extract connection info from DATABASE_URL
    local db_url="$DATABASE_URL"

    # Simple connectivity check using psql if available
    if command -v psql &> /dev/null; then
        # Extract connection details from URL
        # Format: postgresql+asyncpg://user:password@host:port/dbname
        local proto=$(echo "$db_url" | cut -d':' -f1)
        local user=$(echo "$db_url" | cut -d'/' -f3 | cut -d':' -f1)
        local password=$(echo "$db_url" | cut -d':' -f3 | cut -d'@' -f1)
        local host=$(echo "$db_url" | cut -d'@' -f2 | cut -d':' -f1)
        local port=$(echo "$db_url" | cut -d':' -f4 | cut -d'/' -f1)
        local dbname=$(echo "$db_url" | cut -d'/' -f4)

        PGPASSWORD="$password" psql -h "$host" -U "$user" -d "$dbname" -c "SELECT 1" > /dev/null 2>&1 || {
            log_error "Database connectivity check failed"
            return 1
        }
    fi

    log "Database connectivity verified"
    return 0
}

# Function to get current migration revision
get_current_revision() {
    log "Getting current migration revision..."

    cd "$PROJECT_ROOT"
    alembic current
}

# Function to get migration history
get_migration_history() {
    log "Recent migration history:"

    cd "$PROJECT_ROOT"
    alembic history --rev-range base:heads | head -20
}

# Function to validate migrations
validate_migrations() {
    log "Validating migration files..."

    cd "$PROJECT_ROOT"

    # Check if migrations directory exists
    if [ ! -d "migrations/versions" ]; then
        log_error "Migrations directory not found"
        return 1
    fi

    # Count migration files
    local migration_count=$(ls -1 migrations/versions/*.py 2>/dev/null | wc -l)
    log "Found $migration_count migration files"

    return 0
}

# Function to perform dry run
perform_dry_run() {
    log "Performing dry run migration..."

    cd "$PROJECT_ROOT"

    # Create a test connection to check SQL
    if alembic upgrade head --sql > /tmp/migration_preview.sql 2>&1; then
        log "Migration SQL preview (first 50 lines):"
        head -50 /tmp/migration_preview.sql
        return 0
    else
        log_error "Dry run failed"
        return 1
    fi
}

# Function to run migrations
run_migrations() {
    log "Running database migrations..."

    cd "$PROJECT_ROOT"

    if ! alembic upgrade head; then
        log_error "Migration failed"
        return 1
    fi

    log "Migrations completed successfully"
    return 0
}

# Function to verify migration success
verify_migration() {
    log "Verifying migration success..."

    cd "$PROJECT_ROOT"

    local current=$(alembic current | grep -oP '\(head\)\s*\K.*')
    if [ -z "$current" ]; then
        log_error "Could not verify migration - database might not be initialized"
        return 1
    fi

    log "Current revision: $current"
    return 0
}

# Function to rollback migration
rollback_migration() {
    local steps=${1:-1}

    log "Rolling back $steps migration step(s)..."

    cd "$PROJECT_ROOT"

    # Get current head revision
    local current_head=$(alembic current 2>&1 | tail -1)

    if [ -z "$current_head" ]; then
        log_error "Could not determine current migration state"
        return 1
    fi

    log "Current state: $current_head"

    # Rollback by going back N steps
    for ((i=0; i<steps; i++)); do
        if ! alembic downgrade -1; then
            log_error "Rollback step $((i+1)) failed"
            return 1
        fi
    done

    log "Rollback completed"
    return 0
}

# Function to display migration status
show_migration_status() {
    log "=== Migration Status ==="
    echo ""

    log "Current Revision:"
    get_current_revision

    echo ""
    log "Recent Migrations:"
    get_migration_history

    echo ""
}

# Main migration flow
main() {
    local command=${2:-upgrade}

    log "Database Migration Tool - Environment: $ENVIRONMENT"
    echo ""

    # Validate environment
    if ! validate_environment; then
        log_error "Environment validation failed"
        exit 1
    fi

    # Check database connectivity
    if ! check_database; then
        log_error "Database connectivity failed"
        exit 1
    fi

    # Validate migration files
    if ! validate_migrations; then
        log_error "Migration validation failed"
        exit 1
    fi

    # Process command
    case $command in
        upgrade)
            log "Starting upgrade migration..."

            # Show current status
            show_migration_status

            # Perform dry run
            if ! perform_dry_run; then
                log_error "Dry run failed - aborting"
                exit 1
            fi

            echo ""
            read -p "Proceed with migration? (yes/no): " confirm
            if [ "$confirm" != "yes" ]; then
                log "Migration cancelled by user"
                exit 0
            fi

            # Run migrations
            if ! run_migrations; then
                log_error "Migration failed"
                exit 1
            fi

            # Verify success
            if ! verify_migration; then
                log_error "Migration verification failed"
                exit 1
            fi

            show_migration_status
            log "Upgrade migration completed successfully!"
            ;;

        downgrade)
            local steps=${3:-1}
            log "Starting downgrade migration (rolling back $steps step(s))..."

            # Show current status
            show_migration_status

            read -p "Rollback $steps migration(s)? (yes/no): " confirm
            if [ "$confirm" != "yes" ]; then
                log "Rollback cancelled by user"
                exit 0
            fi

            # Rollback migrations
            if ! rollback_migration "$steps"; then
                log_error "Rollback failed"
                exit 1
            fi

            show_migration_status
            log "Downgrade migration completed successfully!"
            ;;

        status)
            show_migration_status
            ;;

        history)
            log "Full migration history:"
            cd "$PROJECT_ROOT"
            alembic history
            ;;

        current)
            log "Current revision:"
            cd "$PROJECT_ROOT"
            alembic current
            ;;

        *)
            echo "Usage: $0 [staging|production] [upgrade|downgrade|status|history|current] [steps]"
            echo ""
            echo "Commands:"
            echo "  upgrade       - Run pending migrations (default)"
            echo "  downgrade     - Rollback N migrations (default 1)"
            echo "  status        - Show migration status"
            echo "  history       - Show full migration history"
            echo "  current       - Show current revision"
            echo ""
            echo "Examples:"
            echo "  $0 staging upgrade"
            echo "  $0 production upgrade"
            echo "  $0 staging downgrade 1"
            echo "  $0 production status"
            exit 1
            ;;
    esac

    exit 0
}

# Run main function
main "$@"
