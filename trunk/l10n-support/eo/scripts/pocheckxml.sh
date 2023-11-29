#!/bin/bash
#            POLOGY XML CHECK:   http://pology.nedohodnik.net
# Parameter: Root directory at which to start analyzing.
#            If not given, all of `messages` will be analyzed.
#
# NB You will need to adapt the path to your clone of pology.
#
project=messages
if [ $# -gt 0 ]; then
  project=$1
fi
$HOME/tools/github-KDE-pology/scripts/posieve.py check-kde4 -s lokalize $project
