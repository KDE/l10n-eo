#!/bin/bash
#
# poprettyxml.sh
# Pretty print GNU gettext PO-file msgid or msgstr which contains XML
#
# Usage:
# Copy/paste the text following ", fuzzy" or following msgid ""
# to a separate file and provide this file as argument.
#
# Copyright (C) 2023 Oliver Kellogg <okellogg@users.sourceforge.net>
# Distributable under the MIT license https://opensource.org/license/mit/
#

pofrag=$1
tmpfile=pretty.tmp

sed 's/^#*|* *"//; s/"$//; s/\\"/"/g' $pofrag | tr -d '\n' > $tmpfile
echo >> $tmpfile
haveHtmlDecl=$(grep '<html>' $tmpfile)
if [ -z "$haveHtmlDecl" ]; then
  sed -e '1i <html><body>' -e '$a </body></html>' -i $tmpfile
fi
cat $tmpfile | xmllint --format -

rm -f $tmpfile

# Example input:
#| "<html><head/><body><p>Format is used to define the image file names by "
#| "the use of placeholder tags.</p><ul style=\"margin-top: 0px; margin-"
#| "bottom: 0px; margin-left: 0px; margin-right: 0px; -qt-list-indent: 1;"
#| "\"><li style=\" margin-top:12px; margin-bottom:0px; margin-left:0px; "
#| "margin-right:0px; -qt-block-indent:0; text-indent:0px;\">Placeholder<span "
#| "style=\" font-weight:704;\"> %f</span> or <span style=\" font-weight:704;"
#| "\">%filename</span>: The name of the .esq file, without extension.</"
#| "li><li style=\" margin-top:0px; margin-bottom:0px; margin-left:0px; "
#| "margin-right:0px; -qt-block-indent:0; text-indent:0px;\">Placeholder<span "
#| "style=\" font-weight:704;\"> %D</span> or <span style=\" font-weight:704;"
