#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

BUCKET_NAME="currency-icons"
R2_ENDPOINT_URL="${R2_ENDPOINT_URL:-}"
R2_ACCESS_KEY_ID="${R2_ACCESS_KEY_ID:-}"
R2_SECRET_ACCESS_KEY="${R2_SECRET_ACCESS_KEY:-}"
PROVIDERS_ROOT="./providers"

if ! command -v aws >/dev/null 2>&1; then
  echo -e "${RED}AWS CLI is not installed. Please install it first:${NC}"
  echo "brew install awscli"
  exit 1
fi

if [[ -f ".env" ]]; then
  echo -e "${GREEN}Loading environment variables from .env file${NC}"
  set -a
  source .env
  set +a
fi

if [[ -z "$R2_ENDPOINT_URL" || -z "$R2_ACCESS_KEY_ID" || -z "$R2_SECRET_ACCESS_KEY" ]]; then
  echo -e "${RED}Please set the following environment variables:${NC}"
  echo "export R2_ENDPOINT_URL='https://YOUR_ACCOUNT_ID.r2.cloudflarestorage.com'"
  echo "export R2_ACCESS_KEY_ID='your_access_key_id'"
  echo "export R2_SECRET_ACCESS_KEY='your_secret_access_key'"
  exit 1
fi

if [[ ! -d "$PROVIDERS_ROOT" ]]; then
  echo -e "${RED}Providers directory not found: $PROVIDERS_ROOT${NC}"
  exit 1
fi

aws configure set aws_access_key_id "$R2_ACCESS_KEY_ID"
aws configure set aws_secret_access_key "$R2_SECRET_ACCESS_KEY"
aws configure set default.region auto
aws configure set default.output json

echo -e "${GREEN}Starting provider-only deployment to Cloudflare R2...${NC}"

for index_file in "$PROVIDERS_ROOT/index.json"; do
  if [[ -f "$index_file" ]]; then
    file_name="$(basename "$index_file")"
    echo -e "${YELLOW}Uploading ${file_name}...${NC}"
    aws s3 cp "$index_file" "s3://$BUCKET_NAME/providers/$file_name" \
      --endpoint-url "$R2_ENDPOINT_URL" \
      --cache-control "public, max-age=300" \
      --content-type "application/json"
  fi
done

for version_dir in "$PROVIDERS_ROOT"/*/; do
  version="$(basename "$version_dir")"

  for version_json in "$version_dir/index.json" "$version_dir/metadata.json"; do
    if [[ -f "$version_json" ]]; then
      file_name="$(basename "$version_json")"
      echo -e "${YELLOW}Uploading provider ${file_name} for ${version}...${NC}"
      aws s3 cp "$version_json" "s3://$BUCKET_NAME/providers/$version/$file_name" \
        --endpoint-url "$R2_ENDPOINT_URL" \
        --cache-control "public, max-age=300" \
        --content-type "application/json"
    fi
  done

  if [[ -d "$version_dir/svg" ]]; then
    echo -e "${YELLOW}Uploading provider SVG files for ${version}...${NC}"
    aws s3 sync "$version_dir/svg/" "s3://$BUCKET_NAME/providers/$version/svg/" \
      --endpoint-url "$R2_ENDPOINT_URL" \
      --exclude "*.DS_Store" \
      --cache-control "public, max-age=31536000" \
      --content-type "image/svg+xml" \
      --delete
  fi

  for size_dir in "$version_dir"/png/*/; do
    size="$(basename "$size_dir")"
    echo -e "${YELLOW}Uploading provider PNG ${size}px for ${version}...${NC}"
    aws s3 sync "$size_dir" "s3://$BUCKET_NAME/providers/$version/png/$size/" \
      --endpoint-url "$R2_ENDPOINT_URL" \
      --exclude "*.DS_Store" \
      --cache-control "public, max-age=31536000" \
      --content-type "image/png" \
      --delete
  done

  for size_dir in "$version_dir"/webp/*/; do
    size="$(basename "$size_dir")"
    echo -e "${YELLOW}Uploading provider WebP ${size}px for ${version}...${NC}"
    aws s3 sync "$size_dir" "s3://$BUCKET_NAME/providers/$version/webp/$size/" \
      --endpoint-url "$R2_ENDPOINT_URL" \
      --exclude "*.DS_Store" \
      --cache-control "public, max-age=31536000" \
      --content-type "image/webp" \
      --delete
  done
done

provider_count="$(aws s3 ls "s3://$BUCKET_NAME/providers/" --endpoint-url "$R2_ENDPOINT_URL" --recursive | wc -l)"

echo -e "${GREEN}✓ Provider files uploaded: $provider_count${NC}"
echo "Providers index: https://currency-icons.YOUR_CUSTOM_DOMAIN/providers/index.json"
echo "Providers version index: https://currency-icons.YOUR_CUSTOM_DOMAIN/providers/VERSION/index.json"
echo "Providers SVG: https://currency-icons.YOUR_CUSTOM_DOMAIN/providers/VERSION/svg/provider.svg"
echo "Providers PNG: https://currency-icons.YOUR_CUSTOM_DOMAIN/providers/VERSION/png/SIZE/provider.png"
echo "Providers WebP: https://currency-icons.YOUR_CUSTOM_DOMAIN/providers/VERSION/webp/SIZE/provider.webp"