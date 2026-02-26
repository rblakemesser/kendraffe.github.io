#!/usr/bin/env bash
set -euo pipefail

title="${TITLE:-}"
slug="${SLUG:-}"
date_full="${DATE:-}"
categories="${CATEGORIES:-}"
image="${IMAGE:-}"
link="${LINK:-}"

if [[ -z "$title" ]]; then
  echo "ERROR: TITLE is required" >&2
  exit 1
fi

slugify() {
  local input="$1"
  input="$(printf "%s" "$input" | tr '[:upper:]' '[:lower:]')"
  input="$(printf "%s" "$input" | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')"
  printf "%s" "$input"
}

yaml_quote() {
  local value="$1"
  if [[ -z "$value" ]]; then
    printf ""
    return
  fi

  if [[ "$value" == \"*\" && "$value" == *\" ]]; then
    printf "%s" "$value"
    return
  fi
  if [[ "$value" == \'*\' && "$value" == *\' ]]; then
    printf "%s" "$value"
    return
  fi

  value="${value//\"/\\\"}"
  printf "\"%s\"" "$value"
}

if [[ -z "$slug" ]]; then
  slug="$(slugify "$title")"
fi
if [[ -z "$slug" ]]; then
  echo "ERROR: could not derive SLUG; provide SLUG=..." >&2
  exit 1
fi

if [[ -z "$date_full" ]]; then
  date_full="$(date '+%Y-%m-%d %H:%M:%S %z')"
fi

post_date="${date_full%% *}"
post_path="_posts/${post_date}-${slug}.markdown"

if [[ -f "$post_path" ]]; then
  echo "ERROR: post already exists: $post_path" >&2
  exit 1
fi

escaped_title="${title//\"/\\\"}"
image_yaml="$(yaml_quote "$image")"
link_yaml="$(yaml_quote "$link")"

mkdir -p _posts

cat >"$post_path" <<EOF
---
layout: post
title:  "$escaped_title"
date:   $date_full
categories: ${categories}
image: ${image_yaml}
link: ${link_yaml}
---

Write here.
EOF

echo "created: $post_path"
