#!/usr/bin/perl -w

#### DEBUG
#my $DEBUG = 1;
my $DEBUG = 0;

#### TIME
my $time = time();
my $duration = 0;
my $current_time = $time;

=head2

    APPLICATION     bowtieIndex

    PURPOSE
  
        Run bowtie-build to convert FASTA files into *ebwt indexed files
		
    USAGE
    
    ./bowtieIndex.pl <--inputdir String> <--outputdir String>
			[--subdirs] [--help]
	
    --inputdir           :   Location of directory containing *.fa files
    --outputdir          :   Print *ebwt files to this directory
    --subdirs            :   Process files in subdirs of inputdir
    --help               :   print help info

    EXAMPLES

perl /nethome/bioinfo/apps/agua/0.4/bin/apps/bowtieIndex.pl \
--inputdir /nethome/bioinfo/data/sequence/chromosomes/rat/rn4/fasta \
--outputdir /nethome/bioinfo/data/sequence/chromosomes/rat/rn4/bowtie


=cut

use strict;

#### EXTERNAL MODULES
use Term::ANSIColor qw(:constants);
use Data::Dumper;
use Getopt::Long;
use FindBin qw($Bin);

#### USE LIBRARY
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
use Aligner::BOWTIE;
use Conf::Agua;
use Timer;
use Util;

##### STORE ARGUMENTS TO PRINT TO FILE LATER
my @arguments = @ARGV;
print "bowtieIndex.pl    arguments: @arguments\n";

#### FLUSH BUFFER
$| =1;

#### GET CONF 
my $conf = Conf::Agua->new(inputfile=>"$aguadir/conf/default.conf");
my $bowtie = $conf->getKey("applications:aquarius-8", 'BOWTIE');
print "bowtieIndex.pl    bowtie: $bowtie\n";

#### GET OPTIONS
# GENERAL
my $inputdir;
my $outputdir;
my $subdirs;

my $help;
if ( not GetOptions (
    'inputdir=s'   => \$inputdir,
    'outputdir=s'   => \$outputdir,
    'subdirs'   	=> \$subdirs,
    'help'          => \$help
) )
{ print "Use option --help for usage instructions.\n";  exit;    };

#### PRINT HELP
if ( defined $help )	{	usage();	}

#### CHECK INPUTS
die "inputdir not defined (Use --help for usage)\n" if not defined $inputdir;
die "Can't find inputdir: $inputdir\n" if not -d $inputdir;
$outputdir = $inputdir if not defined $outputdir;

my $bowtieObject = Aligner::BOWTIE->new(
	{
		bowtie	=> 	$bowtie,
		conf	=>	$conf
	}
);
$bowtieObject->convertReferences($inputdir, $outputdir, $subdirs);


#### PRINT RUN TIME
my $runtime = Timer::runtime( $time, time() );
print "bowtieIndex.pl    Run time: $runtime\n";
print "bowtieIndex.pl    Completed $0\n";
print "bowtieIndex.pl    ";
print Timer::datetime(), "\n";
print "bowtieIndex.pl    ****************************************\n\n\n";
exit;


#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#									SUBROUTINES
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


sub usage
{
	print GREEN;
	print `perldoc $0`;
	print RESET;
	exit;
}


