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
    echo -e "${YELLOW}Or create a .env file with these variables${NC}"
    exit 1
fi

echo -e "${GREEN}Starting deployment to Cloudflare R2...${NC}"

configure_r2_aws_cli

# Upload SVG files
echo -e "${YELLOW}Uploading SVG files to R2...${NC}"
aws s3 sync ./svg/ s3://$BUCKET_NAME/svg/ \
    --endpoint-url "$R2_ENDPOINT_URL" \
    --exclude "*.DS_Store" \
    --cache-control "public, max-age=31536000" \
    --content-type "image/svg+xml" \
    --delete

# Upload WebP files
echo -e "${YELLOW}Uploading WebP files to R2...${NC}"
for size_dir in ./webp/*/; do
    size=$(basename "$size_dir")
    echo -e "${YELLOW}Uploading ${size}px WebP files...${NC}"
    aws s3 sync "$size_dir" s3://$BUCKET_NAME/webp/$size/ \
        --endpoint-url "$R2_ENDPOINT_URL" \
        --exclude "*.DS_Store" \
        --cache-control "public, max-age=31536000" \
        --content-type "image/webp" \
        --delete
done

if [[ -d "./providers" ]]; then
    echo -e "${YELLOW}Uploading provider icons to R2...${NC}"
    upload_provider_assets "./providers" "$BUCKET_NAME"
fi

# List uploaded files (optional)
echo -e "${GREEN}Deployment completed!${NC}"
echo -e "${YELLOW}Checking uploaded files:${NC}"

svg_count=$(count_s3_objects "$BUCKET_NAME" "svg/")
webp_count=$(count_s3_objects "$BUCKET_NAME" "webp/")
provider_count=0

if [[ -d "./providers" ]]; then
    provider_count=$(count_s3_objects "$BUCKET_NAME" "providers/")
fi

echo -e "${GREEN}✓ SVG files uploaded: $svg_count${NC}"
echo -e "${GREEN}✓ WebP files uploaded: $webp_count${NC}"
if [[ -d "./providers" ]]; then
    echo -e "${GREEN}✓ Provider files uploaded: $provider_count${NC}"
fi

echo ""
echo -e "${GREEN}Files are now available at:${NC}"
echo "SVG: https://currency-icons.YOUR_CUSTOM_DOMAIN/svg/filename.svg"
echo "WebP: https://currency-icons.YOUR_CUSTOM_DOMAIN/webp/SIZE/filename.webp"
if [[ -d "./providers" ]]; then
    print_provider_url_templates
fi
echo ""
echo -e "${YELLOW}Note: Replace YOUR_CUSTOM_DOMAIN with your actual R2 custom domain${NC}"