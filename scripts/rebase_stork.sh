#!/bin/bash

# list files which are modified by the step01 initialization of Babbler so that they are ignored
ignore="README.md
        test/tests/kernels/simple_diffusion/tests"

# make sure there are no uncommited changes in commit directories, even if they're staged
if [ -n "$(git diff master --name-only step*)" ]; then
  echo "Error: There are uncommited changes in the commit directories. Please commit or stash "
  echo "       them before rebasing with the stork application."
  exit 1
fi

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

# clean up stork
#
# NOTE: This has to be done from the 'babbler_devel' root because 'stork' has been initialized as a
#       new git repository, and so we can't tell what has changed from within 'stork'.
echo "Leaving directory: '~/projects'"
cd babbler_devel

# move files in 'ignore' to temporary location (so Babbler modifications are preserved)
echo -n "Cleaning in 'stork'..."
for file in $ignore
do
  mv stork/$file $tmp
done

# check if any stork files are deprecated, i.e., no longer generated for new MOOSE apps
deleted=''
for delete in $(git ls-files stork --deleted)
do
  # but definitely still skip 'ignore' files in this check
  for file in $ignore
  do
    if [ $file == ${delete#stork/} ]; then
      continue 2
    fi
  done

  # mark all occurances of file in both 'stork' and commit directories for deletion
  deleted+=$(git ls-files *${delete#stork/})' '
done

# remove deleted stork files from list of git files so that 'rebase_commits.sh' runs properly
if [ -n "$deleted" ]; then
  git rm $deleted &> /dev/null
fi
echo "Done."

# invoke rebase commits script
echo -n "Rebasing commits on updated stork app directory... "
scripts/rebase_commits.sh stork &> $tmp/out

# make sure script exited properly, otherwise, print output from rebase script
if [ $? -eq 0 ] || [ -n "$deleted" ]; then
  echo "Done."

  # move ignored files back to stork
  for file in $ignore
  do
    mv $tmp/$(basename $file) stork/$file
  done

  # parse --add option, if not adding tracking, unstage any and all files in 'deleted'
  if [[ "$1" == "-a" || "$1" == "--add" ]]; then
    git add stork*
  elif [ -n "$deleted" ]; then
    git reset HEAD $deleted
  fi

  echo -e "Checking git status:\n"
  git status
else
  echo -e "\n"

  # create a regex pattern to remove any messages specifically about 'ignore' files
  squelch="/\("
  for file in $ignore
  do
    squelch="$squelch$(echo $file | sed -e 's/\//\\\//g')\|"
  done

  # print out and revert changes
  sed "${squelch%|})/d" $tmp/out
  git restore stork*
  git clean stork/ -f
fi

# delete temp directory
rm -rf $tmp
