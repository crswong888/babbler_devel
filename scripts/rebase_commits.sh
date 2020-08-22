#!/bin/bash

# warning, this will unstage any staged changes to $1

# remove forward slash from source directory name if provided
srcdir="${1%/}"

function stash {
  git stash push -- $1*
}

git reset HEAD $srcdir* --quiet
modified=$(git diff --name-only $srcdir)
# if [ -n $modified ]; then
#
# fi
# else, no staged or unstaged changes found, aborting

if [ -f "tmp" ]; then
  rm tmp
fi

for dstdir in step*
do
  if [ ${dstdir:4:2} -gt ${srcdir:4:2} ]; then
    for srcfile in $modified
    do
      # Find the destination file if it exists
      dstfile=$dstdir${srcfile#$srcdir}
      if [ ! -f $dstfile ]; then
        # issue warning, skipping file - if it is a new file, it should be added by some other means
        continue
      fi

      # Stash and get retro diff
      git stash push -- $srcfile*
      diff=$(diff $srcfile $dstfile | grep '^[1-9]') # pipe to grep to and only output diff codes

      echo "$diff"

      # split and read into an array
      # for d in $diff
      # do
      #   # ifs=$IFS
      #   # IFS=","
      #   read -r -a diffarray <<< "$diff"
      #   # IFS=$ifs
      #   echo ${diffarray[0]}
      # done

      # split by each char
      # for d in $diff
      # do
      #   for char in $(echo "$d" | sed 's/\(.\)/\1\n/g')
      #   do
      #     echo $char
      #   done
      # done

      # pop stash
      git stash apply --quiet
      git stash drop stash@{0}

      # copy only those lines which don't match the retro diff
      ifs=$IFS # store default internal field separator so we can switch back and forth
      j=$((1)) # current line index in dstfile
      for i in $(seq 1 $(wc -l < $srcfile))
      do
        difftype="None"
        for d in $diff
        do
          # read lower and upper diff line indices (x,x[a|c|d]x,x) from each file into an array
          IFS="acd"
          read -r -a lines <<< $d
          IFS=","
          read -r -a srclines <<< ${lines[0]}
          read -r -a dstlines <<< ${lines[1]}
          IFS=$ifs # restore default IFS

          # store lower and upper line indices to determine how it should be copied - if at all
          srclower=${srclines[0]}
          srcupper=${srclines[1]}
          if [ -z $srcupper ]; then
            srcupper=$srclower
          fi

          dstlower=${dstlines[0]}
          dstupper=${dstlines[1]}
          if [ -z $dstupper ]; then
            dstupper=$dstlower
          fi

          # determine if current line matches a diff index
          if [ $i -ge $srclower ] && [ $i -le $srcupper ]; then
            difftype=$(echo $d | sed 's/[^acd]*//g') # pipe type char (add, change, del) to sed
            break
          fi
        done

        echo "Before:"
        echo $j
        echo $(($(wc -l < tmp) + 1))

        #
        if [ $difftype = "None" ]; then
          sed -n "$i"p $srcfile >> tmp
          #j=$((j + 1))
        elif [ $difftype = "a" ]; then
          sed -n "$i"p $srcfile >> tmp
          #j=$((j + 1))
          for range in $(seq $dstlower $dstupper)
          do
            sed -n "$(($(wc -l < tmp) + 1))"p $dstfile >> tmp
            #j=$((j + 1))
          done
        elif [ $difftype = "c" ] && [ $i = $srcupper ]; then
          for range in $(seq $dstlower $dstupper)
          do
            sed -n "$(($(wc -l < tmp) + 1))"p $dstfile >> tmp
            #j=$((j + 1))
          done
        fi

      done
    done

    # this is temporary!!!!
    mv tmp tmptmp
    exit 1

  fi
done
