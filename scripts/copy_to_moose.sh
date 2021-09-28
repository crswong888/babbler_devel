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
    echo "    <options> Non-positional arguments supplied after <source>:"
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

# modify paths and add forward slash to directory names if not provided
moosedir="../moose/"
echo "Entering directory: '$moosedir'"
cd $moosedir
srcdir="../babbler_devel/${1%/}/"
dstdir="tutorials/tutorial01_app_development/${1%/}/"

if [ ! -d $srcdir ]; then
  echo "Error: Directory $srcdir does not exist."
  exit 1
fi

if [ -d $dstdir ] && ! [[ "$2" == "-f" || "$2" == "--force" || "$3" == "-f" || "$3" == "--force" ]]; then
  echo "Error: Directory '$dstdir' already exists. Use '-f' to overwrite existing files."
  exit 1
elif [ ! -d $dstdir ]; then
  echo "Creating directory '$dstdir'."
  mkdir $dstdir
fi

# check that there aren't any unstaged changes in MOOSE version
if [ -n "$(git diff --name-only $dstdir)" ]; then
  echo "Error: There are unstaged changes in the '$dstdir' directory. Please add or stash them "
  echo "       before overwriting files."
  exit 1
fi

# parse --add option
track=false
if [[ "$2" == "-a" || "$2" == "--add" || "$3" == "-a" || "$3" == "--add" ]]; then
  track=true
fi

# function for copying file to a specified destination
function copyfile {
  dstpath="$(dirname $2)"
  if [ ! -d $dstpath ]; then
    mkdir -p $dstpath
  fi
  cp -p $1 $2
}

# function for tracking or staging changes to a file - only adds files not already staged
function gitadd {
  if [ ! -d $1 ] && [ -z "$(git diff --name-only --staged -- $1)" ]; then
    git add $1
  else
    echo -e "\nWarning: File '$1' is already staged for commit so changes weren't tracked."
  fi
}

echo -n "Copying tracked files from '$srcdir' to '$dstdir'... "
for file in $(cd $srcdir && git ls-files)
do
  dst=$dstdir$file
  copyfile $srcdir$file $dst

  if $track; then
    gitadd $dst
  fi
done
echo "Done."

echo -n "Deleting tracked files in '$dstdir' not in '$srcdir'..."
for file in $(cd $dstdir && git ls-files)
do
  if [ ! -f $srcdir$file ]; then
    dst=$dstdir$file
    rm $dst

    if $track; then
      gitadd $dst
    fi
  fi
done
echo "Done."

echo -e "Checking git status in '$moosedir':\n"
git status
