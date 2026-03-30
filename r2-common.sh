#!/usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_error() {
  echo -e "${RED}$1${NC}"
}

print_success() {
  echo -e "${GREEN}$1${NC}"
}

print_warning() {
  echo -e "${YELLOW}$1${NC}"
}

require_aws_cli() {
  if ! command -v aws >/dev/null 2>&1; then
    print_error "AWS CLI is not installed. Please install it first:"
    echo "brew install awscli"
    exit 1
  fi
}

load_r2_env_file() {
  local env_file="${1:-.env}"

  if [[ -f "$env_file" ]]; then
    print_success "Loading environment variables from ${env_file}"
    set -a
    source "$env_file"
    set +a
  fi
}

require_r2_env() {
  if [[ -z "${R2_ENDPOINT_URL:-}" || -z "${R2_ACCESS_KEY_ID:-}" || -z "${R2_SECRET_ACCESS_KEY:-}" ]]; then
    print_error "Please set the following environment variables:"
    echo "export R2_ENDPOINT_URL='https://YOUR_ACCOUNT_ID.r2.cloudflarestorage.com'"
    echo "export R2_ACCESS_KEY_ID='your_access_key_id'"
    echo "export R2_SECRET_ACCESS_KEY='your_secret_access_key'"
    return 1
  fi
}

configure_r2_aws_cli() {
  aws configure set aws_access_key_id "$R2_ACCESS_KEY_ID"
  aws configure set aws_secret_access_key "$R2_SECRET_ACCESS_KEY"
  aws configure set default.region auto
  aws configure set default.output json
}

upload_provider_assets() {
  local providers_root="$1"
  local bucket_name="$2"

  for index_file in "$providers_root/index.json"; do
    if [[ -f "$index_file" ]]; then
      local file_name
      file_name="$(basename "$index_file")"
      print_warning "Uploading provider index ${file_name}..."
      aws s3 cp "$index_file" "s3://$bucket_name/providers/$file_name" \
        --endpoint-url "$R2_ENDPOINT_URL" \
        --cache-control "public, max-age=300" \
        --content-type "application/json"
    fi
  done

  for version_dir in "$providers_root"/*/; do
    local version
    version="$(basename "$version_dir")"

    for version_json in "$version_dir/index.json" "$version_dir/metadata.json"; do
      if [[ -f "$version_json" ]]; then
        local file_name
        file_name="$(basename "$version_json")"
        print_warning "Uploading provider ${file_name} for ${version}..."
        aws s3 cp "$version_json" "s3://$bucket_name/providers/$version/$file_name" \
          --endpoint-url "$R2_ENDPOINT_URL" \
          --cache-control "public, max-age=300" \
          --content-type "application/json"
      fi
    done

    if [[ -d "$version_dir/svg" ]]; then
      print_warning "Uploading provider SVG files for ${version}..."
      aws s3 sync "$version_dir/svg/" "s3://$bucket_name/providers/$version/svg/" \
        --endpoint-url "$R2_ENDPOINT_URL" \
        --exclude "*.DS_Store" \
        --cache-control "public, max-age=31536000" \
        --content-type "image/svg+xml" \
        --delete
    fi

    for size_dir in "$version_dir"/png/*/; do
      local size
      size="$(basename "$size_dir")"
      print_warning "Uploading provider PNG ${size}px for ${version}..."
      aws s3 sync "$size_dir" "s3://$bucket_name/providers/$version/png/$size/" \
        --endpoint-url "$R2_ENDPOINT_URL" \
        --exclude "*.DS_Store" \
        --cache-control "public, max-age=31536000" \
        --content-type "image/png" \
        --delete
    done

    for size_dir in "$version_dir"/webp/*/; do
      local size
      size="$(basename "$size_dir")"
      print_warning "Uploading provider WebP ${size}px for ${version}..."
      aws s3 sync "$size_dir" "s3://$bucket_name/providers/$version/webp/$size/" \
        --endpoint-url "$R2_ENDPOINT_URL" \
        --exclude "*.DS_Store" \
        --cache-control "public, max-age=31536000" \
        --content-type "image/webp" \
        --delete
    done
  done
}

count_s3_objects() {
  local bucket_name="$1"
  local prefix="$2"

  aws s3 ls "s3://$bucket_name/$prefix" --endpoint-url "$R2_ENDPOINT_URL" --recursive | wc -l | tr -d '[:space:]'
}

require_nonzero_count() {
  local label="$1"
  local count="$2"

  if [[ ! "$count" =~ ^[0-9]+$ ]]; then
    print_error "${label} count is not numeric: ${count}"
    exit 1
  fi

  if (( count == 0 )); then
    print_error "${label} upload verification failed: zero objects found in R2"
    exit 1
  fi
}

get_public_base_url() {
  if [[ -n "${R2_CUSTOM_DOMAIN:-}" ]]; then
    printf 'https://%s\n' "$R2_CUSTOM_DOMAIN"
  fi
}

has_public_base_url() {
  [[ -n "${R2_CUSTOM_DOMAIN:-}" ]]
}

print_currency_url_templates() {
  local base_url
  base_url="$(get_public_base_url)"

  if [[ -z "$base_url" ]]; then
    return 1
  fi

  echo "Currencies SVG: ${base_url}/currencies/svg/filename.svg"
  echo "Currencies PNG: ${base_url}/currencies/png/SIZE/filename.png"
  echo "Currencies WebP: ${base_url}/currencies/webp/SIZE/filename.webp"
  echo "SVG: ${base_url}/svg/filename.svg"
  echo "PNG: ${base_url}/png/SIZE/filename.png"
  echo "WebP: ${base_url}/webp/SIZE/filename.webp"
}

print_provider_url_templates() {
  local base_url
  base_url="$(get_public_base_url)"

  if [[ -z "$base_url" ]]; then
    return 1
  fi

  echo "Providers SVG: ${base_url}/providers/VERSION/svg/provider.svg"
  echo "Providers PNG: ${base_url}/providers/VERSION/png/SIZE/provider.png"
  echo "Providers WebP: ${base_url}/providers/VERSION/webp/SIZE/provider.webp"
  echo "Providers index: ${base_url}/providers/index.json"
  echo "Providers version index: ${base_url}/providers/VERSION/index.json"
}

print_custom_domain_hint() {
  if [[ -z "${R2_CUSTOM_DOMAIN:-}" ]]; then
    print_warning "Set R2_CUSTOM_DOMAIN to print public HTTPS URLs after deploy."
  fi
}