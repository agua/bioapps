#!/usr/bin/perl -w

#### DEBUG
my $DEBUG = 0;
$DEBUG = 1;

#### TIME
my $time = time();

=head2

    APPLICATION     unzipFiles
    
    PURPOSE
    
        UNZIP FILES, FILTERING BY STRING MATCH OR REGEX
    
    INPUT
    
        1. REQUIRED: INPUT DIRECTORY CONTAINING *gz FILES
    
        2. OPTIONAL: FILTER TERM AND REGEX TO FILTER FILES BEFORE DOWNLOADING
    
    OUTPUT
    
        1. UNZIPPED FILES IN OUTPUT DIRECTORY

    USAGE
    
    ./unzipFiles.pl <--type String> <--inputdir String> <--outputdir String> [--filter String] [--regex String] [--help]
    
    --type              :   Name of unzip application (unzip|gunzip) (DEFAULT: gunzip)
    --inputdir       	:   Directory containing input files
    --outputdir       	:   Unzip files to this directory
    --filter            :   Unzip only files containing this text fragment
    --regex             :   Unzip only files matching this regular expression
    --delete            :   Optionally delete all zip files after unzipping
    --help              :   PRINT HELP INFO

    EXAMPLES

./unzipFiles.pl --type gunzip \
--inputdir /nethome/syoung/agua/Project1/Workflow1/downloads \
--outputdir /data/sequence/reference/human/hg19/fasta \
--regex chr[0-9MYX]+.fa.gz
 
=cut

use strict;

#### USE LIB
use FindBin qw($Bin);

use lib "$Bin/../../lib";

#### USE FULL PATH TO SCRIPT IN COMMAND SO THAT CORRECT LIBS
#### CAN BE USED IF LINKS ARE INVOLVED
print "Application must be called with full path (e.g., /full/path/to/file.pl)\n" and exit if $0 =~ /^\./;
my $aguadir;
BEGIN {	
	($aguadir) = $0 =~ /^(.+?)\/[^\/]+\/[^\/]+\/[^\/]+\/[^\/]+\/[^\/]+$/;
	unshift @INC, "$aguadir/lib";
}

use lib "/agua/lib";

#### INTERNAL MODULES
use Timer;
#use Util;

#### EXTERNAL MODULES
use File::Path;
use Getopt::Long;

#### GET OPTIONS
my $type;
my $inputdir;
my $outputdir;
my $filter;
my $regex;
my $delete;
my $help;
usage() if not GetOptions (
	'type=s' 		=> \$type,
	'inputdir=s' 	=> \$inputdir,
	'outputdir=s' 	=> \$outputdir,
	'filter=s' 		=> \$filter,
	'regex=s' 		=> \$regex,
	'delete' 		=> \$delete,
	'help' => \$help
);
usage() if defined $help;

#### TYPE OF URL IS 'html' OR 'text'
print "Agua::Cluster::Agua::unzipFiles    Type not defined (option --type)\n" and exit if not defined $type;
print "Agua::Cluster::Agua::unzipFiles    Type must be 'gunzip' or 'unzip'\n" and exit if $type !~ /^(gunzip|unzip)$/i;

#### CHECK FOR REQUIRED URL
die "type not defined (option --type)\n" if not defined $type;

#### CHECK FOR REQUIRED OUTPUT DIRECTORY
die "Output directory not defined (option --outputdir)\n" if not defined $outputdir;

package Object;
use Moose;
use Data::Dumper;
use Moose::Util qw( apply_all_roles );

#### SET LOG
my $SHOWLOG = 4;
my $PRINTLOG = 5;
my $logfile =   "/tmp/unzipFiles.$$.log";

use MooseX::Declare;
class Object with (Agua::Common::Logger, Agua::Cluster::Util) {

}


### INSTANTIATE
my $object = Object->new({
    SHOWLOG     => $SHOWLOG,
    PRINTLOG    => $PRINTLOG,
    logfile     => $logfile
});


#### RUN
$object->unzipFiles(
{
	type 		=> $type,
	inputdir 	=> $inputdir,
	outputdir 	=> $outputdir,
	filter 		=> $filter,
	regex 		=> $regex,
	delete 		=> $delete
});

#### PRINT RUN TIME
my $runtime = Timer::runtime( $time, time() );
print "\nRun time: $runtime\n";
print "Completed $0\n";
print Timer::datetime(), "\n";
print "****************************************\n\n\n";
exit;

###########################################################################################
####################                 S U B R O U T I N E S                ################# 
###########################################################################################

sub usage	{	`perldoc $0`;	}

