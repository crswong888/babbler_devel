#!/bin/bash

# TODO: add argument to be verbose about warnings - otherwise, don't print certain warnings

# NOTE: There MUST be a difference between the local source files and those at the specified SHA,
# which defaults to 'HEAD'. Otherwise, there is no way to tell what has changed in the source file,
# and therefore, what ought to be merged into all destination files.
#
# If the changes you wish to rebase off of have already been committed, specify an old SHA that
# represents the state of the file before the new changes were applied.

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
  echo "Error: Could not find a directory named '$srcdir/'."
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
  gitdiff=$2 # same as diff - pass it in "$2" format
  srcfile=$3
  dstfile=$4

  # copy only those lines which don't match the retro diff
  ifs=$IFS # store default internal field separator so we can switch back and forth
  i=$((1)) # initialize file line indexing
  skipped=$((0)) # initialize value to adjust $srcfile indices in $diff to reflect those in $gitdiff
  while [ $i -le $(wc -l < $srcfile) ]
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
      srclower=$((${srclines[0]} + $skipped))
      srcupper=$((${srclines[1]} + $skipped))
      if [ $srcupper -eq 0 ]; then
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
      # if there is no diff at $sha, then any line in local version of $srcfile is merged
      sed -n "$i"p $srcfile >> /tmp/dstfile

      # obtain diff data between local version of $srcfile and the one at the specified head
      gitdifftype="None"
      for d in $gitdiff
      do
        IFS="acd"
        read -r -a lines <<< $d
        IFS=","
        read -r -a newlines <<< ${lines[0]}
        read -r -a oldlines <<< ${lines[1]}
        IFS=$ifs

        newlower=${newlines[0]}
        newupper=${newlines[1]}
        if [ -z $newupper ]; then
          newupper=$newlower
        fi

        oldlower=${oldlines[0]}
        oldupper=${oldlines[1]}
        if [ -z $oldupper ]; then
          oldupper=$oldlower
        fi

        if [ $i -ge $newlower ] && [ $i -le $newupper ]; then
          gitdifftype=$(echo $d | sed 's/[^acd]*//g')
          break
        fi
      done

      # If a line was created or deleted in $srcfile - diff indices at $sha need to be adjusted
      if [ $gitdifftype = "d" ]; then
        skipped=$(($skipped + 1))
      elif [ $gitdifftype = "a" ]; then
        skipped=$(($skipped - ($oldupper - $oldlower + 1)))
      fi
    elif [ $difftype = "a" ]; then
      sed -n "$i"p $srcfile >> /tmp/dstfile
      for range in $(seq $dstlower $dstupper)
      do
        sed -n "$(($(wc -l < /tmp/dstfile) + 1))"p $dstfile >> /tmp/dstfile
      done
    elif [ $difftype = "c" ] && [ $i -eq $srcupper ]; then
      for range in $(seq $dstlower $dstupper)
      do
        sed -n "$(($(wc -l < /tmp/dstfile) + 1))"p $dstfile >> /tmp/dstfile
      done
    fi

    # update current line index
    i=$(($i + 1))
  done

  # overwrite $dstfile with the temporary merger file if any actual changes were made
  if [ -n "$(diff /tmp/dstfile $dstfile)" ]; then
    mv /tmp/dstfile $dstfile
    echo "Merged changes from '$srcfile' into '$dstfile'"
    return 0 # indicate that a file has actually changed
  fi

  return 1 # indicate that no changes were made
}

changes=false # initialize variable to track wether any changes have been made at all
for dstdir in step*
do
  if [ $srcdir == "stork" ] || [ ${dstdir:4:2} -gt ${srcdir:4:2} ]; then
    if [ -n "$(git diff --name-only $dstdir)" ]; then
      echo -n "Error: There are unstaged changes in the '$dstdir/' directory. Please add or stash "
      echo    "them before rebasing."
      exit 1
    fi

    for srcfile in $(git ls-files $srcdir)
    do
      # Check that local copy exists
      if [ ! -f $srcfile ]; then
        echo "Warning: Could not find local copy of tracked file '$srcfile'. It will be skipped."
        continue
      fi

      # Find the destination file if it exists
      dstfile=$dstdir${srcfile#$srcdir}
      if [ ! -f $dstfile ]; then
        echo "Warning: Cannot merge changes from '$srcfile' into non-existant file: '$dstfile'."
        continue
      fi

      # Write a temporary file containing the contents of $srcfile at $sha and output a `diff`
      git show $sha:$srcfile > /tmp/srcfile
      diff=$(diff /tmp/srcfile $dstfile | grep '^[1-9]') # pipe to grep to and only output diff code
      gitdiff=$(diff $srcfile /tmp/srcfile | grep '^[1-9]')

      # Copy lines from $srcfile to $dstfile which don't match $diff and merge those that do
      if [[ -n "$diff" || -n "$gitdiff" ]]; then
        if copydiff "$diff" "$gitdiff" $srcfile $dstfile; then
          changes=true
        fi
      fi

      # delete the temporary file copied from head at $sha
      rm /tmp/srcfile
    done
  fi
done

if $changes; then
  echo -e "Checking git status:\n"
  git status
else
  echo "Warning: No changes from '$srcdir' were merged. Be sure that there is a difference between "
  echo "         the local copy and the one at the specified SHA so that changes can be identified."
  echo "   Note: SHA used = '$sha'"
  exit 1
fi
