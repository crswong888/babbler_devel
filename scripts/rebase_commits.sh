#!/bin/bash

function printusage {
    echo "Usage:    ./scripts/rebase_commits.sh <source> <sha>"
    echo ""
    echo "    This script does not yet have documentation."
    echo ""

    # This script uses a diff at a specific head to select which lines to copy to the file in the
    # subsequent commit directories. If no sha is specified, it assumes HEAD for comparing diffs
}

if [[ "$1" == "-h" || "$1" == "--help" || $# == 0 || $# > 2 ]]; then
    printusage
    exit 1
fi

# remove forward slash from source directory name if provided and check if dir exists
srcdir="${1%/}"
if [ ! -d $srcdir ]; then
  echo "Error: Directory $srcdir does not exist."
  exit 1
fi

# determine branch head to use for comparing file diffs
sha=$2
if [ -z $sha ]; then
  sha="HEAD"
fi

if [ "$(git cat-file -t $sha)" != "commit" ]; then
  echo "Error: $sha is not a valid commit."
  exit 1
fi

# Function for copying lines which don't match a `diff` at $sha from file in $srcdir to $dstdir
function copydiff {
  # '/tmp/dstfile' will temporarily store file updates before merging - be sure one isn't lingering
  if [ -f "/tmp/dstfile" ]; then
    rm /tmp/dstfile
  fi

  # define convenience variables (these are the required positional arguments for this func)
  diff=$1 # diff argument must be the entire string - pass it in "$1" format
  srcfile=$2
  dstfile=$3

  # copy only those lines which don't match the retro diff
  ifs=$IFS # store default internal field separator so we can switch back and forth
  for i in $(seq 1 $(wc -l < $srcfile))
  do
    difftype="None"
    for d in $diff
    do
      # read lower and upper diff line indices (x,x[a|c|d]x,x) from each file into an array
      IFS="acd" # split string by a, c, or d
      read -r -a lines <<< $d
      IFS="," # split strings by commas
      read -r -a srclines <<< ${lines[0]}
      read -r -a dstlines <<< ${lines[1]}
      IFS=$ifs # restore default IFS

      # store lower and upper line diff indices for $srcfile
      srclower=${srclines[0]}
      srcupper=${srclines[1]}
      if [ -z $srcupper ]; then
        srcupper=$srclower
      fi

      # lower and upper diff indices for $dstfile
      dstlower=${dstlines[0]}
      dstupper=${dstlines[1]}
      if [ -z $dstupper ]; then
        dstupper=$dstlower
      fi

      # determine if current line matches a diff index - get the type of diff if it is
      if [ $i -ge $srclower ] && [ $i -le $srcupper ]; then
        difftype=$(echo $d | sed 's/[^acd]*//g') # pipe char to sed - (a)dd, (c)hange, (d)elete
        break
      fi
    done

    # copy lines from $srcfile to '/tmp/dstfile' based on the type of `diff` determined
    touch /tmp/dstfile
    if [ $difftype = "None" ]; then
      sed -n "$i"p $srcfile >> /tmp/dstfile
    elif [ $difftype = "a" ]; then
      sed -n "$i"p $srcfile >> /tmp/dstfile
      for range in $(seq $dstlower $dstupper)
      do
        sed -n "$(($(wc -l < /tmp/dstfile) + 1))"p $dstfile >> /tmp/dstfile
      done
    elif [ $difftype = "c" ] && [ $i = $srcupper ]; then
      for range in $(seq $dstlower $dstupper)
      do
        sed -n "$(($(wc -l < /tmp/dstfile) + 1))"p $dstfile >> /tmp/dstfile
      done
    fi
  done

  # overwrite $dstfile with the temporary merger file
  mv /tmp/dstfile $dstfile
}

for dstdir in step*
do
  if [ ${dstdir:4:2} -gt ${srcdir:4:2} ]; then
    for srcfile in $(git ls-files $srcdir)
    do
      # Find the destination file if it exists
      dstfile=$dstdir${srcfile#$srcdir}
      if [ ! -f $dstfile ]; then
        # issue warning, skipping file - if it is a new file, it should be added by some other means
        continue
      fi

      # Write a temporary file containing the contents of $srcfile at $sha and output a `diff`
      git show $sha:$srcfile > /tmp/srcfile
      diff=$(diff /tmp/srcfile $dstfile | grep '^[1-9]') # pipe to grep to and only output diff code
      rm /tmp/srcfile

      # Invoke function to copy lines from $srcfile to $dstfile which don't match $diff
      if [ -n "$diff" ]; then
        echo -n "Merging changes from '$srcfile' into '$dstfile'... "
        copydiff "$diff" $srcfile $dstfile
        echo "Done."
      fi
    done
  fi
done

echo -e "Checking git status:\n"
git status
