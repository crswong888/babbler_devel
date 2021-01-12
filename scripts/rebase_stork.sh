#!/bin/bash

### TODO: need to add a clang format to the end of this

# list files which are modified by the step01 initialization of Babbler so that they are ignored
ignore="README.md
        test/tests/kernels/simple_diffusion/tests"

# delete the existing stork
if [ -d "stork" ]; then
  rm -rf stork
fi

# create directory for storing temp files
tmp="/tmp/babbler_tmp"
if [ -d $tmp ]; then
  rm -rf $tmp
fi
mkdir $tmp

# reinitialize stork
echo "Entering directory: '~/projects'"
cd ~/projects
echo -n "Initializing Babbler stork application... "
moose/scripts/stork.sh Babbler &> /dev/null
mv babbler/ babbler_devel/stork
echo "Done."

# move files in $ignore to temporary location (so Babbler modifications are preserved)
for file in $ignore
do
  mv babbler_devel/stork/$file $tmp
done

# invoke rebase commits script
echo "Leaving directory: '~/projects'"
cd babbler_devel
echo -n "Rebasing commits on stork app directory... "
scripts/rebase_commits.sh stork &> $tmp/out

# make sure script exited properly, otherwise, print output from rebase script
if [ $? -eq 0 ]; then
  echo "Done."

  # move ignored files back to stork
  for file in $ignore
  do
    mv $tmp/$(basename $file) stork/$file
  done

  # parse --add option
  if [[ "$1" == "-a" || "$1" == "--add" ]]; then
    git add stork*
  fi

  echo -e "Checking git status:\n"
  git status
else
  echo -e "\n"

  # create a regex pattern to remove any messages specifically about $ignore files
  squelch="/\("
  for file in $ignore
  do
    squelch="$squelch$(echo $file | sed -e 's/\//\\\//g')\|"
  done

  # print out and revert changes
  sed "${squelch%|})/d" $tmp/out
  git checkout stork*
  git clean stork/ -f
fi

# delete temp directory
rm -rf $tmp
