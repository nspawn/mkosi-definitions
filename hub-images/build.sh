#!/usr/bin/env bash

root_dir=$(pwd)

for definitions_dir in ./*/*; do
    if [ -d "$definitions_dir"/mkosi.images ] && cd "$definitions_dir"; then
        mkosi
    else
        echo "Could not cd to $definitions_dir"
    fi
    cd "$root_dir" || exit 3
done
