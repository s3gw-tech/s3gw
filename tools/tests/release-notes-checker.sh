#!/bin/bash
#
# Copyright 2023 SUSE, LLC.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ------
#
# This script checks that the 'latest' symlink of docs/release-notes
# matches the version passed

if [ -z "$1" ]; then
    echo "usage: $0: VERSION STRING"
    exit 1
fi

VERSION_PARAMETER=$1
echo "release-notes-checker:"
echo "Checking for symlink of version: ${VERSION_PARAMETER}"
VERSION_AFTER_V=$(cut -d "v" -f2 <<< ${VERSION_PARAMETER})
VERSION_AFTER_RC=$(cut -d "-" -f1 <<< ${VERSION_AFTER_V})
EXPECTED_RN_FILE="s3gw-v${VERSION_AFTER_RC}.md"
echo "Expected release notes file is: ${EXPECTED_RN_FILE}"

PATH_LATEST=$(realpath docs/release-notes/latest | xargs basename)
echo "latest symlink real path is: ${PATH_LATEST}"

if [ "$PATH_LATEST" = "$EXPECTED_RN_FILE" ]; then
    echo "Release notes file symlink is correct"
else
    echo "Release notes file symlink is NOT correct"
    exit 1
fi
