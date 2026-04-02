#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKEND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="$(cd "$BACKEND_DIR/.." && pwd)"
COMPOSE_FILE="$BACKEND_DIR/docker-compose.yml"
TEST_ENV_FILE="$BACKEND_DIR/.env.test"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Rosier Backend Test Suite${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Step 1: Create test environment file
echo -e "${YELLOW}[1/6] Setting up test environment...${NC}"
cat > "$TEST_ENV_FILE" << 'EOF'
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/rosier_test
REDIS_URL=redis://localhost:6379/1
ELASTICSEARCH_URL=http://localhost:9200
JWT_SECRET_KEY=test-secret-key-do-not-use-in-production
ENVIRONMENT=test
SENTRY_DSN=
EOF
echo -e "${GREEN}✓ Test environment configured${NC}"
echo ""

# Step 2: Start docker services
echo -e "${YELLOW}[2/6] Starting Docker services...${NC}"
cd "$BACKEND_DIR"

# Check if containers are already running
if docker-compose ps | grep -q "Up"; then
    echo "Stopping existing containers..."
    docker-compose down 2>/dev/null || true
fi

# Start fresh services
docker-compose up -d postgres redis elasticsearch

# Wait for services to be healthy
echo "Waiting for services to be healthy..."
max_attempts=30
attempt=0

while [ $attempt -lt $max_attempts ]; do
    # Check PostgreSQL
    if docker-compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then
        # Check Redis
        if docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; then
            # Check Elasticsearch
            if curl -s http://localhost:9200 > /dev/null 2>&1; then
                echo -e "${GREEN}✓ All services healthy${NC}"
                break
            fi
        fi
    fi

    attempt=$((attempt + 1))
    if [ $attempt -eq $max_attempts ]; then
        echo -e "${RED}✗ Services failed to start${NC}"
        docker-compose logs
        exit 1
    fi

    echo "Waiting... ($attempt/$max_attempts)"
    sleep 2
done
echo ""

# Step 3: Install Python dependencies
echo -e "${YELLOW}[3/6] Installing Python dependencies...${NC}"
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
fi

source .venv/bin/activate
pip install -q -r requirements.txt
pip install -q pytest pytest-asyncio pytest-cov httpx

echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

# Step 4: Run database migrations
echo -e "${YELLOW}[4/6] Running database migrations...${NC}"
export $(cat "$TEST_ENV_FILE" | xargs)

alembic upgrade head
echo -e "${GREEN}✓ Migrations completed${NC}"
echo ""

# Step 5: Run test suite
echo -e "${YELLOW}[5/6] Running test suite...${NC}"
echo ""

# Array to store test results
test_results=()

# Run each test file with coverage
test_files=(
    "tests/test_auth.py"
    "tests/test_cards.py"
    "tests/test_dresser.py"
    "tests/test_onboarding.py"
    "tests/test_products.py"
    "tests/test_profile.py"
    "tests/test_recommendation.py"
    "tests/test_api_integration.py"
    "tests/test_edge_cases.py"
    "tests/test_database_migrations.py"
    "tests/test_services.py"
    "tests/test_performance.py"
)

for test_file in "${test_files[@]}"; do
    if [ -f "$test_file" ]; then
        echo -e "${BLUE}Running $test_file...${NC}"
        if pytest "$test_file" -v --tb=short --color=yes 2>&1 | tee -a test_output.log; then
            test_results+=("✓ $test_file")
        else
            test_results+=("✗ $test_file")
        fi
    fi
done

echo ""
echo -e "${BLUE}Running full coverage report...${NC}"
pytest tests/ -v --cov=app --cov-report=html --cov-report=term-missing --cov-report=xml 2>&1 | tee -a test_output.log
echo ""

# Step 6: Cleanup
echo -e "${YELLOW}[6/6] Cleaning up...${NC}"
deactivate || true
echo -e "${GREEN}✓ Cleanup complete${NC}"
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"
for result in "${test_results[@]}"; do
    echo "$result"
done

# Check coverage
if [ -f "coverage.xml" ]; then
    echo ""
    echo -e "${BLUE}Coverage Report:${NC}"
    grep -A 1 'line-rate' coverage.xml | head -1
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Test Results${NC}"
echo -e "${BLUE}========================================${NC}"

# Parse results from log
if grep -q "failed" test_output.log; then
    echo -e "${RED}Some tests failed. Check test_output.log for details.${NC}"
    docker-compose down
    exit 1
else
    echo -e "${GREEN}All tests passed!${NC}"
fi

# Optional: keep services running or stop them
read -p "Keep Docker services running? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Stopping Docker services...${NC}"
    docker-compose down
    echo -e "${GREEN}✓ Services stopped${NC}"
else
    echo -e "${YELLOW}Services still running. Stop with: cd $BACKEND_DIR && docker-compose down${NC}"
fi

echo ""
echo -e "${GREEN}Test run complete!${NC}"
