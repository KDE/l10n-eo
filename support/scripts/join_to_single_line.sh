#!/bin/bash
#
# join_to_single_line.sh
# Expects as input a po msgid or msgstr stripped of initial and final
# quotation marks. Joins the multiple lines into a single line.
# May be useful when analyzing embedded XML where we want to join
# XML tags that have been split across lines such as:
#                  <a href
#                  =\"blab\"
#                  >Blab</
#                  a>

# sed '1,$a ¦' $1 | tr -d '\n' | sed 's/¦/\n/g'
cat $1 | tr -d '\n'

