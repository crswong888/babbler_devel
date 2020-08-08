#!/bin/bash

# Add forward slash to source directory name if not provided
srcname="${1%/}/"

# babbler submodule should be a child folder of current working directory
#    - search for it
# and the current working directory should be the babbler_devel repo parent dir with git initialized
#    - check for .git folder or something idk

# Function for copying file to a specified destination
function copyfile {
  dstpath="$(dirname $2)"
  if [ ! -d $dstpath ]; then
    mkdir -p $dstpath
  fi
  cp -p $1 $2
}

# copy files from source to Babbler
echo -n "Copying files tracked by Git from '$srcname' to 'babbler'... "
for file in `git ls-files $srcname`
do
  dst="babbler/${file#$srcname}"
  copyfile $file $dst
done
echo "Done."
