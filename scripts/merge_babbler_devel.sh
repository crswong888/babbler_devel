#!/bin/bash

### merge the 'devel' branch into 'master' and delete 'devel' once everything looks good

# check connection to remote repository
echo -n "Checking connection to remote '`cd babbler/ && git ls-remote --get-url`'... "
cd babbler/ && git ls-remote &> /dev/null && cd ../
if [ ! $? -eq 0 ]; then
  echo -e "\nError: Could not establish connection to remote '`git ls-remote --get-url`'."
  exit 1
fi
echo "Done."

# import the build_and_test function
source ./scripts/build_and_test.sh

# clean up babbler submodule
git submodule deinit babbler/ -f
git submodule update --init babbler/
echo "Entering directory: 'babbler/'"
cd babbler/
make clean
git clean -xdf &> /dev/null

# fetch origin remote and check that 'devel' branch exists
git fetch
if [ -z "$(git show-ref refs/remotes/origin/devel)" ]; then
  echo "Error: Remote branch 'devel' not found on Babbler repository. Run 'push_babbler_devel.sh' "
  echo "       and verify that the remote repository looks good before running this script."
  exit 1
fi

# create a temporary orphan branch and reset it with 'origin/devel'
if [ -n "$(git show-ref refs/heads/temp)" ]; then
  git branch -D temp
fi
git checkout --orphan temp
git reset --hard origin/devel

# assuming 'push_babbler_devel.sh' ran, then every commit has been tested, but test at least HEAD here
if ! build_and_test; then
  echo "Testing of Babbler application failed. Please check output for error reports."
  exit 1
fi

# overwrite existing 'master' with 'temp' branch and push to remote
if [ -n "$(git show-ref refs/heads/master)" ]; then
  git branch -D master
fi
git branch -m master
echo "Renamed branch 'temp' to 'master'"
echo -e "Checking git log:\n"
git log
git push -u -f origin master

# delete local and remote 'devel' branch
if [ -n "$(git show-ref refs/heads/devel)" ]; then
  git branch -D devel
fi
git push --delete origin devel

# stage submodule update and report final git status
echo "Leaving directory: 'babbler/'"
cd ../
git add -v babbler
echo -e "Checking git status:\n"
git status

# messages to follow succesful merge
echo "Babbler update complete."
echo -n "Changes pushed to branch '`cd babbler/ && git symbolic-ref --short HEAD`' of "
echo "'`cd babbler/ && git ls-remote --get-url`'."
echo "View repository at https://github.com/idaholab/babbler."
echo ""
echo "Babbler submodule checked out at `cd babbler/ && git rev-parse HEAD`."
echo "Commit and push Babbler submodule update to `git ls-remote --get-url` when ready."
