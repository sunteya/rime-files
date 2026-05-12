#!/usr/bin/env bash

set -x

root="$(cd "$(dirname "$0")/.." && pwd)"
src="$root/src"
tiger="$src/虎码秃版 鼠须管 （Mac）2026.03.01"

rsync -aL \
  --exclude='.DS_Store' \
  --exclude='01 双拼反查配置（自然码 小鹤 微软）/' \
  --exclude='PY_c*' \
  --exclude='stroke.dict.yaml' \
  --exclude='tigress*' \
  "$tiger/" \
  "$root/"
