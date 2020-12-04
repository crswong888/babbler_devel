#!/bin/bash

### Test a particular Babbler commit directory in babbler_devel

# import the build_and_test function
source ./scripts/build_and_test.sh

dir=$1 # specify the argument as the desired directory for which a Babbler application is stored
failed=false # initialize variable to track wether compilation, testing, etc., of babbler failed

echo "Entering directory: $dir"
cd $dir
make clean

# compile application, run test harness, and run all input files
build_and_test

echo ""
if ! $failed; then
  echo "Testing of Babbler application in $dir completed succesfully."
else
  echo "Testing of Babbler application in $dir failed. Please check output for error reports."
fi
