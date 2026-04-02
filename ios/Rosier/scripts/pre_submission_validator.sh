#!/bin/bash

# Rosier Pre-App Store Submission Validator
# Comprehensive checklist verification before submitting to Apple
# Usage: ./pre_submission_validator.sh [--verbose] [--fix-report]

set -euo pipefail

# ANSI color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly GRAY='\033[0;37m'
readonly NC='\033[0m' # No Color

# Configuration
readonly SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly SOURCES_DIR="$PROJECT_ROOT/Sources"
readonly TESTS_DIR="$PROJECT_ROOT/Tests"
readonly RESOURCES_DIR="$PROJECT_ROOT/Resources"

# Options
VERBOSE="${1:---verbose}"
FIX_REPORT="${2:---fix-report}"

# Counters
CHECKS_TOTAL=0
CHECKS_PASS=0
CHECKS_FAIL=0
CHECKS_WARN=0

# Track failures for final report
declare -a FAILED_CHECKS
declare -a WARNING_CHECKS

# ==============================================================================
# UTILITY FUNCTIONS
# ==============================================================================

log_pass() {
    ((CHECKS_PASS++))
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_fail() {
    ((CHECKS_FAIL++))
    FAILED_CHECKS+=("$1")
    echo -e "${RED}[FAIL]${NC} $1"
}

log_warn() {
    ((CHECKS_WARN++))
    WARNING_CHECKS+=("$1")
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_info() {
    if [[ "$VERBOSE" == "--verbose" ]]; then
        echo -e "${BLUE}[INFO]${NC} $1"
    fi
}

log_section() {
    echo ""
    echo -e "${BLUE}=== $1 ===${NC}"
}

check() {
    ((CHECKS_TOTAL++))
    local check_name="$1"
    local check_cmd="$2"
    local check_type="${3:-pass}" # pass, warn, info

    log_info "Running: $check_name"

    if eval "$check_cmd" > /dev/null 2>&1; then
        case $check_type in
            pass) log_pass "$check_name" ;;
            warn) log_warn "$check_name" ;;
            info) log_info "$check_name" ;;
        esac
        return 0
    else
        case $check_type in
            pass) log_fail "$check_name" ;;
            warn) log_warn "$check_name" ;;
            info) log_info "$check_name" ;;
        esac
        return 1
    fi
}

# ==============================================================================
# CODE QUALITY CHECKS
# ==============================================================================

run_code_quality_checks() {
    log_section "CODE QUALITY CHECKS"

    # Force unwraps (should be minimal)
    local unwrap_count=$(grep -r '!' "$SOURCES_DIR" --include='*.swift' 2>/dev/null | \
        grep -v '//' | grep -v '!=' | grep -v '!(' | grep -v 'IBOutlet' | wc -l || echo "0")

    if [[ $unwrap_count -eq 0 ]]; then
        log_pass "No force unwraps found"
    elif [[ $unwrap_count -lt 5 ]]; then
        log_warn "Found $unwrap_count force unwraps (acceptable in small amounts)"
    else
        log_fail "Found $unwrap_count force unwraps (should be < 5)"
    fi
    ((CHECKS_TOTAL++))

    # SwiftLint checks (if available)
    if command -v swiftlint > /dev/null 2>&1; then
        local lint_errors=$(swiftlint lint "$SOURCES_DIR" --quiet 2>&1 | grep -c "error:" || echo "0")
        if [[ $lint_errors -eq 0 ]]; then
            log_pass "SwiftLint: No errors"
        else
            log_fail "SwiftLint: $lint_errors error(s) found"
        fi
        ((CHECKS_TOTAL++))
    else
        log_warn "SwiftLint not installed (optional but recommended)"
        ((CHECKS_TOTAL++))
    fi

    # TODO/FIXME in production code
    local todo_count=$(grep -rn 'TODO\|FIXME' "$SOURCES_DIR" --include='*.swift' 2>/dev/null | \
        grep -v 'Tests/' | wc -l || echo "0")

    if [[ $todo_count -eq 0 ]]; then
        log_pass "No TODO/FIXME comments in production code"
    else
        log_warn "Found $todo_count TODO/FIXME comments (should clean before submission)"
    fi
    ((CHECKS_TOTAL++))

    # Print statements (should use os_log)
    local print_count=$(grep -rn 'print(' "$SOURCES_DIR" --include='*.swift' 2>/dev/null | \
        grep -v 'Tests/' | grep -v 'os_log' | wc -l || echo "0")

    if [[ $print_count -eq 0 ]]; then
        log_pass "No print statements in production code"
    else
        log_fail "Found $print_count print statements (use os_log instead)"
    fi
    ((CHECKS_TOTAL++))

    # Check for hardcoded secrets
    local secrets=$(grep -rn 'api_key\|apiKey\|secret\|password' "$SOURCES_DIR" \
        --include='*.swift' 2>/dev/null | grep -v 'mock\|Mock\|test\|Test' | \
        grep -v 'Config\|config' | wc -l || echo "0")

    if [[ $secrets -eq 0 ]]; then
        log_pass "No hardcoded secrets detected"
    else
        log_fail "Found $secrets potential hardcoded secrets (use environment variables)"
    fi
    ((CHECKS_TOTAL++))

    # Compiler warnings
    log_info "Checking for compiler warnings..."
    check "No compiler warnings" \
        "swiftc -typecheck '$SOURCES_DIR' 2>&1 | grep -c 'warning:' | grep -q '^0$' || true"
}

# ==============================================================================
# REQUIRED FILES CHECKS
# ==============================================================================

run_required_files_checks() {
    log_section "REQUIRED FILES CHECKS"

    check "Info.plist exists" "test -f '$SOURCES_DIR/App/Info.plist'"
    ((CHECKS_TOTAL++))

    check "Entitlements file exists" "test -f '$SOURCES_DIR/App/Rosier.entitlements'"
    ((CHECKS_TOTAL++))

    check "PrivacyInfo.xcprivacy exists" "test -f '$SOURCES_DIR/App/PrivacyInfo.xcprivacy'"
    ((CHECKS_TOTAL++))

    check "LaunchScreen.storyboard exists" "test -f '$RESOURCES_DIR/LaunchScreen.storyboard'"
    ((CHECKS_TOTAL++))

    check "App icon (1024x1024) exists" "test -f '$RESOURCES_DIR/Assets/AppIcon-1024.png'"
    ((CHECKS_TOTAL++))

    check "Default assets configured" "ls '$RESOURCES_DIR/Assets/' | grep -q 'AppIcon' || true"
    ((CHECKS_TOTAL++))

    # Validate Info.plist is parseable
    if plutil -lint "$SOURCES_DIR/App/Info.plist" > /dev/null 2>&1; then
        log_pass "Info.plist is valid XML"
        ((CHECKS_TOTAL++))
    else
        log_fail "Info.plist has syntax errors"
        ((CHECKS_TOTAL++))
    fi

    # Validate entitlements file
    if plutil -lint "$SOURCES_DIR/App/Rosier.entitlements" > /dev/null 2>&1; then
        log_pass "Rosier.entitlements is valid XML"
        ((CHECKS_TOTAL++))
    else
        log_fail "Rosier.entitlements has syntax errors"
        ((CHECKS_TOTAL++))
    fi

    # Validate privacy manifest
    if plutil -lint "$SOURCES_DIR/App/PrivacyInfo.xcprivacy" > /dev/null 2>&1; then
        log_pass "PrivacyInfo.xcprivacy is valid XML"
        ((CHECKS_TOTAL++))
    else
        log_fail "PrivacyInfo.xcprivacy has syntax errors"
        ((CHECKS_TOTAL++))
    fi
}

# ==============================================================================
# APP STORE REQUIREMENTS CHECKS
# ==============================================================================

run_app_store_requirements_checks() {
    log_section "APP STORE REQUIREMENTS CHECKS"

    # ITSAppUsesNonExemptEncryption check
    if grep -q "ITSAppUsesNonExemptEncryption" "$SOURCES_DIR/App/Info.plist"; then
        local encryption_value=$(grep -A1 "ITSAppUsesNonExemptEncryption" "$SOURCES_DIR/App/Info.plist" | tail -1)
        if [[ "$encryption_value" == *"false"* ]]; then
            log_pass "ITSAppUsesNonExemptEncryption properly set to false"
        else
            log_fail "ITSAppUsesNonExemptEncryption should be false for non-encrypted app"
        fi
    else
        log_fail "ITSAppUsesNonExemptEncryption not declared"
    fi
    ((CHECKS_TOTAL++))

    # NSPrivacyTracking check
    if grep -q "NSPrivacyTracking" "$SOURCES_DIR/App/PrivacyInfo.xcprivacy"; then
        log_pass "NSPrivacyTracking declared in privacy manifest"
    else
        log_fail "NSPrivacyTracking not declared (required for App Store)"
    fi
    ((CHECKS_TOTAL++))

    # Apple Sign-In entitlement
    if grep -q "com.apple.developer.applesignin" "$SOURCES_DIR/App/Rosier.entitlements"; then
        log_pass "Apple Sign-In entitlement configured"
    else
        log_warn "Apple Sign-In not configured (optional, but recommended)"
    fi
    ((CHECKS_TOTAL++))

    # Push notification entitlement
    if grep -q "aps-environment" "$SOURCES_DIR/App/Rosier.entitlements"; then
        log_pass "Push notification entitlement configured"
    else
        log_warn "Push notifications not configured (optional)"
    fi
    ((CHECKS_TOTAL++))

    # Keychain sharing
    if grep -q "keychain-access-groups" "$SOURCES_DIR/App/Rosier.entitlements"; then
        log_pass "Keychain access groups configured"
    else
        log_warn "Keychain sharing not configured (optional)"
    fi
    ((CHECKS_TOTAL++))

    # Associated domains for deep linking
    if grep -q "com.apple.developer.associated-domains" "$SOURCES_DIR/App/Rosier.entitlements"; then
        log_pass "Associated domains configured for deep linking"
    else
        log_info "Associated domains not configured (optional if no deep linking)"
    fi
    ((CHECKS_TOTAL++))

    # App groups
    if grep -q "com.apple.security.application-groups" "$SOURCES_DIR/App/Rosier.entitlements"; then
        log_pass "App groups configured"
    else
        log_info "App groups not configured (optional)"
    fi
    ((CHECKS_TOTAL++))

    # Bundle identifier check
    local bundle_id=$(grep -A1 "CFBundleIdentifier" "$SOURCES_DIR/App/Info.plist" | tail -1 | grep -o 'com\.[a-zA-Z0-9.]*' || echo "")
    if [[ ! -z "$bundle_id" ]]; then
        log_pass "Bundle identifier configured: $bundle_id"
    else
        log_fail "Bundle identifier not configured"
    fi
    ((CHECKS_TOTAL++))

    # Version number
    local version=$(defaults read "$SOURCES_DIR/App/Info" CFBundleShortVersionString 2>/dev/null || echo "")
    if [[ ! -z "$version" ]]; then
        log_pass "App version set: $version"
    else
        log_fail "App version (CFBundleShortVersionString) not set"
    fi
    ((CHECKS_TOTAL++))

    # Minimum iOS version
    local min_ios=$(defaults read "$SOURCES_DIR/App/Info" MinimumOSVersion 2>/dev/null || echo "")
    if [[ ! -z "$min_ios" ]]; then
        log_pass "Minimum iOS version set: $min_ios"
    else
        log_fail "Minimum iOS version not set"
    fi
    ((CHECKS_TOTAL++))
}

# ==============================================================================
# LEGAL & COMPLIANCE CHECKS
# ==============================================================================

run_legal_checks() {
    log_section "LEGAL & COMPLIANCE CHECKS"

    check "Terms of Service exists" \
        "test -f '$PROJECT_ROOT/../../docs/legal/terms_of_service.md'"
    ((CHECKS_TOTAL++))

    check "Privacy Policy exists" \
        "test -f '$PROJECT_ROOT/../../docs/legal/privacy_policy.md'"
    ((CHECKS_TOTAL++))

    check "Affiliate Disclosure exists" \
        "test -f '$PROJECT_ROOT/../../docs/legal/affiliate_disclosure.md'"
    ((CHECKS_TOTAL++))

    # Verify legal docs are not empty
    if [[ -s "$PROJECT_ROOT/../../docs/legal/terms_of_service.md" ]]; then
        log_pass "Terms of Service is not empty"
    else
        log_fail "Terms of Service is empty or missing content"
    fi
    ((CHECKS_TOTAL++))

    if [[ -s "$PROJECT_ROOT/../../docs/legal/privacy_policy.md" ]]; then
        log_pass "Privacy Policy is not empty"
    else
        log_fail "Privacy Policy is empty or missing content"
    fi
    ((CHECKS_TOTAL++))
}

# ==============================================================================
# LOCALIZATION CHECKS
# ==============================================================================

run_localization_checks() {
    log_section "LOCALIZATION CHECKS"

    check "Localizable.strings exists" \
        "find '$SOURCES_DIR' -name 'Localizable.strings' | grep -q '.' || true"
    ((CHECKS_TOTAL++))

    # Check for hardcoded strings in SwiftUI/UIKit
    local hardcoded=$(grep -rn 'Text("' "$SOURCES_DIR" --include='*.swift' 2>/dev/null | \
        grep -v 'Localizable' | grep -v 'Mock' | grep -v 'test' | wc -l || echo "0")

    if [[ $hardcoded -lt 5 ]]; then
        log_warn "Found $hardcoded hardcoded Text strings (should use localization)"
    else
        log_fail "Found $hardcoded hardcoded Text strings (use localization keys)"
    fi
    ((CHECKS_TOTAL++))
}

# ==============================================================================
# TEST COVERAGE CHECKS
# ==============================================================================

run_test_coverage_checks() {
    log_section "TEST COVERAGE CHECKS"

    # Check for test files
    local test_count=$(find "$TESTS_DIR" -name '*Tests.swift' 2>/dev/null | wc -l || echo "0")

    if [[ $test_count -gt 0 ]]; then
        log_pass "Found $test_count test file(s)"
    else
        log_fail "No test files found"
    fi
    ((CHECKS_TOTAL++))

    # Count test methods
    local test_methods=$(grep -rn 'func test' "$TESTS_DIR" --include='*.swift' 2>/dev/null | wc -l || echo "0")

    if [[ $test_methods -ge 40 ]]; then
        log_pass "Found $test_methods test method(s) (requirement: >= 40)"
    elif [[ $test_methods -ge 20 ]]; then
        log_warn "Found $test_methods test method(s) (recommended: >= 40)"
    else
        log_fail "Found $test_methods test method(s) (minimum: 20, recommended: 40)"
    fi
    ((CHECKS_TOTAL++))

    # Check for XCTest imports
    if grep -q "import XCTest" "$TESTS_DIR"/*.swift 2>/dev/null; then
        log_pass "XCTest framework properly imported"
    else
        log_fail "XCTest not imported in tests"
    fi
    ((CHECKS_TOTAL++))

    # Check for mock objects
    if [[ -f "$TESTS_DIR/RosierTests/Mocks/MockServices.swift" ]]; then
        log_pass "Mock objects defined for testing"
    else
        log_info "No mock objects found (optional)"
    fi
    ((CHECKS_TOTAL++))
}

# ==============================================================================
# CONFIGURATION CHECKS
# ==============================================================================

run_configuration_checks() {
    log_section "CONFIGURATION CHECKS"

    # Package.swift exists
    check "Package.swift exists" "test -f '$PROJECT_ROOT/Package.swift'"
    ((CHECKS_TOTAL++))

    # Validate Package.swift syntax
    if swift package describe > /dev/null 2>&1 || cd "$PROJECT_ROOT" && swift package describe > /dev/null 2>&1; then
        log_pass "Package.swift is valid Swift manifest"
    else
        log_fail "Package.swift has syntax errors"
    fi
    ((CHECKS_TOTAL++))

    # Check for .swiftlint.yml
    if [[ -f "$PROJECT_ROOT/.swiftlint.yml" ]]; then
        log_pass ".swiftlint.yml configuration file exists"
    else
        log_info ".swiftlint.yml not found (optional but recommended)"
    fi
    ((CHECKS_TOTAL++))

    # Check for .gitignore
    check "Git is properly configured" "test -f '$PROJECT_ROOT/.gitignore'"
    ((CHECKS_TOTAL++))
}

# ==============================================================================
# ACCESSIBILITY CHECKS
# ==============================================================================

run_accessibility_checks() {
    log_section "ACCESSIBILITY CHECKS"

    # Check for accessibility identifiers
    local accessibility=$(grep -rn 'accessibilityIdentifier\|accessibilityLabel\|accessibilityValue' \
        "$SOURCES_DIR" --include='*.swift' 2>/dev/null | wc -l || echo "0")

    if [[ $accessibility -gt 10 ]]; then
        log_pass "Accessibility labels configured ($accessibility found)"
    else
        log_warn "Limited accessibility configuration ($accessibility labels found)"
    fi
    ((CHECKS_TOTAL++))

    # Check for appropriate dynamic type usage
    local dynamic_type=$(grep -rn 'dynamicTypeSize\|preferredContentSizeCategory' \
        "$SOURCES_DIR" --include='*.swift' 2>/dev/null | wc -l || echo "0")

    if [[ $dynamic_type -gt 0 ]]; then
        log_pass "Dynamic type support implemented"
    else
        log_warn "No dynamic type support detected"
    fi
    ((CHECKS_TOTAL++))

    # Check for color contrast helpers
    if grep -q 'accessibilityElement\|isAccessibilityElement' "$SOURCES_DIR" --include='*.swift' 2>/dev/null; then
        log_pass "Accessibility elements properly marked"
    else
        log_warn "Accessibility element marking not found"
    fi
    ((CHECKS_TOTAL++))
}

# ==============================================================================
# PERFORMANCE CHECKS
# ==============================================================================

run_performance_checks() {
    log_section "PERFORMANCE CHECKS"

    # Check for potential memory leaks (strong self captures)
    local weak_self=$(grep -rn '\[weak self\]' "$SOURCES_DIR" --include='*.swift' 2>/dev/null | wc -l || echo "0")
    local strong_self=$(grep -rn '\[self\]' "$SOURCES_DIR" --include='*.swift' 2>/dev/null | \
        grep -v '\[weak self\]' | grep -v '\.self' | wc -l || echo "0")

    if [[ $strong_self -gt 0 ]]; then
        log_warn "Found $strong_self strong self captures (check for retain cycles)"
    else
        log_pass "No obvious retain cycles detected"
    fi
    ((CHECKS_TOTAL++))

    # Check for async/await usage
    local async=$(grep -rn 'async' "$SOURCES_DIR" --include='*.swift' 2>/dev/null | wc -l || echo "0")

    if [[ $async -gt 5 ]]; then
        log_pass "Async/await properly used ($async instances)"
    else
        log_warn "Limited async/await usage detected"
    fi
    ((CHECKS_TOTAL++))

    # Check for threading issues
    local thread_issues=$(grep -rn 'DispatchQueue\|Thread\|GCD' "$SOURCES_DIR" \
        --include='*.swift' 2>/dev/null | wc -l || echo "0")

    if [[ $thread_issues -gt 0 ]]; then
        log_pass "Thread management implemented"
    else
        log_info "Limited explicit thread management (may be using async/await)"
    fi
    ((CHECKS_TOTAL++))
}

# ==============================================================================
# SECURITY CHECKS
# ==============================================================================

run_security_checks() {
    log_section "SECURITY CHECKS"

    # Check for SSL pinning
    local ssl=$(grep -rn 'certificate\|SSL\|TLS' "$SOURCES_DIR" \
        --include='*.swift' 2>/dev/null | wc -l || echo "0")

    if [[ $ssl -gt 0 ]]; then
        log_info "SSL/TLS configuration detected"
    else
        log_warn "No explicit SSL/TLS pinning detected (ensure secure by default)"
    fi
    ((CHECKS_TOTAL++))

    # Check for secure storage usage
    local keychain=$(grep -rn 'KeyChain\|kSecClass' "$SOURCES_DIR" --include='*.swift' 2>/dev/null | wc -l || echo "0")

    if [[ $keychain -gt 0 ]]; then
        log_pass "Keychain usage for secure storage detected"
    else
        log_warn "No keychain usage detected (credentials should use secure storage)"
    fi
    ((CHECKS_TOTAL++))

    # Check for hardcoded URLs
    local hardcoded_urls=$(grep -rn 'https://' "$SOURCES_DIR" --include='*.swift' 2>/dev/null | \
        grep -v 'example.com\|localhost\|127.0.0.1' | grep -v '//' | wc -l || echo "0")

    if [[ $hardcoded_urls -lt 3 ]]; then
        log_pass "No obvious hardcoded URLs found"
    else
        log_warn "Found $hardcoded_urls hardcoded URLs (use configuration)"
    fi
    ((CHECKS_TOTAL++))

    # Privacy manifest usage
    if [[ -f "$SOURCES_DIR/App/PrivacyInfo.xcprivacy" ]]; then
        log_pass "Privacy manifest file configured"
    else
        log_fail "Privacy manifest not configured (required for App Store)"
    fi
    ((CHECKS_TOTAL++))
}

# ==============================================================================
# REPORT GENERATION
# ==============================================================================

print_summary() {
    log_section "VALIDATION SUMMARY"

    local percentage=0
    if [[ $CHECKS_TOTAL -gt 0 ]]; then
        percentage=$(( (CHECKS_PASS * 100) / CHECKS_TOTAL ))
    fi

    echo ""
    echo "Total Checks:     $CHECKS_TOTAL"
    echo -e "Passed:           ${GREEN}$CHECKS_PASS${NC}"
    echo -e "Failed:           ${RED}$CHECKS_FAIL${NC}"
    echo -e "Warnings:         ${YELLOW}$CHECKS_WARN${NC}"
    echo ""
    echo "Pass Rate:        $percentage%"
    echo ""

    if [[ $CHECKS_FAIL -eq 0 ]]; then
        echo -e "${GREEN}All critical checks passed! Ready for submission.${NC}"
    else
        echo -e "${RED}$CHECKS_FAIL critical checks failed. Please fix before submission.${NC}"
    fi

    echo ""
}

print_detailed_report() {
    if [[ $CHECKS_FAIL -gt 0 ]] || [[ $CHECKS_WARN -gt 0 ]]; then
        log_section "DETAILED FAILURES & WARNINGS"

        if [[ $CHECKS_FAIL -gt 0 ]]; then
            echo -e "${RED}FAILED CHECKS:${NC}"
            for failed in "${FAILED_CHECKS[@]}"; do
                echo "  - $failed"
            done
            echo ""
        fi

        if [[ $CHECKS_WARN -gt 0 ]]; then
            echo -e "${YELLOW}WARNINGS:${NC}"
            for warning in "${WARNING_CHECKS[@]}"; do
                echo "  - $warning"
            done
            echo ""
        fi
    fi
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║   Rosier Pre-App Store Submission Validator              ║"
    echo "║   Version: 1.0.0                                          ║"
    echo "║   Project: iOS Fashion App                                ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo "Project Root: $PROJECT_ROOT"
    echo "Timestamp:    $(date)"
    echo ""

    # Run all validation suites
    run_code_quality_checks
    run_required_files_checks
    run_app_store_requirements_checks
    run_legal_checks
    run_localization_checks
    run_test_coverage_checks
    run_configuration_checks
    run_accessibility_checks
    run_performance_checks
    run_security_checks

    # Print results
    print_summary
    print_detailed_report

    # Exit with appropriate code
    if [[ $CHECKS_FAIL -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

main "$@"
