#!/usr/bin/perl -w

#### DEBUG
my $DEBUG = 0;
#$DEBUG = 1;

#### TIME
my $time = time();
my $duration = 0;
my $current_time = $time;

=head2

    APPLICATION     realignBam

    PURPOSE
  
		REALIGN *bam FILE READS AROUND INDEL OR MISMATCH REGIONS AND
		
		OUTPUT TO A 'CLEANED' *bam FILE
	
	NOTES
	
		GATK REFERENCE:
		
		Unlike most mappers, the GATK IndelRealigner walker uses the full alignment context to determine whether an appropriate alternate reference (i.e. indel) exists and updates SAMRecords accordingly.
	
	
		THE PROCESS CONSISTS OF TWO STEPS:
		
			1. CREATE INDEL INTERVALS FILE

			Emit intervals for the Local Indel Realigner to target for cleaning.
			
			time /usr/local/java/bin/java \
			-jar /nethome/syoung/base/apps/gatk/1.0.4705/GenomeAnalysisTK.jar \
			-I aln.bam \
			-R $REF \
			-T RealignerTargetCreator \
			-U \
			-S SILENT \
			-o realignTargets.intervals

			2. REALIGN READS IN MERGED INTERVALS

			Perform local realignment of reads based on misalignments due to the presence of indels. 
			time /usr/local/java/bin/java \
			-jar /nethome/syoung/base/apps/gatk/1.0.4705/GenomeAnalysisTK.jar \
			-I aln.bam \
			-R $REF \
			-T IndelRealigner \
			-targetIntervals realignTargets.intervals \
			--out realigned.bam \
			-U \
			-S SILENT
		
	VERSION		0.01

	HISTORY
	
		0.01 CREATE TARGETS AND GENERATE CLEANED *bam FILE USING GATK
		
    INPUTS

        1. SORTED *bam FILE
        
        2. OUTPUT DIRECTORY LOCATION
        
    OUTPUTS
    
        1. 'TARGETS' FILE CONTAINING REGIONS WITH INDELS AND MISMATCHES
		
		2. CLEANED *bam FILE CONTAINING READS REALIGNED IN TARGET REGIONS
        
    USAGE
    
    ./realignBam.pl \
	<--inputdirs String>  <--outputdir String> \
	<--reference String> <--label Integer> \
    [--keep] [--queue String] [--maxjobs Integer] [--cpus Integer ][--help]
    
    --inputdirs	:   Comma-separated list of directories containing
	                         chr* subdirs
    --outputdir :   Create this directory and write output files to it
    --species   :   Name of the reference species (e.g., 'human', 'mouse')
    --label     :   Name to used to submit maxjobs to cluster
    --keep      :   Keep intermediate files
    --queue     :   Cluster queue options
    --maxjobs   :   Max. number of concurrent cluster maxjobs (DEFAULT: 30)
    --cpus      :   Max. number of cpus per job (DEFAULT: 4)
    --help      :   print help info

    EXAMPLES


perl /nethome/bioinfo/apps/agua/0.5/bin/apps/snp/realignBam.pl \
--binlevel 2 \
--filename hit.bam \
--inputdirs \
/scratch/syoung/base/pipeline/SRA/NA18507/SRP000239/sampled/200bp/chr22/maq/1,\
/scratch/syoung/base/pipeline/SRA/NA18507/SRP000239/sampled/200bp/chr22/maq/2,\
--outputdir /scratch/syoung/base/pipeline/SRA/NA18507/SRP000239/sampled/200bp/chr22/maq/realign \
--species human \
--label eland-realign \
--walltime 48 \
--cluster LSF \
--queue small \
--cpus 1 \
--maxjobs 1000 \
--clean \
--stdout /scratch/syoung/base/pipeline/SRA/NA18507/SRP000239/sampled/200bp/chr22/maq/realign/realignBam.binlevel2.out


=cut

use strict;

#### EXTERNAL MODULES
use Term::ANSIColor qw(:constants);
use Data::Dumper;
use Getopt::Long;
use FindBin qw($Bin);
use File::Path;
use File::Copy;

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
use SNP;
use FileTools;
use Timer;
use Util;
use Conf::Agua;

##### STORE ARGUMENTS TO PRINT TO FILE LATER
my @arguments = @ARGV;

#### FLUSH BUFFER
$| =1;

#### GET CONF 
my $conf = Conf::Agua->new(inputfile=>"$aguadir/conf/default.conf");
my $bowtie = $conf->getKey("agua", 'realignBam');
my $samtools = $conf->getKey("applications:aquarius-8", 'SAMTOOLS');
my $gatk = $conf->getKey("applications:aquarius-8", 'GATK');
my $java = $conf->getKey("applications:aquarius-8", 'JAVA');
my $cluster = $conf->getKey("agua", 'CLUSTERTYPE');
my $qstat = $conf->getKey("cluster", 'QSTAT');
my $qsub = $conf->getKey("cluster", 'QSUB'); #### /usr/local/bin/qsub

#### SET msub TO qsub FOR ARRAY JOB SUBMISSION
$qsub = "/usr/local/bin/qsub";

#### GET OPTIONS
# SPECIFIC
my $inputdirs;
my $outputdir;
my $referencedir;
my $species;
my $filename;
my $binlevel;
my $bindir;
my $params;
my $label;

# GENERAL
my $clean;
my $stdout;
my $keep;

# CLUSTER
my $maxjobs = 30;
my $sleep = 5;
my $verbose;
my $tempdir;
my $cpus = 1;
my $queue;
my $walltime = 24; #### WALL TIME IN HOURS (INTEGER)
my $dot = 1;
my $cleanup;

my $help;
if ( not GetOptions (

	#### GENERAL
    'inputdirs=s'  	=> \$inputdirs,
    'outputdir=s'   => \$outputdir,
    'species=s'   	=> \$species,
    'referencedir=s'=> \$referencedir,
    'filename=s' 	=> \$filename,
    'binlevel=s' 	=> \$binlevel,
    'bindir=s' 		=> \$bindir,
    'clean'        	=> \$clean,
    'stdout=s' 		=> \$stdout,

	#### SPECIFIC
    'label=s'       => \$label,
    'params=s'      => \$params,
    'keep'        	=> \$keep,

	#### CLUSTER
    'maxjobs=i'     => \$maxjobs,
    'cpus=i'        => \$cpus,
    'cluster=s' 	=> \$cluster,
    'queue=s'       => \$queue,
    'walltime=i'    => \$walltime,
    'sleep=s' 		=> \$sleep,
    'cleanup'       => \$cleanup,
    'verbose' 		=> \$verbose,
    'tempdir=s' 	=> \$tempdir,
    'help'          => \$help
	
) )
{ print "Use option --help for usage instructions.\n";  exit;    };

#### PRINT TO STDOUT IF DEFINED stdout
if ( defined $stdout )
{
	print "realignBam.pl    Printing STDOUT to stdoutfile:\n\n$stdout\n\n";

	my ($stdout_path) = $stdout =~ /^(.+)\/[^\/]+$/;
	File::Path::mkpath($stdout_path) if not -d $stdout_path;
	open(STDOUT, ">$stdout") or die "Can't open STDOUT file: $stdout\n" if defined $stdout;
}

#### PRINT HELP
if ( defined $help )	{	usage();	}

#### CHECK INPUTS
die "queue not defined (option --help for usage)\n" if not defined $queue;
die "inputdirs not defined (option --help for usage)\n" if not defined $inputdirs;
die "outputdir not defined (Use --help for usage)\n" if not defined $outputdir;
die "filename not defined (Use --help for usage)\n" if not defined $filename;

#### MAKE OUTPUT DIR IF NOT EXISTS
print "realignBam.pl    outputdir is a file: $outputdir\n" and exit if -f $outputdir;
File::Path::mkpath($outputdir) if not -d $outputdir;
print "realignBam.pl    Can't create output directory: $outputdir\n" and exit if not -d $outputdir;

#### IF NOT DEFINED referencedir, SET IT BASED ON SPECIES
if ( not defined $referencedir )
{
	my $basedir = $conf->getKey("data", uc($species));
	my $build = $conf->getKey("data", uc($species) . "LATESTBUILD");
	$referencedir = "$basedir/$build/fasta";
}
print "realignBam.pl    referencedir: $referencedir\n";
die "Can't find referencedir: $referencedir\n" if not -d $referencedir;


#### CHECK INPUT DIRS
my @indirs = split ",", $inputdirs;
foreach my $indir ( @indirs )
{   
    print "realignBam.pl    Can't find inputdir: $indir\n" and exit if not -d $indir;
}

#### DEBUG
print "realignBam.pl    inputdirs: $inputdirs\n";
print "realignBam.pl    outputdir: $outputdir\n";
print "realignBam.pl    cluster: $cluster\n";
print "realignBam.pl    params: $params\n" if defined $params;


#### RETRIEVE COMMAND
my $command = "$0 @arguments";

#### INSTANTIATE realignBam
my $snp = SNP->new(
	{
		#### SPECIFIC INPUTS
		inputdirs  	=> \@indirs,
		outputdir   => $outputdir,
		referencedir=> $referencedir,
		filename   	=> $filename,
		params   	=> $params,
		binlevel   	=> $binlevel,
		bindir   	=> $bindir,
		label       => $label,
		params      => $params,
		species     => $species,

		#### GENERAL INPUTS
		clean     	=> $clean,
		gatk		=> $gatk,
		java		=> $java,
		samtools	=> $samtools,

		#### CLUSTER (PRESETS AND USER)
		command		=> $command,
		cluster 	=> $cluster,
		queue 		=> $queue,
		walltime 	=> $walltime,
		cpus        => $cpus,
		qstat 		=> $qstat,
		qsub        => $qsub,
		maxjobs     => $maxjobs,
		sleep       => $sleep,
		cleanup     => $cleanup,
		verbose 	=> $verbose,
		tempdir 	=> $tempdir,
		dot         => $dot
	}
);
	
#### RUN RNA PAIRED TRANSCRIPTOME ANALYSIS
print "realignBam.pl    Doing realignBam()\n";
$snp->realignBam();

#### PRINT RUN TIME
my $runtime = Timer::runtime( $time, time() );
print "realignBam.pl    Run time: $runtime\n";
print "realignBam.pl    Completed $0\n";
print "realignBam.pl    ";
print Timer::datetime(), "\n";
print "realignBam.pl    ****************************************\n\n\n";
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


