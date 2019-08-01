#!/bin/bash

find /usr/share/nginx/html/nspawn.org/public/storage/ -iname "mkosi-*" -print -exec rm -rf {} \+
