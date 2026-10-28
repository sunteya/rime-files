#!/usr/bin/env bash

set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
combiner="$root/src/keytao-phrase-combiner"
user_dir="$root/user"
user_combiner_dict="$user_dir/phrase_combiner.user.dict.yaml"
combiner_user_template="$combiner/phrase_combiner.user.dict.yaml"

mkdir -p "$user_dir"

if [ ! -s "$user_combiner_dict" ]; then
  cp "$combiner_user_template" "$user_combiner_dict"
fi

(
  cd "$combiner"
  python3 scripts/generate_phrase_combiner.py
)

rsync -aL \
  --exclude=".*" \
  --exclude="scripts/" \
  --exclude="README.md" \
  --exclude="phrase_combiner.user.dict.yaml" \
  "$combiner/" \
  "$root/"

ln -sfn "user/phrase_combiner.user.dict.yaml" "$root/phrase_combiner.user.dict.yaml"
