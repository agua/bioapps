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

class Aligner::ELAND with (Agua::Common::Logger,
	Agua::Cluster::Jobs,
	Agua::Cluster::Checker,
	Agua::Cluster::Util,
	Agua::Cluster::Convert,
	Agua::Cluster::Merge,
	Agua::Cluster::Sort,
	Agua::Cluster::Usage,
	Agua::Common::Database,
	Agua::Common::Util,
	Agua::Common::SGE) {


#### DEBUG
our $DEBUG = 0;
$DEBUG = 1;


use Agua::DBaseFactory;
use Agua::DBase::MySQL;
use Conf::Agua;
use File::Path;

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
has 'casava'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'inputtype'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'pairparams'=> ( isa => 'Str|Undef', is => 'rw', default => '' );
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

#/////}
	
sub BUILD {
	my $self	=	shift;

	#my $DEBUG = 1;
	print "Aligner::ELAND::BUILD    Aligner::ELAND::BUILD()\n" if $DEBUG;
	print "Aligner::ELAND::BUILD    self:\n" if $DEBUG;
	print Dumper $self if $DEBUG;

	print "Aligner::ELAND::BUILD    Doing self->setDbh()\n" if $DEBUG;
	$self->setDbh();
}

sub run {				#### DO ALIGNMENT
	my $self		=	shift;

	my $DEBUG = 1;
	print "ELAND::run    ELAND::run()\n" if $DEBUG;

	#### INPUTS
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
	$self->checkFiles(\@infiles);
	$self->checkFiles(\@mates);
	
	#### SPLIT FILES
	my $label 			=	$self->label();
	my $splitfile 		=	$self->splitfile();

	#### SET DEFAULT SPLITFILE IF NOT DEFINED
	$splitfile = "$outputdir/splitfile.txt" if not defined $splitfile;
	print "ELAND::run    splitfile: $splitfile\n" if $DEBUG;

	###############################################
	###########   SET REFERENCE NAMES    ##########
	my $references = $self->listReferenceSubdirs($referencedir);
	print "ELAND::run    references: @$references\n" if $DEBUG;

	##############################################
	############	SPLIT INPUT FILES   ##########
	##############################################
	print "ELAND::run    Doing doSplitfiles()   ", Timer::current_datetime(), "\n";
	my $splitfiles = $self->doSplitfiles($splitfile, $label);
	print "ELAND::run    After doSplitfiles()   ", Timer::current_datetime(), "\n";
	print "ELAND::::run    length splitfiles: ", scalar(@$splitfiles), "\n" if $DEBUG;

	##############################################
	############	ELAND ALIGNMENT    ##########
	#############################################
	print "ELAND::run    Doing alignment()    ", Timer::current_datetime(), "\n";
	$self->doBatchAlignment($outputdir, $referencedir, $references, $splitfiles, $label) if $cluster;
	$self->doAlignment($outputdir,  $referencedir, $references, $splitfiles, $label) if not $cluster;
	print "ELAND::run    After alignment()    ", Timer::current_datetime(), "\n";
	print "ELAND::::run    length splitfiles: ", scalar(@$splitfiles), "\n" if $DEBUG;
	
	#################################################
	#####   CONVERT *_export.txt TO out.sam    ######
	#################################################
	print "ELAND::run    Doing exportToSam      ", Timer::current_datetime(), "\n";
	$self->exportToSam($splitfiles, $referencedir, $outputdir, $references, $matefiles);
	print "ELAND::run    After exportToSam      ", Timer::current_datetime(), "\n";
	
	################################################
	########        FILTER SAM HITS          #######
	################################################
	print "ELAND::run    Doing subdirSamHits        ", Timer::current_datetime(), "\n";
	$self->subdirSamHits($outputdir, $references, $splitfiles, "out.sam", "hit.sam", "miss.sam");
	print "ELAND::run    After subdirSamHits        ", Timer::current_datetime(), "\n";
	
	################################################
	######        CUMULATIVE MERGE SAM        ######
	################################################
	print "ELAND::run    Doing cumulativeMergeSam        ", Timer::current_datetime(), "\n";
	$self->cumulativeMergeSam($outputdir, $references, $splitfiles, "hit.sam", "hit.sam");
	print "ELAND::run    After cumulativeMergeSam        ", Timer::current_datetime(), "\n";

	##############################################
	#########    CONVERT SAM  TO BAM   ###########
	##############################################
	print "ELAND::run    Doing samToBam     ", Timer::current_datetime(), "\n";
	$self->samToBam($outputdir, $references, "hit.sam", "hit.bam");
	print "ELAND::run    After samToBam     ", Timer::current_datetime(), "\n";
}

=head2

	SUBROUTINE		doAlignment
	
	PURPOSE
	
		ALIGN READS WITH ELAND_standalone.pl TO PRODUCE export.txt FILE

=cut

sub doAlignment {
	my $self			=	shift;
	my $outputdir 		=	shift;
	my $referencedir 	=	shift;
	my $references		=	shift;
	my $splitfiles 		=	shift;
	my $label 			=	shift;

my $DEBUG = 1;

	print "ELAND::doAlignment    ELAND::doAlignment(outputdir, referencedir, splitfiles, label)\n" if $DEBUG;
	print "ELAND::doAlignment    outputdir: $outputdir\n" if $DEBUG;
	print "ELAND::doAlignment    referencedir: $referencedir\n" if $DEBUG;
	print "ELAND::doAlignment    splitfiles: $splitfiles\n" if $DEBUG;
	print "ELAND::doAlignment    label: $label\n" if $DEBUG;

	#### GET REQUIRED VARIABLES
	my $casava = $self->casava();
	print "ELAND::doAlignment    casava: $casava\n" if $DEBUG;
	print "ELAND::doAlignment    casava not defined. Exiting\n" and exit if not defined $casava;
	my $inputtype = $self->inputtype();
	print "ELAND::doAlignment    inputtype: $inputtype\n" if $DEBUG;
	print "ELAND::doAlignment    inputtype not defined. Exiting\n" and exit if not defined $inputtype;
	
	#### GET OPTIONAL VARIABLES
	my $seedlength = $self->seedlength();
	my $quality = $self->quality();
	my $pairparams = $self->pairparams();

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
			print "ELAND::doAlignment    outdir: $outdir\n" if $DEBUG;
	
			#### MOVE TO OUTPUT DIR
			chdir($outdir) or die "Can't chdir to outdir: $outdir\n";
		
			my $command = qq{$casava/ELAND_standalone.pl \\\n};
			$command .= qq{--input-type $inputtype \\\n};
			$command .= qq{--eland-genome $referencedir/$reference \\\n};
			$command .= qq{--input-file $infile \\\n};
			$command .= qq{--input-file $mate \\\n} if defined $mate;	
			$command .= qq{--seedlength $seedlength \\\n} if defined $seedlength;
			$command .= qq{--base-quality $quality \\\n} if defined $quality;
			$command .= qq{--pair-params $pairparams \\\n} if defined $pairparams;
			$command .= "\n";
	
			#### SET LABEL
			my $label = "$label-$counter";
			$label =~ s/\///;
			
			#### SET JOB
			my $job = $self->setJob( [ $command ], $label, $outdir);
			push @$jobs, $job;
		}
	}


#print "ELAND::run    length(jobs): ", scalar(@$jobs), "\n";
#print Dumper $$jobs[0];
#exit;


	#### RUN ALIGNMENT JOBS
	$self->runJobs($jobs, $label);
}


sub doBatchAlignment { 	#### RUN ELAND AGAINST ALL REFERENCE FILES USING CLUSTER BATCH JOB
	my $self			=	shift;
	my $outputdir		=	shift;
	my $referencedir 	=	shift;
	my $references		=	shift;
	my $splitfiles		=	shift;	
	my $label			=	shift;

my $DEBUG = 1;
	print "ELAND::doBatchAlignment    ELAND::doBatchAlignment(outputfile, referencefiles, splitfiles)\n" if $DEBUG;
	print "ELAND::doBatchAlignment    outputdir: $outputdir\n" if $DEBUG;
	print "ELAND::doBatchAlignment    referencedir: $referencedir\n" if $DEBUG;
	print "ELAND::doBatchAlignment    No. splitfiles: ", scalar(@$splitfiles), "\n" if $DEBUG;

	#### COLLECT ALL JOBS FOR EACH INPUT FILE AGAINST ALL REFERENCE FILES
	my $jobs = $self->generateBatchJobs($outputdir, $references, $splitfiles, $label);

	##### RUN ALIGNMENT JOBS
	$self->runJobs($jobs, "eland");
}

sub batchCommand {		#### GENERATE BATCH/ARRAY JOB COMMAND
	my $self			=	shift;
	my $outputdir		=	shift;
	my $referencepath	=	shift;
	my $splitfiles		=	shift;

#my $DEBUG = 1;

	print "ELAND::batchCommand    ELAND::batchCommand(outputfile, referencepath, splitfiles)\n" if $DEBUG;
	print "ELAND::batchCommand    outputdir: $outputdir\n" if $DEBUG;
	print "ELAND::batchCommand    referencepath: $referencepath\n" if $DEBUG;
	#print "ELAND::batchCommand    splitfiles:\n" if $DEBUG;
	#print Dumper $splitfiles if $DEBUG;

	#### USER INPUTS
	my $matefiles 		= 	$self->matefiles();
	my $params 			=	$self->params();  #### OVERRIDE PARAMS IN DEFAULT COMMAND
	my $label 			=	$self->label();	#### USED TO GENERATE INPUTFILE NAMES	
	my $inputtype 		=	$self->inputtype();
	print "ELAND::batchCommand    inputtype: $inputtype\n" if $DEBUG;

	#### CHECK INPUTS
	print "ELAND::batchCommand    inputtype not defined. Exiting\n" and exit if not defined $inputtype;
	print "ELAND::batchCommand    label not defined. Exiting\n" if not defined $label;

	#### EXECUTABLES
	my $casava 			= 	$self->casava();
	print "ELAND::batchCommand    casava: $casava\n" if $DEBUG;
	print "ELAND::batchCommand    casava not defined. Exiting\n" and exit if not defined $casava;
	
	##### CLUSTER
	my $cluster 		=	$self->cluster();
	print "ELAND::batchCommand    cluster: $cluster\n" if $DEBUG;

	#### GET THE BASE DIRECTORY OF THE SPLIT FILES - ALWAYS TWO DIRECTORIES DOWN
	my $splitfile = $$splitfiles[0][0];
	print "ELAND::batchCommand    splitfile: $splitfile\n" if $DEBUG;
	my ($basedir) = $splitfile =~ /^(.+?)\/\d+\/([^\/]+)$/;
	print "ELAND::batchCommand    basedir: $basedir\n" if $DEBUG;
	
	#### GET SUFFIX OF SPLIT FILE IF EXISTS
	my ($suffix) = $self->fileSuffix($splitfile);
	$suffix = '' if not defined $suffix;
	
	#### SET INDEX PATTERN FOR BATCH JOB
	my $index;
	$index = "\$LSB_JOBINDEX" if $cluster eq "LSF";
	$index = "\$PBS_TASKNUM" if $cluster eq "PBS";

	#### SET OUTPUT FILES
	my ($referencedir, $reference) = $referencepath =~ /^(.+?)\/([^\/]+)$/;
	$reference =~ s/\.vld$//;
	$reference =~ s/\.fa$//;
	print "ELAND::batchCommand    reference: $reference\n" if $DEBUG;

	#### SET INPUT AND MATE FILES, E.G.:
	#### /scratch/syoung/base/pipeline/bixby/run1/ln/$LSB_JOBINDEX/ln_1.$LSB_JOBINDEX.txt
	#### /scratch/syoung/base/pipeline/bixby/run1/ln/$LSB_JOBINDEX/ln_2.$LSB_JOBINDEX.txt	
	my $firstmate = $label . "_1";
	my $inputfile = "$basedir/$index/$firstmate.$index$suffix";
	print "ELAND::batchCommand    AFTER inputfile: $inputfile\n" if $DEBUG;

	#### DO SECOND MATE IF matefiles DEFINED
	my $secondmate = $label . "_2" if defined $matefiles;
	my $matefile = "$basedir/$index/$secondmate.$index$suffix" if defined $matefiles;
	print "ELAND::batchCommand    AFTER matefile: $matefile\n" if $DEBUG and defined $matefile;

	#### GET OPTIONAL VARIABLES
	my $seedlength = $self->seedlength();
	my $quality = $self->quality();
	my $pairparams = $self->pairparams();

	#### ELAND COMMAND
	my $eland_command = qq{$casava/ELAND_standalone.pl \\\n};
	$eland_command .= qq{--input-type $inputtype \\\n};
	$eland_command .= qq{--eland-genome $referencedir/$reference \\\n};
	$eland_command .= qq{--input-file $inputfile \\\n};
	$eland_command .= qq{--input-file $matefile \\\n} if defined $matefile;	
	$eland_command .= qq{--seedlength $seedlength \\\n} if defined $seedlength;
	$eland_command .= qq{--base-quality $quality \\\n} if defined $quality;
	$eland_command .= qq{--pair-params $pairparams \\\n} if defined $pairparams;
	$eland_command .= "\n";

	#### CHECK TEMPDIR EXISTS AND IS NOT A FILE
	my $tempdir = $self->tempdir();
	if ( defined $tempdir and $tempdir and not -d $tempdir )
	{
		print "ELAND::batchCommand    tempdir directory not found: $tempdir\n" if not -d $tempdir;
		print "ELAND::batchCommand    tempdir is a file: $tempdir\n" if -f $tempdir;
	}

	#### SET OUTPUT DIRECTORY
	my $outdir = "$basedir/$reference/$index";
	
	#### SET TEMP-RELATED DIRS
	my $old_outdir	=	$outdir;
	my $temp_outdir =	"$tempdir/$outdir" if defined $tempdir;

	#### USE TEMPDIR IF DEFINED
	if ( defined $tempdir and $tempdir and -d $tempdir )
	{
		print "ELAND::batchCommand    USING tempdir: $tempdir\n" if $DEBUG;

		#### SET TEMP OUTPUT DIR
		$outdir = $temp_outdir;
	}
	
	#### SET SCRIPT
	my $command = qq{
export PATH=$casava:\$PATH
export PATH=$referencedir/\$LSB_JOBINDEX:\$PATH
mkdir -p $outdir
cd $outdir
$eland_command
};

	if ( defined $tempdir )
	{
		$command .= qq{
mv $outdir/* $old_outdir
rm -fr $outdir

};
	}

	return $command;	
}	#	batchCommand
sub indexReferenceFiles {	#### CONVERT .fa REFERENCE FASTA FILES TO ELAND INDEX FORMAT
	my $self			=	shift;
	my $inputdir		=	shift;
	my $outputdir		=	shift;

	my $DEBUG = 1;
	#print "ELAND::indexReferenceFiles    ELAND::indexReferenceFiles(inputdir, outputdir) ", Timer::current_datetime(), "\n" if $DEBUG;
	#print "ELAND::indexReferenceFiles    inputdir: $inputdir\n" if $DEBUG;
	#print "ELAND::indexReferenceFiles    outputdir: $outputdir\n" if $DEBUG;

	File::Path::mkpath($outputdir) if not -d $outputdir;
	print "ELAND::indexReferenceFiles    Can't create outputdir: $outputdir\n" and exit if not -d $outputdir;

	#### SANITY CHECK
	print "ELAND::indexReferenceFiles    inputdir not defined: $inputdir\n" and exit if not defined $inputdir;
	print "ELAND::indexReferenceFiles    outputdir not defined: $outputdir\n" and exit if not defined $outputdir;
	print "ELAND::indexReferenceFiles    inputdir is a file: $inputdir\n" and exit if -f $inputdir;
	print "ELAND::indexReferenceFiles    outputdir is a file: $outputdir\n" and exit if -f $outputdir;
	print "ELAND::indexReferenceFiles    Can't find inputdir: $inputdir\n" and exit if not -d $inputdir;
	print "ELAND::indexReferenceFiles    Can't find outputdir: $outputdir\n" and exit if not -d $outputdir;
	
	#### GET REFERENCE FILES
	my $fastafiles = $self->listFiles($inputdir, "\*.fa");

	#### GET CASAVA
	my $casava		=	$self->casava();
	print "ELAND::indexReferenceFiles    casava not defined\n" and exit if not defined $casava or not $casava;

	#### CONVERT FILES 
	my $counter = 0;
	my $jobs = [];
	for my $fastafile ( @$fastafiles )
	{
		next if $fastafile =~ /^[\.]+$/;

		my ($reference) = $fastafile =~ /^.+?\/([^\/]+)$/;
		my $command;
		$command = "time $casava/squashGenome $outputdir $fastafile";
		print "ELAND::indexReferenceFiles    command: $command\n" if $DEBUG;

		#### SET LABEL
		my $label = "eland-indexRef-$counter";

		#### SET JOB
		my $job = $self->setJob( [ $command ], $label, $outputdir);
		push @$jobs, $job;
	}

	#### RUN ALIGNMENT JOBS
	my $label = "eland-indexRef";
	$self->runJobs($jobs, $label);
}

=head2

	SUBROUTINE		exportToSam
	
	PURPOSE
	
		1. CONVERT *_export.txt ELAND OUTPUT FILE TO out.sam SAMTOOLS FILE

		2. DO FOR *_export.txt FILES PRODUCED BY ALIGNMENTS OF ALL SPLITFILES
		
			AGAINST ALL REFERENCE SUBDIRECTORIES
			
	NOTES
	
		NB: THIS USES --qlogodds OPTION FOR export2sam.p WHICH ASSUMES THAT
		
			THE INPUT FILES ARE IN solexa FORMAT
		
=cut

sub exportToSam {		#### CONVERT *_export.txt ELAND OUTPUT FILE TO out.sam SAMTOOLS FILE
	my $self			=	shift;

	return $self->localExportToSam(@_) if not $self->cluster();	

	my $splitfiles 		=	shift;
	my $referencedir 	=	shift;
	my $outputdir 		=	shift;
	my $references 		=	shift;
	my $matefiles		=	shift;
	
my $DEBUG = 1;
	print "ELAND::exportToSam    ELAND::exportToSam()\n" if $DEBUG;

	#### GET REQUIRED VARIABLES
	my $samtools = $self->samtools();
	print "ELAND::exportToSam    samtools: $samtools\n" if $DEBUG;
	print "ELAND::exportToSam    samtools not defined. Exiting\n" and exit if not defined $samtools;

	#### COLLECT ALL JOBS FOR EACH INPUT FILE AGAINST ALL REFERENCE FILES
	my $jobs = [];
	foreach my $reference ( @$references )
	{
		my $refdir = "$referencedir/$reference";
		next if $refdir =~ /^[\.]+$/;

		my ($basedir, $task) = $$splitfiles[0][0] =~ /^(.+?)\/(\d+)\/[^\/]+$/;
		#print "basedir: $basedir\n" if $DEBUG;
		#print "task: $task\n" if $DEBUG;

		#### SET INDEX PATTERN FOR BATCH JOB
		my $index = $self->getIndex();

		my $outdir = "$basedir/$reference";
		File::Path::mkpath($outdir) if not -d $outdir;
		print "Could not create output dir: $outdir\n" if not -d $outdir;

		#### OUTPUT SAM FILE
		my $samfile = "$outdir/$index/out.sam";

		#### INPUT EXPORT FILES
		my $exportfile_1 = "$outdir/$index/reanalysis_export.txt";
		my $exportfile_2;
		if ( defined $matefiles )
		{
			$exportfile_1 = "$outdir/$index/reanalysis_1_export.txt";
			$exportfile_2 = "$outdir/$index/reanalysis_2_export.txt";
		}
	
		#### SET LOCATION OF export2sam
		my $export2sam = "$samtools/export2sam.pl";
		$samtools =~ /(\d+)\.(\d+)\.(\d+)(\/)?$/;
		my $hundreds= 	$1 || 0;
		my $tens	=	$2 || 0;
		my $ones	=	$3 || 0;
		my ($samtools_version) = $hundreds * 100 + $tens * 10 + $ones;

		#### SET COMMAND
		my $command = qq{$samtools/export2sam.pl $exportfile_1 $exportfile_2 > $samfile\n};

		if ( $samtools_version >= 18 )
		{
			####	export2sam.pl converts GERALD export files to SAM format.
			####	
			####	Usage: export2sam.pl --read1=FILENAME [ options ] | --version | --help
			####	
			####	  --read1=FILENAME  read1 export file (mandatory)
			####	  --read2=FILENAME  read2 export file
			####	  --nofilter        include reads that failed the pipeline/RTA purity filter
			####	  --qlogodds        assume export file(s) use logodds quality values as reported
			####						  by pipeline prior to v1.3 (default: phred quality values)

			$command = "$samtools/misc/export2sam.pl --read1=$exportfile_1 ";
			$command .= " --read2=$exportfile_2" if defined $exportfile_2;
			$command .= " --qlogodds ";
			$command .= " > $samfile\n";
		}	

		#### SET LABEL AND TASKS
		my $label = "exportToSam-$reference";
		my $tasks = scalar(@$splitfiles);
			
		#### SET JOB-
		my $job = $self->setBatchJob( [ $command ], $label, $outdir, $tasks);
#print "ELAND::exportToSam    job:\n";
#print Dumper $job;
#exit;

		push @$jobs, $job;	
	}
	print "ELAND::run    length(jobs): ", scalar(@$jobs), "\n" if $DEBUG;

	#### RUN ALIGNMENT JOBS
	$self->runJobs($jobs, "exportToSam");	
}

=head2

	SUBROUTINE		localExportToSam
	
	PURPOSE
	
		1. CONVERT *_export.txt ELAND OUTPUT FILE TO out.sam SAMTOOLS FILE

		2. DO FOR *_export.txt FILES PRODUCED BY ALIGNMENTS OF ALL SPLITFILES
		
			AGAINST ALL REFERENCE SUBDIRECTORIES
			
	NOTES
	
		NB: THIS USES --qlogodds OPTION FOR export2sam.p WHICH ASSUMES THAT
		
			THE INPUT FILES ARE IN solexa FORMAT
		
=cut

sub localExportToSam {		#### CONVERT *_export.txt ELAND OUTPUT FILE TO out.sam SAMTOOLS FILE
	my $self			=	shift;
	my $splitfiles 		=	shift;
	my $referencedir 	=	shift;
	my $outputdir 		=	shift;
	my $references 		=	shift;
	my $matefiles		=	shift;
	
my $DEBUG = 1;
	print "ELAND::localExportToSam    ELAND::localExportToSam()\n" if $DEBUG;

	#### GET REQUIRED VARIABLES
	my $samtools = $self->samtools();
	print "ELAND::localExportToSam    samtools: $samtools\n" if $DEBUG;
	print "ELAND::localExportToSam    samtools not defined. Exiting\n" and exit if not defined $samtools;

	#### COLLECT ALL JOBS FOR EACH INPUT FILE AGAINST ALL REFERENCE FILES
	my $jobs = [];
	foreach my $reference ( @$references )
	{
		my $refdir = "$referencedir/$reference";
		next if $refdir =~ /^[\.]+$/;

		#### DO ALIGNMENTS FOR ALL SPLITFILES 
		my $counter = 0;
		foreach my $splitfile ( @$splitfiles )
		{
			$counter++;

			#### SET OUTPUT DIR TO SUBDIRECTORY CONTAINING SPLITFILE
			my ($basedir, $index) = $$splitfile[0] =~ /^(.+?)\/(\d+)\/([^\/]+)$/;
			my $outdir = "$outputdir/$reference/$index";
			File::Path::mkpath($outdir) if not -d $outdir;
			print "Could not create output dir: $outdir\n" if not -d $outdir;
	
			#### OUTPUT SAM FILE
			my $samfile = "$outdir/out.sam";
	
			#### INPUT EXPORT FILES
			my $exportfile_1 = "$outdir/reanalysis_export.txt";
			my $exportfile_2;
			if ( defined $matefiles )
			{
				$exportfile_1 = "$outdir/reanalysis_1_export.txt";
				$exportfile_2 = "$outdir/reanalysis_2_export.txt";
			}
		
			#### SET LOCATION OF export2sam
			my $export2sam = "$samtools/export2sam.pl";
			$samtools =~ /(\d+)\.(\d+)\.(\d+)(\/)?$/;
			my $hundreds= 	$1 || 0;
			my $tens	=	$2 || 0;
			my $ones	=	$3 || 0;
			my ($samtools_version) = $hundreds * 100 + $tens * 10 + $ones;
	
			#### SET COMMAND
			my $command = qq{$samtools/export2sam.pl $exportfile_1 $exportfile_2 > $samfile\n};
	
			if ( $samtools_version >= 18 )
			{
				####	export2sam.pl converts GERALD export files to SAM format.
				####	
				####	Usage: export2sam.pl --read1=FILENAME [ options ] | --version | --help
				####	
				####	  --read1=FILENAME  read1 export file (mandatory)
				####	  --read2=FILENAME  read2 export file
				####	  --nofilter        include reads that failed the pipeline/RTA purity filter
				####	  --qlogodds        assume export file(s) use logodds quality values as reported
				####						  by pipeline prior to v1.3 (default: phred quality values)
	
				$command = "$samtools/misc/export2sam.pl --read1=$exportfile_1 ";
				$command .= " --read2=$exportfile_2" if defined $exportfile_2;
				$command .= " --qlogodds ";
				$command .= " > $samfile\n";
			}	
	
			#### SET LABEL AND TASKS
			my $label = "localExportToSam-$reference";
			my $tasks = scalar(@$splitfiles);
				
			#### SET JOB
			my $job = $self->setJob( [ $command ], $label, $outdir);
	
			push @$jobs, $job;
		}

	}
	print "ELAND::run    length(jobs): ", scalar(@$jobs), "\n" if $DEBUG;	
	
	#### RUN ALIGNMENT JOBS
	$self->runJobs($jobs, "localExportToSam");	
}


sub getReferences {		#### RETURN A LIST OF REFERENCE NAMES (I.E.: NOT FILEPATHS)
	my $self		=	shift;
	my $referencedir=	shift;
	
#my $DEBUG = 1;
	print "ELAND::getReferences    ELAND::getReferences(referencedir)\n" if $DEBUG;
	print "ELAND::getReferences    referencedir: $referencedir\n" if $DEBUG;

	my $referencefiles = $self->listReferenceFiles($referencedir, "\*\.vld");
	my $references = $self->getFilenames($referencefiles);
	foreach my $reference ( @$references )
	{
		$reference =~ s/\.vld$//;
		$reference =~ s/\.fa$//;
	}

	return $references;
}






}

