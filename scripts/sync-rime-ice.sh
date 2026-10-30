#!/usr/bin/env bash

set -euxo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
repo="$root/repo"
rime_ice="$repo/rime-ice"

if [ -e "$rime_ice/.git" ]; then
  git -C "$rime_ice" pull --ff-only
else
  mkdir -p "$repo"
  git clone https://github.com/iDvel/rime-ice.git "$rime_ice"
fi

rsync -aL \
  --exclude='.git/' \
  --exclude='.github/' \
  --exclude='.gitignore' \
  --exclude='AGENTS.md' \
  --exclude='recipe.yaml' \
  --exclude='custom_phrase.txt' \
  --exclude='default.yaml' \
  --exclude='double_pinyin*.schema.yaml' \
  --exclude='go.work' \
  --exclude='LICENSE' \
  --exclude='others/' \
  --exclude='README.md' \
  --exclude='squirrel.yaml' \
  --exclude='t9.schema.yaml' \
  --exclude='weasel.yaml' \
  "$rime_ice/" \
  "$root/"
