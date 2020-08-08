#!/bin/bash

# enable extglob
shopt -s extglob

# babbler submodule should be a child folder of current working directory
#    - search for it
# and the current working directory should be the babbler_devel repo parent dir with git initialized
#    - check for .git folder or something idk

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

# */ we need a separate set of tags that are intended for the devel branch only
# */ and we should only delete those at origin
# git push origin --delete $(git tag -l)

# clear all local and remote tags with "devel" suffix
for tag in `git tag -l`
do
  if [ ${tag#step??_} == "devel" ]; then
    git push origin --delete $tag
    git tag -d $tag
  fi
done

# create a temporary orphan branch and clear the directory - preserve the .git, of course
git checkout --orphan temp
rm -rfv !(.git|.|..) &> /dev/null
git add --all
echo "Removed all files on branch 'temp'"

# REPEAT THE FOLLOWING FOR ALL COMMITS
# ----------------------------------------------------------------------

# what if no steps are found
# what if step* is found bout its not in the format stepXX, e.g., step1
# what if no commit message is returned?

for file in ../step*
do
  # read commit message and copy files from commit directory to babbler
  echo "Leaving directory: 'babbler/'"
  cd ../
  srcname=$(basename $file)
  msg=`commitmsg $srcname`
  ./scripts/copy_to_babbler.sh "$srcname"

  # compile and test the application - we need to ensure that every step works
  #
  # okay... what do I do here if compilation or testing fails. How do i even determine failure from shell?
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

echo -e "Checking git tag:\n"
git tag
git push origin *_devel

# stage updates to babbler submodule
echo "Leaving directory: 'babbler/'"
cd ../
git add babbler
echo -e "Checking git status:\n"
git status

# quick message about checking babbler/devel on github
# quick message about pushing the submodule update for this repo
