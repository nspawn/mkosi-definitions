#!/bin/bash

shopt -s extglob
root_dir="$(pwd)"
for f in "$root_dir"/*/*; do
  if [ -d "$f" ]; then
    cd "$f"
    rm -rf *.builddir *.cache
    if [ -d mkosi.output ]; then
      cd mkosi.output
      rm -f !(*.tar.xz|*.raw.xz|*.SHA256SUMS|*.SHA256SUMS.gpg)
    fi
  fi
  cd "$root_dir" || exit
done
