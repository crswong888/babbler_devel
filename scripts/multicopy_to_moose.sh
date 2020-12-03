#!/bin/bash

function printusage {
    echo "Usage:    ./scripts/multicopy_to_moose.sh <lower> <upper> <options>"
    echo ""
    echo "    Invokes the 'copy_to_moose.sh' script for directories formatted as 'stepXX_*', where "
    echo "    'XX' is an integer in the range specified by [<lower>, <upper>]."
    echo ""
    echo "    <lower> The lower index for the range of directories to copy."
    echo ""
    echo "    <upper> The upper index for the range of directories to copy."
    echo ""
    echo "    <options> Non-positional arguments supplied after <lower> <upper>:"
    echo ""
    echo "              -f, --force "
    echo "                  The '../moose/tutorials/tutorial01_app_development/stepXX_*' folder "
    echo "                  will be overwritten if it already exists."
    echo ""
    echo "              -a, --add "
    echo "                  Add git tracking to newly created files. Modified files are skipped."
    echo ""
}

if [[ "$1" == "-h" || "$1" == "--help" || $# == 0 || $# > 4 ]]; then
    printusage
    exit 1
fi

# inoke copy_to_moose script on all commit directories in specified range
for srcdir in step*
do
  if [ ${srcdir:4:2} -ge $1 ] && [ ${srcdir:4:2} -le $2 ]; then
    echo "Now running: './scripts/copy_to_moose.sh $srcdir $3 $4'"
    ./scripts/copy_to_moose.sh $srcdir $3 $4

    # make sure that script completed succesfully
    if [ ! $? -eq 0 ]; then
      exit 1
    fi
    echo -e "Leaving directory: '../moose/'"
  fi
done
