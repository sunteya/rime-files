#!/usr/bin/env bash

set -euxo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
repo="$root/repo"
rime_huma="$repo/rime-huma"

if [ -e "$rime_huma/.git" ]; then
  git -C "$rime_huma" pull --ff-only
else
  mkdir -p "$repo"
  git clone https://github.com/ywxt/rime-huma.git "$rime_huma"
fi

rsync -aL \
  --exclude='.git/' \
  --exclude='.github/' \
  --exclude='hotfix/' \
  --exclude='LICENSE' \
  --exclude='README.md' \
  "$rime_huma/" \
  "$root/"
