#!/bin/bash
#
# pocheckhotkeys.sh
#
# Purpose: Check that keyboard shortcuts are symmetrical between msgid
#          and msgstr of translated PO files.
#
# Usage:   Change directory to the "messages" subdir of your checkout of
#            svn+ssh://svn@svn.kde.org/home/kde/trunk/l10n-kf6/??
#          or other path (replace ?? by your language) and run this script.
#          It will iterate over */*.po and print each filename, possibly
#          followed by the offending msgid/msgstr occurrences.
#          Output goes to stdout.
#
# Copyright (C) 2024, Oliver Kellogg <olivermkellogg@gmail.com>
# This script is distributed under the MIT license,
#          https://opensource.org/license/mit
#

for i in $(grep -l '&' */*.po)
do
  echo -e "== $i ==\n"
  perl -n -e 'chomp;
              if (/^msgid "(.+?)"$/) {
                my $msgid = $1;
                my $msgstr = <>;
                chomp $msgstr;
                if ($msgid =~ /&\w/ or $msgid =~ /\w&/) {
                  unless ($msgstr =~ /&/) {
                    print "msgid \"$msgid\"\n$msgstr\n\n";
                  }
                } elsif ($msgstr =~ /&\w/ or $msgstr =~ /\w&/) {
                  print "msgid \"$msgid\"\n$msgstr\n\n";
                }
              }
              ' $i
  echo
done

