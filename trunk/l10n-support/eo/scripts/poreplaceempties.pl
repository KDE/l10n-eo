#!/usr/bin/perl
#
# poreplaceempties.pl
#          Replace empty entries of a PO file by translated
#          entries from a second PO file.
#
# Usage:
#          Expects two pofiles as arguments on the command line.
#          The first pofile is expected to contain (many) empty msgstr.
#          The second pofile is expected to contain exactly the clean
#          translations for the empty entries of the first file but
#          no more. I.e. the second file will be a subset of the
#          first file (will not contain the translated entries of the
#          first file).
#          The program will merge the second file's entries into
#          the corresponding empty entries of the first file.
#          Resulting output is written to stdout.
#
# Options: must precede the file name arguments.
#      -v  Show progress message on parsing.
#
# Copyright  (C) 2023, Oliver Kellogg <okellogg@users.sourceforge.net>
# This module is distributed under the same terms as Perl itself.
#

use utf8;
use FindBin;
use lib $FindBin::Bin;
require Text::PO::SimpleParser;

binmode (STDOUT, ":utf8");

my $Version = "20231108";
my $verbose = 0;

while (@ARGV && $ARGV[0] =~ /^-/) {
  if ($ARGV[0] eq "-v") {
    $verbose = 1;
    print "poreplaceempties.pl version $Version\n\n";
  } else {
    print("Ignoring unknown option " . $ARGV[0] . "\n");
  }
  shift @ARGV;
}
scalar(@ARGV) == 2 or die "poreplaceempties.pl : Expecting two pofile names\n";

my $file1 = $ARGV[0];
-e "$file1" or die "poreplaceempties : no such file $file1\n";

my $file2 = $ARGV[1];
-e "$file2" or die "poreplaceempties : no such file $file2\n";

$verbose and print "Parse($file1)\n";
my $parsed1 = Text::PO::SimpleParser::Parse($file1);  # filter=0
$parsed1 or die "poreplaceempties : error on parsing file $file1\n";

$verbose and print "Parse($file2)\n";
my $parsed2 = Text::PO::SimpleParser::Parse($file2);  # filter=0
$parsed2 or die "poreplaceempties : error on parsing file $file2\n";

my $hdr = shift @$parsed1;
exists($hdr->{HEADER}) or die "poreplaceempties : SimpleParser::Parse did not return header\n";
foreach my $c (@{$hdr->{comment}}) {
  print "#$c\n";
}

shift @$parsed2;  # header from file2 is unused

print "msgid \"\"\n";
print "msgstr \"\"\n";
foreach my $c (@{$hdr->{msgstr}}) {
  print "\"$c\"\n";
}
print "\n";

foreach my $e1 (@$parsed1) {
  my $msgctxt = $e1->{msgctxt};
  my $msgid = $e1->{msgid};
  my $msgid_plural = $e1->{msgid_plural};
  my $msgstr  = "";
  my $msgstr1 = "";
  my $e2;
  my $commentRef = $e1->{comment};
  map { print "#$_\n" } @$commentRef;
  if (ref $msgctxt) {
    print "msgctxt \"\"\n";
    map { print "\"$_\"\n" } @$msgctxt;
  } elsif ($msgctxt) {
    print "msgctxt \"$msgctxt\"\n";
  }
  my $msKey = ($msgid_plural ? "msgstr[0]" : "msgstr");
  if (ref $msgid) {
    print "msgid \"\"\n";
    map { print "\"$_\"\n" } @$msgid;
    if ($e1->{$msKey} ne "") {
      $msgstr = $e1->{$msKey};
    } else {
      @$parsed2 or die "$file1 $msgid[0] : no more entries in $file2\n";
      $e2 = shift @$parsed2;
      if ($e2->{$msKey} ne "") {
        $msgstr = $e2->{$msKey};
      } else {
        warn "$file1 $msgid[0] : entry in $file2 is empty\n";
        $msgstr = $e1->{$msKey};
      }
    }
  } else {
    print "msgid \"$msgid\"\n";
    if ($e1->{$msKey} ne "") {
      $msgstr = $e1->{$msKey};
    } else {
      @$parsed2 or die "$file1 $msgid : no more entries in $file2\n";
      $e2 = shift @$parsed2;
      if ($e2->{$msKey} ne "") {
        $msgstr = $e2->{$msKey};
      } else {
        warn "$file1 $msgid : entry in $file2 is empty\n";
        $msgstr = $e1->{$msKey};
      }
    }
  }
  if ($msgid_plural) {
    if (ref $msgid_plural) {
      print "msgid_plural \"\"\n";
      map { print "\"$_\"\n" } @$msgid_plural;
    } else {
      print "msgid_plural \"$msgid_plural\"\n";
    }
    $msgstrP = $e1->{'msgstr[1]'};
  }
  if (ref $msgstr) {
    print "$msKey \"\"\n";
    map { print "\"$_\"\n" } @$msgstr;
  } else {
    print "$msKey \"$msgstr\"\n";
  }
  if ($msgid_plural) {
    $msKey = 'msgstr[1]';
    my $msgstr2P = ($e2 ? $e2->{$msKey} : "");
    if ($msgstrP || !$msgstr2P) {
      if (ref $msgstrP) {
        print "$msKey \"\"\n";
        map { print "\"$_\"\n" } @$msgstrP;
      } else {
        print "$msKey \"$msgstrP\"\n";
      }
    } elsif (ref $msgstr2P) {
      print "$msKey \"\"\n";
      map { print "\"$_\"\n" } @$msgstr2P;
    } else {
      print "$msKey \"$msgstr2P\"\n";
    }
  }
  print "\n";
}

