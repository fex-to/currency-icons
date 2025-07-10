#!/usr/bin/env bash

# Dependencies: inkscape, cwebp
# Install: brew install inkscape webp

SIZES=(32 48 64 128 256)
SRC_DIR="./svg"
DST_ROOT="./webp"

command -v inkscape >/dev/null 2>&1 || { echo >&2 "inkscape not installed!"; exit 1; }
command -v cwebp >/dev/null 2>&1 || { echo >&2 "cwebp not installed!"; exit 1; }

for size in "${SIZES[@]}"; do
  DST_DIR="${DST_ROOT}/${size}"
  mkdir -p "$DST_DIR"
done

for svg in "$SRC_DIR"/*.svg; do
  filename=$(basename "${svg%.*}")
  for size in "${SIZES[@]}"; do
    DST_DIR="${DST_ROOT}/${size}"
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
