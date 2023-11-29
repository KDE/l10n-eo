#!/usr/bin/perl
#
# pomerge.pl - merge two PO files containing same msgid's .
#
# Usage:
#              Expects the two pofiles as arguments on the command line.
#              The given pofiles are expected to be free of fuzz.
#              Gives preference to the first pofile if both files have
#              a non empty msgstr for a given msgid.
#              Writes the result to stdout.
#
# Options:     must precede the file name arguments.
#          -2  Carry forward the comments from the second file instead of
#              from the first file. (By default, the comments from the first
#              file are carried forward.)
#          -v  Show progress message on parsing.
#
# Copyright  (C) 2023, Oliver Kellogg <okellogg@users.sourceforge.net>
# This module is distributed under the same terms as Perl itself.
#

use utf8;
use FindBin;
use lib $FindBin::Bin;
require Text::PO::SimpleParser;

binmode (STDOUT, ":utf8");

my $Version = "20230315";
my $c2 = 0;
my $verbose = 0;

while (@ARGV && $ARGV[0] =~ /^-/) {
  if ($ARGV[0] eq "-v") {
    $verbose = 1;
    print "pomerge.pl version $Version\n\n";
  } elsif ($ARGV[0] eq "-2") {
    $c2 = 1;
  } else {
    print("Ignoring unknown option " . $ARGV[0] . "\n");
  }
  shift @ARGV;
}
scalar(@ARGV) == 2 or die "pomerge.pl : Expecting two pofile names\n";

my $file1 = $ARGV[0];
-e "$file1" or die "pomerge : no such file $file1\n";

my $file2 = $ARGV[1];
-e "$file2" or die "pomerge : no such file $file2\n";

$verbose and print "Parse($file1)\n";
my $parsed1 = Text::PO::SimpleParser::Parse($file1);  # filter=0
$parsed1 or die "pomerge : error on parsing file $file1\n";

$verbose and print "Parse($file2)\n";
my $parsed2 = Text::PO::SimpleParser::Parse($file2);  # filter=0
$parsed2 or die "pomerge : error on parsing file $file2\n";

my $hdr1 = shift @$parsed1;
my $hdr2 = shift @$parsed2;
my $hdr = ($c2 ? $hdr2 : $hdr1);
exists($hdr->{HEADER}) or die "pomerge : SimpleParser::Parse did not return header\n";
foreach my $c (@{$hdr->{comment}}) {
  print "#$c\n";
}

print "msgid \"\"\n";
print "msgstr \"\"\n";
foreach my $c (@{$hdr->{msgstr}}) {
  print "\"$c\"\n";
}
print "\n";

# $e2, $msgstr2, $loc2 are stateful for supporting file2 containing a
# sparse subset of file1 messages.  In the foreach-loop over @$parsed1,
# if $loc2 is set then @$parsed2 is not shifted until $loc2 matches
# $loc1.
my($e2, $msgstr2);
# $loc2 may be set when file2 contains a sparse subset of file1 messages.
# Sparse subset mode is not supported with switch "-2".
my $loc2 = "";

foreach my $e1 (@$parsed1) {
  my $msgctxt = $e1->{msgctxt};
  my $msgid = $e1->{msgid};
  my $msgid_plural = $e1->{msgid_plural};
  my $msgstr  = "";
  my $msgstr1 = "";
  my($fuzzyId, $fuzzyId1) = ("", "");
  if (@$parsed2 && !$loc2) {
    $e2 = shift @$parsed2;
  }
  my $commentRef = ($c2 && $e2 ? $e2->{comment} : $e1->{comment});
  my $loc1;
  foreach my $c (@$commentRef) {
    $c =~ s/, fuzzy//;
    $c or next;
    if ($c =~ /^\| msgid "(.+)"$/) {
      $fuzzyId = $1;
    } elsif ($c =~ /^\| msgid_plural "(.+)"$/) {
      $fuzzyId1 = $1;
    } elsif ($c !~ /^\|/) {
      print "#$c\n";
      if (!$loc1 && $commentRef == $e1->{comment} and $c =~ /^: ([^ ]+)/) {
        $loc1 = $1;
      }
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
    unless (exists($e1->{fuzzy})) {
      $msgstr = $e1->{$msKey};
    }
  } else {
    print "msgid \"$msgid\"\n";
    if ($msgid eq $fuzzyId || !exists($e1->{fuzzy})) {
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
      if ($msgid eq $fuzzyId || !exists($e1->{fuzzy})) {
        $msgstrP = $e1->{'msgstr[1]'};
      }
    }
  }
  my $match12;
  if ($e2) {
    if ($loc2) {
      if ($loc1 eq $loc2) {
        if ($verbose) {
          print "# DEBLOCK $loc1\n";
        }
        $match12 = 1;
        $loc2 = "";
      } elsif ($verbose) {
        print "# STILL_BLOCKED $loc1  $loc2\n";
      }
    } else {
      $msgstr2 = $e2->{$msKey};
      $commentRef = $e2->{comment};
      foreach my $c (@$commentRef) {
        if ($c =~ /^: (.+)$/) {
          my $l2 = $1;
          my @loci = split(' ', $l2);
          if (grep { $loc1 eq $_ } @loci) {
            $match12 = 1;
            last;
          }
          $loc2 = $c;
        }
      }
      if ($match12) {
        $loc2 = "";
      }
    }
  }
  if ($msgstr || $loc2 || !$msgstr2) {
    if (ref $msgstr) {
      print "$msKey \"\"\n";
      map { print "\"$_\"\n" } @$msgstr;
    } else {
      print "$msKey \"$msgstr\"\n";
    }
  } elsif (ref $msgstr2) {
    print "$msKey \"\"\n";
    map { print "\"$_\"\n" } @$msgstr2;
  } else {
    print "$msKey \"$msgstr2\"\n";
  }
  if ($msgid_plural) {
    $msKey = 'msgstr[1]';
    my $msgstr2P = ($e2 && !$loc2 ? $e2->{$msKey} : "");
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
  if ($match12) {
    $msgstr2 = "";
    $e2 = undef;
  }
  print "\n";
}

my $unprocessed = scalar(@$parsed2);
$unprocessed and die("Error at end: still $unprocessed unprocessed items from $file2\n");

