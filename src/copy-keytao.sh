#!/usr/bin/env bash

set -x

root="$(cd "$(dirname "$0")/.." && pwd)"
src="$root/src"
keytao="$src/KeyTao"
user_dir="$root/user"
user_keytao_dict="$user_dir/keytao.user.dict.yaml"
keytao_user_template="$keytao/rime/keytao.user.dict.yaml"

mkdir -p "$user_dir"

if [ ! -s "$user_keytao_dict" ]; then
  cp "$keytao_user_template" "$user_keytao_dict"
fi

rsync -aL \
  --exclude="keytao-bj.schema.yaml" \
  --exclude="keytao-dz*.dict.yaml" \
  --exclude="keytao.user.dict.yaml" \
  --exclude="default.custom.yaml" \
  --exclude="user.yaml" \
  "$keytao/rime/" \
  "$root/"

ln -sfn "user/keytao.user.dict.yaml" "$root/keytao.user.dict.yaml"

rsync -aL \
  --exclude="keytao-dz.schema.yaml" \
  "$keytao/schema/desktop/" \
  "$root/"

# rsync -aL \
#   "$keytao/extend-dicts/keytao.iboot.dict.yaml" \
#   "$root/"
