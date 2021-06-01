#!/bin/bash

### Test a particular Babbler commit directory in babbler_devel

# import the build_and_test function
source ./scripts/build_and_test.sh

if [[ $# == 0 || $# > 1 ]]; then
  echo "Error: Please specify a valid Babbler application directory."
  exit 1
fi

dir=$1 # specify the argument as the desired directory for which a Babbler application is stored
echo "Entering directory: $dir"
cd $dir
make clean &> /dev/null

# compile application, run test harness, and run all input files
if build_and_test; then
  echo -e "\nTesting of Babbler application in '$dir' completed succesfully."
else
  echo -ne "\nTesting of Babbler application in '$dir' failed. "
  echo "Please check the output for error reports."
fi
