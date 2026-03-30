#!/usr/bin/env bash

set -euo pipefail

REPO_URL="https://github.com/fex-to/provider-icons.git"
ARCHIVE_BASE_URL="https://github.com/fex-to/provider-icons/archive/refs"
OUTPUT_ROOT="./providers"
SIZES=(32 48 64 128 256 512)
VERSION_INPUT="latest"
FORCE=0

usage() {
  cat <<'EOF'
Usage:
  ./import-provider-icons.sh [--version <tag|main>] [--output-root <dir>] [--force]

Examples:
  ./import-provider-icons.sh
  ./import-provider-icons.sh --version 3.1.16
  ./import-provider-icons.sh --version main
  ./import-provider-icons.sh --version 3.1.16 --force
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION_INPUT="${2:-}"
      shift 2
      ;;
    --output-root)
      OUTPUT_ROOT="${2:-}"
      shift 2
      ;;
    --force)
      FORCE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

require_command() {
  local command_name="$1"
  command -v "$command_name" >/dev/null 2>&1 || {
    echo "$command_name is required but not installed" >&2
    exit 1
  }
}

resolve_latest_tag() {
  local latest_release_tag

  latest_release_tag="$(curl -fsSLI -o /dev/null -w '%{url_effective}' https://github.com/fex-to/provider-icons/releases/latest | awk -F/ '{print $NF}')"

  if [[ -n "$latest_release_tag" && "$latest_release_tag" != "latest" ]]; then
    echo "$latest_release_tag"
    return 0
  fi

  git ls-remote --tags --refs "$REPO_URL" \
    | awk -F/ '{print $3}' \
    | sort -V \
    | tail -n 1
}

resolve_archive_tag() {
  local requested_tag="$1"
  local candidate_tags=()
  local candidate

  if [[ "$requested_tag" == v* ]]; then
    candidate_tags+=("$requested_tag" "${requested_tag#v}")
  else
    candidate_tags+=("$requested_tag" "v${requested_tag}")
  fi

  for candidate in "${candidate_tags[@]}"; do
    if curl -fsSI "${ARCHIVE_BASE_URL}/tags/${candidate}.tar.gz" >/dev/null 2>&1; then
      echo "$candidate"
      return 0
    fi
  done

  echo "Unable to resolve provider-icons tag: ${requested_tag}" >&2
  exit 1
}

render_png_and_webp() {
  local svg_file="$1"
  local png_dir="$2"
  local webp_dir="$3"
  local file_name="$4"

  for size in "${SIZES[@]}"; do
    local png_out="${png_dir}/${size}/${file_name}.png"
    local webp_out="${webp_dir}/${size}/${file_name}.webp"

    rsvg-convert -w "$size" -h "$size" "$svg_file" > "$png_out"
    cwebp -quiet -q 90 "$png_out" -o "$webp_out" >/dev/null
  done
}

generate_providers_indexes() {
  local output_root="$1"

  python3 - "$output_root" <<'PY'
import json
import sys
from pathlib import Path

output_root = Path(sys.argv[1]).resolve()
index_path = output_root / "index.json"
root_index = {"versions": {}}
sizes_order = ["32", "48", "64", "128", "256", "512"]

for version_dir in sorted(path for path in output_root.iterdir() if path.is_dir()):
  svg_dir = version_dir / "svg"
  if not svg_dir.is_dir():
    continue

  version_name = version_dir.name
  version_entries = {}
  metadata_path = version_dir / "metadata.json"

  metadata = {}
  if metadata_path.is_file():
    metadata = json.loads(metadata_path.read_text(encoding="utf-8"))

  for svg_file in sorted(svg_dir.glob("*.svg")):
    raw_name = svg_file.stem
    provider_id = raw_name.upper()

    provider_entry = {
      "id": provider_id,
      "name": raw_name,
      "files": {
        "filename": raw_name,
        "svg": svg_file.is_file(),
        "png": [],
        "webp": [],
      },
    }

    for size in sizes_order:
      png_file = version_dir / "png" / size / f"{raw_name}.png"
      webp_file = version_dir / "webp" / size / f"{raw_name}.webp"

      if png_file.is_file():
        provider_entry["files"]["png"].append(size)

      if webp_file.is_file():
        provider_entry["files"]["webp"].append(size)

    version_entries[provider_id] = provider_entry

  version_index_path = version_dir / "index.json"
  version_index_path.write_text(json.dumps(version_entries, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

  version_summary = {
    "path": f"providers/{version_name}",
    "index": f"providers/{version_name}/index.json",
    "iconCount": len(version_entries),
    "formats": {
      "svg": True,
      "png": sizes_order,
      "webp": sizes_order,
    },
  }

  if metadata_path.is_file():
    version_summary["metadata"] = f"providers/{version_name}/metadata.json"

  if metadata:
    if "importedAt" in metadata:
      version_summary["importedAt"] = metadata["importedAt"]
    if "resolvedVersion" in metadata:
      version_summary["resolvedVersion"] = metadata["resolvedVersion"]

  root_index["versions"][version_name] = version_summary

index_path.write_text(json.dumps(root_index, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
PY
}

require_command git
require_command curl
require_command tar
require_command rsvg-convert
require_command cwebp
require_command python3

if [[ -z "$VERSION_INPUT" ]]; then
  echo "Version cannot be empty" >&2
  exit 1
fi

if [[ "$VERSION_INPUT" == "latest" ]]; then
  VERSION="$(resolve_latest_tag)"
  ARCHIVE_URL="${ARCHIVE_BASE_URL}/tags/${VERSION}.tar.gz"
  VERSION_DIR_NAME="$VERSION"
elif [[ "$VERSION_INPUT" == "main" ]]; then
  VERSION="main"
  ARCHIVE_URL="${ARCHIVE_BASE_URL}/heads/main.tar.gz"
  VERSION_DIR_NAME="main-$(date -u +%Y%m%d%H%M%S)"
else
  VERSION="$(resolve_archive_tag "$VERSION_INPUT")"
  ARCHIVE_URL="${ARCHIVE_BASE_URL}/tags/${VERSION}.tar.gz"
  VERSION_DIR_NAME="$VERSION"
fi

DEST_DIR="${OUTPUT_ROOT}/${VERSION_DIR_NAME}"

if [[ -d "$DEST_DIR" ]]; then
  if [[ "$FORCE" -ne 1 ]]; then
    echo "Destination already exists: $DEST_DIR" >&2
    echo "Use --force to rebuild it" >&2
    exit 1
  fi

  rm -rf "$DEST_DIR"
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

ARCHIVE_PATH="${TMP_DIR}/provider-icons.tar.gz"

echo "Downloading provider-icons ${VERSION}..."
curl -LfsS "$ARCHIVE_URL" -o "$ARCHIVE_PATH"

echo "Extracting archive..."
tar -xzf "$ARCHIVE_PATH" -C "$TMP_DIR"

EXTRACTED_DIR="$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
SRC_SVG_DIR="${EXTRACTED_DIR}/icons"

if [[ ! -d "$SRC_SVG_DIR" ]]; then
  SRC_SVG_DIR="${EXTRACTED_DIR}/packages/icons/icons"
fi

if [[ ! -d "$SRC_SVG_DIR" ]]; then
  echo "Unable to locate SVG icons directory in provider-icons archive" >&2
  exit 1
fi

mkdir -p "$DEST_DIR/svg" "$DEST_DIR/png" "$DEST_DIR/webp"

for size in "${SIZES[@]}"; do
  mkdir -p "$DEST_DIR/png/$size" "$DEST_DIR/webp/$size"
done

icon_count=0

for svg_file in "$SRC_SVG_DIR"/*.svg; do
  [[ -e "$svg_file" ]] || continue

  file_name="$(basename "${svg_file%.svg}")"
  cp "$svg_file" "$DEST_DIR/svg/${file_name}.svg"
  render_png_and_webp "$svg_file" "$DEST_DIR/png" "$DEST_DIR/webp" "$file_name"

  icon_count=$((icon_count + 1))
  if (( icon_count % 25 == 0 )); then
    echo "Processed ${icon_count} icons..."
  fi
done

if (( icon_count == 0 )); then
  echo "No SVG files found in $SRC_SVG_DIR" >&2
  exit 1
fi

cat > "$DEST_DIR/metadata.json" <<EOF
{
  "source": "fex-to/provider-icons",
  "requestedVersion": "${VERSION_INPUT}",
  "resolvedVersion": "${VERSION}",
  "outputVersion": "${VERSION_DIR_NAME}",
  "sizes": [32, 48, 64, 128, 256, 512],
  "iconCount": ${icon_count},
  "importedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

generate_providers_indexes "$OUTPUT_ROOT"

echo "Imported ${icon_count} provider icons into ${DEST_DIR}"