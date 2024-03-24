#!/usr/bin/perl
#
# poadopt.pl
#          Replace entries of a PO file by translated entries from a
#          second PO file in case of matching msgid.
#
# Usage:
#          Expects two pofiles as arguments on the command line.
#          The first pofile is expected to contain (many) empty or
#          fuzzy msgstr.
#          The second pofile is expected to contain more of clean
#          translations than the first file and is also expected to
#          have msgid's that mostly correspond with the first file.
#          When a msgid from the second file is also found in the
#          first file then the corresponding msgstr from the second is
#          copied to the first.
#          Resulting output is written to stdout.
#
# Options: must precede the file name arguments.
#     -ph  Preserve header of the first file.
#      -v  Show progress message on parsing.
#
# Copyright  (C) 2023, Oliver Kellogg <okellogg@users.sourceforge.net>
# This module is distributed under the same terms as Perl itself.
#

use utf8;
use FindBin;
use lib $FindBin::Bin;
require Text::PO::SimpleParser;

sub printLine;
sub printLines;

binmode (STDOUT, ":utf8");

my $Version = "20240112";
my $verbose = 0;
my $preserve_header = 0;

while (@ARGV && $ARGV[0] =~ /^-/) {
  my $arg = $ARGV[0];
  if ($arg eq "-v") {
    $verbose = 1;
    warn "poadopt.pl version $Version\n\n";
  } elsif ($arg eq "-ph") {
    $preserve_header = 1;
  } else {
    warn("Ignoring unknown option $arg\n");
  }
  shift @ARGV;
}
scalar(@ARGV) == 2 or die "poadopt.pl : Expecting two pofile names\n";

my $file1 = $ARGV[0];
-e "$file1" or die "poadopt : no such file $file1\n";

my $file2 = $ARGV[1];
-e "$file2" or die "poadopt : no such file $file2\n";

$verbose and warn "Parse($file1)\n";

my $mjChar = '¦';   # multiline join char: broken bar (octal 246)
$Text::PO::SimpleParser::multiline_join_char = $mjChar;

my $parsed1 = Text::PO::SimpleParser::Parse($file1);  # filter=0
$parsed1 or die "poadopt : error on parsing file $file1\n";

$verbose and warn "Parse($file2)\n";
my $parsed2 = Text::PO::SimpleParser::Parse($file2);  # filter=0
$parsed2 or die "poadopt : error on parsing file $file2\n";

my $hdr1 = shift @$parsed1;
exists($hdr1->{HEADER}) or die "poadopt($file1) : SimpleParser::Parse did not return header\n";

my $hdr2 = shift @$parsed2;
exists($hdr2->{HEADER}) or die "poadopt($file2) : SimpleParser::Parse did not return header\n";

my $header = ($preserve_header ? $hdr1 : $hdr2);
foreach my $c (@{$header->{comment}}) {
  print "#$c\n";
}

print "msgid \"\"\n";
print "msgstr \"\"\n";

unless ($preserve_header) {
  # POT-Creation-Date: 2021-11-21 01:50+0000\n
  my $potCreationDate1 = $hdr1->{msgstr};
     $potCreationDate1 =~ s/^.*?POT-Creation-Date: //;
     $potCreationDate1 =~ s/\\n.*$//;
  my $potCreationDate2 = $hdr2->{msgstr};
     $potCreationDate2 =~ s/^.*?POT-Creation-Date: //;
     $potCreationDate2 =~ s/\\n.*$//;
  #  $potCreationDate2 is used as regex thus we must deal with the '+' of the timezone
     $potCreationDate2 =~ s/\+/./;  # . = any character
  $hdr2->{msgstr} =~ s/$potCreationDate2/$potCreationDate1/;
}
printLines($header->{msgstr});
print "\n";

my %ID;   # indexed by msgid of @$parsed2
          # returns ref to the entry in @$parsed2

foreach my $e2 (@$parsed2) {
  my $msgid = $e2->{msgid};
  if (exists $ID{$msgid}) {
    my $e = $ID{$msgid};
    if ($e->{'msgstr'} ne "" && $e->{'msgstr'} ne $e2->{'msgstr'}) {
      warn("$file2 : $msgid existing : " . $e->{'msgstr'} . " ; new : " .
           $e2->{'msgstr'} . " ; adopting new value\n"); 
    }
  }
  $ID{$msgid} = $e2;
  my $msgid_plural = $e2->{msgid_plural};
  if (exists $ID{$msgid_plural}) {
    my $e = $ID{$msgid_plural};
    if ($e->{'msgstr[1]'} ne "" && $e->{'msgstr[1]'} ne $e2->{'msgstr[1]'}) {
      warn("$file2 : $msgid_plural existing : " . $e->{'msgstr[1]'} . " ; new : " .
           $e2->{'msgstr[1]'} . " ; adopting new value\n"); 
    }
  }
  $ID{$msgid_plural} = $e2;
}

for (my $i = 0; $i < scalar(@$parsed1); ++$i) {
  my $e1 = $parsed1->[$i];
  my $msgctxt = $e1->{msgctxt};
  my $msgid = $e1->{msgid};
  defined($msgid) or last;
  $msgid eq "" and last;
  my $msgid_plural = $e1->{msgid_plural};
  my $commentRef = $e1->{comment};
  my $isFuzzy = 0;
  foreach my $c (@$commentRef) {
    if ($c =~ /, fuzzy/) {
      $c =~ s/, fuzzy//;
      $isFuzzy = 1;
      $c or next;
    }
    if ($c !~ /^\|/) {
      print "#$c\n";
    }
  }
  if (ref $msgctxt) {
    print "msgctxt \"\"\n";
    map { print "\"$_\"\n" } @$msgctxt;
  } elsif ($msgctxt =~ /$mjChar/) {
    print "msgctxt \"\"\n";
    printLines($msgctxt);
  } elsif ($msgctxt) {
    print "msgctxt \"$msgctxt\"\n";
  }

  my $msKey = ($msgid_plural ? "msgstr[0]" : "msgstr");
  if ($msgid =~ /$mjChar/) {
    print "msgid \"\"\n";
    printLines($msgid);
  } else {
    printLine("msgid \"$msgid\"");
  }
  if ($isFuzzy) {
    $e1->{$msKey} = "";
  }

  if ($msgid_plural ne "") {
    if ($msgid_plural =~ /$mjChar/) {
      print "msgid_plural \"\"\n";
      printLines($msgid_plural);
    } else {
      printLine("msgid_plural \"$msgid_plural\"");
    }
  }

  my $msgstr = $e1->{$msKey};
  if (exists $ID{$msgid}) {
    my $e2 = $ID{$msgid};
    my $msgstr2 = $e2->{$msKey};
    if ($msgstr2 ne "") {
      if ($msgstr ne "" && $msgstr ne $msgstr2) {
        warn("$file1 : replacing $msgstr BY $msgstr2\n");
      }
      $msgstr = $msgstr2;
    }
  }
  if ($msgstr =~ /$mjChar/) {
    print "$msKey \"\"\n";
    printLines($msgstr);
  } else {
    printLine("$msKey \"$msgstr\"");
  }

  if ($msgid_plural ne "") {
    my $msgstrP = $e1->{'msgstr[1]'};
    if (exists $ID{$msgid_plural}) {
      my $e2 = $ID{$msgid_plural};
      my $msgstr2P = $e2->{'msgstr[1]'};
      if ($msgstr2P ne "") {
        if ($msgstrP ne "" && $msgstrP ne $msgstr2P) {
          warn("$file1 : replacing \[1\] $msgstrP BY $msgstr2P\n");
        }
        $msgstrP = $msgstr2P;
      }
    }
    if ($msgstrP =~ /$mjChar/) {
      print "msgstr\[1\] \"\"\n";
      printLines($msgstrP);
    } else {
      printLine("msgstr\[1\] \"$msgstrP\"");
    }
  }

  if ($i < scalar(@$parsed1) - 1) {
    print "\n";
  }
}

sub printLine {
  my $line = shift;
  if (length($line) > 80) {
    my $keyword = $line;
    $keyword =~ s/ .*$//;
    my $content = $line;
    $content =~ s/^[^ ]+ //;
    print "$keyword \"\"\n";
    print "$content\n";
  } else {
    print "$line\n";
  }
}

sub printLines {
  my $multiJoin = shift;
  my @lines = split(/$mjChar/, $multiJoin);
  foreach (@lines) {
    print "\"$_\"\n";
  }
}

