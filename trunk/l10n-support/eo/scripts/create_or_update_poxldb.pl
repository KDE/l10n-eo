#!/usr/bin/perl
#
# create_or_update_poxldb.pl
# Make PO translation database from kde/trunk/l10n-kf[56]/eo/messages/*/*.po
#
# Copyright (C) 2023, Oliver Kellogg <okellogg@users.sourceforge.net>
# This progam is distributed under the same terms as perl itself, see
#                          https://dev.perl.org/licenses/artistic.html
#
use utf8;

$KDESVN_TRUNK = $ENV{KDESVN_TRUNK_CHECKOUT};
unless ($KDESVN_TRUNK) {
  $KDESVN_TRUNK = $ENV{HOME} . "/info/kde/trunk";
}

my $dbfile = "${KDESVN_TRUNK}/po_db.txt";

my @po_inputfiles;

while (@ARGV) {
  my $arg = shift @ARGV;
  if ($arg eq "-dbfile") {
    $dbfile = shift @ARGV;
  } else {
    push @po_inputfiles, $arg;
  }
}

unless (@po_inputfiles) {
  @po_inputfiles = glob "${KDESVN_TRUNK}/l10n-kf[56]/eo/messages/*/*.po";
}

my $sep = '¦';   # msgid/msgstr separator char in output file (broken bar, octal 246)

# Key: $msgid$sep$msgstr
# Value: Number of times encountered
my %db = ();

binmode (STDOUT, ":utf8");

if (-e "$dbfile") {
  open(DB, "<:utf8", $dbfile) or die "Error: cannot open $dbfile for reading\n";
  print "Reading file $dbfile\n";
  while (<DB>) {
    chomp;
    my $line = $_;
    if ($line =~ /$sep/) {
      my ($id, $str) = split($sep, $_);
      $db{$id} = $str;
    } else {
      print "ignoring line in $dbfile: $line\n";
    }
  }
  close(DB);
}

foreach my $po (@po_inputfiles) {
  open(PO, "<:utf8", $po) or die "Error: cannot open file $po\n";
  while (<PO>) {
    chomp;
    if (/^msgid "(..*?)"$/) {
      my $id = $1;
      my $msgstr = <PO>;
      chomp $msgstr;
      if ($msgstr =~ /^msgstr(.0.)? "(..*?)"$/) {
        my $str = $2;
        unless (exists($db{$id})) {
          $db{$id} = $str;
        }
      }
    }
  }
  close(PO);
}

open(DB, ">:utf8", $dbfile) or die "Error: cannot open $dbfile for writing\n";

print "Writing file $dbfile\n";

foreach my $k (sort keys %db) {
  next if ($k =~ /^Your (names|emails)$/);
  my $value = $db{$k};
  print DB ("$k$sep$value\n");
}

close (DB);

