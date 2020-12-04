#!/bin/bash

### Test all Babbler applications inside the MOOSE directory

# import the build_and_test function
source ./scripts/build_and_test.sh

failed=false # initialize variable to track wether compilation, testing, etc., of babbler failed
for file in ~/projects/moose/tutorials/tutorial01_app_development/step*
do
  echo "Entering directory: $file"
  cd $file
  make clean

  # compile application, run test harness, and run all input files
  build_and_test
done

echo ""
if ! $failed; then
  echo "Testing of Babbler applications in MOOSE completed succesfully."
else
  echo "Testing of Babbler applications in MOOSE failed. Please check output for error reports."
fi
