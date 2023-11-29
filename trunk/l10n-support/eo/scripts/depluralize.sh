#!/bin/bash
#
# depluralize.sh
# Purpose: Print msgid / msgid_plural of po file as two separate msgid's
# This is needed by translate-po (https://github.com/zcribe/translate-po)
# because it cannot handle msgid_plural.
#

sed 's/^msgstr\[0\]/msgstr/; /msgstr\[1\]/d; s/^msgid_plural/msgstr ""\n\n#, plural\nmsgid/' $1

#   #: Apper/Updater/UpdateDetails.cpp:229
#   #, kde-format
#   msgid "For more information about this update please visit this website:"
#   msgid_plural ""
#   "For more information about this update please visit these websites:"
#   msgstr[0] ""
#   msgstr[1] ""

