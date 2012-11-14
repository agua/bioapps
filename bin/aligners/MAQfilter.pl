#!/usr/bin/perl -w

#### DEBUG
my $DEBUG = 0;
#$DEBUG = 1;

#### TIME
my $time = time();
my $duration = 0;
my $current_time = $time;

=head2

    APPLICATION     MAQ
	    
    PURPOSE
  
        WRAPPER SCRIPT FOR RUNNING MAQ ASSEMBLY AND SNP PREDICTION

    INPUT

        1. ASSEMBLY DIRECTORY
        
        2. FASTA OR FASTQ INPUT FILES
        
    OUTPUT
    
        1. MAQ OUTPUT FILES IN ASSEMBLY DIRECTORY
        
    USAGE
    
    ./MAQ.pl <--inputfiles String> <--matefiles String> <--outputdir String>
        <--referencedir String> [--splitfile String] [--reads Integer] [--convert]
        [--clean] [--queue String] [--maxjobs Integer] [--cpus Integer] [--help]

    --inputfiles       :   Single FASTQ sequence file
    --matefiles        :   Single FASTQ mate pair file
    --outputdir       :   Create this directory and write output files to it
    --referencedir    :   Location of squashed genome reference files
    --splitfile       :    Location of file containing list of split input files
    --reads           :   Number of reads per sub-file
    --convert         :   Convert from Solexa to Sanger FASTQ ('pre1.3' or 'post-1.3')
							(NB: MUST USE for all Solexa data)
    --clean           :   Clean run (remove old splitfile)
    --queue           :   Cluster queue options
    --maxjobs            :   Max. number of concurrent cluster maxjobs
    --cpus            :   Max. number of cpus per job
    --help            :   print help info
    
    
	EXAMPLES


mkdir -p /p/NGS/syoung/base/pipeline/maq/sample1
cd /p/NGS/syoung/base/pipeline/maq/sample1

perl /nethome/bioinfo/apps/agua/0.4/bin/apps/MAQ.pl \
--convert \
--outputdir /p/NGS/syoung/base/pipeline/maq/sample1 \
--matefiles /nethome/bioinfo/data/sequence/demo/maq/inputs/s_1_2_sequence.100000.txt \
--inputfiles /nethome/bioinfo/data/sequence/demo/maq/inputs/s_1_1_sequence.100000.txt \
--referencedir /nethome/bioinfo/data/sequence/chromosomes/human-bfa \
--maxjobs 30 \
--reads 10000



cd /mihg/users/yedwards/.agua/Project1/Workflow1/sample1

perl /nethome/bioinfo/apps/agua/0.4/bin/apps/MAQ.pl \
--convert \
--outputdir /mihg/users/yedwards/.agua/Project1/Workflow1/sample1 \
--matefiles /nethome/bioinfo/data/sequence/demo/maq/inputs/s_1_2_sequence.100000.txt \
--inputfiles /nethome/bioinfo/data/sequence/demo/maq/inputs/s_1_1_sequence.100000.txt \
--referencedir /nethome/bioinfo/data/sequence/chromosomes/human-bfa \
--maxjobs 30 \
--reads 10000


=cut

use strict;

#### EXTERNAL MODULES
use Term::ANSIColor qw(:constants);
use Data::Dumper;
use Getopt::Long;
use FindBin qw($Bin);

#### USE LIBRARY
use lib "$Bin/../../../lib";	
use lib "$Bin/../../../lib/external";	

#### INTERNAL MODULES
use MAQ;
use Timer;
use Util;
use Conf::Agua;

##### STORE ARGUMENTS TO PRINT TO FILE LATER
my @arguments = @ARGV;
#print "MAQ.pl    Arguments: @arguments\n";

#### FLUSH BUFFER
$| =1;

#### SET MAQ LOCATION
my $conf = Conf::Agua->new(inputfile=>"$Bin/../../../conf/default.conf");
my $maq = $conf->getKey("agua", 'MAQ');
my $qstat = $conf->getKey("cluster", 'QSTAT');
my $qsub = $conf->getKey("cluster", 'QSUB'); #### /usr/local/bin/qsub

#### DEFAULT MAX FILE LINES (MULTIPLE OF 4 BECAUSE EACH FASTQ RECORD IS 4 LINES)
my $maxlines = 4000000;

#### GET OPTIONS
#### GENERAL
my $stdout;
my $inputfiles;
my $matefiles;
my $readfile;
my $outputdir;
my $reads;
my $referencedir;
my $splitfile;

#### MAQ-SPECIFIC
my $clean;			#### ONLY GENERATE SPLIT FILES IF THEY DON'T EXIST
my $label;
my $convert;		#### CONVERT FROM SOLEXA TO SANGER QUALITIES
my $verbose;
my $solexa = "post-1.3";

#### CLUSTER OPTIONS
my $tempdir = "/tmp";
my $cluster = "PBS";
my $queue = "-q gsmall";
my $maxjobs = 30;
my $cpus = 1;
my $sleep = 5;
my $parallel;
my $dot = 1;

my $help;
print "MAQ.pl    Use option --help for usage instructions.\n" and exit if not GetOptions (
	
	#### GENERAL
    'stdout=s' 		=> \$stdout,
    'inputfiles=s' 	=> \$inputfiles,
    'outputdir=s'	=> \$outputdir,
    'referencedir=s'=> \$referencedir,
    'splitfile=s' 	=> \$splitfile,
    'reads=i' 		=> \$reads,
    'clean' 		=> \$clean,
    'label=s' 		=> \$label,

	#### MAQ-SPECIFIC
    'convert=s' 	=> \$convert,	#### CONVERT pre-/post-GA Pipeline v1.3 TO SANGER FASTQ
    'matefiles=s' 	=> \$matefiles,	#### PAIRED END MATE

	#### CLUSTER
    'maxjobs=s' 	=> \$maxjobs,
    'cpus=i'        => \$cpus,
    'cluster=s' 	=> \$cluster,
    'queue=s' 		=> \$queue,
    'verbose' 		=> \$verbose,
    'tempdir=s' 	=> \$tempdir,
    'parallel' 		=> \$parallel,
    'help' 			=> \$help
);

#### SET NUMBER OF LINES IF reads OPTION WAS USED
$maxlines = $reads * 4 if defined $reads;

#### PRINT HELP
if ( defined $help )	{	usage();	}

#### CHECK INPUTS
die "inputfiles not defined (Use --help for usage)\n" if not defined $inputfiles;
die "outputdir not defined (Use --help for usage)\n" if not defined $outputdir;
die "referencedir file not defined (Use --help for usage)\n" if not defined $referencedir;

#### MAKE OUTPUT DIR IF NOT EXISTS
File::Path::mkpath($outputdir) if not -d $outputdir;
print "Could not create output directory: $outputdir\n" if not -d $outputdir;

#### PRINT TO STDOUT IF DEFINED stdout
print "Printing STDOUT to file:\n\n$stdout\n\n" if defined $stdout;
open(STDOUT, ">$stdout") or die "Can't open STDOUT file: $stdout\n" if defined $stdout;
open(STDERR, ">>$stdout") or die "Can't open STDOUT file: $stdout\n" if defined $stdout;

print "MAQ.pl    inputfiles: $inputfiles\n";
print "MAQ.pl    matefiles: $matefiles\n" if defined $matefiles;
print "MAQ.pl    outputdir: $outputdir\n";
print "MAQ.pl    referencedir: $referencedir\n";
print "MAQ.pl    convert: $convert\n" if defined $convert;

#### CHECK INPUTS
print "--convert type not supported: $convert (must be 'post-1.3' or 'pre1.3')\n" and exit if ( defined $convert and $convert !~ /^(post|pre)-1.3$/ );

#### GET REFERENCE FILES
chdir($referencedir) or die "Can't change to reference directory: $referencedir\n";
my @referencefiles = <*.bfa*>;
print "MAQ.pl    Quitting because no files found in directory: $referencedir\n" and exit if scalar(@referencefiles) == 0;

#### SORT BY NUMBER
@referencefiles = Util::sort_naturally(\@referencefiles);
print "MAQ.pl    referencefiles: @referencefiles\n";

#### DEBUG
@referencefiles = reverse @referencefiles;

#### PARTIALLY PARALLEL
if ( not defined $parallel )
{
	for my $referencefile ( @referencefiles )
	{
		next if $referencefile =~ /^[\.]+$/;
		my $runMaq = MAQ->new(
			{
				inputfiles 	=> $inputfiles,
				matefiles 	=> $matefiles,
				referencefile => "$referencedir/$referencefile",
				outputdir 	=> $outputdir,
				maxlines 	=> $maxlines,
				clean 		=> $clean,
				label 		=> $label,
				splitfile 	=> $splitfile,
				tempdir 	=> $tempdir,
				verbose 	=> $verbose,
	
				maxjobs 	=> $maxjobs,
				cpus        => $cpus,
				cluster 	=> $cluster,
				queue 		=> $queue,
				qstat 		=> $qstat,
				qsub 		=> $qsub,
				sleep 		=> $sleep,
				convert 	=> $convert,
				dot 		=> $dot,
				maq 		=> $maq
			}
		);
		
		$runMaq->run();
	
		#### DON'T REDO THE SPLIT FILES EVERY TIME
		$clean = 0;
	}
}

#### MASSIVELY PARALLEL
else
{
	my $runMaq = MAQ->new(
		{
			inputfiles 	=> $inputfiles,
			matefiles 	=> $matefiles,
			outputdir 	=> $outputdir,
			maxlines 	=> $maxlines,
			clean 		=> $clean,
			label 		=> $label,
			splitfile 	=> $splitfile,
			tempdir 	=> $tempdir,
			verbose 	=> $verbose,

			maxjobs 	=> $maxjobs,
			cpus        => $cpus,
			cluster 	=> $cluster,
			queue 		=> $queue,
			qstat 		=> $qstat,
			qsub 		=> $qsub,
			sleep 		=> $sleep,
			convert 	=> $convert,
			dot 		=> $dot,
			maq 		=> $maq
		}
	);

#print "runMaq: \n";
#print Dumper $runMaq;
#exit;
#

	#### CHECK INPUT FILES
	my $infiles;
	@$infiles = split ",", $inputfiles;
	my $mates;
	@$mates = split ",", $matefiles if defined $matefiles;

	#### CHECK FILES EXIST
	checkFiles($infiles);
	checkFiles($mates);
	
	#### STORE USAGE STATS
	my $total_usage = {};
	
	#### STORE DURATIONS
	my $durations = {};
	
	#### PRINT DURATION
	my $duration;
	print "MAQ.pl    ", Timer::current_datetime(), "    BEFORE convert reference\n";

	#### CONVERT REFERENCE FILES
	for my $referencefile ( @referencefiles )
	{
		next if $referencefile =~ /^[\.]+$/;

		#### SET REFERENCE BINARY FILE
		my $referencebinary = $referencefile;
		$referencebinary =~ s/\.[^\.]+?$/.bfa/;

		#### CONVERT REFERENCE FILE INTO BINARY FILE
		my $convert_command = $runMaq->convertReference($referencefile, $referencebinary);
		print `$convert_command` if defined $convert_command;
	}

	#### PRINT DURATION
	$durations->{convertreference} = Timer::runtime( $current_time, time() );
	$current_time = time();
	print "MAQ.pl    ", Timer::current_datetime(), "    $durations->{convertreference}    AFTER convert reference\n";

	#### DO SPLITFILES
	#### SET NAME OF FILE CONTAINING LIST OF SPLITFILES 
	if ( not defined $splitfile or not $splitfile )
	{
		$splitfile = "$outputdir/splitfiles";
		$runMaq->set_splitfile($splitfile);
	}
	#print "MAQ.pl    splitfile: $splitfile\n" if $DEBUG;
	
	#### SPLIT INPUT FILES INTO SMALLER 'SPLIT FILES'
	print "MAQ.pl    DOING split files\n";
	my $splitfiles = $runMaq->doSplitfiles($splitfile, $label);
	print "No splitfiles produced. Quitting\n" and exit if not defined $splitfiles or scalar(@$splitfiles) == 0;
	print "MAQ.pl::run    length splitfiles: ", scalar(@$splitfiles), "\n" if $DEBUG;
	#print "MAQ.pl    splitfiles: \n" if $DEBUG;
	#print Dumper @$splitfiles if $DEBUG;
	#print "\n" if $DEBUG;
	
	#### PRINT DURATION
	$durations->{splitfiles} = Timer::runtime( $current_time, time() );
	$current_time = time();
	print "MAQ.pl    ", Timer::current_datetime(), "    $durations->{splitfiles}    AFTER set splitfiles\n";

	###############################################
	#############	  CONVERT SOLEXA    ###########
	###############################################

	#### CONVERT SOLEXA SPLIT FILES TO SANGER-FORMAT FILES
	if ( defined $convert )
	{
		print "MAQ.pl    convert is defined. Doing conversion from Solexa to Sanger format FASTQ\n";

		my $jobs = [];

		my $counter = 0;
		foreach my $splitfile ( @$splitfiles )
		{
			$counter++;
			
			print "MAQ.pl    splitfile: @$splitfile\n" if $DEBUG;
			my $commandsHash = $runMaq->solToSangerCommands($splitfile);
			my $commands = $commandsHash->{commands};
			my $files = $commandsHash->{files};
			next if not defined $commands or scalar(@$commands) == 0;
	
			#### SET LABEL
			my $label = "sol2sang-$counter";
			
			#### SET JOB
			my $job = $runMaq->setJob($commands, $label, $outputdir);
			push @$jobs, $job;
		}

		print "MAQ.pl    length(jobs): ", scalar(@$jobs), "\n";
		
		#### RUN ALIGNMENT JOBS
		$runMaq->runJobs($jobs);

		#### GET USAGE STATISTICS
		my $convertsolexa_usage = $runMaq->usageStats($jobs);
		$total_usage->{convertsolexa} = $convertsolexa_usage;

		#### PRINT DURATION
		$durations->{convertsolexa} = Timer::runtime( $current_time, time() );
		$current_time = time();
		print "MAQ.pl    ", Timer::current_datetime(), "    $durations->{convertsolexa}    Completed conversion from Solexa to Sanger-format FASTQ\n";
	}

	###############################################
	#############	  CONVERT FASTQ	    ###########
	###############################################
	
	#### CONVERT .fastq FILES TO .bfq FORMAT
	print "MAQ.pl    Converting FASTQ to BFQ format\n";
	
	#### INITIALISE JOBS
	my $jobs = [];

	my $counter = 0;
	foreach my $splitfile ( @$splitfiles )
	{
		$counter++;
		
		my $commandsHash = $runMaq->fastqToBfqCommands($splitfile);
		my $commands = $commandsHash->{commands};

		next if not defined $commands or scalar(@$commands) == 0;

		#### SET LABEL
		my $label = "fstq2bfq-$counter";
		
		#### SET JOB
		my $job = $runMaq->setJob($commands, $label, $outputdir);
		push @$jobs, $job;
	}		

	#### RUN ALIGNMENT JOBS
	print "MAQ.pl    RUNNING ", scalar(@$jobs), " jobs...\n";
	$runMaq->runJobs($jobs);

	#### GET USAGE STATISTICS
	my $convertfastq_usage = $runMaq->usageStats($jobs);
	$total_usage->{convertfastq} = $convertfastq_usage;

	#### PRINT DURATION
	$durations->{convertfastq} = Timer::runtime( $current_time, time() );
	$current_time = time();
	print "MAQ.pl    ", Timer::current_datetime(), "    $durations->{convertfastq}    Completed conversion from .fastq to .bfq format";
	
	
	###############################################
	#############		ALIGNMENT		###########
	###############################################

	#### CHANGE SPLITFILE SUFFIXES TO .bfq
	foreach my $splitfile ( @$splitfiles )
	{
		$$splitfile[0] =~ s/\.fastq$/.bfq/;
		$$splitfile[1] =~ s/\.fastq$/.bfq/ if defined $$splitfile[1];
	}
#print "splitfiles:\n";
#print Dumper $splitfiles;
#exit;

	#### DO ALIGNMENTS AGAINST ALL REFERENCE FILES
	print "MAQ.pl    DO ALIGNMENTS against reference files\n";
	my $alignment_jobs = [];
	for my $referencefile ( @referencefiles )
	{
		next if $referencefile =~ /^[\.]+$/;
	
		$referencefile = "$referencedir/$referencefile";
		#print "MAQ.pl    referencefile: $referencefile\n" if $DEBUG;
		
		$runMaq->set_referencefile($referencefile);
		
		#### SET REFERENCE BINARY FILE
		my $referencebinary = $referencefile;
		$referencebinary =~ s/\.[^\.]+?$/.bfa/;
	
		#### SET REFERENCE
		my ($reference) = $referencefile =~ /([^\/]+)$/;
		$reference =~ s/\.bfa$//i;

		#### DO ALIGNMENTS FOR ALL SPLITFILES 
		my $counter = 0;
		foreach my $splitfile ( @$splitfiles )
		{
			$counter++;
			
			#### SET OUTPUT DIR TO SUBDIRECTORY CONTAINING SPLITFILE
			my ($basedir, $index) = $$splitfile[0] =~ /^(.+?)\/(\d+)\/([^\/]+)$/;

			#### SET *.map FILE
			my $outputdir = "$basedir/$reference";
			my $mapfile = "$outputdir/$index/out.map";

			#### GET ALIGNMENT COMMANDS FOR THIS REFERENCE FILE	
			my $commands = $runMaq->matchCommands($splitfile, $outputdir, $referencefile, $referencebinary, $mapfile);
			#print "MAQ.pl    Commands:\n";
			#print join "\n", @$commands;
			#print "\n";

			next if not defined $commands or scalar(@$commands) == 0;
			
			#### SET .sam FILE	
			my $samfile = "$outputdir/$index/out.sam";

			#### CONVERT .map FILE TO .sam FILE
			my $sam_command = $runMaq->maqToSamCommand($outputdir, $mapfile, $samfile);
	
			#### SET REFERENCE
			my ($reference) = $referencefile =~ /([^\/]+)\.bfa$/i;
	
			#### SET LABEL
			my $label = "$reference-$counter";
			
			#### SET JOB
			my $job = $runMaq->setJob($commands, $label, $outputdir);
			push @$alignment_jobs, $job;
		}
	}	
	print "MAQ.pl    length(alignment_jobs): ", scalar(@$alignment_jobs), "\n";

	#### RUN ALIGNMENT JOBS
	$runMaq->runJobs($alignment_jobs);
	
	#### GET USAGE STATISTICS
	my $alignment_usage = $runMaq->usageStats($alignment_jobs);
	$total_usage->{alignment} = $alignment_usage;

	#### PRINT DURATION
	$durations->{convertfastq} = Timer::runtime( $current_time, time() );
	$current_time = time();
	print "MAQ.pl    ", Timer::current_datetime(), "    $durations->{convertsolexa}    Completed alignments";


#	###############################################
#	#############		ALIGNMENT		###########
#	###############################################
#
#	#### CHANGE SPLITFILE SUFFIXES TO .bfq
#	foreach my $splitfile ( @$splitfiles )
#	{
#		$$splitfile[0] =~ s/\.fastq$/.bfq/;
#		$$splitfile[1] =~ s/\.fastq$/.bfq/ if defined $$splitfile[1];
#	}
##print "splitfiles:\n";
##print Dumper $splitfiles;
##exit;
#
#	#### DO ALIGNMENTS AGAINST ALL REFERENCE FILES
#	print "MAQ.pl    DO ALIGNMENTS against reference files\n";
#	my $alignment_jobs = [];
#	for my $referencefile ( @referencefiles )
#	{
#		next if $referencefile =~ /^[\.]+$/;
#	
#		$referencefile = "$referencedir/$referencefile";
#		#print "MAQ.pl    referencefile: $referencefile\n" if $DEBUG;
#		
#		$runMaq->set_referencefile($referencefile);
#		
#		#### SET REFERENCE BINARY FILE
#		my $referencebinary = $referencefile;
#		$referencebinary =~ s/\.[^\.]+?$/.bfa/;
#	
#		#### SET REFERENCE
#		my ($reference) = $referencefile =~ /([^\/]+)$/;
#		$reference =~ s/\.bfa$//i;
#
#
#		my $reference_counter = 0;
#		foreach my $referencefile ( @referencefiles )
#		{
#			print "Tophat::run    referencefile: $referencefile\n";
#			$reference_counter++;
#			print "Tophat::run    reference_counter: $reference_counter\n";
#			
#			#### CREATE A BATCH JOB TO RUN ALIGNMENTS FOR ALL SPLITFILES
#			my $batch_command = $self->tophatBatchCommand("$outputdir/$referencefile", "$reference/$referencefile", $splitfiles);
#			print "Tophat::run    batch_command: \n\n$batch_command\n\n\n" if defined $batch_command;
#
#
#
#	print "MAQ.pl    length(alignment_jobs): ", scalar(@$alignment_jobs), "\n";
#
#	#### RUN ALIGNMENT JOBS
#	$runMaq->runJobs($alignment_jobs);
#	
#	#### GET USAGE STATISTICS
#	my $alignment_usage = $runMaq->usageStats($alignment_jobs);
#	$total_usage->{alignment} = $alignment_usage;
#
#	#### PRINT DURATION
#	$durations->{alignment} = Timer::runtime( $current_time, time() );
#	$current_time = time();
#	print "MAQ.pl    ", Timer::current_datetime(), "    $durations->{alignment}    Completed alignments";
#
#
#	
#	###############################################
#	#############		  maq2sam		###########
#	###############################################
#
#
#	#### CONVERT .map FILES TO .sam FILES FOR EACH SPLIT FILE OUTPUT
#	my $maq2sam_jobs = [];
#	for my $referencefile ( @referencefiles )
#	{
#		next if $referencefile =~ /^[\.]+$/;
#	
#		$referencefile = "$referencedir/$referencefile";
#		#print "MAQ.pl    referencefile: $referencefile\n" if $DEBUG;
#
#		#### SET REFERENCE
#		my ($reference) = $referencefile =~ /([^\/]+)$/;
#		$reference =~ s/\.bfa$//i;
#		my $counter = 0;
#		foreach my $splitfile ( @$splitfiles )
#		{
#			$counter++;
#			
#			#### SET OUTPUT DIR TO SUBDIRECTORY CONTAINING SPLITFILE
#			my ($basedir, $index) = $$splitfile[0] =~ /^(.+?)\/(\d+)\/([^\/]+)$/;
#
#			#### SET .map FILE
#			my $outputdir = "$basedir/$reference";
#			my $mapfile = "$outputdir/$index/out.map";
#
#			#### SET .sam FILE	
#			my $samfile = "$outputdir/$index/out.sam";
#
#			#### CONVERT .map FILE TO .sam FILE
#			my $sam_command = $runMaq->maqToSamCommand($outputdir, $mapfile, $samfile);
#	
#			#### SET REFERENCE
#			my ($reference) = $referencefile =~ /([^\/]+)\.bfa$/i;
#	
#			#### SET LABEL
#			my $label = "$reference-$counter";
#			
#			#### SET JOB
#			my $job = $runMaq->setJob($commands, $label, $outputdir);
#			push @$maq2sam_jobs, $job;
#		}
#	}	
#	print "MAQ.pl    length(alignment_jobs): ", scalar(@$alignment_jobs), "\n";
#
#	#### RUN ALIGNMENT JOBS
#	$runMaq->runJobs($alignment_jobs);
#	
#	#### GET USAGE STATISTICS
#	my $alignment_usage = $runMaq->usageStats($alignment_jobs);
#	$total_usage->{maq2sam} = $alignment_usage;
#
#	#### PRINT DURATION
#	$durations->{maq2sam} = Timer::runtime( $current_time, time() );
#	$current_time = time();
#	print "MAQ.pl    ", Timer::current_datetime(), "    $durations->{maq2sam}    Completed alignments";
#



	###############################################
	#############	  PREDICT SNPS	    ###########
	###############################################
	
	#### GET COMMANDS TO MERGE MAPS AND PREDICT SNPS AND INDELS
	print "MAQ.pl    DOING snpCommands\n" if $DEBUG;
	my $snp_jobs = [];
	for my $referencefile ( @referencefiles )
	{
		next if $referencefile =~ /^[\.]+$/;
	
		$referencefile = "$referencedir/$referencefile";
		#print "MAQ.pl    referencefile: $referencefile\n" if $DEBUG;
		
		$runMaq->set_referencefile($referencefile);
		
		#### SET REFERENCE BINARY FILE
		my $referencebinary = $referencefile;
		$referencebinary =~ s/\.[^\.]+?$/.bfa/;

		my $commands = $runMaq->snpCommands($splitfiles, $referencefile, $referencebinary);

		#### SET REFERENCE
		my ($reference) = $referencefile =~ /([^\/]+)$/;
		$reference =~ s/\.bfa$//i;

		#### SET LABEL
		my $label = "$reference";

		#### GET LABEL, COMMANDS, ETC.
		my $job = $runMaq->setJob($commands, $label, $outputdir);	
		push @$snp_jobs, $job;
	}
	print "MAQ.pl    length(jobs): ", scalar(@$snp_jobs), "\n";

	#### RUN out.map MERGE AND SNP/INDEL CALLING JOBS
	$runMaq->runJobs($snp_jobs);

	#### PRINT DURATION
	$durations->{snp} = Timer::runtime( $current_time, time() );
	$current_time = time();
	print "MAQ.pl    ", Timer::current_datetime(), "    $durations->{convertsolexa}    Completed merges and SNP/indel calling";


	#### GET USAGE STATISTICS
	my $snp_usage = $runMaq->usageStats($snp_jobs);
	$total_usage->{snp} = $snp_usage;


	#### PRINT USAGE STATS
	my $usagefile = "$outputdir/USAGE.txt";
	printUsage($usagefile, $total_usage, $durations, \@arguments);
	
}	#	parallel


#### PRINT RUN TIME
my $runtime = Timer::runtime( $time, time() );
print "MAQ.pl    Run time: $runtime\n";
print "MAQ.pl    Completed $0\n";
print "MAQ.pl    ";
print Timer::current_datetime(), "\n";
print "MAQ.pl    ****************************************\n\n\n";
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


sub statValue
{	
	#my $self		=	shift;
	my $stats		=	shift;
	my $field		=	shift;
	my $operation 	=	shift;
	
my $DEBUG = 0;

	print "MAQ.pl::statValue    statValue(stats,field)\n" if $DEBUG;
	print "MAQ.pl::statValue    length stats: ", scalar(@$stats), "\n" if $DEBUG;
	print "MAQ.pl::statValue    field: $field\n" if $DEBUG;
	print "MAQ.pl::statValue    operation: $operation\n" if $DEBUG;
	
	return if not defined $stats or not @$stats;

	#print "MAQ.pl::statValue    stats[0]->{$field}:\n";
	#print Dumper $$stats[0]->{$field};
	#print "\n";
	
	my ($suffix) = $$stats[0]->{$field} =~ /^\s*[\d\.]+\s+(\S+)$/;
	$suffix = '' if not defined $suffix;
	print "MAQ.pl::statValue    suffix: $suffix\n" if $DEBUG;

	my $value = 0;
	$value = 99999999 if $operation eq "min";
	
	foreach my $stat ( @$stats )
	{
		next if not defined $stat->{$field};
		#print "MAQ.pl::statValue    stat:\n";
		#print Dumper $stat;

		$stat->{$field} =~ /^(\d+)/;

		if ( $operation eq "max" )
		{
			if ( $1 > $value )	{	$value = $1;	}
		}
		if ( $operation eq "min" )
		{
			if ( $1 < $value )	{	$value = $1;	}
		}
		if ( $operation eq "total" )
		{
			$value += $1;
		}
	}
	print "MAQ.pl::statValue    value: $value\n" if $DEBUG;

	return $value . $suffix;	
}

=head2

	SUBROUTINE		checkFiles
	
	PURPOSE
	
		CHECK INPUT FILES ARE ACCESSIBLE AND NON-EMPTY

=cut

sub checkFiles
{
	my $files	=	shift;

	#### SANITY CHECK
	foreach my $file ( @$files )
	{
		if ( $file !~ /\.(txt|fastq|bfq)$/ )
		{
			print "MAQ.pl::alignmentCommands     file must end in .txt, .fastq or .bfq\n";
			print "MAQ.pl::alignmentCommands    file: $file\n";
			exit;
		}
		if ( -z $file )
		{
			print "MAQ.pl::alignmentCommands     file is empty. Quitting.\n";
			exit;
		}
	}
}


=head2

	SUBROUTINE		printUsage
	
	PURPOSE
	
		CHECK INPUT FILES ARE ACCESSIBLE AND NON-EMPTY

=cut


sub printUsage
{

my $DEBUG = 1;

	print "MAQ.pl::printUsage    printUsage(usagefile, total_usage, durations, arguments)\n" if $DEBUG;

	my $usagefile		=	shift;
	my $total_usage		=	shift;
	my $durations		=	shift;
	my $arguments		=	shift;
	
	print "Printing USAGE file: $usagefile\n";
	my $headings = ['completed', 'reported', 'cputime', 'maxmemory', 'maxswap', 'maxprocesses', 'maxthreads', 'status', 'shellscript'];	
	my $types = ['convertsolexa', 'convertfastq', 'alignment', 'snp'];
	open(OUT, ">$usagefile") or die "Can't open usage file: $usagefile\n";	

	#### PRINT RUN TIME
	my $runtime = Timer::runtime( $time, time() );
	print OUT "MAQ.pl    Run time: $runtime\n";
	print OUT "MAQ.pl    Completed $0\n";
	print OUT "MAQ.pl    ";
	print OUT Timer::current_datetime(), "\n";
	print OUT "MAQ.pl    Command:\n";
	print OUT "$0 @$arguments\n";
	print OUT "MAQ.pl    ****************************************\n\n\n";
	print OUT "USAGE STATISTICS\n";
	print OUT "\n";
	
	#### PRINT USAGE FOR EACH TYPE
	foreach my $type ( @$types )
	{
		print OUT uc($type);
		print OUT $durations->{$type} if defined $durations->{$type};
		print OUT "\n";

		my $stats = $total_usage->{$type};
		if ( not defined $stats or not @$stats )
		{
			print OUT "\n";
			next;
		}

		#### PRINT MIN, MAX AND TOTAL
		my $fields = ['cputime', 'maxmemory', 'maxswap'];
		foreach my $field ( @$fields )
		{
			my $min = statValue($stats, $field, 'min');
			print OUT uc($field), " MIN: $min\n";

			my $max = statValue($stats, $field, 'max');
			print OUT uc($field), " MAX: $max\n";
	
			if ( $field eq "cputime" )
			{
				my $total = statValue($stats, $field, 'total');
				print OUT uc($field). " TOTAL: $total\n";
			}
		}

		#### PRINT HEADERS
		foreach my $heading ( @$headings )	{	print OUT "$heading\t";	}
		print OUT "\n";

		foreach my $stat ( @$stats )
		{
			foreach my $heading ( @$headings )
			{	
				print OUT "$stat->{$heading}\t";	
			}
			print OUT "\n";
		}
		print OUT "\n";
	}
	close(OUT) or die "Can't close usage file: $usagefile\n";
}
