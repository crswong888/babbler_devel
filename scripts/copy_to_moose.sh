#!/bin/bash

function printusage {
    echo "Usage:    ./scripts/copy_to_moose.sh <source> <options>"
    echo ""
    echo "    Creates a folder in '../moose/tutorials/tutorial01_app_development/' to represent a "
    echo "    new Babbler commit. This script must be ran from 'babbler_devel/'. Any unstaged "
    echo "    changes in '../moose/tutorials/tutorial01_app_development/<source>' should be staged "
    echo "    before running this script."
    echo ""
    echo "    <source> The name of the source directory to copy."
    echo ""
    echo "    <options> Non-positional arguments supplied after <source> <destination>:"
    echo ""
    echo "              -f, --force "
    echo "                  The '../moose/tutorials/tutorial01_app_development/<source>' folder "
    echo "                  will be overwritten if it already exists."
    echo ""
    echo "              -a, --add "
    echo "                  Add git tracking to newly created files. Modified files are skipped."
    echo ""
}

if [[ "$1" == "-h" || "$1" == "--help" || $# == 0 || $# > 3 ]]; then
    printusage
    exit 1
fi

# Modify paths and add forward slash to directory names if not provided
echo "Entering directory: '../moose/'"
cd ../moose/
srcname="${1%/}/"
srcdir="../babbler_devel/"
dstname="tutorials/tutorial01_app_development/${1%/}/"

if [ ! -d $srcdir$srcname ]; then
  echo "Error: Directory $srcdir$srcname does not exist."
  exit 1
fi

if [ -d $dstname ] && ! [[ "$2" == "-f" || "$2" == "--force" || "$3" == "-f" || "$3" == "--force" ]]; then
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

echo -n "Copying files tracked by Git from '$srcdir$srcname' to '$dstname'... "
for file in `cd $srcdir && git ls-files $srcname`
do
  dst=$dstname${file#$srcname}
  copyfile $srcdir$file $dst

  # only add new untracked files to preserve any previously staged changes
  if [[ "$2" == "-a" || "$2" == "--add" || "$3" == "-a" || "$3" == "--add" ]] && ! gitstatus $dst $dstname; then
    git add $dst
  fi
done
echo "Done."

echo "Leaving directory: 'moose/'"
cd ../babbler_devel
echo -n "Copying files not tracked by Git, except those which match a '.gitignore' pattern... "
if [ ! -f "$srcname.gitignore" ]; then
  echo -e "\nFile '$srcname.gitignore' not found. Skipping untracked files."
else
  for file in `find $srcname`
  do
    if ! gitstatus $file $srcname && [ -z "`git check-ignore $file`" ]; then
      copyfile $file "../moose/$dstname${file#$srcname}"
    fi
  done
fi
echo "Done."

echo -e "Checking git status in '../moose/':\n"
cd ../moose/ && git status
