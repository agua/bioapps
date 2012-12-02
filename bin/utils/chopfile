#!/usr/bin/perl -w

use strict;

=head2    APPLICATION    chopfile

=head2


=head2    PURPOSE

=head4    Print a user-defined number of lines from one file

=head4          to another file

=head2


=head2    USAGE

=head2

chopfile.pl <--inputfile String> <--outputfile String>
               <--lines Integer] [--help]

=over 10

=item B<--inputfile         :   Print lines from this source file>

=item B<--outputfile        :   Print lines to this target file>

=item B<--lines             :   Print this number of lines>

=item B<--offset            :   Start printing at this line>

=item B<--help              :   Print help info>
     
=back     

=cut

#### EXTERNAL MODULES
use Getopt::Long;


#### GET OPTIONS
my $inputfile;
my $outputfile;
my $lines;
my $offset = 0;
my $help;
GetOptions (
	'outputfile=s'  =>   \$outputfile,
	'inputfile=s'   =>   \$inputfile,
	'lines=s'       =>   \$lines,
	'offset=s'      =>   \$offset,
	'help'          =>   \$help
) or die "No options specified. Try '--help'\n";

#### USAGE
sub usage()
{
    print `perldoc $0`;
    exit;
}
usage() if defined $help;

#### CHECK INPUTS
print "inputfile not defined (option --inputfile)\n" and exit if not defined $inputfile;
print "outputfile not defined (option --outputfile)\n" and exit if not defined $outputfile;
print "lines not defined (option --url)\n" and exit if not defined $lines;

#### CHECK INPUTFILE
print "Can't find inputfile: $inputfile\n" and exit if not -f $inputfile;

#### OPEN FILES     
open(FILE, $inputfile) or die "Can't open input file '$inputfile'\n";
open(OUTPUTFILE, ">$outputfile") or die "Can't open outputfile '$outputfile'\n";

#### SKIP LINES UNTIL OFFSET
my $line;
my $line_number = 0;
while ( $line_number < $offset ) {
	<FILE>;
	$line_number++;
}

#### PRINT LINES
$line_number = 0;
while( defined($line = <FILE>) and $line_number < $lines )
{
	print OUTPUTFILE $line;
	$line_number++;
}
close(OUTPUTFILE);
close(FILE);

print "OUTPUTFILE CREATED ($lines LINES):\n\n$outputfile\n\n";


