#!/bin/bash

### Test all Babbler applications inside the MOOSE directory

failed=false # initialize variable to track wether compilation, testing, etc., of babbler failed
for file in ~/projects/moose/tutorials/tutorial01_app_development/step*
do
  echo "Entering directory: $file"
  cd $file
  make clean

  echo -n "Compiling Babbler... "
  make clean &> /tmp/babbler_devel_out
  make -j4 &> /tmp/babbler_devel_out # make the -j4 optional input
  if [ $? -eq 0 ]; then
    echo "Done."
  else
    echo ""
    cat /tmp/babbler_devel_out
    echo "Error: Babbler failed to compile."
    failed=true
    break
  fi

  echo -n "Running test harness... "
  ./run_tests -j4 &> /tmp/babbler_devel_out
  if [ $? -eq 0 ]; then
    echo "Done."
  else
    echo ""
    cat /tmp/babbler_devel_out
    failed=true
    break
  fi

  for inputfile in $(git ls-files *.i)
  do
    echo -n "Executing $inputfile... "
    ./babbler-opt -i $inputfile &> /tmp/babbler_devel_out
    if [ $? -eq 0 ]; then
      echo "Done."
    else # moose error report will be output
      echo ""
      cat /tmp/babbler_devel_out
      failed=true
      break 2
    fi
  done
done
rm /tmp/babbler_devel_out

echo ""
if ! $failed; then
  echo "Testing of Babbler applications in MOOSE completed succesfully."
else
  echo "Testing of Babbler applications in MOOSE failed. Please check output for error reports."
fi
