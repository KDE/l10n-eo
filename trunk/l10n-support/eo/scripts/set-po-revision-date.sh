#!/bin/bash
#
# set-po-revision-date.sh  - update the PO-Revision-Date line in po file(s)
#
# Usage:
#   set-po-revision-date.sh [ -d "<date_to_use>" ]  <one_or_more_po_filenames>
#
# If the option "-d" is not given then the current date will be used.
# The date format given for "-d" shall follow the pattern YYYY-MM-DD hh:mm[+-]TZOF
# where TZOF is a timezone offset as seen in the PO-Revision-Date line of PO files.
# If TZOF is not given then a fixed value will be used: +0100
#
# Example: "2024-03-28 06:34+0100"
#
# Copyright (C) 2024, Oliver Kellogg <okellogg@users.sourceforge.net>
# Distributed under the MIT license, https://opensource.org/license/mit
#
if [ $# -eq 0 ]; then
  echo "Provide at least one PO filename as argument"
  exit 1
fi
if [ $1 = "-d" ]; then
  shift
  Date="$1"
  if [[ ! $Date =~ [-+]0[0-9]00$ ]]; then
    Date+="+0100"
  fi
  shift
else
  Date=$(date +"%Y-%m-%d %H:%M+0100")
fi

sed "s/PO-Revision-Date: ....-..-.. ..:..[-+]0[0-9]00/PO-Revision-Date: $Date/" -i $*

