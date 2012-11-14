#!/usr/bin/perl -w

#### DEBUG
my $DEBUG = 0;
#$DEBUG = 1;

#### TIME
my $time = time();
my $duration = 0;
my $current_time = $time;


=head2

    APPLICATION     elandIndex

    PURPOSE
  
        Convert FASTA files into squashed/indexed ELAND reference files
	    
    USAGE
    
    ./elandIndex.pl <--inputdir String> <--outputdir String> [--help]
	
    --inputdir           :   Location of directory containing *.fa files
    --outputdir          :   Print indexed files to this directory
    --help               :   print help info

    EXAMPLES

perl /nethome/bioinfo/apps/agua/0.4/bin/apps/elandIndex.pl \
--inputdir /nethome/bioinfo/data/sequence/chromosomes/rat/rn4/fasta
--outputdir /nethome/bioinfo/data/sequence/chromosomes/rat/rn4/eland

=cut

use strict;

#### EXTERNAL MODULES
use Term::ANSIColor qw(:constants);
use Data::Dumper;
use Getopt::Long;
use File::Path;

#### USE LIBRARY
use lib "../../lib";
my $Bin;
BEGIN {
	($Bin) = $0 =~ /^(.+?)\/[^\/]+$/;
	$Bin =~ s/\/[^\/]+\/[^\/]+\/[^\/]+$//;
	unshift @INC, "$Bin/lib";
}

#### INTERNAL MODULES
use Timer;
use Util;
use Conf::Agua;
use Aligner::ELAND;

##### STORE ARGUMENTS TO PRINT TO FILE LATER
my @arguments = @ARGV;
print "elandIndex.pl    arguments: @arguments\n";

#### FLUSH BUFFER
$| =1;

#### GET CONF
my $configfile = "$Bin/conf/default.conf";
print "configfile: $configfile\n";
#my $configfile = "$Bin/../../../conf/default.conf";
print "elandIndex.pl    configfile: $configfile\n" if $DEBUG;
my $conf = Conf::Agua->new(inputfile=>$configfile);
my $casava = $conf->getKey("applications:aquarius-8", 'CASAVA');
print "elandIndex.pl    casava: $casava\n" if $DEBUG;

#### GET OPTIONS
# GENERAL
my $inputdir;
my $outputdir;
my $subdirs;
my $SHOWLOG = 2;
my $PRINTLOG = 4;
my $help;
usage() if ( not GetOptions (
    'inputdir=s'   	=> \$inputdir,
    'outputdir=s'   => \$outputdir,
    'subdirs'   	=> \$subdirs,
	'SHOWLOG=i'		=> \$SHOWLOG,
	'PRINTLOG=i'	=> \$PRINTLOG,
    'help'          => \$help
));
usage() if defined $help;

#### CHECK INPUTS
die "inputdir not defined (Use --help for usage)\n" if not defined $inputdir;
$outputdir = $inputdir if not defined $outputdir;

my $elandObject = Aligner::ELAND->new({
		casava		=> 	$casava,
		conf		=>	$conf,
		SHOWLOG		=>	$SHOWLOG,
		PRINTLOG	=>	$PRINTLOG
	}
);
$elandObject->convertReferences($inputdir, $outputdir, $subdirs);

#### PRINT RUN TIME
my $runtime = Timer::runtime( $time, time() );
print "elandIndex.pl    Run time: $runtime\n";
print "elandIndex.pl    Completed $0\n";
print "elandIndex.pl    ";
print Timer::datetime(), "\n";
print "elandIndex.pl    ****************************************\n\n\n";
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


