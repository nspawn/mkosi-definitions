#!/usr/bin/env bash

root_dir=$(pwd)

for definitions_dir in ./*/*; do
    if [ -d "$definitions_dir"/mkosi.images ] && cd "$definitions_dir"; then
        if ! mkosi; then
            echo "mkosi failed for $definitions_dir"
            # Always return 0, so that all images are built
            true
        fi
    else
        echo "Could not cd to $definitions_dir"
    fi
    cd "$root_dir" || exit 3
done
