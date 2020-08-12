#!/bin/bash

# Test all Babbler applications inside the MOOSE directory
#
# How to exit if test or compilation fails? (Need to do the same in update_babbler.sh)
for file in ../moose/tutorials/tutorial01_app_development/step*
do
  echo "Entering directory: $file"
  cd $file

  make clean
  make -j4
  ./run_tests -j4

  echo "Leaving directory: $file"
  cd ../../../../babbler_devel
done
