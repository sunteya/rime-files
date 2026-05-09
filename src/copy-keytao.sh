#!/usr/bin/env bash

set -x

root="$(cd "$(dirname "$0")/.." && pwd)"
src="$root/src"
keytao="$src/KeyTao"

rsync -aL \
  --exclude="keytao-bj.schema.yaml" \
  --exclude="keytao-dz*.dict.yaml" \
  "$keytao/rime/" \
  "$root/"

rsync -aL \
  --exclude="keytao-dz.schema.yaml" \
  "$keytao/schema/desktop/" \
  "$root/"

# rsync -aL \
#   "$keytao/extend-dicts/keytao.iboot.dict.yaml" \
#   "$root/"
