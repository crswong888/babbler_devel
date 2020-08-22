#!/bin/bash

# This script uses a diff at a specific head to select which lines to copy to the file in the
# subsequent commit directories. If no sha is specified, it assumes HEAD for comparing diffs

# remove forward slash from source directory name if provided
srcdir="${1%/}"

# determine sha to use for compaing file diffs
sha=$2
if [ -z $sha ]; then
  sha="HEAD"
fi

if [ "$(git cat-file -t $sha)" != "commit" ]; then
  echo "Error: $sha is not a valid commit."
  exit 1
fi

# '/tmp/dstfile' will temporarily store file updates before merging - be sure one isn't lingering
if [ -f "/tmp/dstfile" ]; then
  rm /tmp/dstfile
fi

ifs=$IFS # store default internal field separator so we can switch back and forth
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

      #
      git show $sha:$srcfile > /tmp/srcfile
      diff=$(diff /tmp/srcfile $dstfile | grep '^[1-9]') # pipe to grep to and only output diff codes
      rm /tmp/srcfile

      # temporary
      if [ -z "$diff" ]; then
        continue
      fi
      # not this ^^^^^
      # this:
      #
      # if [ -n $diff ]; then
      #   execute the function
      # fi

      ######################
      # all of the rest of this can be passed to a function which takes $diff, $srcfile and $dstfile
      # the function should just remove tmp, its hardly slower and much more secure

      # copy only those lines which don't match the retro diff
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

        #
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
    done
  fi
done

echo -e "Checking git status:\n"
git status
