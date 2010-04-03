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

use English qw( -no_match_vars );
use Getopt::Long;
use File::Basename;

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

my $VERSION = '2010.0403.1801';

#  Total statistics

my %TABS;
my %DIV;

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
        $LIB
        $PROGNAME
        $CONTACT
	$LICENSE
        $URL
    );

    $LICENSE	= "GPL-2+";
    $LIB        = basename $PROGRAM_NAME;
    $PROGNAME   = $LIB;

    $CONTACT     = "Jari Aalto";
    $URL         = "http://freshmeat.net/projects/indent-stat";

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

Display indentation statictics from files. This is a poor
man's implementation to quicly see what kind of indentation
amounts and indentation levels occur in files. The result are
presented by file, and total summary over files at the end.

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

=item B<-v, --verbose LEVEL>

Print informational messages. Increase numeric LEVEL for more
verbosity.

=item B<-V, --version>

Print contact and version information.

=back

=head1 EXAMPLES

Display statistics about one of the Perl modules:

    $ indent-stat /usr/share/perl/5.10.1/Pod/Html.pm

    /usr/share/perl/5.10.1/Pod/Html.pm BY INDENT
    2 30
    4 571
    5 1
    6 32
    7 5
    8 347
    ...
    Totals BY INDENTATION LEVEL (nultiples of)
    2 30
    3 282
    4 1042
    5 6

=head1 TROUBLESHOOTING

None.

=head1 EXAMPLES

None.

=head1 ENVIRONMENT

None.

=head1 FILES

None.

=head1 SEE ALSO

indent(1)

=head1 COREQUISITES

Uses standard Perl modules.

=head1 AVAILABILITY

Homepage is at http://freshmeat.net/projects/indent-stat

=head1 AUTHOR

Copyright (C) 2009-2010 Jari Aalto

=head1 LICENSE

This program is free software; you can redistribute and/or modify
program under the terms of GNU General Public license either version 2
of the License, or (at your option) any later version.

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
	eval "use Pod::Man;";
        $EVAL_ERROR  and  die "$id: Cannot generate Man: $EVAL_ERROR";

        my %options;
        $options{center} = 'cvs status - formatter';

        my $parser = Pod::Man->new(%options);
        $parser->parse_from_file ($PROGRAM_NAME);
    }
    else
    {
	if ( $^V =~ /5\.10/ )
	{
	    # Bug in 5.10. Cant use string ("") as a symbol ref
	    # while "strict refs" in use at
	    # /usr/share/perl/5.10/Pod/Text.pm line 249.

	    system("pod2text $PROGRAM_NAME");
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
    );

    Getopt::Long::config( qw
    (
        require_order
        no_ignore_case
        no_ignore_case_always
    ));

    my ( $help, $helpMan, $helpHtml, $version ); # local variables to function

    $debug = -1;

    GetOptions      # Getopt::Long
    (
	  "help-html"	    => \$helpHtml
	, "help-man"	    => \$helpMan
	, "h|help"	    => \$help
	, "v|verbose:i"	    => \$verb
	, "V|version"	    => \$version
    );

    $version	and  die "$VERSION $CONTACT $LICENSE $URL\n";
    $help	and  Help();
    $helpMan	and  Help(-man);
    $helpHtml	and  Help(-html);
    $version	and  Version();

    $debug = 1  if $debug == 0;
    $debug = 0  if $debug < 0;

    $verb = 1  if  $test and $verb == 0;
    $verb = 5  if  $debug;
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

sub Print ($;$)
{
    my $href = shift;
    my $topic = shift;

    print $topic, "\n"	if $topic;

    for my $tab ( sort {$a <=> $b} keys %$href )
    {
	print $tab, " ", $href->{$tab}, "\n";
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

sub TabToSpaces ($)
{
    # Code from Perl Cookbook

    local $_ = shift;

    # expand leading tabs first--the common case

    s/^(\t+)/' ' x (8 * length($1))/e;

    # Now look for nested tabs. Have to expand them one at a time - hence
    # the while loop. In each iteration, a tab is replaced by the number of
    # spaces left till the next tab-stop. The loop exits when there are
    # no more tabs left

    1 while (s/\t/' ' x (8 - length($`)%8)/e);

    $_;
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

sub Read ($)
{
    my $file = shift;

    open my $FH, "<", $file	or return;

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
	    elsif ( $len > 2   and   $len <= 4 * 6) # Examine max up to 6 indentation levels deep
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

    Print \%tabs, "$file BY INDENT";
    Print \%div, "$file BY INDENTATION LEVEL (multiples of)";

    close $FH;
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

    Print \%TABS, "Totals BY INDENT";
    Print \%DIV, "Totals BY INDENTATION LEVEL (nultiples of)";
}

Main();

# End of file
