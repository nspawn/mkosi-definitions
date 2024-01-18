#!/usr/bin/env bash

root_dir=$(pwd)

for definitions_dir in ./*/*; do
    if cd "$definitions_dir" && [ -d "$definitions_dir"/mkosi.images ]; then
        mkosi
    else
        echo "Could not cd to $definitions_dir"
    fi
    cd "$root_dir" || exit 3
done
