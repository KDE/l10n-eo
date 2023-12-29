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
cat $tmpfile | xmllint --html --format -

if [ $? -eq 0 ]; then
  rm $tmpfile
fi

# Example input:
#| "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\" \"http://www.w3.org/TR/"
#| "REC-html40/strict.dtd\"><html><head><style type=\"text/css\">p, li "
#| "{ white-space: pre-wrap; }</style></head><body>Variables will be replaced "
#| "by a special value and can even contain parameters.<br />For example the "
#| "variable <div style=\"font-family:monospace; background: #b3c1d6; color: "
#| "black\"><pre>$artist</pre></div>or the equivalent<div style=\"font-family:"
#| "monospace; background: #b3c1d6; color: black\"><pre>${artist}</pre></"
#| "div>will be replaced by the relevant artist of the cd. Variables may also "
#| "have attribute, for example:<div style=\"font-family:monospace; "
#| "background: #b3c1d6; color: black\"><pre>${today format=\"yyyy-MM-dd\"}</"
#| "pre></div>This would print the current date. <br /><table border=1><thead>"
#| "<tr><th>Variable</th><th>Parameter</th><th>Description</th><th>Example</th>"
#| "</tr></thead><tbody><tr><td>$artist</td><td></td><td>Prints the relevant "
#| "artist of the extracted cd.</td><td>${artist }</td></tr><tr><td>$title</td>"
#| "<td></td><td>Prints the relevant title of the extracted cd.</td><td></td></"
#| "tr></tbody></table></body></html>"
