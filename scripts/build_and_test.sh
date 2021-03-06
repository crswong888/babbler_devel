#!/bin/bash

# returns with an exit status of 0 if compilation and testing succesful, else exits with 1

# import this function with `source ./scripts/build_and_test.sh` BEFORE entering babbler directories
function build_and_test {
  echo -n "Compiling Babbler... "
  make clean &> /tmp/babbler_devel_out
  make -j4 &> /tmp/babbler_devel_out # make the -j4 optional input
  if [ $? -eq 0 ]; then
    echo "Done."
  else
    echo ""
    cat /tmp/babbler_devel_out
    echo "Error: Babbler failed to compile."
    return 1
  fi

  echo -n "Running test harness... "
  ./run_tests -j4 -p2 &> /tmp/babbler_devel_out
  if [ $? -eq 0 ]; then
    echo "Done."
  else
    echo ""
    cat /tmp/babbler_devel_out
    return 1
  fi

  for inputfile in $(git ls-files *.i)
  do
    # skip input files with '_error' suffix - these are supposed to fail
    if [ ${inputfile%_error.i} != $inputfile ]; then
      continue
    fi

    # check that input file runs without errors on 4 procs and 2 threads/proc
    echo -n "Executing $inputfile... "
    mpiexec -n 4 ./babbler-opt -i $inputfile --n-threads=2 &> /tmp/babbler_devel_out
    if [ $? -eq 0 ]; then
      echo "Done."
    else # moose error report will be output
      echo ""
      cat /tmp/babbler_devel_out
      return 1
    fi
  done

  rm /tmp/babbler_devel_out
  return 0 # indicate succesful completion
}
