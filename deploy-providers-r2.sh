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
  print_error "Providers directory not found: $PROVIDERS_ROOT"
  exit 1
fi

configure_r2_aws_cli

print_success "Starting provider-only deployment to Cloudflare R2..."
upload_provider_assets "$PROVIDERS_ROOT" "$BUCKET_NAME"

provider_count="$(count_s3_objects "$BUCKET_NAME" "providers/")"

print_success "Provider files uploaded: $provider_count"
require_nonzero_count "Provider" "$provider_count"
if has_public_base_url; then
  print_success "Public URLs:"
  print_provider_url_templates
fi

print_custom_domain_hint