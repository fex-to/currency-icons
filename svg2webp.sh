#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

# Dependencies: cwebp and either inkscape or rsvg-convert
# Install: brew install inkscape librsvg webp

SIZES=(32 48 64 128 256 512)
CANONICAL_SRC_DIR="./currencies/svg"
CANONICAL_PNG_ROOT="./currencies/png"
CANONICAL_WEBP_ROOT="./currencies/webp"
LEGACY_SRC_DIR="./svg"
LEGACY_PNG_ROOT="./png"
LEGACY_WEBP_ROOT="./webp"

command -v cwebp >/dev/null 2>&1 || { echo >&2 "cwebp not installed!"; exit 1; }

if command -v inkscape >/dev/null 2>&1; then
  SVG_RENDERER="inkscape"
elif command -v rsvg-convert >/dev/null 2>&1; then
  SVG_RENDERER="rsvg-convert"
else
  echo >&2 "Neither inkscape nor rsvg-convert is installed!"
  exit 1
fi

render_png() {
  local svg_file="$1"
  local png_out="$2"
  local size="$3"

  if [[ "$SVG_RENDERER" == "inkscape" ]]; then
    inkscape "$svg_file" --export-type=png --export-filename="$png_out" -w "$size" -h "$size"
    return
  fi

  rsvg-convert -w "$size" -h "$size" "$svg_file" > "$png_out"
}

bootstrap_canonical_svg_dir() {
  mkdir -p "$CANONICAL_SRC_DIR"

  if compgen -G "$CANONICAL_SRC_DIR/*.svg" >/dev/null; then
    return
  fi

  if compgen -G "$LEGACY_SRC_DIR/*.svg" >/dev/null; then
    cp "$LEGACY_SRC_DIR"/*.svg "$CANONICAL_SRC_DIR"/
  fi
}

sync_legacy_currency_paths() {
  mkdir -p "$LEGACY_SRC_DIR"
  find "$LEGACY_SRC_DIR" -maxdepth 1 -type f -name '*.svg' -delete

  if compgen -G "$CANONICAL_SRC_DIR/*.svg" >/dev/null; then
    cp "$CANONICAL_SRC_DIR"/*.svg "$LEGACY_SRC_DIR"/
  fi

  for size in "${SIZES[@]}"; do
    local canonical_png_dir="$CANONICAL_PNG_ROOT/$size"
    local canonical_webp_dir="$CANONICAL_WEBP_ROOT/$size"
    local legacy_png_dir="$LEGACY_PNG_ROOT/$size"
    local legacy_webp_dir="$LEGACY_WEBP_ROOT/$size"

    mkdir -p "$legacy_png_dir" "$legacy_webp_dir"
    find "$legacy_png_dir" -maxdepth 1 -type f -name '*.png' -delete
    find "$legacy_webp_dir" -maxdepth 1 -type f -name '*.webp' -delete

    if compgen -G "$canonical_png_dir/*.png" >/dev/null; then
      cp "$canonical_png_dir"/*.png "$legacy_png_dir"/
    fi

    if compgen -G "$canonical_webp_dir/*.webp" >/dev/null; then
      cp "$canonical_webp_dir"/*.webp "$legacy_webp_dir"/
    fi
  done
}

prepare_currency_raster_dirs() {
  for size in "${SIZES[@]}"; do
    local canonical_png_dir="$CANONICAL_PNG_ROOT/$size"
    local canonical_webp_dir="$CANONICAL_WEBP_ROOT/$size"

    mkdir -p "$canonical_png_dir" "$canonical_webp_dir"
    find "$canonical_png_dir" -maxdepth 1 -type f -name '*.png' -delete
    find "$canonical_webp_dir" -maxdepth 1 -type f -name '*.webp' -delete
  done
}

bootstrap_canonical_svg_dir

prepare_currency_raster_dirs

icon_count=0

for svg in "$CANONICAL_SRC_DIR"/*.svg; do
  filename=$(basename "${svg%.*}")
  icon_count=$((icon_count + 1))

  for size in "${SIZES[@]}"; do
    png_out="${CANONICAL_PNG_ROOT}/${size}/${filename}.png"
    webp_out="${CANONICAL_WEBP_ROOT}/${size}/${filename}.webp"

    # SVG → PNG
    render_png "$svg" "$png_out" "$size"

    # PNG → WEBP
    cwebp -quiet -q 90 "$png_out" -o "$webp_out" >/dev/null
  done
done

sync_legacy_currency_paths

files_per_format=$((icon_count * ${#SIZES[@]}))
echo "Using SVG renderer: ${SVG_RENDERER}"
echo "Generated PNG and WebP variants for ${icon_count} currency icons across ${#SIZES[@]} sizes."
echo "Canonical PNG files: ${files_per_format}"
echo "Canonical WebP files: ${files_per_format}"
echo "Legacy PNG files: ${files_per_format}"
echo "Legacy WebP files: ${files_per_format}"
