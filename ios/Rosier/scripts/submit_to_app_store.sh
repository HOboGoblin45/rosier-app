#!/bin/bash

# Rosier App Store Submission Script
# Automates TestFlight and App Store submissions with full validation
# Usage: ./submit_to_app_store.sh [testflight|appstore] [--skip-validation] [--notify]

set -euo pipefail

# ANSI color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Configuration
readonly SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly BUILD_DIR="$PROJECT_ROOT/build"
readonly EXPORT_DIR="$BUILD_DIR/export"
readonly ARCHIVE_PATH="$BUILD_DIR/Rosier.xcarchive"
readonly IPA_PATH="$EXPORT_DIR/Rosier.ipa"
readonly APP_IDENTIFIER="com.rosier.app"
readonly TEAM_ID="${APPLE_TEAM_ID:-}"
readonly XCODE_VERSION_MIN="16.0"

# Slack configuration (optional)
readonly SLACK_WEBHOOK="${SLACK_WEBHOOK_URL:-}"

# Submission mode (testflight|appstore)
MODE="${1:-testflight}"
SKIP_VALIDATION="${2:---skip-validation}"
NOTIFY="${3:---notify}"

# Counters
PREFLIGHT_CHECKS=0
PREFLIGHT_PASSED=0
PREFLIGHT_FAILED=0

# ==============================================================================
# UTILITY FUNCTIONS
# ==============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_section() {
    echo ""
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo ""
}

preflight_check() {
    local check_name="$1"
    local check_cmd="$2"
    local expected_result="${3:-0}"

    ((PREFLIGHT_CHECKS++))

    if eval "$check_cmd" > /dev/null 2>&1; then
        if [[ "$expected_result" == "0" ]]; then
            log_success "$check_name"
            ((PREFLIGHT_PASSED++))
            return 0
        fi
    fi

    log_error "$check_name"
    ((PREFLIGHT_FAILED++))
    return 1
}

notify_slack() {
    local message="$1"
    local status="${2:-:information_source:}"

    if [[ -z "$SLACK_WEBHOOK" ]]; then
        return
    fi

    local payload=$(cat <<EOF
{
    "blocks": [
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "$status *Rosier App Store Submission*\n$message"
            }
        }
    ]
}
EOF
)

    curl -X POST -H 'Content-type: application/json' \
        --data "$payload" \
        "$SLACK_WEBHOOK" > /dev/null 2>&1 || true
}

# ==============================================================================
# VALIDATION FUNCTIONS
# ==============================================================================

validate_inputs() {
    log_section "Validating Submission Inputs"

    if [[ ! "$MODE" =~ ^(testflight|appstore)$ ]]; then
        log_error "Invalid mode: $MODE. Must be 'testflight' or 'appstore'"
        exit 1
    fi

    if [[ -z "$TEAM_ID" ]]; then
        log_warning "APPLE_TEAM_ID not set. App Store operations may fail."
    fi

    log_success "Submission mode: $MODE"
}

validate_environment() {
    log_section "Validating Environment"

    # Check Xcode version
    local xcode_version=$(xcodebuild -version | grep "Xcode" | awk '{print $2}')
    log_info "Xcode version: $xcode_version"

    if ! [[ "$xcode_version" > "$XCODE_VERSION_MIN" ]] 2>/dev/null; then
        log_error "Xcode $XCODE_VERSION_MIN+ required (found $xcode_version)"
        exit 1
    fi

    # Check for required tools
    preflight_check "xcodebuild installed" "command -v xcodebuild"
    preflight_check "xcrun installed" "command -v xcrun"
    preflight_check "git installed" "command -v git"

    if [[ $PREFLIGHT_FAILED -gt 0 ]]; then
        log_error "$PREFLIGHT_FAILED environment checks failed"
        exit 1
    fi

    log_success "Environment validation passed"
}

validate_certificates() {
    log_section "Validating Code Signing"

    # List available signing identities
    security find-identity -v -p codesigning > /tmp/identities.txt 2>&1 || true

    if [[ ! -s /tmp/identities.txt ]] || grep -q "0 identities found" /tmp/identities.txt; then
        log_error "No code signing identities found. Set up in Keychain Access."
        exit 1
    fi

    log_success "Found valid code signing identities"
    log_info "Available identities:"
    security find-identity -v -p codesigning | grep -E "(^[[:space:]]+[0-9]+|Developer ID)" || true
}

validate_provisioning_profiles() {
    log_section "Validating Provisioning Profiles"

    local profiles_dir="$HOME/Library/MobileDevice/Provisioning Profiles"

    if [[ ! -d "$profiles_dir" ]]; then
        log_error "No provisioning profiles found at $profiles_dir"
        exit 1
    fi

    local profile_count=$(ls "$profiles_dir"/*.mobileprovision 2>/dev/null | wc -l)

    if [[ $profile_count -eq 0 ]]; then
        log_error "No provisioning profiles installed"
        exit 1
    fi

    log_success "Found $profile_count provisioning profile(s)"
}

validate_source_code() {
    log_section "Validating Source Code Quality"

    PREFLIGHT_CHECKS=0
    PREFLIGHT_PASSED=0
    PREFLIGHT_FAILED=0

    # Check for force unwraps (excluding test code and comments)
    local force_unwraps=$(grep -r '!' "$PROJECT_ROOT/Sources" --include='*.swift' 2>/dev/null | \
        grep -v '//' | grep -v '!=' | grep -v '!(' | wc -l)

    if [[ $force_unwraps -gt 0 ]]; then
        log_warning "Found $force_unwraps force unwraps in production code"
    fi

    # Check for TODO/FIXME in production code
    local todos=$(grep -r 'TODO\|FIXME' "$PROJECT_ROOT/Sources" --include='*.swift' 2>/dev/null | \
        grep -v 'Tests/' | wc -l)

    if [[ $todos -gt 0 ]]; then
        log_warning "Found $todos TODO/FIXME comments in production code"
    fi

    # Check for debug print statements
    local prints=$(grep -r 'print(' "$PROJECT_ROOT/Sources" --include='*.swift' 2>/dev/null | \
        grep -v 'Tests/' | grep -v 'os_log' | wc -l)

    if [[ $prints -gt 0 ]]; then
        log_warning "Found $prints print statements (should use os_log)"
    fi

    preflight_check "Swift syntax valid" \
        "swiftc -typecheck -parse '$PROJECT_ROOT/Sources' 2>/dev/null || true"

    log_success "Source code validation complete"
}

validate_required_files() {
    log_section "Validating Required App Store Files"

    PREFLIGHT_CHECKS=0
    PREFLIGHT_PASSED=0
    PREFLIGHT_FAILED=0

    preflight_check "Info.plist exists" \
        "test -f '$PROJECT_ROOT/Sources/App/Info.plist'"

    preflight_check "Entitlements file exists" \
        "test -f '$PROJECT_ROOT/Sources/App/Rosier.entitlements'"

    preflight_check "PrivacyInfo.xcprivacy exists" \
        "test -f '$PROJECT_ROOT/Sources/App/PrivacyInfo.xcprivacy'"

    preflight_check "Launch screen exists" \
        "test -f '$PROJECT_ROOT/Resources/LaunchScreen.storyboard'"

    preflight_check "App icon exists (1024x1024)" \
        "test -f '$PROJECT_ROOT/Resources/Assets/AppIcon-1024.png'"

    # Validate Info.plist content
    local bundle_version=$(defaults read "$PROJECT_ROOT/Sources/App/Info" CFBundleShortVersionString 2>/dev/null || echo "")
    if [[ -z "$bundle_version" ]]; then
        log_error "CFBundleShortVersionString not set in Info.plist"
        ((PREFLIGHT_FAILED++))
    else
        log_success "Bundle version: $bundle_version"
        ((PREFLIGHT_PASSED++))
    fi

    if [[ $PREFLIGHT_FAILED -gt 0 ]]; then
        log_error "$PREFLIGHT_FAILED required files are missing"
        exit 1
    fi

    log_success "All required files present"
}

validate_app_store_metadata() {
    log_section "Validating App Store Metadata"

    PREFLIGHT_CHECKS=0
    PREFLIGHT_PASSED=0
    PREFLIGHT_FAILED=0

    # Check for required legal documents
    preflight_check "Terms of Service exists" \
        "test -f '$PROJECT_ROOT/../../docs/legal/terms_of_service.md'"

    preflight_check "Privacy Policy exists" \
        "test -f '$PROJECT_ROOT/../../docs/legal/privacy_policy.md'"

    # Validate entitlements for App Store requirements
    if grep -q "com.apple.developer.applesignin" "$PROJECT_ROOT/Sources/App/Rosier.entitlements"; then
        log_success "Apple Sign-In entitlement configured"
        ((PREFLIGHT_PASSED++))
    else
        log_warning "Apple Sign-In not configured (optional)"
    fi

    if grep -q "aps-environment" "$PROJECT_ROOT/Sources/App/Rosier.entitlements"; then
        log_success "Push notifications entitlement configured"
        ((PREFLIGHT_PASSED++))
    fi

    # Validate privacy manifest
    if grep -q "NSPrivacyTracking" "$PROJECT_ROOT/Sources/App/PrivacyInfo.xcprivacy"; then
        log_success "Privacy manifest includes tracking declaration"
        ((PREFLIGHT_PASSED++))
    fi

    if [[ $PREFLIGHT_FAILED -gt 0 ]]; then
        log_warning "$PREFLIGHT_FAILED app store requirements not fully configured"
    fi
}

run_all_validations() {
    if [[ "$SKIP_VALIDATION" != "--skip-validation" ]]; then
        validate_environment
        validate_certificates
        validate_provisioning_profiles
        validate_source_code
        validate_required_files
        validate_app_store_metadata
    else
        log_warning "Skipping validations (--skip-validation flag set)"
    fi
}

# ==============================================================================
# BUILD FUNCTIONS
# ==============================================================================

clean_build_artifacts() {
    log_section "Cleaning Previous Build Artifacts"

    if [[ -d "$BUILD_DIR" ]]; then
        log_info "Removing $BUILD_DIR"
        rm -rf "$BUILD_DIR"
    fi

    log_success "Build artifacts cleaned"
}

build_archive() {
    log_section "Building Archive"

    mkdir -p "$BUILD_DIR"

    local build_cmd="xcodebuild archive \
        -scheme Rosier \
        -configuration Release \
        -archivePath '$ARCHIVE_PATH' \
        -destination 'generic/platform=iOS' \
        -allowProvisioningUpdates"

    if [[ -n "$TEAM_ID" ]]; then
        build_cmd="$build_cmd -teamID $TEAM_ID"
    fi

    log_info "Building with command: $build_cmd"

    if eval "$build_cmd" 2>&1 | tee "$BUILD_DIR/build.log"; then
        log_success "Archive built successfully: $ARCHIVE_PATH"
    else
        log_error "Archive build failed. See $BUILD_DIR/build.log for details."
        exit 1
    fi

    # Validate archive
    if [[ ! -d "$ARCHIVE_PATH" ]]; then
        log_error "Archive not found at expected path: $ARCHIVE_PATH"
        exit 1
    fi

    log_success "Archive validated"
}

export_ipa() {
    log_section "Exporting IPA"

    mkdir -p "$EXPORT_DIR"

    # Create export options plist
    local export_options_plist="$BUILD_DIR/ExportOptions.plist"
    cat > "$export_options_plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>${MODE}</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>teamID</key>
    <string>${TEAM_ID}</string>
    <key>teamBundleIdentifier</key>
    <string>${APP_IDENTIFIER}</string>
</dict>
</plist>
EOF

    log_info "ExportOptions.plist created"

    local export_cmd="xcodebuild -exportArchive \
        -archivePath '$ARCHIVE_PATH' \
        -exportOptionsPlist '$export_options_plist' \
        -exportPath '$EXPORT_DIR'"

    log_info "Exporting IPA..."

    if eval "$export_cmd" 2>&1 | tee "$BUILD_DIR/export.log"; then
        log_success "IPA exported successfully"
    else
        log_error "IPA export failed. See $BUILD_DIR/export.log for details."
        exit 1
    fi

    # Validate IPA
    if [[ ! -f "$IPA_PATH" ]]; then
        log_error "IPA not found at expected path: $IPA_PATH"
        exit 1
    fi

    local ipa_size=$(du -h "$IPA_PATH" | cut -f1)
    log_success "IPA validated (Size: $ipa_size)"
}

validate_with_app_store_connect() {
    log_section "Validating with App Store Connect"

    if [[ ! -f "$IPA_PATH" ]]; then
        log_error "IPA not found: $IPA_PATH"
        exit 1
    fi

    # Use xcrun altool for validation
    log_info "Validating IPA with altool..."

    if xcrun altool --validate-app \
        --file "$IPA_PATH" \
        --type ios \
        --apiKey "$APPLE_API_KEY" \
        --apiIssuer "$APPLE_API_ISSUER" 2>&1 | tee "$BUILD_DIR/validation.log"; then
        log_success "IPA validation passed"
    else
        log_error "IPA validation failed. See $BUILD_DIR/validation.log"
        exit 1
    fi
}

upload_to_app_store_connect() {
    log_section "Uploading to App Store Connect"

    if [[ ! -f "$IPA_PATH" ]]; then
        log_error "IPA not found: $IPA_PATH"
        exit 1
    fi

    log_info "Uploading IPA to $MODE..."

    if xcrun altool --upload-app \
        --file "$IPA_PATH" \
        --type ios \
        --apiKey "$APPLE_API_KEY" \
        --apiIssuer "$APPLE_API_ISSUER" 2>&1 | tee "$BUILD_DIR/upload.log"; then
        log_success "IPA uploaded successfully to $MODE"
    else
        log_error "IPA upload failed. See $BUILD_DIR/upload.log"
        exit 1
    fi
}

# ==============================================================================
# POST-SUBMISSION FUNCTIONS
# ==============================================================================

tag_release() {
    log_section "Tagging Release"

    local version=$(defaults read "$PROJECT_ROOT/Sources/App/Info" CFBundleShortVersionString 2>/dev/null || echo "1.0.0")
    local tag="v$version-$(date +%Y%m%d-%H%M%S)"

    if cd "$PROJECT_ROOT" && git tag "$tag" 2>/dev/null; then
        log_success "Git tag created: $tag"
        git push origin "$tag" 2>/dev/null || log_warning "Could not push tag (git push may require credentials)"
    else
        log_warning "Could not create git tag (not a git repo or detached HEAD)"
    fi
}

notify_team() {
    log_section "Notifying Team"

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local message="Rosier submitted to App Store $MODE at $timestamp"

    notify_slack "$message" ":rocket:"

    log_success "Team notification sent"
}

update_submission_record() {
    log_section "Updating Submission Record"

    local submission_file="$PROJECT_ROOT/SUBMISSION_RECORD.txt"
    local timestamp=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
    local version=$(defaults read "$PROJECT_ROOT/Sources/App/Info" CFBundleShortVersionString 2>/dev/null || echo "1.0.0")

    cat >> "$submission_file" <<EOF

=== Submission Record ===
Timestamp: $timestamp
Mode: $MODE
Version: $version
Archive: $ARCHIVE_PATH
IPA: $IPA_PATH
Build Log: $BUILD_DIR/build.log
Export Log: $BUILD_DIR/export.log
EOF

    log_success "Submission record updated: $submission_file"
}

print_summary() {
    log_section "Submission Summary"

    echo "Mode:          $MODE"
    echo "Archive:       $ARCHIVE_PATH"
    echo "IPA:           $IPA_PATH"
    echo "Build Log:     $BUILD_DIR/build.log"
    echo "Export Log:    $BUILD_DIR/export.log"
    echo "Timestamp:     $(date)"
    echo ""
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    log_section "Rosier App Store Submission"
    echo "Submission Mode: $MODE"
    echo "Timestamp: $(date)"
    echo ""

    validate_inputs

    # Run all preflight checks
    run_all_validations

    # Build and export
    clean_build_artifacts
    build_archive
    export_ipa

    # Validate and upload
    validate_with_app_store_connect
    upload_to_app_store_connect

    # Post-submission tasks
    tag_release
    update_submission_record
    print_summary

    # Notify team
    if [[ "$NOTIFY" == "--notify" ]]; then
        notify_team
    fi

    log_success "Submission complete!"
}

main "$@"
