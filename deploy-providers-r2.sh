#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/r2-common.sh"

BUCKET_NAME="currency-icons"
R2_ENDPOINT_URL="${R2_ENDPOINT_URL:-}"
R2_ACCESS_KEY_ID="${R2_ACCESS_KEY_ID:-}"
R2_SECRET_ACCESS_KEY="${R2_SECRET_ACCESS_KEY:-}"
PROVIDERS_ROOT="./providers"

require_aws_cli
load_r2_env_file

if ! require_r2_env; then
  exit 1
fi

if [[ ! -d "$PROVIDERS_ROOT" ]]; then
  echo -e "${RED}Providers directory not found: $PROVIDERS_ROOT${NC}"
  exit 1
fi

configure_r2_aws_cli

echo -e "${GREEN}Starting provider-only deployment to Cloudflare R2...${NC}"
upload_provider_assets "$PROVIDERS_ROOT" "$BUCKET_NAME"

provider_count="$(count_s3_objects "$BUCKET_NAME" "providers/")"

echo -e "${GREEN}✓ Provider files uploaded: $provider_count${NC}"
print_provider_url_templates