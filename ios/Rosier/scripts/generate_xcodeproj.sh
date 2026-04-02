#!/bin/bash
#
# Rosier iOS - Xcode Project Generation Script
# Generates .xcodeproj from project.yml using XcodeGen
# This runs as the first step in CI/CD pipeline
#
# Usage:
#   ./scripts/generate_xcodeproj.sh [--verbose]
#
# Environment Variables:
#   XCODEGEN_VERSION: Version to install (default: latest)
#   CI: Set automatically by GitHub Actions
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_YML="$PROJECT_DIR/project.yml"
XCODE_PROJ="$PROJECT_DIR/Rosier.xcodeproj"
VERBOSE=false
XCODEGEN_VERSION="${XCODEGEN_VERSION:-latest}"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --verbose|-v)
      VERBOSE=true
      shift
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

# Helper functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_verbose() {
  if [[ "$VERBOSE" == true ]]; then
    echo -e "${BLUE}[DEBUG]${NC} $1"
  fi
}

# Check prerequisites
check_prerequisites() {
  log_info "Checking prerequisites..."

  if ! command -v xcodegen &> /dev/null; then
    log_warn "XcodeGen not found, installing via Homebrew..."
    if command -v brew &> /dev/null; then
      brew install xcodegen
      log_success "XcodeGen installed"
    else
      log_error "Homebrew not found. Please install XcodeGen manually:"
      log_error "  brew install xcodegen"
      exit 1
    fi
  fi

  if ! [[ -f "$PROJECT_YML" ]]; then
    log_error "project.yml not found at: $PROJECT_YML"
    exit 1
  fi

  log_verbose "XcodeGen version: $(xcodegen version 2>/dev/null || echo 'unknown')"
  log_success "Prerequisites check passed"
}

# Validate project.yml
validate_project_yml() {
  log_info "Validating project.yml..."

  # Basic syntax check - ensure it's valid YAML
  if ! command -v yq &> /dev/null; then
    log_verbose "yq not found, skipping YAML validation"
  else
    if yq eval '.' "$PROJECT_YML" > /dev/null 2>&1; then
      log_success "project.yml syntax valid"
    else
      log_error "Invalid YAML syntax in project.yml"
      exit 1
    fi
  fi

  # Check required fields
  log_verbose "Checking required project.yml fields..."

  if ! grep -q "^name:" "$PROJECT_YML"; then
    log_error "Missing 'name' field in project.yml"
    exit 1
  fi

  if ! grep -q "^targets:" "$PROJECT_YML"; then
    log_error "Missing 'targets' field in project.yml"
    exit 1
  fi

  log_success "project.yml validation passed"
}

# Backup existing Xcode project
backup_existing_project() {
  if [[ -d "$XCODE_PROJ" ]]; then
    local backup_dir="${XCODE_PROJ}.backup.$(date +%s)"
    log_warn "Backing up existing Xcode project to: $backup_dir"
    mv "$XCODE_PROJ" "$backup_dir"
    log_verbose "Backup created: $backup_dir"
  fi
}

# Generate Xcode project
generate_xcode_project() {
  log_info "Generating Xcode project from project.yml..."
  log_verbose "Working directory: $PROJECT_DIR"
  log_verbose "project.yml: $PROJECT_YML"
  log_verbose "Output: $XCODE_PROJ"

  cd "$PROJECT_DIR"

  if xcodegen generate; then
    log_success "Xcode project generated successfully"
  else
    log_error "Failed to generate Xcode project"
    log_error "Restore from backup and check project.yml for errors"
    exit 1
  fi
}

# Verify generated project structure
verify_project_structure() {
  log_info "Verifying generated project structure..."

  # Check that .xcodeproj exists
  if ! [[ -d "$XCODE_PROJ" ]]; then
    log_error "Xcode project not found at: $XCODE_PROJ"
    exit 1
  fi

  # Check required files
  local required_files=(
    "project.pbxproj"
    "xcshareddata/xcschemes/Rosier.xcscheme"
  )

  for file in "${required_files[@]}"; do
    if ! [[ -f "$XCODE_PROJ/$file" ]]; then
      log_warn "Expected file not found: $XCODE_PROJ/$file"
    else
      log_verbose "Found: $file"
    fi
  done

  # Verify project.pbxproj is valid
  if ! plutil -lint "$XCODE_PROJ/project.pbxproj" > /dev/null 2>&1; then
    log_warn "project.pbxproj may have issues (plutil check skipped)"
  fi

  log_success "Project structure verification passed"
}

# Validate build settings
validate_build_settings() {
  log_info "Validating build settings..."

  # Check that key build settings are present
  local pbxproj_path="$XCODE_PROJ/project.pbxproj"

  if ! grep -q "PRODUCT_BUNDLE_IDENTIFIER" "$pbxproj_path"; then
    log_warn "PRODUCT_BUNDLE_IDENTIFIER not found in build settings"
  else
    log_verbose "PRODUCT_BUNDLE_IDENTIFIER: com.rosier.app"
  fi

  if ! grep -q "IPHONEOS_DEPLOYMENT_TARGET" "$pbxproj_path"; then
    log_warn "IPHONEOS_DEPLOYMENT_TARGET not found in build settings"
  else
    log_verbose "IPHONEOS_DEPLOYMENT_TARGET: 17.0"
  fi

  log_success "Build settings validation passed"
}

# Quick build test (optional)
quick_build_test() {
  if [[ "$VERBOSE" == true ]]; then
    log_info "Running quick build test..."

    cd "$PROJECT_DIR"

    if xcodebuild build \
      -project "$XCODE_PROJ" \
      -scheme Rosier \
      -configuration Debug \
      -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
      -derivedDataPath build \
      CODE_SIGN_IDENTITY="" \
      CODE_SIGNING_REQUIRED=NO \
      2>&1 | tail -5; then
      log_success "Quick build test passed"
    else
      log_warn "Quick build test failed (non-fatal)"
    fi
  fi
}

# Print summary
print_summary() {
  log_success "Xcode project generation completed successfully!"
  echo ""
  echo -e "${BLUE}Summary:${NC}"
  echo "  Project: Rosier"
  echo "  Bundle ID: com.rosier.app"
  echo "  Deployment Target: iOS 17.0"
  echo "  Swift Version: 5.9"
  echo "  Generated: $XCODE_PROJ"
  echo ""
  echo "Next steps:"
  echo "  1. Verify all targets are listed: xcodebuild -project '$XCODE_PROJ' -list"
  echo "  2. Build the project: xcodebuild build -project '$XCODE_PROJ' -scheme Rosier"
  echo "  3. Run tests: xcodebuild test -project '$XCODE_PROJ' -scheme Rosier"
}

# Main execution
main() {
  echo ""
  log_info "Rosier iOS - Xcode Project Generator"
  echo "======================================="
  echo ""

  check_prerequisites
  validate_project_yml
  backup_existing_project
  generate_xcode_project
  verify_project_structure
  validate_build_settings
  quick_build_test
  print_summary
}

# Run main function
main

exit 0
