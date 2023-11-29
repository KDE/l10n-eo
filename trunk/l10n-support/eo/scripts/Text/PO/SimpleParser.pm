# Text/PO/SimpleParser.pm   GNU gettext PO file parser
# This module is distributed under the same terms as Perl itself.
# Copyright  (C) 2023, Oliver Kellogg <okellogg@users.sourceforge.net>
#
# -----------------------------------------------------------------------------
# Ver. |   Date   | Changes
# -----+----------+------------------------------------------------------------
# 1.00  2023/03/15  * Initial version
# 1.01  2023/11/27  * Added optional $multiline_join_char (see documentation)
#

package Text::PO::SimpleParser;

require Carp;

use 5.006;
use strict 'vars';
use warnings;
use Exporter qw(import);
use utf8;

# @EXPORT = ();
# @EXPORT_OK = (&Parse);

=head1 NAME

Text::PO::SimpleParser - Parser for GNU gettext PO files

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

our $preserve_string_escapes = 1;
our $expect_header = 1;
our $multiline_join_char;  # undef means it is not used

=head1 SYNOPSIS

Subroutine Parse is the universal entry point (to be called by the
main program.)
It takes a PO file name as the input parameter and parses that file,
constructing an array which is returned by reference.
In case of errors during parsing, Parse_File returns undef.
The subroutine also takes an optional argument ($filter).
If it is -1 then only the untranslated entries are returned.
If it is  1 then only the translated entries are returned.
If it is not provided or is provided as 0 then all entries are returned.

Usage:

   use Text::PO::SimpleParser;

   my $ref_to_array_ = Text::PO::SimpleParser::Parse("/path/to/somefile.po");

   $ref_to_array or die "File had syntax errors\n";

=head1 STRUCTURE OF ELEMENT OF THE ARRAY RETURNED BY Parse

Each element is a reference to a hash consisting of the keys

=over

=item B<comment>  (optional)

Optional reference to array of comment lines preceding a PO entry.
Leading hashmark and whitespace are removed.

=back

=over

=item B<fuzzy>  (optional)

The comments preceding a PO entry may contain the string C<, fuzzy>.
If C<, fuzzy> is present then the C<fuzzy> key is set.
If following the C<, fuzzy> there is a line beginning with C<#| msgid> then
this line is set as the value of the C<fuzzy> slot.

Example:

   #: dialogs/extractingprogressdialog.cpp:153
   #, fuzzy, kde-format
   #| msgid "Do you really want to cancel?"

The C<comment> hash entry will contain a reference to array of the three lines

   : dialogs/extractingprogressdialog.cpp:153
   , fuzzy, kde-format
   | msgid "Do you really want to cancel?"

C<fuzzy> will be set to C<Do you really want to cancel?>.

=back

=over

=item B<msgctxt msgid msgid_plural msgstr msgstr[0] msgstr[1]>

The corresponding hash entry is set: C<msgctxt>, C<msgid>, C<msgid_plural>, C<msgstr>,
C<msgstr[0]>, or C<msgstr[1]>.
If the value of the keyword appears on the same line such as in C<msgid "The text">
then the value of the hash entry is the string value given (C<The text>).
If the value of the keyword appears as lines following the keyword line then

=over

=item * if C<$multiline_join_char> is not set then the value of the slot is a reference to an array of those lines.

=item * if C<$multiline_join_char> is set then the value of the slot is the concatenation of the lines separated by C<$multiline_join_char>, i.e. C<$multiline_join_char> acts as the delimiter by which the joined string can be split into its original lines.

=back

In all cases, the delimiting quotation marks are not forwarded to the hash value.

=back

=cut

# filter ==  0 : return all messages
# filter == -1 : return only untranslated messages
# filter ==  1 : return only translated messages
sub Parse {
  my $file = shift;
  my $filter = 0;
  if (@_) {
    $filter = shift;
  }
  unless (open(F, "<:utf8", $file)) {
    warn "Cannot open file $file\n";
    return undef;
  }
  my @rawlines;

  while (<F>) {
    chomp;
    s/\r//g;
    s/[ \t]+$//;
    /^#\~/ and last;
    push @rawlines, $_;
  }
  close F;
  
  # my @comment;
  # my @msgctxt;
  # my @msgid;
  # my @msgstr;
  my $entry = {};
  my @output;
  my $in_header = $expect_header;
  
  for (my $i = 0; $i < scalar(@rawlines); ++$i) {
    my $line = $rawlines[$i];
    if ($line =~ /^#/) {
      $line =~ s/^#//;
      unless (exists $entry->{comment}) {
        $entry->{comment} = [];
      }
      push @{$entry->{comment}}, $line;
      if ($line =~ /^, fuzzy/) {
        $entry->{fuzzy} = "";
      } elsif ($line =~ /^\| msgid "(.+)"$/) {
        $entry->{fuzzy} = $1;
        $entry->{fuzzy} =~ s/\\"/"/g;
      }
    } elsif ($line =~ /^(msgctxt|msgid_plural|msgid|msgstr\[\d\]|msgstr) ""/) {
      my $key = $1;
      my @body;
      while ($i < scalar(@rawlines) - 1 and $rawlines[++$i] =~ /^"/) {
        my $l = $rawlines[$i];
        $l =~ s/^"//;
        $l =~ s/"$//;
        unless ($preserve_string_escapes) {
          $l =~ s/\\"/"/g;
        }
        push @body, $l;
      }
      if ($in_header && $key eq "msgid") {
        # Empty msgid means it's the header.
        $key = "HEADER";
        $in_header = 0;
      }
      if (defined $multiline_join_char) {
        $entry->{$key} = (@body ? join($multiline_join_char, @body) : "");
      } else {
        $entry->{$key} = (@body ? [ @body ] : "");
      }
      $i >= scalar(@rawlines) - 1 and last;
      --$i;   # counteract inner loop increment
    } elsif ($line =~ /^(msgctxt|msgid_plural|msgid|msgstr\[\d\]|msgstr) "(.+)"$/) {
      my $key = $1;
      my $body = $2;
      unless ($preserve_string_escapes) {
        $body =~ s/\\"/"/g;
      }
      $entry->{$key} = $body;
    } elsif ($line) {
      warn "TODO: $line\n";
    } elsif (%$entry) {
      if ($filter == 0 || ($filter == 1 && $entry->{msgstr}) ||
                          ($filter == -1 && !$entry->{msgstr})) {
        push @output, $entry;
      }
      $entry = {};
    }
  }
  if (%$entry && ($filter == 0 || ($filter == 1 && $entry->{msgstr})
                               || ($filter == -1 && !$entry->{msgstr}))) {
    push @output, $entry;
  }
  return [ @output ];
}

1;

# The End.
