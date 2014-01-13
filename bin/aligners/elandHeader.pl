#!/usr/bin/perl -w

#### DEBUG
my $DEBUG = 0;
#$DEBUG = 1;

#### TIME
my $time = time();

=head2

	APPLICATION     elandHeader
	    
    PURPOSE
    
		CONVERT INCORRECT HEADER FORMATS TO THE SIMPLE HEADER FORMAT
	
		ACCEPTED BY ELAND AND OTHER ALIGNERS MATCHING THIS REGEX:
		
			[A-Z0-9\.]:[0-9]:[0-9]:[0-9]:[0-9](#[0-9]\/[12])?

			(I.E.: basic-sequence-info#label/matenumber)

		WHERE THE LAST PORTION DIFFERS DEPENDING ON WHETHER THE FILE
		
		CONTAINS A SINGLE OR PAIRED END READS

		ALSO, SET BARCODE = 0 IF NOT DEFINED OR ADD BARCODE IN
		
		FORMAT REQUIRED BY ELAND_standalone.pl
		

    INPUTS
    
        1. INPUT FILE
		
    OUTPUTS
    
		1. OUTPUT FILE OF CORRECTLY FORMATTED READS
		
		2. REJECTS FILE OF READS THAT WERE NOT ABLE TO BE FORMATTED CORRECTLY
        
    USAGE
    
    ./elandHeader.pl <--inputfiles String> <format String> [-h]
    
    --inputfiles	:   /full/path/to/inputfiles
    --matefiles		:   /full/path/to/matefiles
    --label			:   Add this to names of converted files
    --dot			:   Print progress count per multiple of this integer
    --help			:   print help info

    EXAMPLES
    
/nethome/bioinfo/apps/agua/0.5/bin/apps/readprep/elandHeader.pl \
--inputfiles /scratch/syoung/base/pipeline/solid/NA18507/SRP000239/min3.length26/samples/100M/min3length26-4.reads_1.fastq \
--matefiles /scratch/syoung/base/pipeline/solid/NA18507/SRP000239/min3.length26/samples/100M/4/min3length26-4.reads_2.fastq \

=cut

use strict;


#### EXTERNAL MODULES
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
use Timer;
use Aligner::ELAND;
use Util;

#### EXTERNAL MODULES
use Data::Dumper;
use Term::ANSIColor qw(:constants);
use Getopt::Long;

#### GET OPTIONS
use Getopt::Long;
my $inputfiles;
my $matefiles;
my $label;
my $dot = 1000000;
my $help;
GetOptions (
    'inputfiles=s' 	=> \$inputfiles,
    'matefiles=s' 	=> \$matefiles,
    'label=s' 		=> \$label,
    'dot=i' 		=> \$dot,
    'help' 			=> \$help             
) or die "No options specified. Use --help for usage\n";
usage() if defined $help;

#### CHECK INPUTS
die "FileTools::elandHeader    inputfiles is not defined (use --help for options)\n" if not defined $inputfiles;
die "FileTools::elandHeader    matefiles is not defined (use --help for options)\n" if not defined $matefiles;
print "FileTools::elandHeader    inputfiles: $inputfiles\n" if $DEBUG;
print "FileTools::elandHeader    matefiles: $matefiles\n" if $DEBUG;

my $elandObject = Aligner::ELAND->new();
$elandObject->simpleFastqHeader($inputfiles, $matefiles, $label);

#### PRINT RUN TIME
my $runtime = Timer::runtime( $time, time() );
print "\nRun time: $runtime\n";
print "Completed $0\n";
print Util::datetime(), "\n";
print "****************************************\n\n\n";
exit;


sub usage
{
	print `perldoc $0`;

	exit;
}
