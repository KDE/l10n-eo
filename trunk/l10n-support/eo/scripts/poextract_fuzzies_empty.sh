#!/bin/bash
#
# poextract_fuzzies_empty.sh
#   Quick hack for extracting only the fuzzy messages
#   from a po file but removing the fuzzy attribute
#   and also setting the translated msgstrings to empty.
#   Multi line msgstr are not handled, they need to be removed
#   manually from the output.
#

msgattrib --only-fuzzy --clear-fuzzy $1 | sed '/^#|/d; s/^msgstr "[^"].*$/msgstr ""/'

