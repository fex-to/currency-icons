#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

# Dependencies: inkscape, cwebp
# Install: brew install inkscape webp

SIZES=(32 48 64 128 256 512)
CANONICAL_SRC_DIR="./currencies/svg"
CANONICAL_DST_ROOT="./currencies/webp"
LEGACY_SRC_DIR="./svg"
LEGACY_DST_ROOT="./webp"

command -v inkscape >/dev/null 2>&1 || { echo >&2 "inkscape not installed!"; exit 1; }
command -v cwebp >/dev/null 2>&1 || { echo >&2 "cwebp not installed!"; exit 1; }

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
    local canonical_dir="$CANONICAL_DST_ROOT/$size"
    local legacy_dir="$LEGACY_DST_ROOT/$size"

    mkdir -p "$legacy_dir"
    find "$legacy_dir" -maxdepth 1 -type f -name '*.webp' -delete

    if compgen -G "$canonical_dir/*.webp" >/dev/null; then
      cp "$canonical_dir"/*.webp "$legacy_dir"/
    fi
  done
}

bootstrap_canonical_svg_dir

for size in "${SIZES[@]}"; do
  DST_DIR="${CANONICAL_DST_ROOT}/${size}"
  mkdir -p "$DST_DIR"
done

for svg in "$CANONICAL_SRC_DIR"/*.svg; do
  filename=$(basename "${svg%.*}")
  for size in "${SIZES[@]}"; do
    DST_DIR="${CANONICAL_DST_ROOT}/${size}"
    png_tmp="${DST_DIR}/${filename}.png"
    webp_out="${DST_DIR}/${filename}.webp"
    # SVG → PNG
    inkscape "$svg" --export-type=png --export-filename="$png_tmp" -w $size -h $size
    # PNG → WEBP
    cwebp -q 90 "$png_tmp" -o "$webp_out"
    rm "$png_tmp"
    echo "Generated: $webp_out"
  done
done

sync_legacy_currency_paths
