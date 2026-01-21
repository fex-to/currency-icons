#!/usr/bin/env bash

# Script for manual deployment to Cloudflare R2
# This script uploads both SVG and generated WebP files to R2 Object Storage

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BUCKET_NAME="currency-icons"
R2_ENDPOINT_URL="${R2_ENDPOINT_URL:-}"
R2_ACCESS_KEY_ID="${R2_ACCESS_KEY_ID:-}"
R2_SECRET_ACCESS_KEY="${R2_SECRET_ACCESS_KEY:-}"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}AWS CLI is not installed. Please install it first:${NC}"
    echo "brew install awscli"
    exit 1
fi

# Load .env file if it exists
if [[ -f ".env" ]]; then
    echo -e "${GREEN}Loading environment variables from .env file${NC}"
    set -a
    source .env
    set +a
fi

# Check environment variables
if [[ -z "$R2_ENDPOINT_URL" || -z "$R2_ACCESS_KEY_ID" || -z "$R2_SECRET_ACCESS_KEY" ]]; then
    echo -e "${RED}Please set the following environment variables:${NC}"
    echo "export R2_ENDPOINT_URL='https://YOUR_ACCOUNT_ID.r2.cloudflarestorage.com'"
    echo "export R2_ACCESS_KEY_ID='your_access_key_id'"
    echo "export R2_SECRET_ACCESS_KEY='your_secret_access_key'"
    echo ""
    echo -e "${YELLOW}Or create a .env file with these variables${NC}"
    exit 1
fi

echo -e "${GREEN}Starting deployment to Cloudflare R2...${NC}"

# Configure AWS CLI for R2
aws configure set aws_access_key_id "$R2_ACCESS_KEY_ID"
aws configure set aws_secret_access_key "$R2_SECRET_ACCESS_KEY"
aws configure set default.region auto
aws configure set default.output json

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
    if [[ -d "$size_dir" ]]; then
        size=$(basename "$size_dir")
        echo -e "${YELLOW}Uploading ${size}px WebP files...${NC}"
        aws s3 sync "$size_dir" s3://$BUCKET_NAME/webp/$size/ \
            --endpoint-url "$R2_ENDPOINT_URL" \
            --exclude "*.DS_Store" \
            --cache-control "public, max-age=31536000" \
            --content-type "image/webp" \
            --delete
    fi
done

# List uploaded files (optional)
echo -e "${GREEN}Deployment completed!${NC}"
echo -e "${YELLOW}Checking uploaded files:${NC}"

# Show file count
svg_count=$(aws s3 ls s3://$BUCKET_NAME/svg/ --endpoint-url "$R2_ENDPOINT_URL" --recursive | wc -l)
webp_count=$(aws s3 ls s3://$BUCKET_NAME/webp/ --endpoint-url "$R2_ENDPOINT_URL" --recursive | wc -l)

echo -e "${GREEN}✓ SVG files uploaded: $svg_count${NC}"
echo -e "${GREEN}✓ WebP files uploaded: $webp_count${NC}"

echo ""
echo -e "${GREEN}Files are now available at:${NC}"
echo "SVG: https://currency-icons.YOUR_CUSTOM_DOMAIN/svg/filename.svg"
echo "WebP: https://currency-icons.YOUR_CUSTOM_DOMAIN/webp/SIZE/filename.webp"
echo ""
echo -e "${YELLOW}Note: Replace YOUR_CUSTOM_DOMAIN with your actual R2 custom domain${NC}"