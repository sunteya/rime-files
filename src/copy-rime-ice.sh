#!/usr/bin/env bash

set -x

root="$(cd "$(dirname "$0")/.." && pwd)"
src="$root/src"
rime_ice="$src/rime-ice"

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
