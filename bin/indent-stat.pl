#!/usr/bin/perl
#
#   indent-stat -- Check indentation statistics of files
#
#   Copyright
#
#       Copyright (C) 2009-2010 Jari Aalto <jari.aaltocante.net>
#
#   License
#
#       This program is free software; you can redistribute it and/or modify
#       it under the terms of the GNU General Public License as published by
#       the Free Software Foundation; either version 2 of the License, or
#       (at your option) any later version.
#
#       This program is distributed in the hope that it will be useful,
#       but WITHOUT ANY WARRANTY; without even the implied warranty of
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#       GNU General Public License for more details.
#
#       You should have received a copy of the GNU General Public License
#       along with this program. If not, see <http://www.gnu.org/licenses/>.

# ****************************************************************************
#
#   Standard perl modules
#
# ****************************************************************************

use strict;

use autouse 'Pod::Text' => qw( pod2text );
use autouse 'Pod::Html' => qw( pod2html );

use English qw(-no_match_vars);
use Getopt::Long;
use File::Basename;
use File::Find;

# ****************************************************************************
#
#   GLOBALS
#
# ****************************************************************************

use vars qw ( $VERSION );

#   This is for use of Makefile.PL and ExtUtils::MakeMaker
#
#   The following variable is updated by custom Emacs setup whenever
#   this file is saved.

my $VERSION = '2010.0404.0635';

#  Total statistics

my %TABS;
my %DIV;

my $DEFAULT_PATH_EXCLUDE =            # Matches *only path component
    '(CVS|RCS|\.(bzr|svn|git|darcs|arch|mtn|hg))$'
    ;

my $DEFAULT_FILE_EXCLUDE =            # Matches *only* file component
    '[#~]$'
    . '|\.[#]'
    . '|\.(s?o|l?a|bin|com|exe|class|elc)$'
    . '|\.(ods|odt|pdf|ppt|xls|rtf)$'
    . '|\.(xpm|jpg|png|gif|tiff|bmp)$'
    ;

# ****************************************************************************
#
#   DESCRIPTION
#
#       Set global variables for the program
#
#   INPUT PARAMETERS
#
#       None
#
#   RETURN VALUES
#
#       None
#
# ****************************************************************************

sub Initialize ()
{
    use vars qw
    (
	$LICENSE
	$CONTACT
	$URL

	$LIB
	$PROGNAME
    );

    $LICENSE    = "GPL-2+";
    $CONTACT    = "Jari Aalto";
    $URL        = "http://freshmeat.net/projects/indent-stat";

    $LIB        = basename $PROGRAM_NAME;
    $PROGNAME   = $LIB;

    $OUTPUT_AUTOFLUSH = 1;
}

# ****************************************************************************
#
#   DESCRIPTION
#
#       Help function and embedded POD documentation
#
#   INPUT PARAMETERS
#
#       None
#
#   RETURN VALUES
#
#       None
#
# ****************************************************************************

=pod

=head1 NAME

indent-stat - Check indentation statistics of files

=head1 SYNOPSIS

  indent-stat [options] FILE [FILE ...]

=head1 DESCRIPTION

Display indentation statictics from files. A simple QA tool to quickly
see if there is varying indentation levels in files. The result are
presented by file. A statistical summary is calculated at the end.

The statistics are by default collected up to 6 standard indentation
levels (column 6 * 4) for multiples of columns 3, 4 and 5.

=head1 OPTIONS

=over 4

=item B<-d, --debug LEVEL>

Turn on debug. Level can be in range 0-10.

=item B<-h, --help>

Print text help

=item B<--help-html>

Print help in HTML format.

=item B<--help-man>

Print help in manual page C<man(1)> format.

=item B<-l, --line>

Present results in one line instead of printing each result in
separate lines. This may help post-processing and reading the results
with other tools.

=item B<-s, --summary>

Print summary over all files at the end.

=item B<-v, --verbose LEVEL>

Print informational messages. Increase numeric LEVEL for more
verbosity. The values are:

    1 = print file name processed
    2 = print file names and statistics for each

=item B<-V, --version>

Print contact and version information.

=back

=head1 EXAMPLES

Display statistics about a Perl module:

    $ indent-stat -v -s /usr/share/perl/5.10.1/Pod/Html.pm

    /usr/share/perl/5.10.1/Pod/Html.pm BY INDENT
    2 30
    4 571
    5 1
    6 32
    7 5
    8 347
    ...
    SUMMARY BY INDENTATION LEVEL (multiples of)
    2 30
    3 282
    4 1042
    5 6

=head1 TROUBLESHOOTING

None.

=head1 ENVIRONMENT

None.

=head1 FILES

None.

=head1 BUGS AND LIMITATIONS

The summary of total statistics at the end are collected in standard
4-column indent steps. There is no way to detect files that may use 2
or standard TAB positions (column 8) for indentation. That is because
8 is dividable by 4 (8 % 4 always yields true) and 4 would be always
dividable by 2.

=head1 EXIT STATUS

Not defined.

=head1 DEPENDENCIES

Uses standard Perl modules.

=head1 BUGS AND LIMITATIONS

None.

=head1 SEE ALSO

indent(1)

=head1 AVAILABILITY

Homepage is at http://freshmeat.net/projects/indent-stat

=head1 AUTHOR

Jari Aalto

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2009-2010 Jari Aalto

This program is free software; you can redistribute and/or modify
program under the terms of GNU General Public license either version 2
of the License, or (at your option) any later version.

Alternatively, this manual manual is also released (at your option)
under the GNU FDL, version 1.3, or (at your option) any later version.

=cut

sub Help (;$$)
{
    my $id   = "$LIB.Help";
    my $type = shift;  # optional arg, type
    my $msg  = shift;  # optional arg, why are we here...

    if ( $type eq -html )
    {
	pod2html $PROGRAM_NAME;
    }
    elsif ( $type eq -man )
    {
	eval "use Pod::Man"
	    or die "$id: Cannot generate Man: $EVAL_ERROR";

	my %options;
	$options{center} = "User commands";

	my $parser = Pod::Man->new(%options);
	$parser->parse_from_file ($PROGRAM_NAME);
    }
    else
    {
	if ( $PERL_VERSION =~ /5\.10/ )
	{
	    # Bug in 5.10. Cant use string ("") as a symbol ref
	    # while "strict refs" in use at
	    # /usr/share/perl/5.10/Pod/Text.pm line 249.

	    system "pod2text $PROGRAM_NAME";
	}
	else
	{
	    pod2text $PROGRAM_NAME;
	}
    }

    defined $msg  and  print $msg;
    exit 0;
}

# ****************************************************************************
#
#   DESCRIPTION
#
#       Display default excludes.
#
#   INPUT PARAMETERS
#
#       None
#
#   RETURN VALUES
#
#       None
#
# ****************************************************************************

sub HelpExclude ()
{
    my $id = "$LIB.HelpExclude";

    print "Default path exclude regexp: '$DEFAULT_PATH_EXCLUDE'\n";
    print "Default file exclude regexp: '$DEFAULT_FILE_EXCLUDE'\n";
}

# ****************************************************************************
#
#   DESCRIPTION
#
#       Read command line arguments and their parameters.
#
#   INPUT PARAMETERS
#
#       None
#
#   RETURN VALUES
#
#       Globally set options.
#
# ****************************************************************************

sub HandleCommandLineArgs ()
{
    my $id = "$LIB.HandleCommandLineArgs";

    use vars qw
    (
	$test
	$verb
	$debug

	$INDENT_MAX

	@OPT_FILE_REGEXP_EXCLUDE
	@OPT_FILE_REGEXP_INCLUDE
	$OPT_LINE
	$OPT_RECURSIVE
	$OPT_REGEXP
	$OPT_SUMMARY
    );

    Getopt::Long::config( qw
    (
	no_ignore_case
	no_ignore_case_always
    ));

    my ( $help, $helpMan, $helpHtml, $version );
    my ( $helpExclude, $indent);

    $debug = -1;
    $verb  = -1;

    GetOptions      # Getopt::Long
    (
	  "help-exclude"    => \$helpExclude
	, "help-html"       => \$helpHtml
	, "help-man"        => \$helpMan
	, "h|help"          => \$help
	, "i|indent-max"    => \$indent
	, "line"            => \$OPT_LINE
	, "include=s"       => \@OPT_FILE_REGEXP_INCLUDE
	, "r|recursive"     => \$OPT_RECURSIVE
	, "R|regexp=s"      => \$OPT_REGEXP
	, "summary"         => \$OPT_SUMMARY
	, "test"            => \$test
	, "v|verbose:i"     => \$verb
	, "V|version"       => \$version
	, "x|exclude=s"     => \@OPT_FILE_REGEXP_EXCLUDE
    );

    $version    and  die "$VERSION $CONTACT $LICENSE $URL\n";
    $help       and  Help();
    $helpMan    and  Help(-man);
    $helpHtml   and  Help(-html);
    $version    and  Version();

    $debug = 1  if  $debug == 0;
    $debug = 0  if  $debug < 0;

    $verb = 1   if  $verb == 0;
    $verb = 0   if  $verb < 0;

    $verb = 1   if  $test and $verb == 0;
    $verb = 5   if  $verb;

    #   Examine only max up to 6 standard 4-column indentation levels
    #   deep. We suppose that there is nothing interesting after that
    #   indentation, becasue code is too much indented. (think 6
    #   if-loops, while loops...)

    $INDENT_MAX = $indent || 6 * 4;
}

# ****************************************************************************
#
#   DESCRIPTION
#
#       Print hash.
#
#   INPUT PARAMETERS
#
#       $href                   Hash reference
#       $str                    String to print as "headiing" before content
#
#   RETURN VALUES
#
#       None
#
# ****************************************************************************

sub Print ($;$)
{
    my $href = shift;
    my $str = shift;

    my $eol = $OPT_LINE ? " " : "\n";
    my $sep = $OPT_LINE ? ":" : " ";

    print $str, $eol    if $str;

    my @keys = sort {$a <=> $b} keys %$href;
    my $i    = 0;
    my $len  = @keys;

    for my $tab ( @keys )
    {
	print $tab, $sep, $href->{$tab};

	#   Do not print trailing whitespace in linewise mode for last element

	print $eol  if  ++$i < $len;
    };

    print "\n"  unless  $eol eq "\n";
}

# ****************************************************************************
#
#   DESCRIPTION
#
#       Convert tabs to spaces. Code is from Perl Cookbook.
#
#   INPUT PARAMETERS
#
#       $str                    String with tabs
#
#   RETURN VALUES
#
#       None
#
# ****************************************************************************

sub TabToSpaces ($)
{
    local $ARG = shift;

    # expand leading tabs first--the common case

    s/^(\t+)/' ' x (8 * length $1)/e;

    # Now look for nested tabs. Have to expand them one at a time - hence
    # the while loop. In each iteration, a tab is replaced by the number of
    # spaces left till the next tab-stop. The loop exits when there are
    # no more tabs left

    1 while ( s/\t/' ' x ((8 - length $PREMATCH) % 8)/e );

    $ARG;
}

# ****************************************************************************
#
#   DESCRIPTION
#
#       Read a FILE and gather statistics. Display per file statistics.
#
#   INPUT PARAMETERS
#
#       $file                   Path name
#
#   RETURN VALUES
#
#       None
#
# ****************************************************************************

sub Read ($)
{
    my $file = shift;

    open my $FH, "<", $file     or return;

    my (%tabs, %div);

    while ( <$FH> )
    {
	chomp;

	if ( /^([[:space:]]+)/ )
	{
	    my $len = length TabToSpaces $1;

	    $tabs{$len}++;
	    $TABS{$len}++;

	    if ( $len == 2 )
	    {
		$div{2}++;
		$DIV{2}++;
	    }
	    elsif ( $len > 2   and   $len <= $INDENT_MAX)
	    {
		for my $div (3, 4, 5)
		{
		    unless ( $len % $div )
		    {
			$div{$div}++;
			$DIV{$div}++;
			last;
		    }
		}
	    }
	}
    }

    close $FH  or  warn "Close $file failure $ERRNO";

    if ( $verb == 1 )
    {
	print $file, "\n";
    }
    elsif ( $verb > 1 )
    {
	Print \%tabs, "$file BY INDENT";
	Print \%div, "$file BY INDENTATION LEVEL (multiples of)";
    }
}

# ****************************************************************************
#
#   DESCRIPTION
#
#       Set global variables for the program
#
#   INPUT PARAMETERS
#
#       None
#
#   RETURN VALUES
#
#       None
#
# ****************************************************************************

sub Main ()
{
    my $id = "$LIB.Main";

    Initialize();
    HandleCommandLineArgs();

    Help() unless (@ARGV);

    for my $file (@ARGV)
    {
	Read $file;
    }

    if ( $OPT_SUMMARY )
    {
	Print \%TABS, "SUMMARY BY USED INDENTATION";
	Print \%DIV, "SUMMARY BY INDENT LEVEL (multiples of)";
    }
}

Main();

# End of file
