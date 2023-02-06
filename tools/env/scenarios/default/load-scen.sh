#!/bin/sh
set -e

s3cmd -c ../s3cmd.cfg mb s3://test

exit 0
