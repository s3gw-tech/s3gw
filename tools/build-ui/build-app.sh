#!/bin/sh

set -e

cd /srv/app/
npm ci
npm run build:prod

exit 0
