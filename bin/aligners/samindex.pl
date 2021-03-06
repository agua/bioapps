#!/usr/bin/perl -w

#### DEBUG
my $DEBUG = 0;
#$DEBUG = 1;

#### TIME
my $time = time();

=head2

    APPLICATION     samindex
	    
    VERSION         0.01

    PURPOSE
  
        CREATE SAMTOOLS INDEX FILES FOR ALL .fa FILES IN THE SUPPLIED DIRECTORY

    INPUT

        1. DIRECTORY CONTAINING .fa FILES
        
    OUTPUT
    
        1. PRINT TO THE INPUT DIRECTORY .fai AND fa.fai FILES CONTAINING SAMTOOLS
		
			INDEX INFORMATION WITH LABELS 'chromosome' AND 'chromosome.fa',
			
			RESPECTIVELY
		
    USAGE
    
    ./samindex.pl <--inputdir String> [--help]
    
		--inputdir				:   Full path to directory containing .fa files
		--help                 	:   print help info

    EXAMPLES

chmod 755 /nethome/bioinfo/apps/agua/0.4/bin/apps/samindex.pl
/nethome/bioinfo/apps/agua/0.4/bin/apps/samindex.pl \
--inputdir /nethome/bioinfo/data/sequence/chromosomes/mouse/mm9/bowtie \
--outputdir /nethome/bioinfo/data/sequence/chromosomes/mouse/mm9/samtools

=cut

use strict;

#### EXTERNAL MODULES
use Term::ANSIColor qw(:constants);
use Data::Dumper;
use Getopt::Long;
use File::Path;
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
use Util;
use Conf::Agua;

#### SET MAQ LOCATION
my $conf = Conf::Agua->new(inputfile=>"$aguadir/conf/default.conf");
my $samtools = $conf->getKey("applications:aquarius-8", 'SAMTOOLS');

#### GET OPTIONS
my $inputdir;
my $outputdir;
my $help;
if ( not GetOptions (
	
	#### GENERAL
    'inputdir=s' 	=> \$inputdir,
    'outputdir=s' 	=> \$outputdir,
    'help' 			=> \$help
) )
{ print "samindex.pl    Use option --help for usage instructions.\n";  exit;    };

#### PRINT HELP
if ( defined $help )	{	usage();	}

#### CHECK INPUTS
die "Input directory not defined (Use --help for usage)\n" if not defined $inputdir;
print "samindex.pl    inputdir: $inputdir\n";
print "samindex.pl    outputdir: $outputdir\n";

#### MAKE OUTPUT DIR IF NOT EXISTS
print "samindex.pl    Output directory is a file: $outputdir\n" and exit if -f $outputdir;
File::Path::mkpath($outputdir) if not -d $outputdir;
print "samindex.pl    Can't create output directory: $outputdir\n" if not -d $outputdir;

#### GET input FILES
chdir($inputdir) or die "Can't change to input directory: $inputdir\n";
my @inputfiles = <*.fa>;
print "samindex.pl    Quitting because no files found in directory: $inputdir\n" and exit if scalar(@inputfiles) == 0;

#### SORT BY NUMBER
@inputfiles = Util::sort_naturally(\@inputfiles);

#### DEBUG
@inputfiles = reverse @inputfiles;
print "samindex.pl    inputfiles: @inputfiles\n";

#### CHANGE TO INPUT DIR

foreach my $inputfile ( @inputfiles )
{
	my $outputfile = "$inputfile.fai";
	print "samindex.pl    outputfile: $outputfile\n";

	#### DO INDEX COMMAND
	my $command = "$samtools/samtools faidx $inputfile";
	print "samindex.pl    command: $command\n" if $DEBUG;
	`$command`;

	#### MOVE TO OUTPUT DIR IF DIFFERENT FROM INPUT DIR
	if ( $inputdir ne $outputdir )
	{
		`mv $inputdir/$outputfile $outputdir/$outputfile`;
	}

	#### COPY TO chromosome.fai FILE
	my $safefile = $outputfile;
	$safefile =~ s/\.fa\././;
	print "samindex.pl    safefile: $safefile\n" if $DEBUG;
	`cp $outputdir/$outputfile $outputdir/$safefile`;
	
	#### ADD '.fa' TO CHROMOSOME NAME IN .fa.fai FILE
	open(FILE, "$outputdir/$outputfile") or die "Can't open output file: $outputdir/$outputfile\n";
	my @lines = <FILE>;
	close(FILE);
	print "samindex.pl    lines: @lines\n" if $DEBUG;
	
	#### PRINT CHANGES TO TEMP FILE
	my $tempfile = "$outputfile.temp";
	print "samindex.pl    tempfile:$tempfile\n" if $DEBUG;
	open(TEMP, ">$outputdir/$tempfile") or die "Can't open temp file: $outputdir/$tempfile\n";
	foreach my $line ( @lines )
	{
		$line =~ s/^(\S+)(.+)$/$1.fa$2/;
		print "samindex.pl    line:$line\n" if $DEBUG;
		
		print TEMP $line;
	}
	close(TEMP);
	
	#### MOVE TEMP TO OUTPUT FILE
	`mv $outputdir/$tempfile $outputdir/$outputfile`;
}




#cd /nethome/bioinfo/data/sequence/chromosomes/human-fa
#
#/nethome/syoung/base/apps/samtools/0.1.6/samtools faidx chr1.fa
#
#WHICH CREATES FILES LIKE THIS:
#
#cat /nethome/bioinfo/data/sequence/chromosomes/human-fa/chr1.fa.fai
#    
#    chr1.fa 247249719       6       50      51
#
#cat /nethome/bioinfo/data/sequence/chromosomes/human-fa/chr2.fa.fai
#
#    chr2    242951149       6       50      51
#
#
#REPLACE chr1 WITH chr1.fa IN INDEX FILES TO AVOID THIS ERROR WHEN GENERATING BAM FILE:
#
#    [sam_read1] reference 'chr1.fa' is recognized as '*'.
#
#
#cd /nethome/bioinfo/data/sequence/chromosomes/human-fa
#cp chr1.fa.fai chr1.fai
#
#CONVERT WITH sed
#
#cat chr2.fa.fai
#    
#    chr2    242951149       6       50      51
#
#sed -e 's/\(chr[A-Z0-9]*\)/\1.fa/' chr2.fa.fai 
#    
#    chr2.fa 242951149       6       50      51
#
#
#sed -e 's/\(chr[A-Z0-9]*\)/\1.fa/' < chr1.fa.fai > TMP; mv -f TMP  chr1.fa.fai


#### PRINT RUN TIME
my $runtime = Timer::runtime( $time, time() );
print "\nRun time: $runtime\n";
print "Completed $0\n";
print Timer::datetime(), "\n";
print "****************************************\n\n\n";
exit;

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#									SUBROUTINES
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


=head2

	SUBROUTINE		set_parameter
	
	PURPOSE
	
		SET THE VALUE OF A PARAMETER IN arguments

=cut

sub set_parameter
{	
	my $arguments		=	shift;
	my $parameter			=	shift;
	my $value			=	shift;

	#my $DEBUG = 1;
	print "samindex.pl::set_parameter    samindex.pl::set_parameter(arguments, parameter, value)\n" if $DEBUG;
	print "samindex.pl::set_parameter    parameter: $parameter\n" if $DEBUG;
	print "samindex.pl::set_parameter    value: $value\n" if $DEBUG;
	
	for ( my $i = 0; $i < @$arguments; $i++ )
	{
		if ( "--$parameter" eq $$arguments[$i] )
		{
			$$arguments[$i + 1] = $value;
			return $arguments;
		}	
	}
	
	return $arguments;
}



=head2

	SUBROUTINE		fill_in
	
	PURPOSE
	
		SUBSTITUTE counter FOR ONE OR MORE '%COUNTER%' STRINGS IN ALL ARGUMENTS

=cut

sub fill_in
{	
	my $arguments		=	shift;
	my $pattern			=	shift;
	my $value			=	shift;
	
	#my $DEBUG = 1;
	print "samindex.pl::fill_in    samindex.pl::fill_in(arguments, value)\n" if $DEBUG;
	print "samindex.pl::fill_in    arguments:\n" if $DEBUG;
	print join "\n", @$arguments if $DEBUG;
	print "\n";
	print "samindex.pl::fill_in    value: $value\n" if $DEBUG;
	
	foreach my $argument ( @$arguments )
	{
		$argument =~ s/$pattern/$value/ig;
	}

	return $arguments;
}


=head2

	SUBROUTINE		get_argument
	
	PURPOSE
	
		EXTRACT AN ARGUMENT FROM THE ARGUMENT ARRAY AND RETURN IT 

=cut

sub get_argument
{	
	my $arguments		=	shift;
	my $name			=	shift;

#my $DEBUG = 1;
print "samindex.pl::get_argument    samindex.pl::get_argument(arguments, name)\n" if $DEBUG;
print "samindex.pl::get_argument    arguments:\n" if $DEBUG;
print join "\n", @$arguments if $DEBUG;
print "\n";
print "samindex.pl::get_argument    name: $name\n" if $DEBUG;

	
	my $argument;
	for ( my $i = 0; $i < @$arguments; $i++ )
	{
		if ( "--$name" eq $$arguments[$i] )
		{
			$argument = $$arguments[$i + 1];
			splice @$arguments, $i, 2;
			return $argument;
		}
	}
	
	return;
}



sub usage
{
	print GREEN;
	print `perldoc $0`;
	print RESET;
	exit;
}


