#!/usr/bin/perl -w

#### DEBUG
#my $DEBUG = 1;
my $DEBUG = 0;

#### TIME
my $time = time();
my $duration = 0;
my $current_time = $time;

=head2

APPLICATION     maqIndex

PURPOSE

	Run maq-build to convert FASTA files into *.bfa binary indexed files
	
USAGE

./maqIndex.pl <--inputdir String> <--outputdir String>
		[--subdirs] [--help]

--inputdir           :   Location of directory containing *.fa files
--outputdir          :   Print *.bfa files to this directory
--subdirs            :   Process files in subdirs of inputdir
--help               :   print help info

EXAMPLES

perl /nethome/bioinfo/apps/agua/0.4/bin/apps/maqIndex.pl \
--inputdir /nethome/bioinfo/data/sequence/chromosomes/rat/rn4/fasta \
--outputdir /nethome/bioinfo/data/sequence/chromosomes/rat/rn4/maq 


=cut

use strict;

#### EXTERNAL MODULES
use Term::ANSIColor qw(:constants);
use Data::Dumper;
use Getopt::Long;
use FindBin qw($Bin);
use File::Path;

#### USE LIBRARY
use lib "$Bin/../../../lib";

#### INTERNAL MODULES
use Aligner::MAQ;
use Conf::Agua;
use Timer;
use Util;

##### STORE ARGUMENTS TO PRINT TO FILE LATER
my @arguments = @ARGV;
print "maqIndex.pl    arguments: @arguments\n";

#### FLUSH BUFFER
$| =1;

#### GET CONF 
my $conf = Conf::Agua->new(inputfile=>"$Bin/../../../conf/default.conf");
my $maq = $conf->getKey("applications:aquarius-8", 'MAQ');
print "maqIndex.pl    maq: $maq\n";

#### GET OPTIONS
my $inputdir;
my $outputdir;
my $subdirs;
my $help;
if ( not GetOptions (
    'inputdir=s'   	=> \$inputdir,
    'outputdir=s'   => \$outputdir,
    'subdirs'   	=> \$subdirs,
    'help'          => \$help
))
{ print "Use option --help for usage instructions.\n";  exit;    };

#### PRINT HELP
if ( defined $help )	{	usage();	}

#### CHECK INPUTS
die "inputdir not defined (Use --help for usage)\n" if not defined $inputdir;
die "outputdir not defined (Use --help for usage)\n" if not defined $outputdir;
print "outputdir is a file: $outputdir\n" if -f $outputdir;
File::Path::mkpath($outputdir) if not -d $outputdir;
print "Can't create outputdir: $outputdir\n" if not -d $outputdir;

#### INSTANIATE MAQ OBJECT
my $maqObject = Aligner::MAQ->new(
	{
		maq => $maq,
		conf => $conf 		
	}
);
$maqObject->convertReferences($inputdir, $outputdir, $subdirs);

#### PRINT RUN TIME
my $runtime = Timer::runtime( $time, time() );
print "maqIndex.pl    Run time: $runtime\n";
print "maqIndex.pl    Completed $0\n";
print "maqIndex.pl    ";
print Timer::datetime(), "\n";
print "maqIndex.pl    ****************************************\n\n\n";
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


