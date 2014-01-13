#!/usr/bin/perl -w

my $DEBUG = 0;
$DEBUG = 1;

=head2

    TEST        removeDuplicates
    
    PURPOSE
    
		REMOVE DUPLICATE LINES BASED ON USER-INPUT KEYS 
		
		
	EXAMPLES
	
./removeDuplicates.pl \
--columns 5,2,1,3,4 \
--inputfile /nethome/syoung/base/pipeline/dbsnp/snp130-chr2.tsv \
--outputfile /nethome/syoung/base/pipeline/dbsnp/snp130-chr2-uniq.tsv 


=cut

use strict;

#### USE FINDBIN
use FindBin qw($Bin);

#### USE LIBS
use lib "$Bin/../../lib";

#### USE FULL PATH TO SCRIPT IN COMMAND SO THAT CORRECT LIBS
#### CAN BE USED IF LINKS ARE INVOLVED
print "Application must be called with full path (e.g., /full/path/to/file.pl)\n" and exit if $0 =~ /^\./;
my $aguadir;
BEGIN {	
	($aguadir) = $0 =~ /^(.+?)\/[^\/]+\/[^\/]+\/[^\/]+\/[^\/]+\/[^\/]+$/;
	unshift @INC, "$aguadir/lib";
}


#### INTERNAL MODULES
use FileTools;

#### EXTERNAL MODULES
use Term::ANSIColor qw(:constants);
use Data::Dumper;
use Getopt::Long;
use File::Path;
use File::Copy;

##### STORE ARGUMENTS TO PRINT TO FILE LATER
my @arguments = @ARGV;
#print "removeDuplicates.pl    arguments: @arguments\n";

#### GET OPTIONS
my $inputfile;
my $columns;
my $outputfile;
my $help;
if ( not GetOptions (
    'inputfile=s'  => \$inputfile,
    'columns=s'   => \$columns,
    'outputfile=s'   => \$outputfile,
    'help'          => \$help
) )
{ print "Use option --help for usage instructions.\n";  exit;    };

#### PRINT HELP
if ( defined $help )	{	usage();	}

#### CHECK INPUTS
die "inputfile not defined (option --help for usage)\n" if not defined $inputfile;
die "outputfile not defined (Use --help for usage)\n" if not defined $outputfile;
#die "columns not defined (Use --help for usage)\n" if not defined $columns;

#### DEBUG
print "removeDuplicates.pl    inputfile: $inputfile\n";
print "removeDuplicates.pl    outputfile: $outputfile\n";
print "removeDuplicates.pl    columns: $columns\n";

my @cols = split ",", $columns;
foreach my $column ( @cols )
{
	print "column '$column' is non-numeric. Exiting\n" and exit if $column !~ /^\d+$/;
}

#print "cols: \n";
#print join "**\n", @cols;
#print "\n";

my $filetool = FileTools->new();
$filetool->removeDuplicates(
	{
		inputfile	=>	$inputfile,
		outputfile	=>	$outputfile,
		columns	=>	\@cols
	}
);


################################################################################
################################################################################
########################           SUBROUTINES          ########################
################################################################################
################################################################################




