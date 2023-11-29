#!/bin/bash
#            softlinkPot2Po.sh
# Creates input file names suitable for translate_po
#            (https://github.com/zcribe/translate-po)

if [ $# -eq 0 ]; then
  echo "provide either <SomeFilename>.lst containing list of POT files"
  echo "            or relative qualified source POT filename(s)"
  echo "            or relative source POT director(y|ies)"
  exit 1
fi
for arg in $*; do
  if [[ $arg =~ .lst ]]; then
    for pot in $(cat $arg); do
      if [ ! -e $pot ]; then
        echo "$arg : $pot does not exist"
        exit 1
      fi
      po=$(basename ${pot/.pot/.po})
      ln -sv $pot ./$po || exit 1
    done
  elif [ -d $arg ]; then
    for pot in $arg/*.pot; do
      po=$(basename ${pot/.pot/.po})
      ln -sv $pot ./$po || exit 1
    done
  else
    if [ ! -f $arg ]; then
      echo "unknown argument $arg : expecting existing pot file name"
      exit 1
    fi
    if [[ ! $arg =~ .pot ]]; then
      echo "unknown argument $arg : expecting file extension .pot"
      exit 1
    fi
    po=$(basename ${pot/.pot/.po})
    ln -sv $pot ./$po || exit 1
  fi
done

