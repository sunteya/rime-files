#!/usr/bin/env bash

set -euxo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
repo="$root/repo"
wanxiang_data="$repo/rime-wanxiang-data"

if [ -e "$wanxiang_data/.git" ]; then
  git -C "$wanxiang_data" pull --ff-only
else
  mkdir -p "$repo"
  git clone https://github.com/amzxyz/rime-wanxiang-data.git "$wanxiang_data"
fi
