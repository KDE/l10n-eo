#!/usr/bin/perl
#
# defuzzify_same.pl
# Purpose: Remove fuzzy attribute and fuzzy content of comment in po
#          file when msgid has in fact not changed, i.e. remove fuzzy
#          comment on such entries.
#          The program accounts for differences in formatting between
#          the fuzzy comment and the msgid (lines may be wrapped
#          differently but such differences need to be ignored).
#
# Copyright (C) 2024, Oliver Kellogg <okellogg@users.sourceforge.net>
# This program is distributed under the same terms as perl itself.
#

use utf8;
use FindBin;
use lib $FindBin::Bin;
require Text::PO::SimpleParser;

binmode (STDOUT, ":utf8");

sub arraysEqual;

my @inputfiles;
my $dir = ".";
my $verbose = 0;
if (@ARGV && $ARGV[0] eq "-v") {
  $verbose = 1;
  shift @ARGV;
}
@ARGV or die "defuzzify_same : require filename\n";
my $file = $ARGV[0];
-e "$file" or die "defuzzify_same : no such file $file\n";

my %xlatns;  # keyed by msgid

$verbose and print "Parse($_)\n";
my $parsed = Text::PO::SimpleParser::Parse($file);  # filter=0
$parsed or die "defuzzify_same : error on parsing file $file\n";

my $hdr = shift @$parsed;
exists($hdr->{HEADER}) or die "defuzzify_same : SimpleParser::Parse did not return header\n";
foreach my $c (@{$hdr->{comment}}) {
  print "#$c\n";
}
print "msgid \"\"\n";
print "msgstr \"\"\n";
foreach my $c (@{$hdr->{msgstr}}) {
  print "\"$c\"\n";
}
print "\n";

for (my $loop = 0; $loop < scalar(@$parsed); ++$loop) {
  my $e = $parsed->[$loop];
  my $msgctxt = $e->{msgctxt};
  my $msgid = $e->{msgid};
  my $msgid_plural = $e->{msgid_plural};
  my @cleanComment;
  my @fuzzyId;
  my $isSame = 0;
  if (exists $e->{'fuzzy'}) {
    foreach (@{$e->{comment}}) {
      my $c = $_;
      $c =~ s/, fuzzy//;
      $c or next;
      #, fuzzy, kde-format
      #| msgctxt "The msgctxt may appear optionally in the fuzzy comment"
      #| msgid ""
      #| "Long line or first line of multi line msgid."
      if ($c =~ /^\| msgid "(.*)?"$/) {
        $1 and push @fuzzyId, $1;
      } elsif ($c =~ /^\| msgid_plural "(.*)?"$/) {
        $1 and push @fuzzyId, $1;
      } elsif ($c =~ /^\| "(.+)?"$/) {
        push @fuzzyId, $1;
      } elsif ($c !~ /^\|/) {
        push @cleanComment, $c;
      }
    }
    if (ref $msgid) {
      if ($msgid_plural) {
        $isSame = arraysEqual($msgid_plural, \@fuzzyId);
      } else {
        $isSame = arraysEqual($msgid, \@fuzzyId);
      }
    } else {
      if ($msgid_plural) {
        $isSame = $msgid_plural eq $fuzzyId[0];
      } else {
        $isSame = $msgid eq $fuzzyId[0];
      }
    }
  }
  my @comment;
  if ($isSame) {
    @comment = @cleanComment;
  } else {
    @comment = @{$e->{comment}};
  }
  map { print "#$_\n" } @comment;
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
  } else {
    print "msgid \"$msgid\"\n";
  }
  my $msgstr = $e->{$msKey};
  my $msgstr1 = $e->{'msgstr[1]'};
  if ($msgid_plural) {
    if (ref $msgid_plural) {
      print "msgid_plural \"\"\n";
      map { print "\"$_\"\n" } @$msgid_plural;
    } else {
      print "msgid_plural \"$msgid_plural\"\n";
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
    if (ref $msgstr1) {
      print "$msKey \"\"\n";
      map { print "\"$_\"\n" } @$msgstr1;
    } else {
      print "$msKey \"$msgstr1\"\n";
    }
  }
  if ($loop < scalar(@$parsed) - 1) {
    print "\n";
  }
}

# Clean implementation for array string equality test.
# We don't use this because PO file generation may break long strings
# differently between fuzzy comment and actual msgid which gives
# inequality although the strings may in fact be equivalent.
sub arraysEqual {
  my($arrayRef0, $arrayRef1) = @_;
  scalar(@$arrayRef0) == scalar(@$arrayRef1) or return 0;
  for (my $i = 0; $i < scalar(@$arrayRef0); ++$i) {
    $arrayRef0->[$i] eq $arrayRef1->[$i] or return 0;
  }
  return 1;
}

# Version of arraysEqual used here discards possible line-break differences,
# i.e. the array elements are joined into one string before comparing.
sub arraysEqual {
  my($arrayRef0, $arrayRef1) = @_;
  my $text0 = join("", @$arrayRef0);
  my $text1 = join("", @$arrayRef1);
  return $text0 eq $text1;
}

