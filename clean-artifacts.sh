#!/bin/bash

find /usr/share/nginx/html/nspawn.org/public/storage/ -iname "mkosi-*" -exec "rm -rf {}" \+
