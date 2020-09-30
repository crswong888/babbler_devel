#!/bin/bash

### Test a particular Babbler commit directory in babbler_devel

dir=$1 # specify the argument as the desired directory for which a Babbler application is stored
failed=false # initialize variable to track wether compilation, testing, etc., of babbler failed

echo "Entering directory: $dir"
cd $dir
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

rm /tmp/babbler_devel_out

echo ""
if ! $failed; then
  echo "Testing of Babbler application in $dir completed succesfully."
else
  echo "Testing of Babbler application in $dir failed. Please check output for error reports."
fi
