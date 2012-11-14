#!/usr/bin/perl -w

#### DEBUG
#my $DEBUG = 1;
my $DEBUG = 0;

#### TIME
my $time = time();
my $duration = 0;
my $current_time = $time;

=head2

APPLICATION     novoIndex

PURPOSE

	Run novoindex to convert FASTA files into *.idx binary indexed files
	
USAGE

./novoIndex.pl <--inputdir String> <--outputdir String>
		[--subdirs] [--help]

--inputdir           :   Location of directory containing *.fa files
--outputdir          :   Print *.bfa files to this directory
--subdirs            :   Process files in subdirs of inputdir
--help               :   print help info

EXAMPLES

perl /nethome/bioinfo/apps/agua/0.4/bin/apps/novoIndex.pl \
--inputdir /nethome/bioinfo/data/sequence/chromosomes/rat/rn4/fasta \
--outputdir /nethome/bioinfo/data/sequence/chromosomes/rat/rn4/novo 


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
use Aligner::NOVOALIGN;
use Conf::Agua;
use Timer;
use Util;

##### STORE ARGUMENTS TO PRINT TO FILE LATER
my @arguments = @ARGV;
print "novoIndex.pl    arguments: @arguments\n";

#### FLUSH BUFFER
$| =1;

#### GET CONF 
my $conf = Conf::Agua->new(inputfile=>"$Bin/../../../conf/default.conf");
my $novoalign = $conf->getKey("applications:aquarius-8", 'NOVOALIGN');
print "novoIndex.pl    novoalign: $novoalign\n";

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

#### INSTANIATE NOVOALIGN OBJECT
my $novoObject = Aligner::NOVOALIGN->new(
	{
		novoalign => $novoalign,
		conf => $conf 		
	}
);
$novoObject->convertReferences($inputdir, $outputdir, $subdirs);

#### PRINT RUN TIME
my $runtime = Timer::runtime( $time, time() );
print "novoIndex.pl    Run time: $runtime\n";
print "novoIndex.pl    Completed $0\n";
print "novoIndex.pl    ";
print Timer::datetime(), "\n";
print "novoIndex.pl    ****************************************\n\n\n";
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


