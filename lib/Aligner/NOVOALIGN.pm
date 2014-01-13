use Getopt::Simple;
use MooseX::Declare;
use MooseX::UndefTolerant::Attribute;

our $DEBUG = 0;
#$DEBUG = 1;

=head2

		PACKAGE		Aligner::NOVOALIGN
		
		VERSION		0.01

		PURPOSE
		
	        WRAPPER SCRIPT FOR RUNNING NOVOALIGN ALIGNMENT
			
		HISTORY
					0.01 BASIC VERSION
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

class Aligner::NOVOALIGN with (Agua::Cluster::Jobs,
	Agua::Cluster::Checker,
	Agua::Cluster::Util,
	Agua::Cluster::Convert,
	Agua::Cluster::Merge,
	Agua::Cluster::Sort,
	Agua::Cluster::Usage,
	Agua::Common::Database,
	Agua::Common::Logger,
	Agua::Common::Util,
	Agua::Common::SGE) {

use Agua::DBaseFactory;
use Agua::DBase::MySQL;
use Conf::Agua;
use File::Path;

# BOOLEAN
has 'clean'		=> ( isa => 'Bool|Undef', is => 'rw', default => '' );

# INTS
has 'walltime'	=> ( isa => 'Int|Undef', is => 'rw', default => 24 );

# STRINGS
has 'novoalign'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'threshold'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'min'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'max'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'paired'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'deviation'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );

has 'username'  => ( isa => 'Str|Undef', is => 'rw' );
has 'cluster'	=> ( isa => 'Str|Undef', is => 'rw' );
has 'splitfile'	=> ( isa => 'Str|Undef', is => 'rw' );
has 'tempdir'	=> ( isa => 'Str|Undef', is => 'rw' );
has 'clustertype'=> ( isa => 'Str|Undef', is => 'rw' );
has 'referencedir'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'outputdir'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'replicates'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'label'			=> ( isa => 'Str|Undef', is => 'rw', default => '' );
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

#### DEBUG
our $DEBUG = 0;
#$DEBUG = 1;

#/////}
	
sub BUILD {
	my $self	=	shift;

	#my $DEBUG = 1;
	print "Aligner::NOVOALIGN::BUILD    Aligner::NOVOALIGN::BUILD()\n" if $DEBUG;
	#print "Aligner::NOVOALIGN::BUILD    self:\n" if $DEBUG;
	#print Dumper $self if $DEBUG;

	print "Aligner::NOVOALIGN::BUILD    Doing self->setDbh()\n" if $DEBUG;
	$self->setDbh();
}

=head2

	SUBROUTINE		run

	PURPOSE
	
		CREATE .sh FILE

=cut

sub run {
	my $self		=	shift;	

my $DEBUG = 1;

	print "Aligner::NOVOALIGN::run    Aligner::NOVOALIGN::run()\n" if $DEBUG;

	#### GET CLUSTER
	my $cluster = $self->cluster();

	#### FILES AND DIRS	
	my $referencedir 	= 	$self->referencedir();
	my $outputdir 		=	$self->outputdir();
	my $inputfiles 		=	$self->inputfiles();
	my $matefiles 		=	$self->matefiles();

	#### GET LABEL, SPLITFILE, CHUNKS
	my $label 			= $self->label();
	my $splitfile 		= $self->splitfile();
	my $chunks 			= $self->chunks();
	
	#### SET DEFAULT SPLITFILE IF NOT DEFINED
	$splitfile = "$outputdir/splitfile.txt" if not defined $splitfile;
	print "Aligner::NOVOALIGN::runBatchDoAlignment    splitfile: $splitfile\n" if $DEBUG;


	###############################################
	###########    GET REFERENCEFILES    ##########
	###############################################
	print "Aligner::NOVOALIGN::run    Doing listReferenceFiles()  ", Timer::current_datetime(), "\n";
	my $referencefiles = $self->listReferenceFiles($referencedir);
	print "Aligner::NOVOALIGN::run    After listReferenceFiles()  ", Timer::current_datetime(), "\n";
	print "Aligner::NOVOALIGN::::run    No. referencefiles: ", scalar(@$referencefiles), "\n";

	###############################################
	###########   SET REFERENCE NAMES    ##########
	###############################################
	my $references = [];
	foreach my $referencefile ( @$referencefiles )
	{
		my ($reference) = $referencefile =~ /^.+?\/([^\/]+)$/;
		$reference =~ s/\.idx$//;
		push @$references, $reference if defined $reference;
		print "Reference not defined for referencefile: $referencefile\n" if not defined $reference;
	}
	print "Aligner::NOVOALIGN::::run    references: @$references\n" if $DEBUG;

	##############################################
	############   SPLIT INPUT FILES   ###########
	##############################################
	print "Aligner::NOVOALIGN::run    Doing doSplitfiles()  ", Timer::current_datetime(), "\n" if $DEBUG;
	my $splitfiles = $self->doSplitfiles($splitfile, $label);
	print "Aligner::NOVOALIGN::run    After doSplitfiles()  ", Timer::current_datetime(), "\n" if $DEBUG;
	print "Aligner::NOVOALIGN::::run    No. splitfiles: ", scalar(@$splitfiles), "\n" if $DEBUG;

	##############################################
	############	   SET CHUNKS      ###########
	##############################################
	print "Aligner::NOVOALIGN::run    Doing splitfileChunks()  ", Timer::current_datetime(), "\n" if defined $chunks and $DEBUG;
	$splitfiles = $self->splitfileChunks($splitfiles, $chunks) if defined $chunks;
	print "Aligner::NOVOALIGN::run    After splitfileChunks()  ", Timer::current_datetime(), "\n"  if defined $chunks and $DEBUG;
	print "Aligner::NOVOALIGN::::run    No. splitfiles: ", scalar(@$splitfiles), "\n" if defined $chunks and $DEBUG;

	##############################################
	##########       RUN Aligner::NOVOALIGN         ##########
	##############################################
	print "Aligner::NOVOALIGN::run    Doing doAlignment()   ", Timer::current_datetime(), "\n";
	$self->doBatchAlignment($outputdir, $referencefiles, $splitfiles, $label);
	print "Aligner::NOVOALIGN::run    After doAlignment()   ", Timer::current_datetime(), "\n";

	###############################################
	######        FILTER SAM HITS          ######
	###############################################
	print "Aligner::NOVOALIGN::runSubdirSamHits    Doing subdirSamHits        ", Timer::current_datetime(), "\n";
	$self->subdirSamHits($outputdir, $references, $splitfiles, "out.sam", "hit.sam", "miss.sam");
	print "Aligner::NOVOALIGN::runSubdirSamHits    After subdirSamHits        ", Timer::current_datetime(), "\n";

	################################################
	######        CUMULATIVE MERGE SAM        ######
	################################################
	print "Aligner::NOVOALIGN::run    Doing cumulativeMergeSam        ", Timer::current_datetime(), "\n";
	$self->cumulativeMergeSam($outputdir, $references, $splitfiles, "hit.sam", "hit.sam");
	print "Aligner::NOVOALIGN::run    After cumulativeMergeSam        ", Timer::current_datetime(), "\n";

	##############################################
	#########         SORT SAM         ###########
	##############################################
	print "Aligner::NOVOALIGN::run    Doing samToBam     ", Timer::current_datetime(), "\n";
	$self->samToBam($outputdir, $references, "hit.sam", "hit.bam");
	print "Aligner::NOVOALIGN::run    After samToBam     ", Timer::current_datetime(), "\n";
	
}	#	run

sub indexReferenceFiles {	#### CONVERT .fa REFERENCE FILES INTO .idx NOVOALIGN INDEX FILES
	my $self			=	shift;
	my $inputdir		=	shift;
	my $outputdir		=	shift;

	my $DEBUG = 1;
	print "NOVOALIGN::indexReferenceFiles    NOVOALIGN::indexReferenceFiles(inputdir, outputdir) ", Timer::current_datetime(), "\n" if $DEBUG;
	print "NOVOALIGN::indexReferenceFiles    inputdir: $inputdir\n" if $DEBUG;
	print "NOVOALIGN::indexReferenceFiles    outputdir: $outputdir\n" if $DEBUG;

	#### GET REFERENCE FILES
	my $fastafiles = $self->listFiles($inputdir, "\*.fa");

	#### GET NOVOALIGN
	my $novoalign		=	$self->novoalign();
	print "NOVOALIGN::convertReferences    novoalign not defined\n" and exit if not defined $novoalign or not $novoalign;

	chdir($inputdir) or die "NOVOALIGN::convertReferences    Can't change to inputdir directory: $inputdir\n";
	
	my $jobs = [];
	my $counter = 0;
	foreach my $fastafile ( @$fastafiles )
	{
		$counter++;
		my ($reference) = $fastafile =~ /([^\/]+)\.fa$/;

		#### SET REFERENCE BINARY FILE
		my $referencebinary = "$outputdir/$reference.idx";

		#### CONVERT REFERENCE FILE INTO BINARY FILE
		my $command;
		$command = "time $novoalign/novoindex -k 14 -s 2 $referencebinary $fastafile";
		print "NOVOALIGN::convertReference    command: $command\n" if defined $command;

		#### SET LABEL
		my $label = "novo-indexRef-$counter";

		#### SET JOB
		my $job = $self->setJob( [ $command ], $label, $outputdir);
		push @$jobs, $job;
	}

	#### RUN ALIGNMENT JOBS
	my $label = "maq-indexRef";
	$self->runJobs($jobs, $label);
}

=head2

	SUBROUTINE		doBatchAlignment
	
	PURPOSE
	
		1. RUN NOVOALIGN AGAINST ALL REFERENCE FILES
		
		2. DO ALL REFERENCES IN PARALLEL AS A BATCH JOBS
		
=cut

sub doBatchAlignment {
	my $self			=	shift;
	my $outputdir		=	shift;
	my $referencefiles 	=	shift;
	my $splitfiles		=	shift;
	my $label			=	shift;	

my $DEBUG = 1;
	print "Aligner::NOVOALIGN::doBatchAlignment    Aligner::NOVOALIGN::doBatchAlignment(outputfile, referencefile, splitfiles)\n" if $DEBUG;
	print "Aligner::NOVOALIGN::doBatchAlignment    outputdir: $outputdir\n" if $DEBUG;
	#print "Aligner::NOVOALIGN::doBatchAlignment    referencefiles: @$referencefiles\n" if $DEBUG;
	#print "Aligner::NOVOALIGN::doBatchAlignment    splitfiles: @$splitfiles\n" if $DEBUG;
	
	#### COLLECT ALL JOBS FOR EACH INPUT FILE AGAINST ALL REFERENCE FILES
	my $jobs = $self->generateBatchJobs($outputdir, $referencefiles, $splitfiles, $label);
	print "Aligner::NOVOALIGN::doBatchAlignment    length(jobs): ", scalar(@$jobs), "\n" if $DEBUG;
	
	##### RUN ALIGNMENT JOBS
	$self->runJobs($jobs, "Aligner::NOVOALIGN");
}

=head2

	SUBROUTINE		batchCommand

	PURPOSE
	
		CREATE .sh FILE

=cut

sub batchCommand {
	my $self			=	shift;
	my $outputdir		=	shift;
	my $referencepath	=	shift;
	my $splitfiles		=	shift;

my $DEBUG = 1;

	print "Aligner::NOVOALIGN::batchCommand    Aligner::NOVOALIGN::batchCommand(outputfile, referencepath, splitfiles)\n" if $DEBUG;
	print "Aligner::NOVOALIGN::batchCommand    outputdir: $outputdir\n" if $DEBUG;
	print "Aligner::NOVOALIGN::batchCommand    referencepath: $referencepath\n" if $DEBUG;
	#print "Aligner::NOVOALIGN::batchCommand    splitfiles:\n" if $DEBUG;
	#print Dumper $splitfiles if $DEBUG;

	#### USER INPUTS
	my $threshold		= 	$self->threshold();
	my $paired 			= 	$self->paired();
	my $distance 		=	$self->distance();
	my $deviation 		=	$self->deviation();
	my $params 			=	$self->params();  #### OVERRIDE PARAMS IN DEFAULT COMMAND
	my $label 			=	$self->label();	#### USED TO GENERATE INPUTFILE NAMES	
	my $keep 			=	$self->keep();

	#### EXECUTABLES
	my $novoalign 		=	$self->novoalign();

	##### CLUSTER AND CPUS
	my $cluster 		=	$self->cluster();
	my $cpus 			=	$self->cpus();

	print "Aligner::NOVOALIGN::batchCommand    distance not defined. Exiting\n" if not defined $distance and $paired;
	print "Aligner::NOVOALIGN::batchCommand    deviation not defined. Exiting\n" if not defined $deviation and $paired;
	print "Aligner::NOVOALIGN::batchCommand    label not defined. Exiting\n" if not defined $label;

	print "Aligner::NOVOALIGN::batchCommand    cluster: $cluster\n" if $DEBUG;

	#### SET PAIRED USING MATEFILES, I.E., DURING NORMAL RUN, NOT CALLED BY check
	$paired = 1 if defined $self->matefiles();

	#### GET THE BASE DIRECTORY OF THE SPLIT FILES - ALWAYS TWO DIRECTORIES DOWN
	my $splitfile = $$splitfiles[0][0];
	print "Aligner::NOVOALIGN::batchCommand    splitfile: $splitfile\n" if $DEBUG;
	my ($basedir) = $splitfile =~ /^(.+?)\/\d+\/([^\/]+)$/;
	print "Aligner::NOVOALIGN::batchCommand    basedir: $basedir\n" if $DEBUG;
	
	#### GET SUFFIX OF SPLIT FILE IF EXISTS
	my ($suffix) = $self->fileSuffix($splitfile);
	$suffix = '' if not defined $suffix;

	#### SET INDEX PATTERN FOR BATCH JOB
	my $index;
	$index = "\$LSB_JOBINDEX" if $cluster eq "LSF";
	$index = "\$PBS_TASKNUM" if $cluster eq "PBS";

	#### SET OUTPUT FILES
	my ($reference) = $referencepath =~ /([^\/]+)$/;
	$reference =~ s/\.idx//;
	print "Aligner::NOVOALIGN::batchCommand    reference: $reference\n" if $DEBUG;

	my $outdir = "$outputdir/$index";
	my $outputfile = "$outdir/out.sam";
	my $alignedfile = "$outdir/aligned.txt";
	my $unalignedfile = "$outdir/unaligned.txt";
	print "Aligner::NOVOALIGN::batchCommand    unalignedfile: $unalignedfile\n" if $DEBUG;
	print "Aligner::NOVOALIGN::batchCommand    outputfile: $outputfile\n" if $DEBUG;

	#### CREATE OUTPUT DIR IF NOT EXISTS
	File::Path::mkpath($outdir) if not -d $outdir;
	print "Can't create outdir: $outdir\n" if not -d $outdir;

	#### SET INPUT AND MATE FILES, E.G.:
	#### /scratch/syoung/base/pipeline/bixby/run1/ln/$LSB_JOBINDEX/ln_1.$LSB_JOBINDEX.txt
	#### /scratch/syoung/base/pipeline/bixby/run1/ln/$LSB_JOBINDEX/ln_2.$LSB_JOBINDEX.txt	
	my $firstmate = $label . "_1";
	my $inputfile = "$basedir/$index/$firstmate.$index$suffix";
	print "Aligner::NOVOALIGN::batchCommand    AFTER inputfile: $inputfile\n" if $DEBUG;

	#### DO SECOND MATE IF matefiles DEFINED
	my $secondmate = $label . "_2" if $paired;
	my $matefile = "$basedir/$index/$secondmate.$index$suffix" if $paired;
	print "Aligner::NOVOALIGN::batchCommand    AFTER matefile: $matefile\n" if $DEBUG and defined $matefile;

	my $command; 

	#### CHECK TEMPDIR EXISTS AND IS NOT A FILE
	my $tempdir = $self->tempdir();
	if ( defined $tempdir and $tempdir and not -d $tempdir )
	{
		print "Aligner::NOVOALIGN::batchCommand    tempdir directory not found: $tempdir\n" if not -d $tempdir;
		print "Aligner::NOVOALIGN::batchCommand    tempdir is a file: $tempdir\n" if -f $tempdir;
	}

	#### SET TEMP-RELATED DIRS
	my $old_outdir	=	$outdir;
	my $temp_outdir 	=	"$tempdir/$outdir" if defined $tempdir;

	#### USE TEMPDIR IF DEFINED
	if ( defined $tempdir and $tempdir and -d $tempdir )
	{
		print "Aligner::NOVOALIGN::batchCommand    USING tempdir: $tempdir\n" if $DEBUG;

		#### SET TEMP OUTPUT DIR
		$outdir = $temp_outdir;
	}
	
	#### SET NOVOALIGN COMMAND
	my $novoalign_command = qq{time $novoalign/novoalign \\
-o SAM \\\n};
	
	#### ADD PARAMS
	$novoalign_command .= qq{$params \\\n} if defined $params;

	#### ADD DISTANCE & DEVIATION IF PAIRED
	$novoalign_command .= qq{-i $distance $deviation \\\n} if $paired;

	#### ADD REFERENCE FILE
	$novoalign_command .= qq{-d $referencepath \\\n};

	#### ADD INPUT FILES
	$novoalign_command .= qq{-f $inputfile $threshold \\\n} if not $paired;
	$novoalign_command .= qq{-f $inputfile $matefile $threshold\\\n} if $paired;
	print "Aligner::NOVOALIGN::batchCommand    command: $novoalign_command\n" if $DEBUG;

	#### OUTPUT FILE
	$novoalign_command =~ s/\\+\n$//g;
	$novoalign_command .= qq{ > $outputfile\n};

print "Aligner::NOVOALIGN    $novoalign_command\n";
exit;


	#### SET SCRIPT
	$command = qq{

export PATH=$novoalign:\$PATH
export PATH=$outdir:\$PATH
mkdir -p $outdir
cd $outdir

$novoalign_command

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







=head2

	SUBROUTINE		listReferenceFiles

	PURPOSE
	
		RETRIEVE A LIST OF REFERENCE FILES FROM THE REFERENCE DIRECTORY

=cut

sub listReferenceFiles {
	my $self		=	shift;
	my $reference	=	shift;

#my $DEBUG = 1;
	print "Aligner::NOVOALIGN::listReferenceFiles    Aligner::NOVOALIGN::listReferenceFiles(reference)\n" if $DEBUG;
	print "Aligner::NOVOALIGN::listReferenceFiles    reference: $reference\n" if $DEBUG;

	my $referencefiles = $self->listFiles($reference, "*\.idx");
	print "Novoalign::listReferenceFiles    No reference files in directory: $reference\n" and exit if not defined $referencefiles or scalar(@$referencefiles) == 0;
	
	#### SORT BY NUMBER
	@$referencefiles = Util::sort_naturally(\@$referencefiles);
	print "Novoalign::listReferenceFiles    referencefiles: @$referencefiles\n" if $DEBUG;

	#### DEBUG
	@$referencefiles = reverse @$referencefiles;
	print "Novoalign::listReferenceFiles    Reversed referencefiles: @$referencefiles\n" if $DEBUG;
	
	return $referencefiles;
}


=head2

	SUBROUTINE		getReferenceFiles
	
	PURPOSE
	
		RETURN A LIST OF REFERENCE FILES (FULL PATHS TO FILES)
		
=cut

sub getReferenceFiles {
	my $self		=	shift;
	my $referencedir=	shift;
	
	return $self->listReferenceFiles($referencedir, "\*\.idx");
}



=head2

	SUBROUTINE		getReferences
	
	PURPOSE
	
		RETURN A LIST OF REFERENCE NAMES (N.B.: NOT THE PATHS TO THE FILES)
		
=cut

sub getReferences {
	my $self		=	shift;
	my $referencedir=	shift;
	
	my $referencefiles = $self->getReferenceFiles($referencedir);
	my $references = $self->getFilenames($referencefiles);
	foreach my $reference ( @$references )	{	$reference =~ s/\.idx$//;	}

	return $references;
}



}
