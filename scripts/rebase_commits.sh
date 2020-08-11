#!/bin/bash

# remove forward slash from directory name if provided
srcname="${1%/}"

currdir=$srcname
for file in step*
do
  if [ ${file:4:2} -le ${srcname:4:2} ]; then
    continue
  else
    ./scripts/new_commit.sh $srcname $file --force --add
  fi
done
