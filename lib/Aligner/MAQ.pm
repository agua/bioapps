use Getopt::Simple;
use MooseX::Declare;
use MooseX::UndefTolerant::Attribute;
  
=head2

		PACKAGE		ELAND
		
		PURPOSE
		
	        WRAPPER SCRIPT FOR RUNNING ELAND SEQUENCE ALIGNMENT
			
=cut

#### EXTERNAL MODULES
use FindBin qw($Bin);

#### USE LIB
use lib "$Bin/..";

#### USES ROLES
use Agua::Cluster::Checker;
use Agua::Cluster::Jobs;

use strict;
use warnings;
use Carp;

our $VERSION = 0.01;

class Aligner::MAQ with (Agua::Cluster::Jobs,
	Agua::Cluster::Checker,
	Agua::Cluster::Util,
	Agua::Cluster::Convert,
	Agua::Cluster::Merge,
	Agua::Cluster::Sort,
	Agua::Cluster::Usage,
	Agua::Common::Util,
	Agua::Common::SGE) {

use Agua::DBaseFactory;
use Agua::DBase::MySQL;
use Conf::Agua;

# BOOLEAN
has 'clean'		=> ( isa => 'Bool|Undef', is => 'rw', default => '' );

# INTS
has 'walltime'	=> ( isa => 'Int|Undef', is => 'rw', default => 24 );

# STRINGS
has 'username'  => ( isa => 'Str|Undef', is => 'rw' );
has 'cluster'	=> ( isa => 'Str|Undef', is => 'rw' );
has 'splitfile'	=> ( isa => 'Str|Undef', is => 'rw' );
has 'tempdir'	=> ( isa => 'Str|Undef', is => 'rw' );
has 'clustertype'=> ( isa => 'Str|Undef', is => 'rw' );

has 'maq'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'referencedir'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'outputdir'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'replicates'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'label'			=> ( isa => 'Str|Undef', is => 'rw', default => '' );
#has 'splitfiles'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'cluster'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );

has 'check'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'inputfiles'=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'matefiles'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'distance'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'params'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'sequencedir'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'rundir'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'maxlines'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'chunks'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'clean'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'keep'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'readhits'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'referencedir'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'species'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'subdirs'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
#has 'inputtype'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
#has 'pairparams'=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'quality'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'seedlength'=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'samtools'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'samtoolsindex'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'lane'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'firstlane'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'convert'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );

# OBJECTS
has 'splitfiles'=> ( isa => 'ArrayRef|Undef', is => 'rw' );
has 'conf' 	=> (
	traits => [ qw(MooseX::UndefTolerant::Attribute)],
	is =>	'rw',
	isa => 'Conf::Agua'
	#,
	#default	=>	sub { Conf::Agua->new(	backup	=>	1, separator => "\t"	);	}
);
has 'db'	=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );

##### INTERNAL MODULES
#use Agua::Cluster::Util;

#### EXTERNAL MODULES
use Data::Dumper;
use File::Path;
use File::Remove;

#### DEBUG
our $DEBUG = 0;
#$DEBUG = 1;

#/////}
	
sub BUILD {
	my $self	=	shift;

	#my $DEBUG = 1;
	print "Aligner::MAQ::BUILD    Aligner::MAQ::BUILD()\n" if $DEBUG;
	#print "Aligner::MAQ::BUILD    self:\n" if $DEBUG;
	#print Dumper $self if $DEBUG;

	print "Aligner::MAQ::BUILD    Doing self->setDbh()\n" if $DEBUG;
	$self->setDbh();
}



=head2
	
	SUBROUTINE		run
	
	PURPOSE
	
		1. CHECK INPUT MATE PAIR FILES
		
		2. DO MAQ ALIGNMENT AND SNP CALLS

			- LOCALLY (IN SERIES)

 			- ON CLUSTER (IN PARALLEL)
	
=cut

sub run {				#### DO ALIGNMENT
	my $self			=	shift;

	my $DEBUG = 1;
	print "MAQ::run    MAQ::run()\n" if $DEBUG;

	#### FILES AND DIRS	
	my $referencedir 	=	$self->referencedir();
	my $outputdir 		=	$self->outputdir();
	my $inputfiles 		=	$self->inputfiles();
	my $matefiles 		=	$self->matefiles();

	#### RUN LOCALLY OR ON CLUSTER
	my $cluster 		=	$self->cluster();
	$cluster = '' if not defined $cluster;

	#### CHECK INPUT FILES EXIST AND NOT EMPTY
	my @infiles = split ",", $inputfiles;
	my @mates = split ",", $matefiles if defined $matefiles;
	checkFiles(\@infiles);
	checkFiles(\@mates);

	#### GET LABEL, SPLIT FILES, CONVERT
	my $label 			=	$self->label();
	my $splitfile 		=	$self->splitfile();
	my $convert 		=	$self->convert();

	#### SET DEFAULT SPLITFILE IF NOT DEFINED
	$splitfile = "$outputdir/splitfile.txt" if not defined $splitfile;
	print "MAQ::runBatchDoAlignment    splitfile: $splitfile\n" if $DEBUG;

	###############################################
	###########   SET REFERENCE NAMES    ##########
	my $references = $self->listReferenceSubdirs($referencedir);
	print "MAQ::run    references: @$references\n";

	##############################################
	############	SPLIT INPUT FILES   ###########
	##############################################
	print "MAQ::run    Doing doSplitfiles()  ", Timer::current_datetime(), "\n";
	my $splitfiles = $self->doSplitfiles($splitfile, $label);
	print "MAQ::run    After doSplitfiles()  ", Timer::current_datetime(), "\n";
	print "MAQ::run    length splitfiles: ", scalar(@$splitfiles), "\n" if $DEBUG;
	
	##############################################
	####     CONVERT SOLEXA TO SANGER FASTQ   #####
	###############################################
	print "MAQ::run    Doing solexaToSanger  ", Timer::current_datetime(), "\n" if defined $convert;
	$self->solexaToSanger($splitfiles) if defined $convert;
	print "MAQ::run    After solexaToSanger  ", Timer::current_datetime(), "\n" if defined $convert;
	
	###############################################
	############# CONVERT FASTQ TO BFQ  ###########
	###############################################
	print "MAQ::run    Doing fastqToBfq      ", Timer::current_datetime(), "\n";
	$self->fastqToBfq($splitfiles, $outputdir, $label);
	print "MAQ::run    After fastqToBfq      ", Timer::current_datetime(), "\n";

	###############################################
	#############     MAQ ALIGNMENT     ###########
	###############################################
	print "MAQ::run    Doing doBatchAlignment()   ", Timer::current_datetime(), "\n";
	print "MAQ::run    Doing alignment()    ", Timer::current_datetime(), "\n";
	$self->doBatchAlignment($outputdir, $referencedir, $references, $splitfiles, $label) if $cluster;
	$self->doAlignment($outputdir,  $referencedir, $references, $splitfiles, $label) if not $cluster;

	#$self->doBatchAlignment($splitfiles, $referencedir, $outputdir, $label);
	print "MAQ::run    After doBatchAlignment()   ", Timer::current_datetime(), "\n";

	####################################################################
	#### CONVERT SUBDIR-LEVEL out.map TO out.sam ---> mergeSam
	####################################################################

	################################################
	######     CONVERT out.map TO out.sam     ######
	################################################
	print "MAQ::run    Doing mapToSam        ", Timer::current_datetime(), "\n";
	$self->subdirMapToSam($outputdir, $references, $splitfiles, "out.map", "hit.sam");
	print "MAQ::run    After mapToSam        ", Timer::current_datetime(), "\n";

#### ????? NECESSARY ?????

	###############################################
	######        FILTER SAM HITS          ######
	###############################################
	print "MAQ::run    Doing subdirSamHits        ", Timer::current_datetime(), "\n";
	$self->subdirSamHits($outputdir, $references, $splitfiles, "out.sam", "hit.sam", "miss.sam");
	print "MAQ::run    After subdirSamHits        ", Timer::current_datetime(), "\n";


	################################################
	######        CUMULATIVE MERGE SAM        ######
	################################################
	print "MAQ::run    Doing cumulativeMergeSam        ", Timer::current_datetime(), "\n";
	$self->cumulativeMergeSam($outputdir, $references, $splitfiles, "hit.sam", "hit.sam");
	print "MAQ::run    After cumulativeMergeSam        ", Timer::current_datetime(), "\n";
	
	##############################################
	#########    CONVERT SAM  TO BAM   ###########
	##############################################
	print "MAQ::run    Doing samToBam     ", Timer::current_datetime(), "\n";
	$self->samToBam($outputdir, $references, "hit.sam", "hit.bam");
	print "MAQ::run    After samToBam     ", Timer::current_datetime(), "\n";

}	# run

sub doAlignment {
	my $self			=	shift;
	my $outputdir 		=	shift;
	my $referencedir 	=	shift;
	my $references		=	shift;
	my $splitfiles 		=	shift;
	my $label 			=	shift;

my $DEBUG = 1;

	print "MAQ::doAlignment    MAQ::doAlignment(outputdir, referencedir, splitfiles, label)\n" if $DEBUG;
	print "MAQ::doAlignment    outputdir: $outputdir\n" if $DEBUG;
	print "MAQ::doAlignment    referencedir: $referencedir\n" if $DEBUG;
	print "MAQ::doAlignment    splitfiles: $splitfiles\n" if $DEBUG;
	print "MAQ::doAlignment    label: $label\n" if $DEBUG;

	#### GET REQUIRED VARIABLES
	my $casava = $self->casava();
	print "MAQ::doAlignment    casava: $casava\n" if $DEBUG;
	print "MAQ::doAlignment    casava not defined. Exiting\n" and exit if not defined $casava;
	my $inputtype = $self->inputtype();
	print "MAQ::doAlignment    inputtype: $inputtype\n" if $DEBUG;
	print "MAQ::doAlignment    inputtype not defined. Exiting\n" and exit if not defined $inputtype;

	#### GET MAQ
	my $maq 		= $self->maq();
	
	#### GET OPTIONAL VARIABLES
	my $params 		= $self->params();
	my $quality 	= $self->quality();

	#### COLLECT ALL JOBS FOR EACH INPUT FILE AGAINST ALL REFERENCE FILES
	my $jobs = [];

	foreach my $reference ( @$references )
	{
		#### DO ALIGNMENTS FOR ALL SPLITFILES 
		my $counter = 0;
		foreach my $splitfile ( @$splitfiles )
		{
			$counter++;
		
			#### SET OUTPUT DIR TO SUBDIRECTORY CONTAINING SPLITFILE
			my $infile = $$splitfile[0];
			my $mate = $$splitfile[1];
			my ($basedir, $index) = $$splitfile[0] =~ /^(.+?)\/(\d+)\/([^\/]+)$/;
			my $outdir = "$outputdir/$reference/$index";
			File::Path::mkpath($outdir) if not -d $outdir;
			print "MAQ::doAlignment    outdir: $outdir\n" if $DEBUG;
	
			#### SET INPUT .bfq FILE(S)
			my $inputbinaries;
			$infile =~ s/(fq|fastq)$/bfq/;
			$mate =~ s/(fq|fastq)$/bfq/ if defined $mate;
			push @$inputbinaries, $infile;
			push @$inputbinaries, $mate if defined $mate;
	
			#### MOVE TO OUTPUT DIR
			chdir($outdir) or die "Can't chdir to outdir: $outdir\n";		

			#### SET UNIQUE *outerr.txt FILE FOR EACH REFERENCE ALIGNMENT
			my $outerrfile = "$outdir/maq-$reference-outerr.txt";
		
			#### SET UNIQUE OUTERR FILE FOR EACH REFERENCE ALIGNMENT
			my $mapfile = "$outdir/out.map";

			#### GET REFERENCE NAME
			my $referencebinary = "$referencedir/$reference.bfa";
			print "MAQ::batchCommand    referencebinary: $referencebinary\n" if $DEBUG;

			my $command = qq{time $maq/maq match $params $mapfile $referencebinary @$inputbinaries  &> $outerrfile};
	
			#### SET LABEL
			my $label = "$label-$counter";
			$label =~ s/\///;
			
			#### SET JOB
			my $job = $self->setJob( [ $command ], $label, $outdir);
			push @$jobs, $job;
		}
	}


#print "MAQ::run    length(jobs): ", scalar(@$jobs), "\n";
#print Dumper $$jobs[0];
#exit;


	#### RUN ALIGNMENT JOBS
	$self->runJobs($jobs, $label);
}


sub doBatchAlignment {
	my $self			=	shift;
	my $outputdir		=	shift;
	my $referencedir 	=	shift;
	my $references		=	shift;
	my $splitfiles		=	shift;	
	my $label			=	shift;

#my $DEBUG = 1;
	print "MAQ::doBatchAlignment    MAQ::doBatchAlignment(splitfiles, referencedir, outputdir)\n" if $DEBUG;

	#### GET REFERENCE FILES
	my $referencefiles = $self->listReferenceFiles($referencedir, "\*.bfa");
	@$referencefiles = reverse @$referencefiles;

	#### CHANGE SPLITFILE SUFFIXES TO .bfq
	foreach my $splitfile ( @$splitfiles )
	{
		$$splitfile[0] =~ s/\.fastq$/.bfq/;
		$$splitfile[1] =~ s/\.fastq$/.bfq/ if defined $$splitfile[1];
	}

	#### COLLECT ALL JOBS FOR EACH INPUT FILE AGAINST ALL REFERENCE FILES
	my $jobs = $self->generateBatchJobs($outputdir, $referencefiles, $splitfiles, $label);
	print "MAQ::doBatchAlignment    length(jobs): ", scalar(@$jobs), "\n" if $DEBUG;
	print "MAQ::doBatchAlignment    No. jobs: ", scalar(@$jobs), "\n";

	#### RUN ALIGNMENT JOBS
	$self->runJobs($jobs, "doBatchAlignment");
}


=head2

	SUBROUTINE		batchCommand

	PURPOSE
	
		CREATE BATCH COMMAND WITH PLACEHOLDERS FOR TASK NUMBER

	INPUTS
		
		1. BASE OUTPUT DIRECTORY CONTAINING SUBDIR ALIGNMENTS
		
		2. PATH TO BINARY REFERENCE .bfa FILE
		
		3. ARRAY OF INPUT FILES, WHERE EACH ELEMENT IS A SHORT
		
			ARRAY OF ONE OR TWO FILES: READ AND ITS MATE IF AVAILABLE

=cut

sub batchCommand {
	my $self			=	shift;
	my $outputdir		=	shift;
	my $referencebinary	=	shift;
	my $splitfiles		=	shift;

#my $DEBUG = 1;
	print "MAQ::batchCommand    MAQ::batchCommand(outputfile, referencebinary, splitfiles)\n" if $DEBUG;
	print "MAQ::batchCommand    outputdir: $outputdir\n" if $DEBUG;
	print "MAQ::batchCommand    referencebinary: $referencebinary\n" if $DEBUG;

	#### GET LABEL FOR LATER USE TO GENERATE INPUTFILE NAMES
	my $label 			=	$self->label();	
	my $maq 			=	$self->maq();	
	my $params 			=	$self->params();
	$params = "" if not defined $params;

	##### CLUSTER
	my $cluster 			=	$self->cluster();
	print "MAQ::batchCommand    cluster: $cluster\n" if $DEBUG;

	#### GET THE BASE DIRECTORY OF THE SPLIT FILES - ALWAYS
	#### TWO DIRECTORIES DOWN FROM THE SPLIT FILE
	my $splitfile = $$splitfiles[0][0];
	print "splitfile: $splitfile\n";
	my ($basedir) = $splitfile =~ /^(.+?)\/\d+\/([^\/]+)$/;
	print "basedir: $basedir\n";

	#### SET BINARY FASTQ .bfq INPUT FILE SUFFIX
	my $suffix = ".bfq";
	
	#### SET INDEX PATTERN FOR BATCH JOB
	my $index = $self->getIndex();

	my $inputbinaries;
	my $firstmate = $label . "_1";
	my $secondmate = $label . "_2";
	push @$inputbinaries, "$basedir/$index/$firstmate.$index$suffix";
	push @$inputbinaries, "$basedir/$index/$secondmate.$index$suffix" if defined $$splitfiles[0][1];	
	print "inputbinaries:\n" if $DEBUG;
	print Dumper $inputbinaries if $DEBUG;
	
	#### GET REFERENCE NAME
	my ($reference) = $referencebinary =~ /^.+?\/([^\/]+)\.bfa$/;
	print "MAQ::batchCommand    reference: $reference\n" if $DEBUG;
	
	#### SET OUTPUTDIR FILE
	my $outdir = "$outputdir/$reference/$index";

	#### SET UNIQUE *outerr.txt FILE FOR EACH REFERENCE ALIGNMENT
	my $outerrfile = "$outdir/maq-$reference-outerr.txt";

	#### SET UNIQUE OUTERR FILE FOR EACH REFERENCE ALIGNMENT
	my $mapfile = "$outdir/out.map";

	#### OUTPUT TO outputdir ACROSS NFS
    my $command = qq{
mkdir -p $outdir;
cd $outdir;
time $maq/maq match $params $mapfile $referencebinary @$inputbinaries  &> $outerrfile
};

	#### CHANGE COMMAND IF TEMP DIR DEFINED
	my $tempdir = $self->tempdir();
	if ( defined $tempdir and $tempdir )
	{
		print "MAQ::batchCommand    tempdir is defined: $tempdir\n" if $DEBUG;

		#### SET TEMP OUTPUT DIR
		my $temp_outputdir = $tempdir . "/" . $outdir;
		
		#### SET UNIQUE OUTERR FILE FOR EACH REFERENCE ALIGNMENT
		my $outerrfile = "$temp_outputdir/maqBatch-$reference-outerr.txt";

		#### OUTPUT TO temp_outputdir ON LOCAL EXECUTION HOST
		my $mapfile = "$temp_outputdir/out.map";
	
		#### OUTPUT TO /tmp ON EXECUTION HOST AND MOVE AFTER COMPLETED
		$command = qq{
mkdir -p $temp_outputdir
time $maq/maq match $params $mapfile $referencebinary @$inputbinaries  &> $outerrfile
mv $temp_outputdir/* $outdir
rm -fr $temp_outputdir
};
	}

	return $command;
	
}	#	batchCommand

sub indexReferenceFiles {
	my $self			=	shift;
	my $inputdir		=	shift;
	my $outputdir		=	shift;

	my $DEBUG = 1;
	print "MAQ::indexReferenceFiles    MAQ::indexReferenceFiles(inputdir, outputdir) ", Timer::current_datetime(), "\n" if $DEBUG;
	print "MAQ::indexReferenceFiles    inputdir: $inputdir\n" if $DEBUG;
	print "MAQ::indexReferenceFiles    outputdir: $outputdir\n" if $DEBUG;

	#### GET REFERENCE FILES
	my $fastafiles = $self->listFiles($inputdir, "\*.fa");

	#### GET MAQ
	my $maq		=	$self->maq();
	print "MAQ::convertReferences    Maq not defined\n" and exit if not defined $maq or not $maq;

	chdir($inputdir) or die "MAQ::convertReferences    Can't change to inputdir directory: $inputdir\n";
	
	my $jobs = [];
	my $counter = 0;
	foreach my $file ( @$fastafiles )
	{
		$counter++;
		my ($reference) = $file =~ /([^\/]+)\.fa$/;
		my $referencebinary = "$outputdir/$reference.bfa";
		my $command = "time $maq/maq fasta2bfa $file $referencebinary";

		#### SET LABEL
		my $label = "maq-indexRef-$counter";
		$label =~ s/\///;

		#### SET JOB
		my $job = $self->setJob( [ $command ], $label, $outputdir);
		push @$jobs, $job;
	}

	#### RUN ALIGNMENT JOBS
	my $label = "maq-indexRef";
	$self->runJobs($jobs, $label);
}

sub fastqToBfq {
#### CONVERT A LIST OF FASTQ FILES (AND MATES) TO BFQ FORMAT

	my $self		=	shift;
	my $splitfiles	=	shift;
	my $outputdir	=	shift;
	my $label		=	shift;

#my $DEBUG = 1;
	print "MAQ::fastqToBfq    MAQ::fastqToBfq(splitfiles, outputdir, label)\n" if $DEBUG;
	print "MAQ::fastqToBfq    splitfiles: \n" if $DEBUG;
	print Dumper $splitfiles if $DEBUG;
	print "MAQ::fastqToBfq    outputdir: $outputdir\n" if $DEBUG;
	print "MAQ::fastqToBfq    label: $label\n" if $DEBUG;

	#### MAQ, CONVERT, AND CLEAN
	my $maq				=	$self->maq();
	my $convert			=	$self->convert();
	my $clean			=	$self->clean();
	
	#### INITIALISE JOBS
	my $jobs = [];

	my $counter = 0;
	foreach my $splitfile ( @$splitfiles )
	{
		$counter++;
		print "MAQ::fastqToBfq    $counter splitfile pair $$splitfile[0]\n" if $DEBUG;
		print "\n" if $DEBUG;
		
		#my $commands = $self->fastqToBfqCommands($splitfile);

		my $commands = [];
		foreach my $inputfile ( @$splitfile )
		{
			my $bfqfile = $inputfile;
			$bfqfile =~ s/\.[^\.]+?$/.bfq/;
			
			print "MAQ::fastqToBfq    Skipping file: $bfqfile\n" and last if -f $bfqfile and not -z $bfqfile and $DEBUG;
			
			print "MAQ::fastqToBfqCommands    bfqfile: $bfqfile\n" if $DEBUG;
	
			push @$commands, "#### Converting .fastq file to .bfq file...";
			push @$commands, "time $maq/maq fastq2bfq $inputfile $bfqfile";		
		}


		next if not defined $commands or scalar(@$commands) == 0;

		#### SET LABEL
		my $this_label = "fstqToBfq-$counter";

		#### SET OUTPUT DIRECTORY
		my ($outdir) = $$splitfile[0] =~ /^(.+?)\/[^\/]+$/;
		
		#### SET JOB
		my $job = $self->setJob($commands, $this_label, $outdir);

		push @$jobs, $job;
	}		

	print "MAQ::fastqToBfq    Skipping fastqToBfq file conversion because no jobs to run\n" and return if scalar(@$jobs) == 0;

	#### RUN ALIGNMENT JOBS
	print "MAQ::    RUNNING ", scalar(@$jobs), " jobs...\n";
	$self->runJobs($jobs, 'fastqToBfq');
}



sub solexaToSanger {
#### CONVERT SOLEXA FASTQ FILES TO SANGER FASTQ FILES
	my $self		=	shift;
	my $splitfiles	=	shift;
	
#my $DEBUG = 1;
	print "MAQ::solexaToSanger    MAQ::solexaToSanger    (splitfiles)\n" if $DEBUG;
	#print "MAQ::solexaToSanger    splitfiles: " if $DEBUG;
	#print Dumper $splitfiles if $DEBUG;
	
	my $jobs = [];
	my $counter = 0;
	foreach my $splitfile ( @$splitfiles )
	{
		$counter++;
		
		print "MAQ::solexaToSanger    splitfile: @$splitfile\n" if $DEBUG;

		my $infile = $$splitfile[0];
		print "MAQ::solexaToSanger    infile: $infile\n" if $DEBUG;
		
		my $commandsHash = $self->solToSangerCommands($splitfile);
		my $commands = $commandsHash->{commands};
		my $files = $commandsHash->{files};
		next if not defined $commands or scalar(@$commands) == 0;

		#### SET LABEL
		my $label = "solexaToSanger-$counter";
		print "MAQ::solexaToSanger    label: $label\n" if $DEBUG;
		
		#### SET OUTPUT DIRECTORY
		my ($outputdir) = $infile =~ /^(.+?)\/[^\/]+$/;
		print "MAQ::solexaToSanger    outputdir: $outputdir\n" if $DEBUG;
		
		#### SET JOB
		my $job = $self->setJob($commands, $label, $outputdir);
		push @$jobs, $job;
	}

	print "MAQ::solexaToSanger    length(jobs): ", scalar(@$jobs), "\n" if $DEBUG;
	
	#### RUN ALIGNMENT JOBS
	$self->runJobs($jobs, 'SolexaToSanger');
}

=head2

	SUBROUTINE		solToSangerCommands
	
	PURPOSE
	
		RETURN COMMANDS TO CONVERT FROM SOLEXA- TO SANGER-FORMAT 
		
		FASTQ FILES AND THE LIST OF .fastq FILES TO BE CREATED
		
	INPUTS
	
		1. ARRAY OF INPUT .txt OR .fastq FILES
		
	OUTPUTS
	
		1. ARRAY OF COMMANDS
		
		2. ARRAY OF .bfq FILE NAMES
		
=cut

sub solToSangerCommands {
	my $self			=	shift;
	my $inputfiles		=	shift;

#my $DEBUG = 1;

	#### MAQ, CONVERT, AND CLEAN
	my $maq				=	$self->maq();
	my $convert			=	$self->convert();
	my $clean			=	$self->clean();

	print "MAQ::solToSangerCommands    MAQ::solToSangerCommands(inputfiles)\n" if $DEBUG;
	print "MAQ::solToSangerCommands    inputfiles: @$inputfiles\n" if $DEBUG;

	#### GET TEMP DIR
	my $tempdir = $self->tempdir();

	my $commands = [];
	my $fastqfiles = [];
	if ( defined $convert and $$inputfiles[0] !~ /\.bfq$/ )
	{
		foreach my $inputfile ( @$inputfiles )
		{
            #### OUTPUT TO OUTPUTDIR ACROSS NFS
			#### SET CONVERSION OUTPUT FILE SUFFIX TO .fastq			
			my $fastqfile = $inputfile;
			if ( $inputfile =~ /fastq$/ )
			{
				$fastqfile =~ s/fastq$/sanger.fastq/;
			}
			elsif ( $inputfile =~ /txt$/ )
			{
				$fastqfile =~ s/\.txt$/.fastq/;
			}
			else
			{
				print "Quitting - Input file has incorrect suffix:	$inputfile\n";
				exit;
			}
			
			push @$commands, "echo 'Converting solexa sequence file to Sanger fastq file'";
			
			if ( $convert =~ /^post-1.3$/ )
			{
				push @$commands, "time $maq/maq ill2sanger $inputfile $fastqfile";
			}
			elsif ( $convert =~ /^pre-1.3$/ )
			{
				push @$commands, "time $maq/maq sol2sanger $inputfile $fastqfile";
			}
			else
			{
				print "MAQ::alignmentCommands    Conversion type not supported: $convert (must be 'post-1.3' or 'pre1.3')\n" and exit;
			}
			
			#### SAVE .fastq FILE NAME
			push @$fastqfiles, $fastqfile;
		}
	}
	
	return { commands => $commands, files => $fastqfiles };	
}


sub getReferenceFiles {
#### RETURN A LIST OF REFERENCE FILES (FULL PATHS TO FILES)
	my $self		=	shift;
	my $referencedir=	shift;

my $DEBUG = 1;
	print "ELAND::getReferenceFiles    ELAND::getReferenceFiles(referencedir)\n" if $DEBUG;
	print "ELAND::getReferenceFiles    referencedir: $referencedir\n" if $DEBUG;
	
	return $self->listReferenceFiles($referencedir, "\*\.bfa");
}

sub getReferences {
#### RETURN A LIST OF REFERENCE NAMES (N.B.: NOT THE PATHS TO THE FILES)
 my $self		=	shift;
	my $referencedir=	shift;
	
my $DEBUG = 1;
	print "ELAND::getReferences    ELAND::getReferences(referencedir)\n" if $DEBUG;
	print "ELAND::getReferences    referencedir: $referencedir\n" if $DEBUG;

	my $referencefiles = $self->getReferenceFiles($referencedir);
	my $references = $self->getFilenames($referencefiles);
	foreach my $reference ( @$references )	{	$reference =~ s/\.bfa$//;	}

	return $references;
}




=head2

	SUBROUTINE		subdirMapToSam
	
	PURPOSE
	
		CONVERT ALL .map FILES IN chr*/<NUMBER> SUBDIRECTORIES
		
		INTO .sam FILES

			maq2sam-long out.map > out.sam

		INPUTS
		
			1. OUTPUT DIRECTORY USED TO PRINT CHROMOSOME-SPECIFIC
			
				SAM FILES TO chr* SUB-DIRECTORIES
			
			2. LIST OF REFERENCE FILE NAMES
		
			3. SPLIT INPUT FILES LIST
			
			4. NAME OF MAP INPUTFILE (E.G., "out.map")

			4. NAME OF SAM OUTPUTFILE (E.G., "accepted_hits.sam")

=cut


sub subdirMapToSam {
	my $self			=	shift;
	my $outputdir		=	shift;
	my $references 		=	shift;
	my $splitfiles		=	shift;
	my $infile			=	shift;
	my $outfile			=	shift;

	print "Cluster::subdirMapToSam    Cluster::subdirMapToSam(outputdir, references, splitfiles, inputfile)\n";
	print "Cluster::subdirMapToSam    outputdir: $outputdir\n";
	#print "Cluster::subdirMapToSam    splitfiles: @$splitfiles\n";
	print "Cluster::subdirMapToSam    infile: $infile\n";
	print "Cluster::subdirMapToSam    outfile: $outfile\n";
	print "Cluster::subdirMapToSam    references: @$references\n";
	
	#### GET REQUIRED VARIABLES
	my $samtools = $self->samtools();
	my $maq = $self->maq();
	print "MAQ::subdirMapToSam    samtools: $samtools\n" if $DEBUG;
	print "MAQ::subdirMapToSam    samtools not defined\n" and return if not defined $samtools;

	#### NB: maq2sam COMMAND ASSUMES out.map FILES GENERATED BY maq-0.7.x.
	#### maq2sam-short IS FOR maq-0.6.x AND EARLIER
	#### PARSE THIS NUMBER OUT FROM MAQ LOCATION WITH FORMAT: ../maq/1.2.3
	my $maq2sam = "maq2sam-long";
	my ($maq_version) = $maq =~ /(\d)\.\d$/;
	#print "MAQ::mapToSamCommand    maq_version: $maq_version\n";
	$maq2sam = "maq2sam-short" if $maq_version < 7;

	#### SET INDEX
	my $cluster = $self->cluster();
	my $index;
	$index = "\$LSB_JOBINDEX" if $cluster eq "LSF";
	$index = "\$PBS_TASKNUM" if $cluster eq "PBS";

	#### SET NUMBER OF SPLITFILES FOR GENERATING BATCH JOB LATER
	my $number_splitfiles = scalar(@$splitfiles);

	my $jobs = [];
	foreach my $reference ( @$references )
	{
		#### SET JOB TO CONVERT ALL MAP FILES FOR THIS REFERENCE
		#### INTO SAM FILES 
		my $outdir = "$outputdir/$reference";
		my $mapfile = "$outdir/$index/$infile";
		my $samfile = "$outdir/$index/$outfile";
		my $command = "$samtools/$maq2sam $mapfile > $samfile";
		my $label = "subdirMapToSam-$reference";
		my $job = $self->setBatchJob( [$command], $label, $outdir, $number_splitfiles);
		
		push @$jobs, $job;
	}

	#### RUN CONVERSION JOBS
	print "Cluster::subdirMapToSam    DOING runJobs for " , scalar(@$jobs), " jobs\n";
	$self->runJobs($jobs, 'subdirMapToSam');
	print "Cluster::subdirMapToSam    Completed subdirMapToSam\n";
}



=head2

	SUBROUTINE		mapToSam
	
	PURPOSE
	
		RUNNING 
		
=cut

sub mapToSam {	
	my $self			=	shift;
	my $splitfiles		=	shift;
	my $referencedir	=	shift;
	my $outputdir		=	shift;
	my $mapfile			=	shift;
	my $samfile			=	shift;

#my $DEBUG = 1;
	print "MAQ::mapToSam    MAQ::mapToSam(splitfiles, referencedir, outputdir)\n" if $DEBUG;

	#### GET REFERENCE FILES
	my $referencefiles = $self->listReferenceFiles($referencedir, "\*.bfa");
	
	#### CONVERT ALL .map FILES
	my $jobs = [];
	for my $referencefile ( @$referencefiles )
	{
		next if $referencefile =~ /^[\.]+$/;
	
		$referencefile = "$referencedir/$referencefile";
		
		#### SET REFERENCE BINARY FILE
		my $referencebinary = $referencefile;
		$referencebinary =~ s/\.[^\.]+?$/.bfa/;
	
		#### SET REFERENCE
		my ($reference) = $referencefile =~ /^.+?\/([^\/]+)\.bfa$/i;

		#### DO ALIGNMENTS FOR ALL SPLITFILES 
		my $counter = 0;
		foreach my $splitfile ( @$splitfiles )
		{
			$counter++;
			
			#### SET OUTPUT DIR TO SUBDIRECTORY CONTAINING SPLITFILE
			my ($basedir, $index) = $$splitfile[0] =~ /^(.+?)\/(\d+)\/[^\/]+$/;
			my $outdir = "$basedir/$reference/$index";

			#### SET *.map FILE
			my $mapfile = "$outdir/$mapfile";

			#### SET .sam FILE	
			my $samfile = "$outdir/$samfile";

			#### CONVERT .map FILE TO .sam FILE
			my $commands;
			my $sam_command = $self->mapToSamCommand($mapfile, $samfile);
			#print "MAQ::mapToSam    sam_command: $sam_command\n";
			push @$commands, $sam_command;
		
			#### SET LABEL
			my $label = "$reference-$counter-mapToSam";
			
			#### SET JOB
			my $job = $self->setJob($commands, $label, $outdir);
			push @$jobs, $job;
		}
	}	

	print "MAQ::mapToSam    No. mapToSam jobs: ", scalar(@$jobs), "\n";

	#### RUN ALIGNMENT JOBS
	$self->runJobs($jobs, "mapToSam");
}

=head2
	
	SUBROUTINE		mapToSamCommand
	
	PURPOSE
	
		RETURN THE COMMAND TO CONVERT A *.map FILE TO A .sam FILE

=cut

sub mapToSamCommand {
	my $self		=	shift;
	my $maqfile		=	shift;
	my $samfile		=	shift;

#my $DEBUG = 1;
	print "MAQ::mapToSamCommand    MAQ::mapToSamCommand(maqfile, samfile)\n" if $DEBUG;
	print "MAQ::mapToSamCommand    maqfile: $maqfile\n" if $DEBUG;
	print "MAQ::mapToSamCommand    samfile: $samfile\n" if $DEBUG;

	#### SANITY CHECK
	print "MAQ::mapToSamCommand    maqfile not defined: $maqfile\n" and exit if not defined $maqfile;
	print "MAQ::mapToSamCommand    samfile not defined: $samfile\n" and exit if not defined $samfile;

	#### GET REQUIRED VARIABLES
	my $samtools = $self->samtools();
	my $maq = $self->maq();
	print "MAQ::mapToSamCommand    samtools: $samtools\n" if $DEBUG;
	print "MAQ::mapToSamCommand    samtools not defined\n" and return if not defined $samtools;

	#### NB: maq2sam COMMAND ASSUMES out.map FILES GENERATED BY maq-0.7.x.
	#### maq2sam-short IS FOR maq-0.6.x AND EARLIER
	my $maq2sam = "maq2sam-long";
	my ($maq_version) = $maq =~ /(\d)\.\d$/;
	#print "MAQ::mapToSamCommand    maq_version: $maq_version\n";
	$maq2sam = "maq2sam-short" if $maq_version < 7;
	
    my $command = "$samtools/$maq2sam $maqfile > $samfile";
	#print "MAQ::mapToSamCommand    command: $command\n";

	return $command;	
}



=head2

	SUBROUTINE		maqSnps
	
	PURPOSE
	
		RUNNING 
		
=cut

sub maqSnps {
	my $self			=	shift;
	my $splitfiles		=	shift;
	my $referencedir	=	shift;
	my $outputdir		=	shift;

my $DEBUG = 1;
	print "MAQ::maqSnps    MAQ::maqSnps(splitfiles, referencedir, outputdir)\n" if $DEBUG;

	#### SET TIMER
	my $current_time = time();

	#### GET REFERENCE FILES
	my $referencefiles = $self->listReferenceFiles($referencedir, "\*.bfa");
	
	#### GET COMMANDS TO MERGE MAPS AND PREDICT SNPS AND INDELS
	my $snp_jobs = [];
	for my $referencefile ( @$referencefiles )
	{
		next if $referencefile =~ /^[\.]+$/;
		#print "MAQ::    referencefile: $referencefile\n" if $DEBUG;
		
		#### SET REFERENCE BINARY FILE
		my $referencebinary = $referencefile;
		$referencebinary =~ s/\.[^\.]+?$/.bfa/;

		#### SET REFERENCE
		my ($reference) = $referencefile =~ /^.+\/([^\/]+)\.[^\.]{2,6}$/;

		#### SET OUTPUT DIRECTORY
		my $outdir = "$outputdir/$reference";

		#### GET SNP PREDICTION COMMANDS
		my $commands = $self->snpCommands($splitfiles, $referencefile, $referencebinary, $outdir);

		#### SET LABEL
		my $label = "maqSnps-" . $reference;
		
		#### GET LABEL, COMMANDS, ETC.
		my $job = $self->setJob($commands, $label, $outdir);	
		push @$snp_jobs, $job;
	}
	print "MAQ::    length(jobs): ", scalar(@$snp_jobs), "\n";

	#### RUN out.map MERGE AND SNP/INDEL CALLING JOBS
	$self->runJobs($snp_jobs, "maqSnps");
}


=head2

	SUBROUTINE		snpCommands

	PURPOSE
	
		RETURN AN ARRAY OF COMMANDS TO ANALYSE SNPS AND INDELS
		
=cut

sub snpCommands {
	my $self			=	shift;
	my $splitfiles		=	shift;
	my $referencefile 	=	shift;
	my $referencebinary	=	shift;
	my $outputdir		=	shift;
	
my $DEBUG = 1;
	print "MAQ::snpCommands    MAQ::snpCommands(splitfiles, referencefile, referencebinary)\n" if $DEBUG;
	print "MAQ::snpCommands    referencefile: $referencefile\n" if $DEBUG;
	print "MAQ::snpCommands    referencebinary: $referencebinary\n" if $DEBUG;

	#### EXECUTABLES
	my $maq 			=	$self->maq();
	
	#### STORE COMMANDS
	my $commands = [];
	push @$commands, "echo 'Changing to output directory: $outputdir'";
	push @$commands, "cd $outputdir";
	
	#######################
	##### DO SNPS
	#######################
	
	# 3. Build the mapping assembly
	push @$commands, "time $maq/maq assemble consensus.cns $referencebinary out.map 2> assemble.log";
	
	# 4. Extract consensus sequences and qualities
	push @$commands, "time $maq/maq cns2fq consensus.cns > cns.fq";
	
	# 5. Extract list of SNPs 
	push @$commands, "time $maq/maq cns2snp consensus.cns > cns.snp";
	
	
	#######################
	##### DO INDELS
	#######################
	
	#2. rmdup       remove pairs with identical outer coordinates (PE)
	push @$commands, "time $maq/maq rmdup out.rmdup out.map";
	
	#3. indelpe     indel calling (PAIRED READS ONLY)
	push @$commands, "time $maq/maq indelpe $referencebinary out.rmdup > out.indelpe";
	
	#4. indelsoa    state-of-art homozygous indel detectionll
	push @$commands, "time $maq/maq indelsoa $referencebinary out.map > out.indelsoa";
	
	#5. filter indels
	push @$commands, "awk '\$5+\$6-\$4 >= 3 \&\& \$4 <= 1' out.indelsoa > out.indelsoa.filter";

	#6. SNPfilter    filter SNP predictions
	push @$commands, "time $maq/scripts/maq.pl SNPfilter -d 1 -s out.indelsoa -F out.indelpe cns.snp &> out.SNPfilter";

#print "MAQ::snpCommands    commands: \n";
#print join "\n", @$commands;
#print "\n";
#exit;
		
	return $commands;	
} 




=head2

	SUBROUTINE		pyramidMergeMap
	
	PURPOSE
	
		1. MERGE ALL FILES PER REFERENCE IN A PYRAMID OF DECREASING
		
			(BY HALF) BATCHES OF MERGES UNTIL THE FINAL OUTPUT FILE
		
			IS PRODUCED.
		
		2. EACH STAGE IS COMPLETED WHEN ALL OF THE MERGES FOR ALL
		
			REFERENCES ARE COMPLETE.
		
		3. EACH PAIRWISE MERGE OPERATION IS CARRIED OUT ON A SEPARATE
		
			EXECUTION HOST
		
		4. THIS METHOD ASSUMES:
		
			1. THERE IS NO ORDER TO THE FILES
			
			2. ALL FILES MUST BE MERGED INTO A SINGLE FILE
		
			3. THE PROVIDED SUBROUTINE MERGES THE FILES
		
		INPUTS
		
=cut

sub pyramidMergeMap {
	my $self			=	shift;
	my $outputdir		=	shift;
	my $references		=	shift;
	my $splitfiles		=	shift;
	my $infile			=	shift;
	my $outfile			=	shift;

my $DEBUG = 1;
print "MAQ::pyramidMergeMap(outputdir, references, splitfiles, infile, outfile)\n" if $DEBUG;
print "MAQ::pyramidMergeMap    outputdir: $outputdir\n" if $DEBUG;
print "MAQ::pyramidMergeMap    references: $references\n" if $DEBUG;
print "MAQ::pyramidMergeMap    splitfiles: $splitfiles\n" if $DEBUG;
print "MAQ::pyramidMergeMap    infile: $infile\n" if $DEBUG;
print "MAQ::pyramidMergeMap    outfile: $outfile\n" if $DEBUG;


	#### SET DEFAULT infile AND outfile
	$infile = "out.map" if not defined $infile;
	$outfile = "out.map" if not defined $outfile;
	
	#### GET SAMTOOLS
	my $maq = $self->maq();

	#### LOAD UP WITH INITIAL BAM FILES
	my $reference_mapfiles;
	foreach my $reference ( @$references )
	{
		#### GET SAM FILES
		my $mapfiles = $self->subfiles($outputdir, $reference, $splitfiles, $infile);
		$reference_mapfiles->{$reference} = $mapfiles;
	}

	my $mergesub = sub {
		my $firstfile	=	shift;
		my $secondfile	=	shift;

		#print "MAQ::pyramidMergeMap::mergesub    firstfile: $firstfile\n" if $DEBUG;
		#print "MAQ::pyramidMergeMap::mergesub    secondfile: $secondfile\n" if $DEBUG;

		#### KEEP THIS PART OF THE LOGIC HERE JUST IN CASE THE
		#### MERGE FUNCTION EXPECTS A PARTICULAR FILE SUFFIX
		my $outfile = $firstfile;
		if ( $outfile =~ /\.merge\.(\d+)$/ )
		{
			my $number = $1;
			$number++;
			$outfile =~ s/\d+$/$number/;	 
		}
		else
		{
			$outfile .= ".merge.1"
		}
		
		
		#### MERGE MAP FILES
		my $command .= "time $maq/maq mapmerge $outfile $firstfile $secondfile;\n";
		
		return ($command, $outfile);
	};


	#### RUN PYRAMID MERGE ON ALL REFERENCES IN PARALLEL
	my $label = "pyramidMergeMap";
	$self->_pyramidMerge($outputdir, $references, $splitfiles, $infile, $outfile, $reference_mapfiles, $label, $mergesub);

	print "MAQ::pyramidMergeMap    Completed.\n";
}


=head2

	SUBROUTINE		cumulativeMergeMap

	PURPOSE
	
		CUMULATIVELY MERGE ALL INPUT SPLIT FILE-BASED out.map FILES INTO A SINGLE
		
		out.map FILE FOR EACH REFERENCE
	
=cut

sub cumulativeMergeMap {
	my $self			=	shift;
	my $splitfiles		=	shift;
	my $references		=	shift;
	my $outputdir		=	shift;
	
my $DEBUG = 1;
	print "MAQ::cumulativeMergeMap    MAQ::cumulativeMergeMap(splitfiles, referencedir, outputdir)\n" if $DEBUG;

	#### GET MAQ
	my $maq = $self->maq();

	#### SET TIMER
	my $current_time = time();
		
	#### GET COMMANDS TO MERGE MAPS AND PREDICT SNPS AND INDELS
	my $jobs = [];
	for my $reference ( @$references )
	{		
		#### GET SAM FILES
		my $infile = "out.map";
		my $mapfiles = $self->subfiles($outputdir, $reference, $splitfiles, $infile);
		#print "MAQ::cumulativeMergeMap    mapfiles: @$mapfiles\n";
		
		#### CHECK FOR MISSED MAP FILES (FAILED ALIGNMENTS)
		$mapfiles = $self->missedMaps($mapfiles);
		
		#### SET OUTPUT DIRECTORY
		my $outdir = "$outputdir/$reference";
		
		#### SET OUTPUT FILE
		my $outfile = "$outdir/out.map";
		
		#### SET MERGE SUBROUTINE
		my $mergesub = sub {
			my $outfile		=	shift;
			my $tempfile	=	shift;
			my $subfile		=	shift;
		
			return "time $maq/maq mapmerge $outfile $tempfile $subfile";
		};
		
		#### GET SNP PREDICTION COMMANDS
		my $commands = $self->cumulativeMergeCommands($mapfiles, $outfile, $mergesub);
		
		#### SET LABEL
		my $label = "cumulativeMergeMap-" . $reference;
		
		#### GET LABEL, COMMANDS, ETC.
		my $job = $self->setJob($commands, $label, $outdir);	
		push @$jobs, $job;
	}
	print "MAQ::cumulativeMergeMap    length(jobs): ", scalar(@$jobs), "\n";
	
	#### RUN out.map MERGE AND SNP/INDEL CALLING JOBS
	$self->runJobs($jobs, "cumulativeMergeMap");
} 



=head2

	SUBROUTINE		missedMaps
	
	PURPOSE
	
		CHECK TO SEE IF ANY out.map FILES ARE MISSING
		
=cut

sub missedMaps {
	my $self		=	shift;
	my $mapfiles	=	shift;
	
	#### CHECK THAT ALL FILES EXIST
	my $missedmaps = [];
	for ( my $i = 0; $i < @$mapfiles; $i++ )
	{
		my $mapfile = $$mapfiles[$i];
		if ( not -f $mapfile )
		{
			push @$missedmaps, splice (@$mapfiles, $i, 1);
			$i--;
		}
	}
	
	#### PRINT ANY MISSING out.map FILES
	if ( scalar(@$missedmaps) > 0 )
	{
		print "MAQ::missedMaps    Missed maps:\n";
		print join "\n", @$missedmaps;
		print "\n\n";
		print "MAQ::missedMaps    Exiting\n";
		exit;
	}
	
	return $mapfiles;	
}


=head2

	SUBROUTINE		checkFiles
	
	PURPOSE
	
		CHECK INPUT FILES ARE ACCESSIBLE AND NON-EMPTY

=cut

sub checkFiles {
	my $self		=	shift;
	my $files		=	shift;

	#### SANITY CHECK
	foreach my $file ( @$files )
	{
		if ( $file !~ /\.(txt|fastq|bfq)$/ )
		{
			print "MAQ::::alignmentCommands     file must end in .txt, .fastq or .bfq\n";
			print "MAQ::::alignmentCommands    file: $file\n";
			exit;
		}
		if ( -z $file )
		{
			print "MAQ::::alignmentCommands     file is empty. Quitting.\n";
			exit;
		}
	}
}



=head2

	SUBROUTINE		fastqToBfqCommands
	
	PURPOSE
	
		RETURN COMMANDS TO CONVERT .fastq FILES TO .bfq FORMAT AND
		
		THE LIST OF .bfq FILES TO BE CREATED
		
	INPUTS
	
		1. ARRAY OF INPUT .fastq FILES
		
	OUTPUTS
	
		1. ARRAY OF COMMANDS
		
		2. ARRAY OF .bfq FILE NAMES
		
	NOTES

		IF THE convert FLAG IS SET, .txt OR .fastq INPUT FILES WILL 
		
		BE CONVERTED FROM SOLEXA TO SANGER FASTQ SEQUENCES. IN THE
		
		CASE OF .bfq INPUT FILES, CONVERSION WILL BE SKIPPED.
		
=cut

sub fastqToBfqCommands {
	my $self			=	shift;
	my $inputfiles		=	shift;

#my $DEBUG = 1;

	print "MAQ::fastqToBfqCommands    MAQ::fastqToBfqCommands(inputfiles)\n" if $DEBUG;
	print "MAQ::fastqToBfqCommands    inputfiles: @$inputfiles\n" if $DEBUG;

	#### MAQ, CONVERT, AND CLEAN
	my $maq				=	$self->maq();
	my $convert			=	$self->convert();
	my $clean			=	$self->clean();
	
	my $commands = [];
	foreach my $inputfile ( @$inputfiles )
	{
		my $bfqfile = $inputfile;
		$bfqfile =~ s/\.[^\.]+?$/.bfq/;
        print "MAQ::fastqToBfqCommands    bfqfile: $bfqfile\n" if $DEBUG;

		push @$commands, "#### Converting .fastq file to .bfq file...";
		push @$commands, "time $maq/maq fastq2bfq $inputfile $bfqfile";		
	}

	return $commands;
}





}