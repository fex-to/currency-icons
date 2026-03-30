#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/r2-common.sh"

BUCKET_NAME="currency-icons"
R2_ENDPOINT_URL="${R2_ENDPOINT_URL:-}"
R2_ACCESS_KEY_ID="${R2_ACCESS_KEY_ID:-}"
R2_SECRET_ACCESS_KEY="${R2_SECRET_ACCESS_KEY:-}"

require_aws_cli
load_r2_env_file

if ! require_r2_env; then
    echo ""
    print_warning "Or create a .env file with these variables"
    exit 1
fi

print_success "Starting deployment to Cloudflare R2..."

configure_r2_aws_cli

print_warning "Uploading SVG files to R2..."
aws s3 sync ./svg/ s3://$BUCKET_NAME/svg/ \
    --endpoint-url "$R2_ENDPOINT_URL" \
    --exclude "*.DS_Store" \
    --cache-control "public, max-age=31536000" \
    --content-type "image/svg+xml" \
    --delete

print_warning "Uploading WebP files to R2..."
for size_dir in ./webp/*/; do
    size="$(basename "$size_dir")"
    print_warning "Uploading ${size}px WebP files..."
    aws s3 sync "$size_dir" s3://$BUCKET_NAME/webp/$size/ \
        --endpoint-url "$R2_ENDPOINT_URL" \
        --exclude "*.DS_Store" \
        --cache-control "public, max-age=31536000" \
        --content-type "image/webp" \
        --delete
done

if [[ -d "./providers" ]]; then
    print_warning "Uploading provider icons to R2..."
    upload_provider_assets "./providers" "$BUCKET_NAME"
fi

print_success "Deployment completed."
print_warning "Checking uploaded object counts..."

svg_count=$(count_s3_objects "$BUCKET_NAME" "svg/")
webp_count=$(count_s3_objects "$BUCKET_NAME" "webp/")
provider_count=0

if [[ -d "./providers" ]]; then
    provider_count=$(count_s3_objects "$BUCKET_NAME" "providers/")
fi

print_success "SVG files uploaded: $svg_count"
print_success "WebP files uploaded: $webp_count"
if [[ -d "./providers" ]]; then
    print_success "Provider files uploaded: $provider_count"
fi

require_nonzero_count "SVG" "$svg_count"
require_nonzero_count "WebP" "$webp_count"
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