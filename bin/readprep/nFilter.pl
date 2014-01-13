#!/usr/bin/perl -w

#### DEBUG
my $DEBUG = 0;
#$DEBUG = 1;

#### TIME
my $time = time();

=head2

	APPLICATION     nFilter
	    
    PURPOSE
    
		1. CONVERT csfasta AND qual TO fastq

    INPUTS
    
        1. INPUT FILE
		
    OUTPUTS
    
		1. OUTPUT FILE OF CORRECTLY FORMATTED READS
		
		2. REJECTS FILE OF READS THAT WERE NOT ABLE TO BE FORMATTED CORRECTLY
        
    USAGE
    
    ./nFilter.pl <--inputfile String> <--outputfile String> <paired Boolean> [-h]
    
    --inputfile		:   /full/path/to/inputfile
    --outputfile	:   /full/path/to/outputfile
	--paired		: 
	--dot			:   Print progress count per multiple of this integer
    --help			:   print help info

    EXAMPLES
    
/nethome/bioinfo/apps/agua/0.5/bin/apps/readprep/nFilter.pl \
--inputfile /scratch/syoung/base/pipeline/jvance/pdx/test/1/test1.sequence.txt \
--outputfile /scratch/syoung/base/pipeline/jvance/pdx/test/1/test1.nfilter.sequence.txt \
--rejectfile /scratch/syoung/base/pipeline/jvance/pdx/test/1/test1.nfilter-reject.sequence.txt

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
use BinData;
use Timer;
use SolexaUtil;
use Util;
use Conf::Agua;

#### INITIALISE SolexaUtil OBJECT
my $solexa = SolexaUtil->new();

#### EXTERNAL MODULES
use Data::Dumper;
use Term::ANSIColor qw(:constants);
use Getopt::Long;

#### GET OPTIONS
use Getopt::Long;
my $inputfile;
my $outputfile;
my $rejectfile;
my $paired;
my $dot = 1000000;
my $help;
GetOptions (
    'inputfile=s' 	=> \$inputfile,
    'outputfile=s' 	=> \$outputfile,
    'rejectfile=s' 	=> \$rejectfile,
    'paired' 		=> \$paired,
    'dot=i' 		=> \$dot,
    'help' 			=> \$help             
) or die "No options specified. Use --help for usage\n";
usage() if defined $help;

#### CHECK INPUTS
die "inputfile is not defined (use --help for options)\n" if not defined $inputfile;
die "outputfile is not defined (use --help for options)\n" if not defined $outputfile;
die "rejectfile is not defined (use --help for options)\n" if not defined $rejectfile;

#### OPEN INPUT FILE
if( $inputfile =~ /\.gz$/ or $inputfile =~ /\.zip$/ )
{
	print "nFilter.pl    Opening with zcat inputfile: $inputfile\n" if $DEBUG;
	my $pipe_command = "zcat $inputfile |";
	open(FILE, $pipe_command) or die "Can't open inputfile: $inputfile\n"
}
else
{
	print "nFilter.pl    Opening normally inputfile: $inputfile\n" if $DEBUG;
	open(FILE, $inputfile) or die "Can't open input file: $inputfile\n";	
}


#### OPEN MATE INPUT FILE IF paired IS DEFINED
my $matefile = $inputfile;
$matefile =~ s/_1\./_2\./;
print "trimRead.pl    matefile: $matefile\n" if $DEBUG;
if ( defined $paired )
{
	#### OPEN FILE AND SET RECORD SEPARATOR
	if( $inputfile =~ /\.gz$/ or $inputfile =~ /\.zip$/ )
	{
		my $pipe_command = "zcat $inputfile |";
		open(MATEFILE, $pipe_command) or die "Can't open matefile: $matefile\n";
	}
	else
	{
		open(MATEFILE, "$matefile") or die "Can't open matefile: $matefile";
	}
}


#### OPEN OUTFILE
open(OUTFILE, ">$outputfile") or die "Can't open outputfile: $outputfile\n";

#### OPEN REJECT FILE
open(REJECT, ">$rejectfile") or die "Can't open rejectfile: $rejectfile\n";

#### OPEN MATE OUTPUT FILE IF paired IS DEFINED
my $mateoutfile = $outputfile;
$mateoutfile =~ s/_1\./_2\./;
print "trimRead.pl    mateoutfile: $mateoutfile\n" if $DEBUG;
open(MATEOUTFILE, ">$mateoutfile") or die "Can't open mateoutfile: $mateoutfile" if defined $paired;

#### OPEN MATE OUTPUT FILE IF paired IS DEFINED
my $mate_rejectfile = $rejectfile;
$mate_rejectfile =~ s/_1\./_2\./;
print "trimRead.pl    mate_rejectfile: $mate_rejectfile\n" if $DEBUG;
open(MATEREJECT, ">$mate_rejectfile") or die "Can't open mate_rejectfile: $mate_rejectfile" if defined $paired;


$/ = "\n";
my $counter = 0;
while ( <FILE> )
{    
	print "$counter\n" if $counter % $dot == 0;
	$counter++;

	#### GET FOUR LINES
	my $sequence_header = $_;
	my $sequence = <FILE>;
	my $quality_header = <FILE>;
	my $quality = <FILE>;

	print "sequence_header not defined \n" and last if not defined $sequence_header;
	print "sequence not defined \n" and last if not defined $sequence;
	print "quality_header not defined \n" and last if not defined $quality_header;
	print "quality_header not defined \n" and last if not defined $quality_header;
	
	print "sequence header: $sequence_header" if $DEBUG;
	print "quality header: $quality_header" if $DEBUG;
	print "sequence: $sequence, length: ", length($sequence), "\n" if $DEBUG;
	print "quality:  $quality, length: ", length($quality), "\n" if $DEBUG;


	#### DO MATEFILE IF paired IS DEFINED		
	my $mate_sequence_header;
	my $mate_sequence;
	my $mate_quality_header;
	my $mate_quality;
	if ( defined $paired )
	{
		$mate_sequence_header = <MATEFILE>;
		$mate_sequence = <MATEFILE>;
		$mate_quality_header = <MATEFILE>;
		$mate_quality = <MATEFILE>;
	
		#print "mate sequence header: $mate_sequence_header" if $DEBUG;
		#print "mate quality header: $mate_quality_header" if $DEBUG;
		#print "mate sequence: $mate_sequence, length: ", length($mate_sequence), "\n" if $DEBUG;
		#print "mate quality:  $mate_quality, length: ", length($mate_quality), "\n" if $DEBUG;	
	}
	
	#### NEXT IF 'N' FOUND IN SEQUENCE OR EITHER MATE SEQUENCE IF PAIRED
	if ( $sequence =~ /N/ 
		or (defined $paired and $mate_sequence =~ /N/) ) 
	{
		#print "nFilter.pl    sequence contains Ns\n";
		#print "nFilter.pl    mate_sequence contains Ns\n";
		#print "nFilter.pl    $sequence_header$sequence$sequence_header$quality\n";
		print REJECT "$sequence_header$sequence$quality_header$quality";
		print MATEREJECT "$mate_sequence_header$mate_sequence$mate_quality_header$mate_quality" if defined $paired;
	}
	else
	{
		print OUTFILE "$sequence_header$sequence$quality_header$quality";
		print MATEOUTFILE "$mate_sequence_header$mate_sequence$mate_quality_header$mate_quality" if defined $paired;
		#print "MATEFILE:\n$mate_sequence_header$mate_sequence$mate_sequence_header$mate_quality" if defined $paired;
	}

	#last if $counter >= 100000;
}
close(FILE) or die "Can't close inputfile: $inputfile\n" if $inputfile !~ /\.zip$/ and $inputfile !~ /\.gz$/;
close(MATEFILE) or die "Can't close matefile: $matefile\n" if defined $paired and $matefile !~ /\.zip$/ and $matefile !~ /\.gz$/;
close(OUTFILE) or die "Can't close outputfile: $outputfile\n";
close(MATEOUTFILE) or die "Can't close mateoutfile: $mateoutfile\n" if defined $paired;
close(REJECT) or die "Can't close rejectfile: $rejectfile\n" if defined $paired;
close(MATEREJECT) or die "Can't close rejectfile: $rejectfile\n" if defined $paired;

#### REPORT COMPLETED
print "nFilter.pl    outputfile printed:\n\n$outputfile\n\n";
print "nFilter.pl    rejectfile printed:\n\n$rejectfile\n\n";

#### PRINT RUN TIME
my $runtime = Timer::runtime( $time, time() );
print "\nRun time: $runtime\n";
print "Completed $0\n";
print Util::datetime(), "\n";
print "****************************************\n\n\n";
exit;

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#									SUBROUTINES
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


sub usage
{
	print `perldoc $0`;

	exit;
}
