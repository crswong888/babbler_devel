#!/bin/bash

# enable extglob
shopt -s extglob

# babbler submodule should be a child folder of current working directory
#    - search for it
# and the current working directory should be the babbler_devel repo parent dir with git initialized
#    - check for .git folder or something idk

# perhaps I shoudld include some option here to only stage commits following a certain point in the
# history, e.g., HEAD~2, step05_kernel_object, and so on, but don't modify step01 or step02...
#
# compiling and testing following each commit should be optional, --run-tests
#
# creating tags should be optional, -t or --tags
#
# pushing to remote babbler should be optional, -p or --push
#   - this also specifies wether tags are pushed too when -t or --tags
#
# perhaps the remote branch should be optional, "some_branch" instead of current default, "devel"
#   - except this might make things messy - no need to create all kinnds of branches of babbler

# check connection to remote repository
echo -n "Checking connection to remote '`cd babbler/ && git ls-remote --get-url`'... "
cd babbler/ && git ls-remote &> /dev/null && cd ../
if [ ! $? -eq 0 ]; then
  echo -e "\nError: Could not establish connection to remote '`git ls-remote --get-url`'."
  exit 1
fi
echo "Done."

# Function for reading a commit message for a specified directory from 'babbler.log'
function commitmsg {
  # babbler.log must exist
  # TODO: how to parse case of multiple commits per step
  # the $1 argument, the only argument, must be provided, and the directory by this name must exist

  # Find commit step and read message:
  readmsg=false
  while read -r line;
  do
    if [[ ${line:0:1} == "#" ]]; then
      continue
    fi
    if $readmsg; then
      if [[ $line != "[]" ]]; then
        echo $line
      else
        break
      fi
    elif [[ $line != "[]" ]] && [[ ${line:0:1} == "[" ]] && [[ ${line:(-1)} == "]" ]]; then
      dir=${line#[}
      if [ ${dir%]} == "${1%/}" ]; then
        readmsg=true
      fi
    fi
  done < babbler.log
}

# Function for copying file to a specified destination
function copyfile {
  dstpath="$(dirname $2)"
  if [ ! -d $dstpath ]; then
    mkdir -p $dstpath
  fi
  cp -p $1 $2
}

# stash any untracked changes to files in any of the step* directories
stashed=false
if [ -n "`git status -s step*`" ]; then
  git stash push -- step*
  stashed=true
fi

# clean up babbler submodule
git submodule deinit babbler/ -f
git submodule update --init babbler/
echo "Entering directory: 'babbler/'"
cd babbler/
make clean
git clean -xdf &> /dev/null

# ensure devel is checked out and clean
git fetch
git checkout devel # if devel not found, git checkout -b devel origin/devel, if origin/devel not found, exit
git reset --hard origin/devel
git clean -xdf &> /dev/null

# clear all local and remote tags with "devel" suffix
for tag in `git tag -l`
do
  if [ ${tag#step??_} == "devel" ]; then
    git push origin --delete $tag
    git tag -d $tag
  fi
done

# create a temporary orphan branch and clear the directory - preserve the .git, of course
if [ -n "`git show-ref refs/heads/temp`" ]; then
  git branch -D temp
fi
git checkout --orphan temp
rm -rfv !(.git|.|..) &> /dev/null
git add --all
echo "Removed all files on branch 'temp'"

# REPEAT THE FOLLOWING FOR ALL COMMITS
# ----------------------------------------------------------------------

# what if no steps are found
# what if a step* is not in the format stepXX, e.g., 'step1_' - this would cause sorting problems
# what if no commit message is returned?

for file in ../step*
do
  # read commit message and copy files from commit directory to babbler
  echo "Leaving directory: 'babbler/'"
  cd ../
  srcname=$(basename $file)
  msg=`commitmsg $srcname`

  # copy files from source to Babbler
  echo -n "Copying files tracked by Git from '$srcname' to 'babbler'... "
  for gitfile in `git ls-files $srcname`
  do
    dst="babbler/${gitfile#$srcname}"
    copyfile $gitfile $dst
  done
  echo "Done."

  # compile and test the application - we need to ensure that every step works
  #
  # okay... what do I do here if compilation or testing fails. How do i even determine failure from
  # shell? Does it have a non-zero exit status?
  echo "Entering directory: 'babbler/'"
  cd babbler/
  make clean
  make -j4 # make the -j4 optional input
  ./run_tests -j4

  # stage and commit files
  git add --all
  git commit -m "$msg"

  # the tags with the `devel` suffix eventually overwrite tags which refer to master branch commits
  git tag "${srcname:0:6}_devel"

  # ensure a clean repository (you can't run this command enough here)
  git clean -xdf &> /dev/null
done

# ----------------------------------------------------------------------

# overwrite devel with the temp branch and push to remote
git branch -D devel
git branch -m devel
echo "Renamed branch 'temp' to 'devel'"
echo -e "Checking git log:\n"
git log
git push -u -f origin devel

# push new tags to remote
echo -e "Checking git tag:\n"
git tag
git push origin *_devel

# pop stash and stage submodule update
echo "Leaving directory: 'babbler/'"
cd ../
if $stashed; then
  git stash apply --quiet
  git stash drop stash@{0}
fi

# stage submodule update and report final git status
git add -v babbler
echo -e "Checking git status:\n"
git status

# messages to follow succesful update
echo "Babbler update complete."
echo -n "Changes pushed to branch '`cd babbler/ && git symbolic-ref --short HEAD`' of "
echo "'`cd babbler/ && git ls-remote --get-url`'."
echo "View repository at https://github.com/idaholab/babbler/tree/devel."
echo ""
echo "'babbler' submodule checked out at `cd babbler/ && git rev-parse HEAD`."
echo "Commit and push 'babbler' submodule update to `git ls-remote --get-url` when ready."
