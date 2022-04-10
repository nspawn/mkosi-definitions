#!/usr/bin/env bash

failed_builds=""
root_dir=$(pwd)

for definitions_dir in ./*/*; do
    if cd "$definitions_dir"; then
        for f in $(for x in *.default; do echo "${x//-*/}"; done | uniq); do
            if ! nspawn-builder -n "$f"; then
                echo "Failed to build $f in the $definitions_dir directory"
                failed_builds+="$f "
            else
                echo "Build of $f succeeded"
            fi
        done
    else
        echo "Could not cd to $definitions_dir"
    fi
    cd "$root_dir" || exit 3
done

if [ -n "$failed_builds" ]; then
    echo "Failed builds: $failed_builds"
else
    echo "All builds succeeded"
fi
