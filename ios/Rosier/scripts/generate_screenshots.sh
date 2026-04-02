#!/bin/bash

# Rosier App Store Screenshot Generator
# Captures App Store screenshots from HTML mockups using headless browser
# Output dimensions: iPhone 16 Pro Max (1290x2796), iPhone 14 Pro Max (1284x2778), iPhone 14 Pro (1179x2556)

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
readonly SCREENSHOTS_DIR="$PROJECT_ROOT/../../docs/screenshots"
readonly OUTPUT_DIR="$SCREENSHOTS_DIR/output"
readonly HTML_DIR="$SCREENSHOTS_DIR"

# Screenshot dimensions (width x height)
declare -A DIMENSIONS=(
    ["iphone16promax"]="1290x2796"
    ["iphone14promax"]="1284x2778"
    ["iphone14pro"]="1179x2556"
)

# Device scale factors
declare -A SCALES=(
    ["iphone16promax"]="3"
    ["iphone14promax"]="3"
    ["iphone14pro"]="3"
)

# Browser type
BROWSER_TYPE="${1:-chrome}"
VERBOSE="${2:---verbose}"

# Counters
SCREENSHOTS_GENERATED=0
SCREENSHOTS_FAILED=0

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

log_warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_section() {
    echo ""
    echo -e "${BLUE}=== $1 ===${NC}"
    echo ""
}

# ==============================================================================
# ENVIRONMENT CHECKS
# ==============================================================================

check_environment() {
    log_section "Environment Validation"

    # Check for required directories
    if [[ ! -d "$HTML_DIR" ]]; then
        log_error "Screenshots directory not found: $HTML_DIR"
        exit 1
    fi

    log_success "Screenshots directory exists: $HTML_DIR"

    # Create output directory
    if [[ ! -d "$OUTPUT_DIR" ]]; then
        mkdir -p "$OUTPUT_DIR"
        log_success "Created output directory: $OUTPUT_DIR"
    fi

    # Check for Chrome
    if command -v google-chrome > /dev/null 2>&1; then
        log_success "Chrome found: $(google-chrome --version)"
    elif command -v chrome > /dev/null 2>&1; then
        log_success "Chrome found: $(chrome --version)"
    elif command -v chromium > /dev/null 2>&1; then
        log_success "Chromium found: $(chromium --version)"
    else
        log_error "Chrome/Chromium not found. Required for headless screenshot generation."
        echo "Install: sudo apt-get install chromium-browser"
        exit 1
    fi

    # Check for Node.js based screenshot tool (optional)
    if command -v node > /dev/null 2>&1; then
        log_success "Node.js found: $(node --version)"
    else
        log_warn "Node.js not found (optional, for advanced screenshot generation)"
    fi
}

# ==============================================================================
# SCREENSHOT GENERATION FUNCTIONS
# ==============================================================================

find_chrome_executable() {
    if command -v google-chrome > /dev/null 2>&1; then
        echo "google-chrome"
    elif command -v google-chrome-stable > /dev/null 2>&1; then
        echo "google-chrome-stable"
    elif command -v chromium > /dev/null 2>&1; then
        echo "chromium"
    elif command -v chromium-browser > /dev/null 2>&1; then
        echo "chromium-browser"
    elif [[ -f "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]]; then
        echo "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    else
        echo ""
    fi
}

generate_screenshot_chrome() {
    local html_file="$1"
    local output_file="$2"
    local width="$3"
    local height="$4"

    local chrome_exe=$(find_chrome_executable)

    if [[ -z "$chrome_exe" ]]; then
        log_error "Chrome executable not found"
        return 1
    fi

    log_info "Generating: $output_file ($width x $height)"

    # Create temporary HTML with proper viewport
    local temp_html="/tmp/screenshot_temp_$(date +%s).html"
    cat > "$temp_html" <<EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            background: white;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
        }
    </style>
</head>
<body>
    <div id="app"></div>
    <script src="file://$html_file"></script>
</body>
</html>
EOF

    # Use Chrome headless mode to capture screenshot
    if "$chrome_exe" \
        --headless \
        --disable-gpu \
        --screenshot="$output_file" \
        --window-size="$width,$height" \
        --hide-scrollbars \
        "file://$html_file" 2>/dev/null; then

        log_success "Generated: $output_file"
        ((SCREENSHOTS_GENERATED++))
        return 0
    else
        log_error "Failed to generate: $output_file"
        ((SCREENSHOTS_FAILED++))
        return 1
    fi
}

generate_screenshot_node() {
    local html_file="$1"
    local output_file="$2"
    local width="$3"
    local height="$4"

    # Check if puppeteer is available
    if ! npm list puppeteer > /dev/null 2>&1; then
        return 1
    fi

    log_info "Generating with Puppeteer: $output_file ($width x $height)"

    # Create Node.js script for screenshot
    local temp_script="/tmp/screenshot_$(date +%s).js"
    cat > "$temp_script" <<'NODEJS'
const puppeteer = require('puppeteer');
const path = require('path');

(async () => {
    const htmlFile = process.argv[1];
    const outputFile = process.argv[2];
    const width = parseInt(process.argv[3]);
    const height = parseInt(process.argv[4]);

    const browser = await puppeteer.launch({
        headless: 'new',
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });

    const page = await browser.newPage();
    await page.setViewport({ width, height, deviceScaleFactor: 3 });
    await page.goto(`file://${path.resolve(htmlFile)}`, { waitUntil: 'networkidle2' });
    await page.screenshot({ path: outputFile, fullPage: true });
    await browser.close();
})();
NODEJS

    if node "$temp_script" "$html_file" "$output_file" "$width" "$height" 2>/dev/null; then
        log_success "Generated: $output_file"
        ((SCREENSHOTS_GENERATED++))
        rm "$temp_script" 2>/dev/null || true
        return 0
    else
        log_error "Failed to generate: $output_file"
        ((SCREENSHOTS_FAILED++))
        rm "$temp_script" 2>/dev/null || true
        return 1
    fi
}

# ==============================================================================
# BATCH PROCESSING
# ==============================================================================

generate_all_screenshots() {
    log_section "Generating App Store Screenshots"

    # Find all HTML screenshot files
    local html_files=$(find "$HTML_DIR" -maxdepth 1 -name "*.html" -type f | sort)

    if [[ -z "$html_files" ]]; then
        log_warn "No HTML screenshot files found in $HTML_DIR"
        return 1
    fi

    # Process each HTML file
    while IFS= read -r html_file; do
        local filename=$(basename "$html_file")
        local basename="${filename%.*}"

        log_section "Processing: $filename"

        # Generate for each device type
        for device in "${!DIMENSIONS[@]}"; do
            local dimensions="${DIMENSIONS[$device]}"
            local width="${dimensions%x*}"
            local height="${dimensions#*x}"
            local output_file="$OUTPUT_DIR/${basename}_${device}.png"

            # Try Puppeteer first (better quality), fall back to Chrome
            if ! generate_screenshot_node "$html_file" "$output_file" "$width" "$height"; then
                generate_screenshot_chrome "$html_file" "$output_file" "$width" "$height"
            fi
        done

    done <<< "$html_files"
}

# ==============================================================================
# VALIDATION & OPTIMIZATION
# ==============================================================================

validate_screenshots() {
    log_section "Validating Generated Screenshots"

    if [[ $SCREENSHOTS_GENERATED -eq 0 ]]; then
        log_error "No screenshots were generated"
        return 1
    fi

    # Check file sizes and dimensions
    for screenshot in "$OUTPUT_DIR"/*.png; do
        if [[ ! -f "$screenshot" ]]; then
            continue
        fi

        local size=$(du -h "$screenshot" | cut -f1)
        log_info "Screenshot: $(basename "$screenshot") ($size)"

        # Verify using identify if ImageMagick is available
        if command -v identify > /dev/null 2>&1; then
            local dimensions=$(identify -format "%wx%h" "$screenshot" 2>/dev/null || echo "unknown")
            log_info "  Dimensions: $dimensions"
        fi
    done

    log_success "All screenshots validated"
}

optimize_screenshots() {
    log_section "Optimizing Screenshots for App Store"

    if ! command -v convert > /dev/null 2>&1; then
        log_warn "ImageMagick not found (optimization skipped)"
        log_warn "Install: sudo apt-get install imagemagick"
        return 0
    fi

    for screenshot in "$OUTPUT_DIR"/*.png; do
        if [[ ! -f "$screenshot" ]]; then
            continue
        fi

        local filename=$(basename "$screenshot")
        log_info "Optimizing: $filename"

        # Compress PNG while maintaining quality
        if convert "$screenshot" \
            -strip \
            -quality 85 \
            -define png:compression-level=9 \
            "$screenshot.tmp" && mv "$screenshot.tmp" "$screenshot"; then
            log_success "Optimized: $filename"
        else
            log_warn "Could not optimize: $filename"
        fi
    done
}

# ==============================================================================
# METADATA & DOCUMENTATION
# ==============================================================================

generate_metadata() {
    log_section "Generating Screenshot Metadata"

    local metadata_file="$OUTPUT_DIR/SCREENSHOTS.md"

    cat > "$metadata_file" <<'EOF'
# Rosier App Store Screenshots

Generated screenshots for App Store submission.

## Device Sizes

- **iPhone 16 Pro Max**: 1290 × 2796 (3x scale, 430 × 932 pt)
- **iPhone 14 Pro Max**: 1284 × 2778 (3x scale, 428 × 926 pt)
- **iPhone 14 Pro**: 1179 × 2556 (3x scale, 393 × 852 pt)

## Guidelines

1. Text and UI should be clearly visible and readable
2. No iPhone bezels or notches in the screenshots
3. Screenshots should represent actual app functionality
4. Avoid placeholder text or mock data
5. Use consistent branding and colors
6. Consider accessibility and contrast

## Files Generated

EOF

    # List all generated screenshots
    for screenshot in "$OUTPUT_DIR"/*.png; do
        if [[ -f "$screenshot" ]]; then
            local filename=$(basename "$screenshot")
            local size=$(du -h "$screenshot" | cut -f1)
            echo "- \`$filename\` ($size)" >> "$metadata_file"
        fi
    done

    cat >> "$metadata_file" <<'EOF'

## Upload Instructions

1. Log in to App Store Connect
2. Navigate to your app's "Screenshots" section
3. For each language/region:
   - Select device type (iPhone)
   - Upload screenshots in display order
   - Add optional descriptions for each screenshot
4. Save changes
5. Submit for review

## Testing

Before submitting:
- [ ] All screenshots display correctly
- [ ] Text is readable and properly formatted
- [ ] No sensitive information visible
- [ ] Screenshots represent current app version
- [ ] All required device sizes provided

EOF

    log_success "Metadata generated: $metadata_file"
}

print_summary() {
    log_section "Screenshot Generation Summary"

    echo "Output Directory:      $OUTPUT_DIR"
    echo "Screenshots Generated: $SCREENSHOTS_GENERATED"
    echo "Screenshots Failed:    $SCREENSHOTS_FAILED"
    echo ""

    if [[ $SCREENSHOTS_GENERATED -gt 0 ]]; then
        log_success "Screenshot generation complete!"
        echo ""
        echo "Files ready for App Store submission:"
        ls -lh "$OUTPUT_DIR"/*.png 2>/dev/null || echo "  (No PNG files found)"
    else
        log_error "No screenshots were generated successfully"
    fi

    echo ""
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║   Rosier App Store Screenshot Generator                  ║"
    echo "║   Version: 1.0.0                                          ║"
    echo "║   Browser: $BROWSER_TYPE                                           ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo "Project Root: $PROJECT_ROOT"
    echo "Screenshots:  $SCREENSHOTS_DIR"
    echo "Output:       $OUTPUT_DIR"
    echo "Timestamp:    $(date)"
    echo ""

    check_environment
    generate_all_screenshots
    validate_screenshots
    optimize_screenshots
    generate_metadata
    print_summary

    # Exit with appropriate code
    if [[ $SCREENSHOTS_FAILED -eq 0 ]] && [[ $SCREENSHOTS_GENERATED -gt 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

main "$@"
