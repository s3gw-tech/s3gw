#!/bin/bash
RES=0
echo "Unit tests found:"
find /radosgw/bin -name "unittest_rgw_sfs_*" -o -name "unittest_rgw_s3gw_*"

echo "Running tests..."
UNIT_TESTS=(`find /radosgw/bin -name "unittest_rgw_sfs_*" -o -name "unittest_rgw_s3gw_*"`)
for unit_test in "${UNIT_TESTS[@]}"
do
  ${unit_test}
  if [ $? -ne 0 ]
  then
    RES=1
  fi
done
exit ${RES}
