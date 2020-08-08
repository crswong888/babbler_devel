#!/bin/bash

function printusage {
    echo "Usage:    new_commit.sh <source> <destination> <options>"
    echo ""
    echo "    Creates a folder in the current working directory to represent a new Babbler commit."
    echo ""
    echo "    <source> The name of the source directory to copy."
    echo ""
    echo "    <destination> The name of the new folder to begin staging changes off of."
    echo ""
    echo "    <options> Non-positional arguments supplied after <source> <destination>:"
    echo ""
    echo "              -f, --force "
    echo "                  The <destination> folder will be overwritten if it already exists."
    echo ""
    echo "              -a, --add "
    echo "                  Add git tracking to newly created files. Modified files are skipped."
    echo ""
}

if [[ "$1" == "-h" || "$1" == "--help" || $# == 0 || $# > 4 ]]; then
    printusage
    exit 1
fi

# Add forward slash to directory names if not provided
srcname="${1%/}/"
dstname="${2%/}/"

if [ ! -d $srcname ]; then
  echo "Error: Directory $srcname does not exist."
  exit 1
fi

if [ -d $dstname ] && ! [[ "$3" == "-f" || "$3" == "--force" || "$4" == "-f" || "$4" == "--force" ]]; then
  echo "Error: Directory '$dstname' already exists. Use '-f' to overwrite existing files."
  exit 1
elif [ ! -d $dstname ]; then
  echo "Creating directory '$dstname'."
  mkdir $dstname
fi

# Function for copying file to a specified destination
function copyfile {
  dstpath="$(dirname $2)"
  if [ ! -d $dstpath ]; then
    mkdir -p $dstpath
  fi
  cp -p $1 $2
}

# Function for determining wether a file is tracked by Git or not
function gitstatus {
  status=1
  if [ -d $1 ]; then
    # consider directories as tracked so all files don't just get added willy-nilly
    status=0
  else
    # check if file is already being tracked to avoid overwriting those changes
    for gitfile in `git ls-files $2`
    do
      if [ $1 == $gitfile ]; then
        status=0
        break
      fi
    done
  fi
  return $status
}

echo -n "Copying files tracked by Git from '$srcname' to '$dstname'... "
for file in `git ls-files $srcname`
do
  dst=$dstname${file#$srcname}
  copyfile $file $dst

  # only add new untracked files to preserve any previously staged changes
  if [[ "$3" == "-a" || "$3" == "--add" || "$4" == "-a" || "$4" == "--add" ]] && ! gitstatus $dst $dstname; then
    git add $dst
  fi
done
echo "Done."

echo -n "Copying files not tracked by Git, except those which match a '.gitignore' pattern... "
if [ ! -f "$srcname.gitignore" ]; then
  echo -e "\nFile '$srcname.gitignore' not found. Skipping untracked files."
else
  for file in `find $srcname`
  do
    if ! gitstatus $file $srcname && [ -z "`git check-ignore $file`" ]; then
      copyfile $file $dstname${file#$srcname}
    fi
  done
fi
echo "Done."

echo -e "Checking git status:\n"
git status
