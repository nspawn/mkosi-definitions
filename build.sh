#!/usr/bin/env bash

failed_builds=""
root_dir=$(pwd)

for definitions_dir in ./*/*; do
    if cd $definitions_dir; then
        for f in $(for x in *.default; do echo "${x//-*/}"; done | uniq); do
            if ! nspawn-builder -n "$f"; then
                failed_builds+="$f "
            else
                echo "Build of $f succeeded"
            fi
        done
    fi
    cd "$root_dir"
done

echo "Failed builds: $failed_builds"
