#!/usr/bin/env bash

set -x

root="$(cd "$(dirname "$0")/.." && pwd)"
src="$root/src"
rime_huma="$src/rime-huma"

rsync -aL \
  --exclude='.git/' \
  --exclude='.github/' \
  --exclude='hotfix/' \
  --exclude='LICENSE' \
  --exclude='README.md' \
  "$rime_huma/" \
  "$root/"
