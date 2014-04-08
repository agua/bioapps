#!/usr/bin/perl -w


=head2

APPLICATION 	download

PURPOSE

	1. Download the files for a UUID using GeneTorrent
	
HISTORY

	v0.0.1	Base functionality

USAGE

uuid   	:    UUID of the sample
gtrepo  :    URL of the GTRepo


EXAMPLE

Download the bam files for a UUID from CGHub 

./download.pl \
--uuid eaa56631-c802-47ff-8118-3ed40d10302b \
--outputdir=/pancanfs/benchmark/split/download

#export UUID=eaa56631-c802-47ff-8118-3ed40d10302b
#export BAMFILE=HCC1954.7x.n25t55s20.bam
#export BASEDIR=/pancanfs/benchmark/split
#export SUBDIR=download


=cut

#### USE LIBS
use FindBin qw($Bin);

#### USE LIBRARY
use lib "$Bin/../../lib";	
use lib "$Bin/../../lib/external";	

#### EXTERNAL MODULES
use Term::ANSIColor qw(:constants);
use Data::Dumper;
use Getopt::Long;

#### INTERNAL MODULES
use GT::Download;

##### STORE ARGUMENTS TO PRINT TO FILE LATER
my $arguments;
@$arguments = @ARGV;
my $SHOWLOG 	=	2;
my $PRINTLOG	=	5;
my $uuid;
my $gtrepo;
my $outputdir;
my $cpus;
my $keyfile;
my $log;
my $help;
my $logfile		=	"/tmp/gtdownload-$$.log";
GetOptions (
    'uuid=s'  		=> 	\$uuid,
    'gtrepo=s'  	=> 	\$gtrepo,
    'outputdir=s'  	=> 	\$outputdir,
    'cpus=s'  		=> 	\$cpus,
    'log=s'  		=> 	\$log,
    'keyfile=s'  	=> 	\$keyfile,
    'help'          => 	\$help,
    'SHOWLOG=i'     => 	\$SHOWLOG,
    'PRINTLOG=i'    => 	\$PRINTLOG,
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

print "uuid not defined\n" and exit if not defined $uuid;

my $object	=	GT::Download->new({
	keyfile		=>	$keyfile,
	log			=>	$log,
	logfile		=>	$logfile,
    SHOWLOG     =>  $SHOWLOG,
    PRINTLOG    =>  $PRINTLOG,
});

$object->download($outputdir, $uuid, $gtrepo, $cpus);

##############################################################

sub usage {
	print `perldoc $0`;
	exit;
}
