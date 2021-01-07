#!/bin/bash

# delete the existing stork
if [ -d "stork" ]; then
  rm -rf stork
fi

# reinitialize stork and delete the README.md (so Babbler modifications are preserved)
echo "Entering directory: '~/projects'"
cd ~/projects
echo -n "Initializing Babbler stork application... "
moose/scripts/stork.sh Babbler &> /dev/null
mv babbler/ babbler_devel/stork
rm babbler_devel/stork/README.md
echo "Done."

# invoke rebase commits script
echo "Leaving directory: '~/projects'"
cd babbler_devel
echo -n "Rebasing commits on stork app directory... "
scripts/rebase_commits.sh stork &> /tmp/babbler_devel_out
status=$?

# make sure script exited properly, otherwise, print output from rebase script
if [ $status -eq 0 ]; then
  echo "Done."

  # parse --add option
  if [[ "$1" == "-a" || "$1" == "--add" ]]; then
    git add stork*
  fi

  echo -e "Checking git status:\n"
  git status
else
  echo -e "\n"
  cat /tmp/babbler_devel_out
fi
rm /tmp/babbler_devel_out
