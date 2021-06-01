#!/bin/bash

### Test all Babbler applications inside the MOOSE directory

# import the 'build_and_test' function
source ./scripts/build_and_test.sh

# set MOOSE application development tutorial directory and indicate that testing procedure has begun
rootdir=~/projects/moose/tutorials/tutorial01_app_development
echo "Building and testing all copies of the Babbler application found at '$rootdir'."

# loop through child directories matching 'step*' in '$rootdir' and run build/test procedure
failed=false # initialize variable to track wether compilation, testing, etc., of babbler failed
for appdir in $rootdir/step*
do
  echo -e "\nEntering directory: $appdir"
  cd $appdir
  make clobber &> /dev/null # we really want to be sure things are clean and fresh here

  # compile application, run test harness, and run all input files
  if ! build_and_test; then
    failed=true
  fi
done

echo ""
if ! $failed; then
  echo "Testing of Babbler applications in MOOSE completed succesfully."
else
  echo "Testing of Babbler applications in MOOSE failed. Please check the output for error reports."
fi
