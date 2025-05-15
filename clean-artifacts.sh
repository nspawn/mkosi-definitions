#!/bin/bash

shopt -s extglob
root_dir="$(pwd)"
for f in "$root_dir"/output/public/storage/*/*/*; do
  if [ -d "$f" ]; then
    cd "$f" || exit
    rm -rf !(*.tar.xz|*.raw.xz|*.SHA256SUMS|*.SHA256SUMS.gpg|*.nspawn)
    # Rename the files to the correct name for machinectl
    find ./ -type f -name "*.SHA256SUMS" -exec bash -c 'mv "$1" "${1%/*}/SHA256SUMS"' _ {} \;
    find ./ -type f -name "*.SHA256SUMS.gpg" -exec bash -c 'mv "$1" "${1%/*}/SHA256SUMS.gpg"' _ {} \;
  fi
  cd "$root_dir" || exit
done
