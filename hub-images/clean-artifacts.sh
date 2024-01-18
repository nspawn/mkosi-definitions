#!/bin/bash

shopt -s extglob
root_dir="$(pwd)"
for f in "$root_dir"/output/public/storage/*/*/*; do
  if [ -d "$f" ]; then
    cd "$f" || exit
    rm -rf !(*.tar.xz|*.raw.xz|*.SHA256SUMS|*.SHA256SUMS.gpg|*.nspawn)
  fi
  cd "$root_dir" || exit
done
