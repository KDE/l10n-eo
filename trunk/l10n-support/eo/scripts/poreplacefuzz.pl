#!/usr/bin/perl
#
# poreplacefuzz.pl
#          Replace fuzzy entries of a PO file by clean translated
#          entries from a second PO file.
#
# Usage:
#          Expects two pofiles as arguments on the command line.
#          The first pofile is expected to contain (many) fuzzies.
#          The second pofile is expected to contain exactly the clean
#          translations for the fuzzy entries of the first file, but
#          no more. I.e. the second file will be a subset of the
#          first file (will contain neither the clean untranslated
#          nor the clean translated entries of the first file).
#          The program will merge the second file's entries into
#          the corresponding fuzzy entries of the first file and
#          will remove the fuzzy comment blocks.
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
    print "poreplacefuzz.pl version $Version\n\n";
  } else {
    print("Ignoring unknown option " . $ARGV[0] . "\n");
  }
  shift @ARGV;
}
scalar(@ARGV) == 2 or die "poreplacefuzz.pl : Expecting two pofile names\n";

my $file1 = $ARGV[0];
-e "$file1" or die "poreplacefuzz : no such file $file1\n";

my $file2 = $ARGV[1];
-e "$file2" or die "poreplacefuzz : no such file $file2\n";

$verbose and print "Parse($file1)\n";
my $parsed1 = Text::PO::SimpleParser::Parse($file1);  # filter=0
$parsed1 or die "poreplacefuzz : error on parsing file $file1\n";

$verbose and print "Parse($file2)\n";
my $parsed2 = Text::PO::SimpleParser::Parse($file2);  # filter=0
$parsed2 or die "poreplacefuzz : error on parsing file $file2\n";

my $hdr = shift @$parsed1;
exists($hdr->{HEADER}) or die "poreplacefuzz : SimpleParser::Parse did not return header\n";
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
  foreach my $c (@$commentRef) {
    $c =~ s/, fuzzy//;
    $c or next;
    if ($c !~ /^\|/) {
      print "#$c\n";
    }
  }
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
    if (exists $e1->{fuzzy}) {
      @$parsed2 or die "$file1 $msgid (fuzzy) : no more entries in $file2\n";
      $e2 = shift @$parsed2;
      $msgstr = ($e2->{$msKey} ne "" ? $e2->{$msKey} : $e1->{$msKey});
    } else {
      $msgstr = $e1->{$msKey};
    }
  } else {
    print "msgid \"$msgid\"\n";
    if (exists($e1->{fuzzy})) {
      @$parsed2 or die "$file1 $msgid (fuzzy) : no more entries in $file2\n";
      $e2 = shift @$parsed2;
      $msgstr = ($e2->{$msKey} ne "" ? $e2->{$msKey} : $e1->{$msKey});
    } else {
      $msgstr = $e1->{$msKey};
    }
  }
  if ($msgid_plural) {
    if (ref $msgid_plural) {
      print "msgid_plural \"\"\n";
      map { print "\"$_\"\n" } @$msgid_plural;
      unless (exists($e1->{fuzzy})) {
        $msgstrP = $e1->{'msgstr[1]'};
      }
    } else {
      print "msgid_plural \"$msgid_plural\"\n";
      unless (exists($e1->{fuzzy})) {
        $msgstrP = $e1->{'msgstr[1]'};
      }
    }
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

