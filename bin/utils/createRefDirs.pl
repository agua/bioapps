#!/usr/bin/perl -w

#### DEBUG
my $DEBUG = 0;
$DEBUG = 1;

#### TIME
my $time = time();
my $duration = 0;
my $current_time = $time;

=head2

    APPLICATION     createRefDirs

    PURPOSE
  
		Create reference file sub-directories, one for each chromosome sequence
		
		file in the input directory. Each sub-directory contains a linked copy of
		
		the corresponding chromosome sequence file in the input directory.

	VERSION		0.01

	HISTORY
	
		0.01 BASIC VERSION, DEFAULT "\.fa" REGEX
		
    INPUT

        1. DIRECTORY CONTAINING INDIVIDUAL SEQUENCE FILES
		
		FOR EACH CHROMOSOME
        
    OUTPUT
    
        1. SUBDIRS INSIDE INPUT DIRECTORY, ONE FOR EACH
		
		CHROMOSOME FILE AND CONTAINING A LINKED COPY OF
		
		THE CHROMOSOME FILE.

    USAGE
    
    ./createRefDirs.pl <--directory String> [--regex String] [--help]
    
    --inputdir    :   Directory containing reference sequence files
    --outputdir	:   Create subdirs in this directory containing links to reference files
    --regex		:   Regular expression to identify chromosome files (Default: '\.fa')
    --help      :   print help info

    EXAMPLES

./createRefDirs.pl \
--inputdir /data/sequence/human/hg19/fasta
--outputdir /data/sequence/human/hg19/fasta

=cut

use strict;

#### EXTERNAL MODULES
use Data::Dumper;
use Getopt::Long;
use FindBin qw($Bin);

#### USE LIBRARY
use lib "$Bin";	
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
use Timer;

##### STORE ARGUMENTS FOR PRINTING TO USAGE FILE LATER
my @arguments = @ARGV;
unshift @arguments, $0;

#### FLUSH BUFFER
$| =1;

#### GET OPTIONS
my $inputdir;
my $outputdir;
my $regex;
my $help;
usage() and exit if ( not GetOptions (
    'inputdir=s' 		=> \$inputdir,
    'outputdir=s' 		=> \$outputdir,
    'regex=s'       => \$regex,
    'help'          => \$help
));
usage() if defined $help;
	
package Object;
use Moose;
use Data::Dumper;
use Moose::Util qw( apply_all_roles );

my $object = Object->new;
apply_all_roles( $object, 'Agua::Cluster::Util' );
$object->createReferenceDirs($inputdir, $outputdir);

#### PRINT RUN TIME
my $runtime = Timer::runtime( $time, time() );
print "createRefDirs.pl    Run time: $runtime\n";
print "createRefDirs.pl    Completed $0\n";
print "createRefDirs.pl    ";
print Timer::datetime(), "\n";
print "createRefDirs.pl    ****************************************\n\n\n";
exit;

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#									SUBROUTINES
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

sub usage
{
	print `perldoc $0`;
	exit;
}


