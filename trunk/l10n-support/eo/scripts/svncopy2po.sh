#!/bin/bash
#
# svncopy2po.sh
# Is expected to be called from within the "templates" directory.
# Argument shall include the "messages" subdir, e.g. messages/kpat/kpat.pot
# Will make an svn copy of the potfile to the ../eo/messages location as po file.
# Uses script initpo.pl for filling PO header and pre-translating common strings.
#
# Copyright (C) 2023, Oliver Kellogg <okellogg@users.sourceforge.net>
# Distributed under the MIT license (https://opensource.org/license/mit/)
#
# set -x
if [ -f $1 ]; then
  pot=$(basename $1)
  potdir=$(dirname $1)
else
  potdir=$1
fi
if [ -z "$potdir" ]; then
  echo "give messages/project name"
  exit 1
fi
if [ ! -e $potdir ]; then
  echo "$potdir does not exist"
  exit 1
fi
if [ ! -e ../eo/$potdir ]; then
  svn mkdir ../eo/$potdir
fi
if [ -n "$pot" ]; then
  po=../eo/$potdir/${pot/.pot/.po}
  if [ ! -e $po ]; then
    svn copy $potdir/$pot $po || break
    svn propset svn:mime-type "text/plain; charset=UTF-8" $po
    initpo.pl $potdir/$pot > $po || break
  fi
  exit
fi
for pot in $potdir/*.pot
do
  po=../eo/${pot/.pot/.po}
  if [ ! -e $po ]; then
    svn copy $pot $po || break
    svn propset svn:mime-type "text/plain; charset=UTF-8" $po
    initpo.pl $pot > $po || break
  fi
done
# set +x
