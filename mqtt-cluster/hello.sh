#!/usr/bin/env bash

work_dir="$(
    cd "$(dirname "$0")" || exit
    pwd
)"
echo "$work_dir"

if [ "$(grep -c "Hello, World" "${work_dir}/hello.sh")" -gt 0 ]; then
    echo '"0" equal 0'
else
    echo '"0" not equal 0'
fi
