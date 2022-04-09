#!/bin/bash

# This script will prevent test to be successful in case that you have duplicated
# Output directories set in the mkosi definitions.

output_dirs=()
working_dir=""

if [ -z "$1" ]; then
    working_dir="./"
else
    working_dir="$1"
fi

if cd "$working_dir"; then
    for f in */*/*.default; do
        output_dir=""
        output_dir=$(grep "^Output=" "$f")
        output_dir=${output_dir#*=}
        output_dir=${output_dir%/*}/
        output_dirs+=("${output_dir}")
    done
fi

total_unique_items=$(printf '%s\n' "${output_dirs[@]}" | awk '!($0 in seen){seen[$0];c++} END {print c}')

((total_unique_items != ${#output_dirs[@]})) && echo "Error: found duplicated directories directives, please validate the Output= section in the mkosi definitions, leaving." && exit 1 || echo "No duplicated directories directives found."
