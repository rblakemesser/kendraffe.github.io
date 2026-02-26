#!/usr/bin/env bash
set -euo pipefail

src="${SRC:-}"
name="${NAME:-}"
preset="${PRESET:-long}"
fmt="${FMT:-webp}"
quality="${QUALITY:-82}"
force="${FORCE:-0}"
gravity="${GRAVITY:-center}"

if [[ -z "$src" ]]; then
  echo "ERROR: SRC is required (path to input image)" >&2
  exit 1
fi

if [[ ! -f "$src" ]]; then
  echo "ERROR: SRC does not exist: $src" >&2
  exit 1
fi

if ! command -v magick >/dev/null 2>&1; then
  echo "ERROR: ImageMagick is required (magick not found)." >&2
  echo "Run: make img-tools" >&2
  exit 1
fi

slugify() {
  local input="$1"
  input="$(printf "%s" "$input" | tr '[:upper:]' '[:lower:]')"
  input="$(printf "%s" "$input" | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')"
  printf "%s" "$input"
}

ext_for_fmt() {
  local f="$1"
  case "$f" in
    webp) echo "webp" ;;
    jpg | jpeg) echo "jpg" ;;
    png) echo "png" ;;
    *) echo "$f" ;;
  esac
}

base_from_src="$(basename "$src")"
base_no_ext="${base_from_src%.*}"
if [[ -z "$name" ]]; then
  name="$(slugify "$base_no_ext")"
fi
if [[ -z "$name" ]]; then
  echo "ERROR: could not derive NAME from SRC; provide NAME=..." >&2
  exit 1
fi

out_dir="assets"
out_ext="$(ext_for_fmt "$fmt")"
out_path="${out_dir}/${name}.${out_ext}"

if [[ -f "$out_path" && "$force" != "1" ]]; then
  echo "ERROR: output already exists: $out_path (set FORCE=1 to overwrite)" >&2
  exit 1
fi

width="${WIDTH:-}"
height="${HEIGHT:-}"

case "$preset" in
  long | post)
    width="${width:-681}"
    height="${height:-300}"
    ;;
  inline)
    width="${width:-1362}"
    ;;
  square | fiction)
    width="${width:-300}"
    height="${height:-300}"
    ;;
  *)
    echo "ERROR: unknown PRESET: $preset (expected long|inline|square)" >&2
    exit 1
    ;;
esac

mkdir -p "$out_dir"

tmp_out="${out_path}.tmp"
rm -f "$tmp_out"

common_args=(
  "$src"
  -auto-orient
  -strip
)

if [[ -n "$height" ]]; then
  magick "${common_args[@]}" \
    -resize "${width}x${height}^" \
    -gravity "$gravity" \
    -extent "${width}x${height}" \
    -quality "$quality" \
    "$tmp_out"
else
  magick "${common_args[@]}" \
    -resize "${width}x>" \
    -quality "$quality" \
    "$tmp_out"
fi

mv -f "$tmp_out" "$out_path"

bytes=""
if stat -f%z "$out_path" >/dev/null 2>&1; then
  bytes="$(stat -f%z "$out_path")"
fi

echo "wrote: $out_path${bytes:+ (${bytes} bytes)}"
echo
echo "Post front matter:"
echo "  image: \"/${out_path}\""
echo
echo "Markdown inline:"
echo "  ![](/${out_path})"
