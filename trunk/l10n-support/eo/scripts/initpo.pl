#!/usr/bin/perl
#
# initpo.pl  [ -db <dbfile> ] <potfile>
# Initialize PO translated file from POT file using
# PO translation database created by mkpoxldb.pl
#              (created from kde/trunk/l10n-kf[56]/eo/messages/*/*.po)
# Options:
# -db <dbfile>
#     Use <dbfile> as the translation database file.
#     If this is not given then the program will interrogate the
#     environment variable PO_TRANSLATION_DATABASE for the dbfile.
#     If the env var is not set then the program will look for a file
#     $SCRIPT_DIR/po_db.txt where $SCRIPT_DIR is the directory in which
#     this script resides.
#     If none of these files exist then the program exits with an error.
# -ph 
#     Preserve header. By default, the header comments will be regenerated.
#
# Copyright (C) 2023-2024, Oliver Kellogg <okellogg@users.sourceforge.net>
# This progam is distributed under the same terms as perl itself, see
#                          https://dev.perl.org/licenses/artistic.html
#
use utf8;

@ARGV or die "provide POT file as argument\n";

my $dbfile;
my $preserve_header = 0;
my $potfile;

while (@ARGV) {
  my $arg = shift @ARGV;
  if ($arg eq "-db") {
    $dbfile = shift @ARGV;
  } elsif ($arg eq "-ph") {
    $preserve_header = 1;
  } elsif ($arg =~ /^-/) {
    die "unknown option: $_\n";
  } else {
    $potfile = $arg;
  }
}

unless ($dbfile) {
  $dbfile = $ENV{"PO_TRANSLATION_DATABASE"};
  unless ($dbfile) {
    $dbfile = "po_db.txt";
    unless (-e "$dbfile") {
      $script_dir = $0;
      $script_dir =~ s@/[^/]+$@@;
      $dbfile = $script_dir . "/" . $dbfile;
    }
  }
}

-e "$dbfile" or die "Translation database not found: $dbfile\n";

-e "$potfile" or die "File not found: $potfile\n";

my $sep = '¦';   # msgid/msgstr separator char in database file (broken bar)

open(DB, "<:utf8", $dbfile) or die "Error: cannot open $dbfile\n";

# Key: msgid; value: msgstr
my %db = ();

while (<DB>) {
  my $l = $_;
  chomp $l;
  my($msgid, $msgstr) = split($sep, $l);
  $db{$msgid} = $msgstr;
}

close(DB);

binmode (STDOUT, ":utf8");

my $filename = $potfile;
$filename =~ s@^.*/@@;

my $project = $potfile;
$project =~ s@/[^/]+$@@;
$project =~ s@^.*/@@;

my $msgstr = "";

open(POT, "<:utf8", $potfile) or die "Error: cannot open file $potfile\n";

# The POT header comes in two variants, a short header and a long header.
#
# The short form is sometimes found in _desktop_ or _json_ potfiles:
#   msgid ""
#   msgstr ""
#   "MIME-Version: 1.0\n"
#   "Content-Type: text/plain; charset=UTF-8\n"
#   "Content-Transfer-Encoding: 8bit\n"
#   "X-Qt-Contexts: true\n"
#
# The long form is the common, more frequently found form:
#   # SOME DESCRIPTIVE TITLE.
#   # Copyright (C) YEAR This file is copyright:
#   # This file is distributed under the same license as the glaxnimate package.
#   # FIRST AUTHOR <EMAIL@ADDRESS>, YEAR.
#   #
#   #, fuzzy
#   msgid ""
#   msgstr ""
#   "Project-Id-Version: PACKAGE VERSION\n"
#   "Report-Msgid-Bugs-To: https://bugs.kde.org\n"
#   "POT-Creation-Date: 2023-12-18 00:40+0000\n"
#   "PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE\n"
#   "Last-Translator: FULL NAME <EMAIL@ADDRESS>\n"
#   "Language-Team: LANGUAGE <kde-i18n-doc@kde.org>\n"
#   "Language: \n"
#   "MIME-Version: 1.0\n"
#   "Content-Type: text/plain; charset=UTF-8\n"
#   "Content-Transfer-Encoding: 8bit\n"
#
# We discard the pot header and create an own one in a separate first loop.
# This first loop ends as soon as the POT header is read, i.e. after the loop
# the input file pointer points to the start of the non header part of the
# POT file.
#

my $project_id_version = $project;
my $pot_creation_date = "";
my @extensions;

while (<POT>) {
  my $l = $_;
  chomp $l;
  $l or last;
  if ($preserve_header) {
    print "$l\n";
  } elsif ($l =~ /"Project-Id-Version: (.+?)\\n"/) {
    unless ($1 eq "PACKAGE VERSION") {
      $project_id_version = $1;
    }
  } elsif ($l =~ /"POT-Creation-Date: (.+?)\\n"/) {
    $pot_creation_date = $1;
  } elsif ($l =~ /("X-.+?\\n")/) {
    push @extensions, $1;
  }
}

if ($preserve_header) { 
  print "\n";
} else {
  unless ($pot_creation_date) {
    if (open(SVNLOG, "svn log -r1:HEAD --limit 1 $potfile |")) {
      while (<SVNLOG>) {
        if (/ (20\d\d-\d\d-\d\d \d\d:\d\d):\d\d (.\d\d\d\d)/) {
          $pot_creation_date = $1 . $2;
        }
      }
      close (SVNLOG);
    } else {
      warn "Cannot run svn log for extracting creation date of $potfile\n";
    }
  }
  # Print the target header
  print "# translation of $filename to Esperanto\n";
  print "# Copyright (C) 2024 Free Software Foundation, Inc.\n";
  print "# This file is distributed under the same license as the $project package.\n";
  print "# Oliver Kellogg <okellogg\@users.sourceforge.net>, 2024.\n";
  print "#\n";
  print "msgid \"\"\n";
  print "msgstr \"\"\n";
  print "\"Project-Id-Version: $project_id_version\\n\"\n";
  print "\"Report-Msgid-Bugs-To: https://bugs.kde.org\\n\"\n";
  print "\"POT-Creation-Date: $pot_creation_date\\n\"\n";
  # print "\"PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE\\n\"\n";
  print "\"PO-Revision-Date: 2024-02-25 21:21+0100\\n\"\n";
  print "\"Last-Translator: Oliver Kellogg <okellogg\@users.sourceforge.net>\\n\"\n";
  print "\"Language-Team: Esperanto <kde-i18n-eo@kde.org>\\n\"\n";
  print "\"Language: eo\\n\"\n";
  print "\"MIME-Version: 1.0\\n\"\n";
  print "\"Content-Type: text/plain; charset=UTF-8\\n\"\n";
  print "\"Content-Transfer-Encoding: 8bit\\n\"\n";
  foreach (@extensions) {
    print "$_\n";
  }
  print "\"X-Generator: translate-po (https://github.com/zcribe/translate-po)\\n\"\n";
  print "\"Plural-Forms: nplurals=2; plural=n != 1;\\n\"\n";
  print "\n";
}

# Process the content following after header

while (<POT>) {
  my $l = $_;
  chomp $l;
  if ($l =~ /^msgid /) {
    $msgstr = "";
    if ($l =~ /^msgid "(..*?)"$/) {
      my $id = $1;
      if (exists $db{$id}) {
        $msgstr = $db{$id};
      } elsif ($id =~ /^[a-z]/) {
        # If first letter lowercase, try again with uppercase
        my $ucid = ucfirst($id);
        if (exists $db{$ucid}) {
          $msgstr = lcfirst($db{$ucid});
        }
      }
    }
    print "$l\n";
  } elsif ($l =~ /^msgstr "(.*?)"$/) {
    if ($1 ne "") {
      $msgstr = $1;
    }
    print "msgstr \"$msgstr\"\n";
  } else {
    print "$l\n";
  }
}
close(POT);

