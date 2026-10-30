#!/usr/bin/env bash

set -euxo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
repo="$root/repo"
keytao="$repo/KeyTao"
user_dir="$root/user"
user_keytao_dict="$user_dir/keytao.user.dict.yaml"
keytao_user_template="$keytao/rime/keytao.user.dict.yaml"

if [ -e "$keytao/.git" ]; then
  git -C "$keytao" pull --ff-only
else
  mkdir -p "$repo"
  git clone https://github.com/xkinput/KeyTao.git "$keytao"
fi

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
