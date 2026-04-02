#!/bin/bash
#
# Rosier iOS - Code Signing Setup Script
# Configures code signing in CI environment
# Imports certificates and provisioning profiles from environment variables
#
# Usage:
#   ./scripts/setup_signing.sh [--type development|appstore]
#
# Environment Variables Required (GitHub Secrets):
#   APPLE_DEVELOPER_ID: Your Apple Developer Team ID (e.g., ABC123XYZ9)
#   IOS_CERTIFICATE_BASE64: Distribution certificate exported as base64
#   IOS_CERT_PASSWORD: Password to unlock the certificate
#   PROVISIONING_PROFILE_BASE64: Provisioning profile as base64
#
# This script:
#   1. Creates a temporary keychain
#   2. Imports the distribution certificate
#   3. Installs the provisioning profile
#   4. Configures build settings
#   5. Cleans up on exit
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CERT_TYPE="${1:-appstore}"
KEYCHAIN_NAME="rosier-ci-keychain"
KEYCHAIN_PASSWORD="$(uuidgen)"
TEMP_DIR="/tmp/rosier-signing-$$"

# Build Settings
BUILD_SETTINGS_FILE="$PROJECT_DIR/Sources/App/BUILD_SETTINGS.xcconfig"

# Verify required environment variables
verify_environment() {
  local required_vars=(
    "APPLE_DEVELOPER_ID"
    "IOS_CERTIFICATE_BASE64"
    "IOS_CERT_PASSWORD"
    "PROVISIONING_PROFILE_BASE64"
  )

  for var in "${required_vars[@]}"; do
    if [[ -z "${!var:-}" ]]; then
      echo -e "${RED}[ERROR]${NC} Required environment variable not set: $var" >&2
      echo ""
      echo "Please configure the following GitHub Secrets:"
      echo "  - APPLE_DEVELOPER_ID: Your Apple Team ID"
      echo "  - IOS_CERTIFICATE_BASE64: Base64-encoded distribution certificate"
      echo "  - IOS_CERT_PASSWORD: Certificate password"
      echo "  - PROVISIONING_PROFILE_BASE64: Base64-encoded provisioning profile"
      exit 1
    fi
  done

  echo -e "${GREEN}[SUCCESS]${NC} All required environment variables are set"
}

# Create temporary directory
setup_temp_directory() {
  mkdir -p "$TEMP_DIR"
  echo -e "${BLUE}[INFO]${NC} Created temp directory: $TEMP_DIR"
}

# Decode certificate
decode_certificate() {
  local cert_file="$TEMP_DIR/certificate.p12"

  echo -e "${BLUE}[INFO]${NC} Decoding distribution certificate..." >&2

  echo "$IOS_CERTIFICATE_BASE64" | base64 --decode > "$cert_file"

  if [[ ! -f "$cert_file" ]]; then
    echo -e "${RED}[ERROR]${NC} Failed to decode certificate" >&2
    cleanup
    exit 1
  fi

  echo -e "${GREEN}[SUCCESS]${NC} Certificate decoded" >&2
  echo "$cert_file"
}

# Decode provisioning profile
decode_provisioning_profile() {
  local profile_file="$TEMP_DIR/provisioning.mobileprovision"

  echo -e "${BLUE}[INFO]${NC} Decoding provisioning profile..." >&2

  echo "$PROVISIONING_PROFILE_BASE64" | base64 --decode > "$profile_file"

  if [[ ! -f "$profile_file" ]]; then
    echo -e "${RED}[ERROR]${NC} Failed to decode provisioning profile" >&2
    cleanup
    exit 1
  fi

  echo -e "${GREEN}[SUCCESS]${NC} Provisioning profile decoded" >&2
  echo "$profile_file"
}

# Create temporary keychain
create_keychain() {
  echo -e "${BLUE}[INFO]${NC} Creating temporary keychain: $KEYCHAIN_NAME"

  # Delete existing keychain if present
  security delete-keychain "$KEYCHAIN_NAME" 2>/dev/null || true

  # Create new keychain
  security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_NAME"
  security set-keychain-settings -lut 3600 "$KEYCHAIN_NAME"
  security list-keychains -s "$KEYCHAIN_NAME" $(security list-keychains | sed s/\"//g)

  echo -e "${GREEN}[SUCCESS]${NC} Keychain created"
}

# Import certificate
import_certificate() {
  local cert_file="$1"

  echo -e "${BLUE}[INFO]${NC} Importing certificate into keychain..."

  # Re-encode P12 with legacy algorithms for macOS compatibility
  # OpenSSL 3.x uses SHA-256 MAC by default, macOS security expects legacy SHA-1/3DES
  local legacy_cert="${cert_file%.p12}_legacy.p12"
  if openssl pkcs12 -in "$cert_file" -out "${cert_file}.pem" -nodes -passin pass:"$IOS_CERT_PASSWORD" 2>/dev/null; then
    openssl pkcs12 -export -in "${cert_file}.pem" -out "$legacy_cert" -passout pass:"$IOS_CERT_PASSWORD" -legacy 2>/dev/null ||     openssl pkcs12 -export -in "${cert_file}.pem" -out "$legacy_cert" -passout pass:"$IOS_CERT_PASSWORD" -certpbe PBE-SHA1-3DES -keypbe PBE-SHA1-3DES -macalg SHA1 2>/dev/null ||     cp "$cert_file" "$legacy_cert"
    rm -f "${cert_file}.pem"
    cert_file="$legacy_cert"
    echo -e "${GREEN}[SUCCESS]${NC} Certificate re-encoded for macOS compatibility"
  fi

  if security import "$cert_file" \
    -k "$KEYCHAIN_NAME" \
    -P "$IOS_CERT_PASSWORD" \
    -A; then
    echo -e "${GREEN}[SUCCESS]${NC} Certificate imported"
  else
    echo -e "${RED}[ERROR]${NC} Failed to import certificate" >&2
    cleanup
    exit 1
  fi

  # Verify certificate was imported
  security find-identity -v -p codesigning "$KEYCHAIN_NAME" | grep -E "(Apple|iPhone) Distribution" || {
    echo -e "${RED}[ERROR]${NC} Distribution certificate not found in keychain" >&2
    cleanup
    exit 1
  }
}

# Install provisioning profile
install_provisioning_profile() {
  local profile_file="$1"
  local profile_dir="$HOME/Library/MobileDevice/Provisioning Profiles"

  echo -e "${BLUE}[INFO]${NC} Installing provisioning profile..."

  mkdir -p "$profile_dir"

  # Extract UUID from profile (mobileprovision files are signed CMS - extract plist first)
  local profile_plist="$TEMP_DIR/profile.plist"
  local profile_uuid=""

  # Try security cms to extract the embedded plist
  if security cms -D -i "$profile_file" > "$profile_plist" 2>/dev/null; then
    profile_uuid=$(/usr/libexec/PlistBuddy -c "Print UUID" "$profile_plist" 2>/dev/null || true)
  fi

  # Fallback: grep the raw mobileprovision file for UUID pattern
  if [[ -z "$profile_uuid" ]]; then
    profile_uuid=$(grep -a -A1 '<key>UUID</key>' "$profile_file" 2>/dev/null | grep '<string>' | sed 's/.*<string>//;s/<\/string>.*//' || true)
  fi

  # Final fallback: generate a UUID
  if [[ -z "$profile_uuid" ]]; then
    profile_uuid=$(uuidgen)
    echo -e "${YELLOW}[WARN]${NC} Could not extract UUID, using generated: $profile_uuid"
  fi

  cp "$profile_file" "$profile_dir/$profile_uuid.mobileprovision"

  echo -e "${GREEN}[SUCCESS]${NC} Provisioning profile installed"
  echo "  Profile UUID: $profile_uuid"
}

# Update build settings
update_build_settings() {
  echo -e "${BLUE}[INFO]${NC} Updating build settings..."

  # Verify build settings file exists
  if [[ ! -f "$BUILD_SETTINGS_FILE" ]]; then
    echo -e "${YELLOW}[WARN]${NC} Build settings file not found: $BUILD_SETTINGS_FILE"
    return 0
  fi

  # Update DEVELOPMENT_TEAM in BUILD_SETTINGS.xcconfig
  if grep -q "^DEVELOPMENT_TEAM =" "$BUILD_SETTINGS_FILE"; then
    sed -i.bak "s/^DEVELOPMENT_TEAM =.*/DEVELOPMENT_TEAM = $APPLE_DEVELOPER_ID/" "$BUILD_SETTINGS_FILE"
    rm -f "${BUILD_SETTINGS_FILE}.bak"
    echo -e "${GREEN}[SUCCESS]${NC} Build settings updated with Team ID: $APPLE_DEVELOPER_ID"
  else
    echo "DEVELOPMENT_TEAM = $APPLE_DEVELOPER_ID" >> "$BUILD_SETTINGS_FILE"
    echo -e "${GREEN}[SUCCESS]${NC} Build settings configured with Team ID: $APPLE_DEVELOPER_ID"
  fi
}

# Verify signing configuration
verify_signing() {
  echo -e "${BLUE}[INFO]${NC} Verifying signing configuration..."

  # Check keychain
  if security list-keychains | grep -q "$KEYCHAIN_NAME"; then
    echo -e "${GREEN}[SUCCESS]${NC} Keychain configured"
  else
    echo -e "${RED}[ERROR]${NC} Keychain not properly configured" >&2
    return 1
  fi

  # Check certificate
  if security find-identity -v -p codesigning "$KEYCHAIN_NAME" | grep -qE "(Apple|iPhone) Distribution"; then
    echo -e "${GREEN}[SUCCESS]${NC} Distribution certificate found"
  else
    echo -e "${RED}[ERROR]${NC} Distribution certificate not found" >&2
    return 1
  fi

  # Check provisioning profile
  local profile_count=$(ls -1 "$HOME/Library/MobileDevice/Provisioning Profiles" 2>/dev/null | wc -l)
  echo -e "${GREEN}[SUCCESS]${NC} Provisioning profiles installed ($profile_count files)"

  return 0
}

# Cleanup function
cleanup() {
  echo -e "${BLUE}[INFO]${NC} Cleaning up temporary files..."

  if [[ -d "$TEMP_DIR" ]]; then
    rm -rf "$TEMP_DIR"
    echo -e "${GREEN}[SUCCESS]${NC} Temporary directory removed"
  fi

  # Note: We intentionally keep the keychain and provisioning profile
  # They will be used during the build
  echo -e "${YELLOW}[NOTE]${NC} Keychain and provisioning profile preserved for build"
}

# Cleanup on exit
trap cleanup EXIT

# Print configuration summary
print_summary() {
  echo ""
  echo -e "${BLUE}Signing Configuration Summary:${NC}"
  echo "================================"
  echo "  Keychain: $KEYCHAIN_NAME"
  echo "  Team ID: $APPLE_DEVELOPER_ID"
  echo "  Certificate Type: iOS Distribution"
  echo "  Cert Type (for fastlane): $CERT_TYPE"
  echo ""
  echo "Environment variables set for build:"
  echo "  MATCH_KEYCHAIN_NAME=$KEYCHAIN_NAME"
  echo "  MATCH_KEYCHAIN_PASSWORD=$KEYCHAIN_PASSWORD"
  echo "  DEVELOPMENT_TEAM=$APPLE_DEVELOPER_ID"
  echo ""
}

# Main execution
main() {
  echo ""
  echo -e "${BLUE}Rosier iOS - Code Signing Setup${NC}"
  echo "=================================="
  echo ""

  verify_environment
  setup_temp_directory

  local cert_file=$(decode_certificate)
  local profile_file=$(decode_provisioning_profile)

  create_keychain
  import_certificate "$cert_file"
  install_provisioning_profile "$profile_file"
  update_build_settings
  verify_signing

  # Export for use in build steps
  export MATCH_KEYCHAIN_NAME="$KEYCHAIN_NAME"
  export MATCH_KEYCHAIN_PASSWORD="$KEYCHAIN_PASSWORD"
  export DEVELOPMENT_TEAM="$APPLE_DEVELOPER_ID"

  print_summary

  echo -e "${GREEN}[SUCCESS]${NC} Code signing setup completed successfully!"
}

# Run main
main

exit 0
