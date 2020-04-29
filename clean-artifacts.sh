#!/bin/bash

find /srv/www/nspawn.org/public/storage/ -iname ".mkosi-*" -print -exec rm -rf {} \+
