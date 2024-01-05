#!/usr/bin/perl
#
# mkpoxldb.pl
# Make PO translation database from kde/trunk/l10n-kf[56]/eo/messages/*/*.po
#
# Copyright (C) 2023, Oliver Kellogg <okellogg@users.sourceforge.net>
# This progam is distributed under the same terms as perl itself, see
#                          https://dev.perl.org/licenses/artistic.html
#
use utf8;

if (@ARGV) {
  $outputfile = $ARGV[0];
} else {
  $outputfile = "po_db.txt";
}

$KDESVN_TRUNK = $ENV{KDESVN_TRUNK_CHECKOUT};
unless ($KDESVN_TRUNK) {
  $KDESVN_TRUNK = $ENV{HOME} . "/info/kde/trunk";
}

my $sep = '¦';   # msgid/msgstr separator char in output file (broken bar, octal 246)

# Key: $msgid$sep$msgstr
# Value: Number of times encountered
my %db = ();

# Flags telling whether user was prompted for input in case of diverging msgstr values.
# Initialized with a few values for which we know we don't want interactive input.
my %user_was_asked = (
     'Your names' => 1, 'Your emails' => 1,
     'General' => 1, 'URL' => 1
   );

binmode (STDOUT, ":utf8");

foreach my $po (glob "${KDESVN_TRUNK}/l10n-kf[56]/eo/messages/*/*.po") {
  open(PO, "<:utf8", $po) or die "Error: cannot open file $po\n";
  while (<PO>) {
    if (/^msgid "(..*?)"$/) {
      my $id = $1;
      my $msgstr = <PO>;
      if ($msgstr =~ /^msgstr "(..*?)"$/) {
        my $str = $1;
        my $key = "$id$sep$str";
        if (exists($db{$key})) {
          $db{$key} += 1;
        } else {
          $db{$key} = 1;
        }
      }
    }
  }
  close(PO);
}

open(DB, ">:utf8", $outputfile) or die "Error: cannot create $outputfile\n";

print "Creating file $outputfile\n";

foreach my $k (sort keys %db) {
  next if ($k =~ /^Your (names|emails)$sep/);
  my $value = $db{$k};
  next if ($value < 3);
  print DB ("$k\n");
}

close (DB);

