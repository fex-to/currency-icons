#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/r2-common.sh"

BUCKET_NAME="currency-icons"
R2_ENDPOINT_URL="${R2_ENDPOINT_URL:-}"
R2_ACCESS_KEY_ID="${R2_ACCESS_KEY_ID:-}"
R2_SECRET_ACCESS_KEY="${R2_SECRET_ACCESS_KEY:-}"
CURRENCY_SVG_DIR="./currencies/svg"
CURRENCY_PNG_ROOT="./currencies/png"
CURRENCY_WEBP_ROOT="./currencies/webp"
LEGACY_SVG_DIR="./svg"
LEGACY_PNG_ROOT="./png"
LEGACY_WEBP_ROOT="./webp"

require_aws_cli
load_r2_env_file

if ! require_r2_env; then
    echo ""
    print_warning "Or create a .env file with these variables"
    exit 1
fi

print_success "Starting deployment to Cloudflare R2..."

configure_r2_aws_cli

if [[ ! -d "$CURRENCY_SVG_DIR" && -d "$LEGACY_SVG_DIR" ]]; then
    CURRENCY_SVG_DIR="$LEGACY_SVG_DIR"
fi

if [[ ! -d "$CURRENCY_WEBP_ROOT" && -d "$LEGACY_WEBP_ROOT" ]]; then
    CURRENCY_WEBP_ROOT="$LEGACY_WEBP_ROOT"
fi

has_currency_png=0

if [[ ! -d "$CURRENCY_PNG_ROOT" && -d "$LEGACY_PNG_ROOT" ]]; then
    CURRENCY_PNG_ROOT="$LEGACY_PNG_ROOT"
fi

if [[ -d "$CURRENCY_PNG_ROOT" ]]; then
    has_currency_png=1
fi

print_warning "Uploading SVG files to R2..."
aws s3 sync "$CURRENCY_SVG_DIR/" s3://$BUCKET_NAME/currencies/svg/ \
    --endpoint-url "$R2_ENDPOINT_URL" \
    --exclude "*.DS_Store" \
    --cache-control "public, max-age=31536000" \
    --content-type "image/svg+xml" \
    --delete

print_warning "Uploading legacy SVG compatibility files to R2..."
aws s3 sync "$CURRENCY_SVG_DIR/" s3://$BUCKET_NAME/svg/ \
    --endpoint-url "$R2_ENDPOINT_URL" \
    --exclude "*.DS_Store" \
    --cache-control "public, max-age=31536000" \
    --content-type "image/svg+xml" \
    --delete

print_warning "Uploading WebP files to R2..."
for size_dir in "$CURRENCY_WEBP_ROOT"/*/; do
    size="$(basename "$size_dir")"
    print_warning "Uploading ${size}px WebP files to currencies/..."
    aws s3 sync "$size_dir" s3://$BUCKET_NAME/currencies/webp/$size/ \
        --endpoint-url "$R2_ENDPOINT_URL" \
        --exclude "*.DS_Store" \
        --cache-control "public, max-age=31536000" \
        --content-type "image/webp" \
        --delete

    print_warning "Uploading ${size}px legacy WebP compatibility files..."
    aws s3 sync "$size_dir" s3://$BUCKET_NAME/webp/$size/ \
        --endpoint-url "$R2_ENDPOINT_URL" \
        --exclude "*.DS_Store" \
        --cache-control "public, max-age=31536000" \
        --content-type "image/webp" \
        --delete
done

if (( has_currency_png )); then
    print_warning "Uploading PNG files to R2..."
    for size_dir in "$CURRENCY_PNG_ROOT"/*/; do
        size="$(basename "$size_dir")"
        print_warning "Uploading ${size}px PNG files to currencies/..."
        aws s3 sync "$size_dir" s3://$BUCKET_NAME/currencies/png/$size/ \
            --endpoint-url "$R2_ENDPOINT_URL" \
            --exclude "*.DS_Store" \
            --cache-control "public, max-age=31536000" \
            --content-type "image/png" \
            --delete

        print_warning "Uploading ${size}px legacy PNG compatibility files..."
        aws s3 sync "$size_dir" s3://$BUCKET_NAME/png/$size/ \
            --endpoint-url "$R2_ENDPOINT_URL" \
            --exclude "*.DS_Store" \
            --cache-control "public, max-age=31536000" \
            --content-type "image/png" \
            --delete
    done
fi

if [[ -d "./providers" ]]; then
    print_warning "Uploading provider icons to R2..."
    upload_provider_assets "./providers" "$BUCKET_NAME"
fi

print_success "Deployment completed."
print_warning "Checking uploaded object counts..."

svg_count=$(count_s3_objects "$BUCKET_NAME" "svg/")
png_count=0
webp_count=$(count_s3_objects "$BUCKET_NAME" "webp/")
currency_svg_count=$(count_s3_objects "$BUCKET_NAME" "currencies/svg/")
currency_png_count=0
currency_webp_count=$(count_s3_objects "$BUCKET_NAME" "currencies/webp/")
provider_count=0

if (( has_currency_png )); then
    png_count=$(count_s3_objects "$BUCKET_NAME" "png/")
    currency_png_count=$(count_s3_objects "$BUCKET_NAME" "currencies/png/")
fi

if [[ -d "./providers" ]]; then
    provider_count=$(count_s3_objects "$BUCKET_NAME" "providers/")
fi

print_success "SVG files uploaded: $svg_count"
if (( has_currency_png )); then
    print_success "PNG files uploaded: $png_count"
fi
print_success "WebP files uploaded: $webp_count"
print_success "Currencies SVG files uploaded: $currency_svg_count"
if (( has_currency_png )); then
    print_success "Currencies PNG files uploaded: $currency_png_count"
fi
print_success "Currencies WebP files uploaded: $currency_webp_count"
if [[ -d "./providers" ]]; then
    print_success "Provider files uploaded: $provider_count"
fi

require_nonzero_count "SVG" "$svg_count"
if (( has_currency_png )); then
    require_nonzero_count "PNG" "$png_count"
fi
require_nonzero_count "WebP" "$webp_count"
require_nonzero_count "Currencies SVG" "$currency_svg_count"
if (( has_currency_png )); then
    require_nonzero_count "Currencies PNG" "$currency_png_count"
fi
require_nonzero_count "Currencies WebP" "$currency_webp_count"
if [[ -d "./providers" ]]; then
    require_nonzero_count "Provider" "$provider_count"
fi

if has_public_base_url; then
    echo ""
    print_success "Public URLs:"
    print_currency_url_templates
    if [[ -d "./providers" ]]; then
        print_provider_url_templates
    fi
fi

print_custom_domain_hint