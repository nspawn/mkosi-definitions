#!/usr/bin/env bash

failed_builds=""
definitions_dir="./"

if cd $definitions_dir; then
    for f in $(for x in *.default; do echo "${x//-*/}"; done | uniq); do
        if ! nspawn-builder -n "$f"; then
            failed_builds+="$f "
        else
            echo "Build of $f succeeded"
        fi
    done
fi

echo "Failed builds: $failed_builds"
