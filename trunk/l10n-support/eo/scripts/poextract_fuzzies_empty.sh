#!/bin/bash
#
# poextract_fuzzies_empty.sh
#   `msgattrib` invocation for extracting only the fuzzy messages from
#   a po file but removing the fuzzy attribute and also setting the
#   translated msgstrings to empty.
#

msgattrib --fuzzy --empty --clear-previous --no-obsolete $1

