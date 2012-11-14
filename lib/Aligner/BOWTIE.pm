use Getopt::Simple;
use MooseX::Declare;
use MooseX::UndefTolerant::Attribute;

=head2

	PACKAGE		BOWTIE
	
	VERSION		0.03

	PURPOSE
	
		WRAPPER SCRIPT FOR RUNNING BOWTIE SNP PREDICTION
		
	HISTORY
	
		0.03 AFTER TESTING FOR SPEED (SEE COMMENTED OUT ALTERNATIVES 
			BELOW), OPTED FOR CUMULATIVE MERGE OF SAM SUBFILES, FOLLOWED
			BY CONVERSION TO BAM

		0.02 ADDED CHUNK-BY-CHROMOSOME IF referencedir SPECIFIED
			AND RUN CUFFLINKS COMMAND
			
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

class Aligner::BOWTIE with (Agua::Cluster::Jobs,
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

has 'bowtie'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
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
	print "Aligner::BOWTIE::BUILD    Aligner::BOWTIE::BUILD()\n" if $DEBUG;
	#print "Aligner::BOWTIE::BUILD    self:\n" if $DEBUG;
	#print Dumper $self if $DEBUG;

	print "Aligner::BOWTIE::BUILD    Doing self->setDbh()\n" if $DEBUG;
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

	print "BOWTIE::run    BOWTIE::run()\n";

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
	my $chunks = $self->chunks();

	#### SET DEFAULT SPLITFILE IF NOT DEFINED
	$splitfile = "$outputdir/splitfile.txt" if not defined $splitfile;
	print "BOWTIE::runBatchDoAlignment    splitfile: $splitfile\n" if $DEBUG;

	###############################################
	###########    GET REFERENCEFILES    ##########
	###############################################
	print "BOWTIE::run    Doing listReferenceFiles()  ", Timer::current_datetime(), "\n";
	my $referencefiles = $self->listReferenceFiles($referencedir);
	print "BOWTIE::run    After listReferenceFiles()  ", Timer::current_datetime(), "\n";
	print "BOWTIE::run    No. referencefiles: ", scalar(@$referencefiles), "\n";
	print "BOWTIE::run    referencefiles: \n";
	print join "\n", @$referencefiles;
	print "\n";
#exit;

	###############################################
	###########   SET REFERENCE NAMES    ##########
	###############################################
	my $references = [];
	foreach my $referencefile ( @$referencefiles )
	{
		my ($reference) = $referencefile =~ /^.+?\/([^\/]+)$/;
		push @$references, $reference if defined $reference;
		print "Reference not defined for referencefile: $referencefile\n" if not defined $reference;
	}
	print "BOWTIE::::run    references: @$references\n";

	##############################################
	############	SPLIT INPUT FILES   ###########
	##############################################
	print "BOWTIE::run    Doing doSplitfiles()  ", Timer::current_datetime(), "\n" if $DEBUG;
	my $splitfiles = $self->doSplitfiles($splitfile, $label);
	print "BOWTIE::run    After doSplitfiles()  ", Timer::current_datetime(), "\n" if $DEBUG;
	print "BOWTIE::::run    No. splitfiles: ", scalar(@$splitfiles), "\n" if $DEBUG;
	
	##############################################
	############	   SET CHUNKS      ###########
	##############################################
	print "BOWTIE::run    Doing splitfileChunks()  ", Timer::current_datetime(), "\n" if defined $chunks and $DEBUG;
	$splitfiles = $self->splitfileChunks($splitfiles, $chunks) if defined $chunks;
	print "BOWTIE::run    After splitfileChunks()  ", Timer::current_datetime(), "\n"  if defined $chunks and $DEBUG;
	print "BOWTIE::::run    No. splitfiles: ", scalar(@$splitfiles), "\n" if defined $chunks and $DEBUG;

	##############################################
	##########       RUN BOWTIE         ##########
	##############################################
	print "BOWTIE::run    Doing doAlignment()   ", Timer::current_datetime(), "\n";
	$self->doBatchAlignment($outputdir, $referencefiles, $splitfiles, $label);
	print "BOWTIE::run    After doAlignment()   ", Timer::current_datetime(), "\n";

	###############################################
	######        FILTER SAM HITS          ######
	###############################################
	print "BOWTIE::runSubdirSamHits    Doing subdirSamHits        ", Timer::current_datetime(), "\n";
	$self->subdirSamHits($outputdir, $references, $splitfiles, "out.sam", "hit.sam", "miss.sam");
	print "BOWTIE::runSubdirSamHits    After subdirSamHits        ", Timer::current_datetime(), "\n";
	
	################################################
	######        CUMULATIVE MERGE SAM        ######
	################################################
	print "BOWTIE::run    Doing cumulativeMergeSam        ", Timer::current_datetime(), "\n";
	$self->cumulativeMergeSam($outputdir, $references, $splitfiles, "hit.sam", "hit.sam");
	print "BOWTIE::run    After cumulativeMergeSam        ", Timer::current_datetime(), "\n";

	##############################################
	#########         SORT SAM         ###########
	##############################################
	print "BOWTIE::run    Doing samToBam     ", Timer::current_datetime(), "\n";
	$self->samToBam($outputdir, $references, "hit.sam", "hit.bam");
	print "BOWTIE::run    After samToBam     ", Timer::current_datetime(), "\n";
	
}	#	run


=head2

	SUBROUTINE		getReferenceFiles
	
	PURPOSE
	
		RETURN A LIST OF REFERENCE FILES (FULL PATHS TO FILES)
		
=cut

sub getReferenceFiles {
	my $self		=	shift;
	my $referencedir=	shift;
	
	return $self->listReferenceFiles($referencedir, "\*\.rev\.1\.ebwt");
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
	foreach my $reference ( @$references )	{	$reference =~ s/\.rev\.1\.ebwt$//;	}

	return $references;
}




=head2

	SUBROUTINE		doAlignment
	
	PURPOSE
	
		RUN BOWTIE AGAINST ALL REFERENCE FILES
		
=cut

sub doBatchAlignment {
	my $self			=	shift;
	my $outputdir		=	shift;
	my $referencefiles 	=	shift;
	my $splitfiles		=	shift;
	my $label			=	shift;	

my $DEBUG = 1;
	print "BOWTIE::doBatchAlignment    BOWTIE::doBatchAlignment(outputfile, referencefile, splitfiles)\n" if $DEBUG;
	print "BOWTIE::doBatchAlignment    outputdir: $outputdir\n" if $DEBUG;
	print "BOWTIE::doBatchAlignment    Number referencefiles: ", scalar(@$referencefiles), "\n" if $DEBUG;
	print "BOWTIE::doBatchAlignment    Number splitfiles: ", scalar(@$splitfiles), "\n" if $DEBUG;

	#### COLLECT ALL JOBS FOR EACH INPUT FILE AGAINST ALL REFERENCE FILES
	my $jobs = $self->generateBatchJobs($outputdir, $referencefiles, $splitfiles, $label);
	print "Bowtie::doBatchAlignment    length(jobs): ", scalar(@$jobs), "\n" if $DEBUG;
	
	##### RUN ALIGNMENT JOBS
	$self->runJobs($jobs, "BOWTIE");
}



=head2

	SUBROUTINE		listReferenceFiles

	PURPOSE
	
		RETRIEVE A LIST OF REFERENCE FILES FROM THE REFERENCE DIRECTORY

=cut

sub listReferenceFiles {
	my $self		=	shift;
	my $reference	=	shift;

#my $DEBUG = 1;
	print "BOWTIE::listReferenceFiles    BOWTIE::listReferenceFiles(reference)\n" if $DEBUG;
	print "BOWTIE::listReferenceFiles    reference: $reference\n" if $DEBUG;

	my $referencefiles = $self->listFiles($reference, "\*rev.1.ebwt");
	print "Bowtie::listReferenceFiles    No reference files in directory: $reference\n" and exit if not defined $referencefiles or scalar(@$referencefiles) == 0;

	#### TRUNCATE REFERENCE FILES TO CREATE CORRECT STUB IDENTIFIER
	foreach my $referencefile ( @$referencefiles )	{ $referencefile =~ s/\.rev\.1\.ebwt$//; }
	
	#### SORT BY NUMBER
	@$referencefiles = Util::sort_naturally(\@$referencefiles);
	print "Bowtie::listReferenceFiles    referencefiles: @$referencefiles\n" if $DEBUG;

	#### DEBUG
	@$referencefiles = reverse @$referencefiles;
	print "Bowtie::listReferenceFiles    Reversed referencefiles: @$referencefiles\n" if $DEBUG;
	
	return $referencefiles;
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

	print "BOWTIE::batchCommand    BOWTIE::batchCommand(outputfile, referencepath, splitfiles)\n" if $DEBUG;
	print "BOWTIE::batchCommand    outputdir: $outputdir\n" if $DEBUG;
	print "BOWTIE::batchCommand    referencepath: $referencepath\n" if $DEBUG;
	
	#### USER INPUTS
	my $paired 			= 	$self->paired();
	my $distance 		=	$self->distance();
	my $params 			=	$self->params();  #### OVERRIDE PARAMS IN DEFAULT COMMAND
	my $label 			=	$self->label();	#### USED TO GENERATE INPUTFILE NAMES	
	my $keep 			=	$self->keep();

	$paired = 1 if defined $self->matefiles();

	print "BOWTIE::batchCommand    distance not defined. Exiting\n" if not defined $distance;
	print "BOWTIE::batchCommand    label not defined. Exiting\n" if not defined $label;

	#### EXECUTABLES
	my $bowtie 			=	$self->bowtie();

	##### CLUSTER AND CPUS
	my $cluster 		=	$self->cluster();
	my $cpus 			=	$self->cpus();

	#### GET THE BASE DIRECTORY OF THE SPLIT FILES - ALWAYS TWO DIRECTORIES DOWN
	my $splitfile = $$splitfiles[0][0];
	#print "BOWTIE::batchCommand    splitfile: $splitfile\n";
	my ($basedir) = $splitfile =~ /^(.+?)\/\d+\/([^\/]+)$/;
	#print "BOWTIE::batchCommand    basedir: $basedir\n";
	
	#### GET SUFFIX OF SPLIT FILE IF EXISTS
	my ($suffix) = $self->fileSuffix($splitfile);
	$suffix = '' if not defined $suffix;

	#### SET INDEX PATTERN FOR BATCH JOB
	my $index;
	$index = "\$LSB_JOBINDEX" if $cluster eq "LSF";
	$index = "\$PBS_TASKNUM" if $cluster eq "PBS";
	$index = "\$TASKNUM" if $cluster eq "SGE";

	#### SET OUTPUT FILES
	my ($reference) = $referencepath =~ /([^\/]+)$/;
	$reference =~ s/\.bfa//;
	my $outdir = "$outputdir/$index";

	#### SET TEMP OUTPUT DIR
	my $tempdir = $self->tempdir();
	if ( defined $tempdir and $tempdir )
	{
		print "BOWTIE::batchCommand    Cant' find tempdir: $tempdir\n"
			and exit if not -d $tempdir;
		print "BOWTIE::batchCommand    tempdir is a file: $tempdir\n"
			and exit if -f $tempdir;
	}
	$outdir = "$tempdir/$outdir" if defined $tempdir and $tempdir;

	my $outputfile = "$outdir/out.sam";
	my $alignedfile = "$outdir/aligned.txt";
	my $unalignedfile = "$outdir/unaligned.txt";
	print "BOWTIE::batchCommand    unalignedfile: $unalignedfile\n" if $DEBUG;
	print "BOWTIE::batchCommand    outputfile: $outputfile\n" if $DEBUG;

	#### SET INPUT AND MATE FILES, E.G.:
	#### /scratch/syoung/base/pipeline/bixby/run1/ln/$LSB_JOBINDEX/ln_1.$LSB_JOBINDEX.txt
	#### /scratch/syoung/base/pipeline/bixby/run1/ln/$LSB_JOBINDEX/ln_2.$LSB_JOBINDEX.txt	
	my $firstmate = $label . "_1";
	my $inputfile = "$basedir/$index/$firstmate.$index$suffix";
	print "BOWTIE::batchCommand    AFTER inputfile: $inputfile\n" if $DEBUG;

	#### DO SECOND MATE IF matefiles DEFINED
	my $secondmate = $label . "_2" if $paired;
	my $matefile = "$basedir/$index/$secondmate.$index$suffix" if $paired;
	print "BOWTIE::batchCommand    AFTER matefile: $matefile\n" if $paired and $DEBUG;

	my $command; 

	##### ADD OUTPUT DIR TO PATH 
	#$command = qq{\nexport PATH=$bowtie:$referencepath/\$LSB_JOBINDEX:\$PATH\n} if $cluster eq "LSF";
	#$command = qq{\nexport PATH=$bowtie:$referencepath/\$PBS_TASKNUM:\$PATH\n} if $cluster eq "PBS";
	#$command = qq{\nexport PATH=$bowtie:$referencepath/\$TASK_ID:\$PATH\n} if $cluster eq "SGE";

	$command .= qq{mkdir -p $outdir
cd $outdir\n};

	#### SET BOWTIE COMMAND
	my $bowtie_command = qq{time $bowtie/bowtie \\
--sam \\
--rf \\
--threads $cpus \\\n};
####--verbose \\

	#### DISTANCE
	$bowtie_command .= qq{-X $distance \\\n} if defined $distance;

	#### PARAMS
	$bowtie_command .= qq{$params \\\n} if defined $params;

	#### OUTPUT FILES
	$bowtie_command .= qq{--al $alignedfile \\
--un $unalignedfile \\\n};

	#### REFERENCE FILE
	$bowtie_command .= qq{$referencepath \\\n};

	#### INPUT FILES
	$bowtie_command .= qq{-1 $inputfile \\
-2 $matefile \\\n} if $paired;
	$bowtie_command .= qq{$inputfile \\\n} if not $paired;

	#### OUTPUT FILE
	$bowtie_command .= qq{$outputfile};
	
	#print "BOWTIE::batchCommand    command: $bowtie_command\n" if $DEBUG;

	#### SET BOWTIE COMMAND
	$command .= $bowtie_command;
	
	#### DO MOVE IF tempdir IS DEFINED
	$command .= qq{
mkdir -p $outputdir/$index
mv $outdir/* $outputdir/$index
rm -fr $outdir\n} if defined $tempdir and $tempdir;

	print "BOWTIE::batchCommand    command: $command\n";

	return $command;
	
}	#	batchCommand



=head2

	SUBROUTINE		bowtieCommand

	PURPOSE
	
		CREATE .sh FILE

=cut


sub bowtieCommand {
	my $self			=	shift;
	my $inputfiles		=	shift;
	my $matefiles		=	shift;
	my $outputdir		=	shift;
	my $reference		=	shift;

#my $DEBUG = 1;
	print "BOWTIE::bowtieCommand    BOWTIE::bowtieCommand(inputfiles, matefiles, outputdir, reference)\n" if $DEBUG;
	print "BOWTIE::bowtieCommand    inputfiles: $inputfiles\n" if $DEBUG;
	print "BOWTIE::bowtieCommand    matefiles: $matefiles\n" if $DEBUG and defined $matefiles;
	print "BOWTIE::bowtieCommand    outputdir: $outputdir\n" if $DEBUG;
	print "BOWTIE::bowtieCommand    reference: $reference\n" if $DEBUG;

	#### USER INPUTS
	my $distance 		=	$self->distance();
	my $params 			=	$self->params();
	my $label 			=	$self->label();
	my $keep 			=	$self->keep();

	#### EXECUTABLES
	my $bowtie 			=	$self->bowtie();
	my $bowtie 			=	$self->bowtie();

	##### CLUSTER
	#my $qstat 			=	$self->qstat();
	#my $jobs 			=	$self->jobs();
	my $cpus 			=	$self->cpus();
	#my $sleep 			=	$self->sleep();
	#my $qsub 			=	$self->qsub();
	#my $queue 			=	$self->queue();

	my $command = qq{
export PATH=$bowtie:\$PATH
export PATH=$bowtie:\$PATH
export PATH=$outputdir:\$PATH

cd $outputdir

time $bowtie/bowtie \\
--num-threads $cpus \\\n};

	#### ADD PARAMS
	$command .= qq{$params \\\n} if defined $params;

	#### KEEP INTERMEDIATE FILES
	$command .= qq{--keep-tmp \\\n} if defined $keep;

	#### SPECIFY OUTPUT DIR, REFERENCE AND INPUT FILES
	$command .= qq{--output-dir $outputdir \\
--mate-inner-dist $distance \\
$reference \\
$inputfiles };

	$command .= qq{\\\n$matefiles } if defined $matefiles and $matefiles;

	return $command;
	
}	#	bowtieCommand

=head2

	SUBROUTINE		convertReferences
	
	PURPOSE
	
		CONVERT .fa REFERENCE FILES INTO BOWTIE *ebwt BINARY REFERENCE FILES

=cut
sub indexReferenceFiles {	#### CONVERT .fa REFERENCE FILES TO INDEXED *ebwt FILES
	my $self			=	shift;
	my $inputdir		=	shift;
	my $outputdir		=	shift;

	my $DEBUG = 1;
	#print "BOWTIE::indexReferenceFiles    BOWTIE::indexReferenceFiles(inputdir, outputdir) ", Timer::current_datetime(), "\n" if $DEBUG;
	#print "BOWTIE::indexReferenceFiles    inputdir: $inputdir\n" if $DEBUG;
	#print "BOWTIE::indexReferenceFiles    outputdir: $outputdir\n" if $DEBUG;

	File::Path::mkpath($outputdir) if not -d $outputdir;
	print "BOWTIE::indexReferenceFiles    Can't create outputdir: $outputdir\n" and exit if not -d $outputdir;

	#### SANITY CHECK
	print "BOWTIE::indexReferenceFiles    inputdir not defined: $inputdir\n" and exit if not defined $inputdir;
	print "BOWTIE::indexReferenceFiles    outputdir not defined: $outputdir\n" and exit if not defined $outputdir;
	print "BOWTIE::indexReferenceFiles    inputdir is a file: $inputdir\n" and exit if -f $inputdir;
	print "BOWTIE::indexReferenceFiles    outputdir is a file: $outputdir\n" and exit if -f $outputdir;
	print "BOWTIE::indexReferenceFiles    Can't find inputdir: $inputdir\n" and exit if not -d $inputdir;
	print "BOWTIE::indexReferenceFiles    Can't find outputdir: $outputdir\n" and exit if not -d $outputdir;
	
	#### GET REFERENCE FILES
	my $fastafiles = $self->listFiles($inputdir, "\*.fa");

	#### GET BOWTIE
	my $bowtie 	=	$self->bowtie();
	print "BOWTIE::convertReferences    bowtie is not defined. Exiting\n" if not defined $bowtie;

	chdir($inputdir) or die "BOWTIE::convertReferences    Can't change to inputdir directory: $inputdir\n";
	
	my $jobs = [];
	my $counter = 0;
	foreach my $file ( @$fastafiles )
	{
		$counter++;

		#### SET LABEL
		my $label = "bowtie-indexRef-$counter";
		$label =~ s/\///;

		my ($stub) = $file =~ /([^\/]+)\.fa$/;
		my $command = "time $bowtie/bowtie-build  $file $outputdir/$stub";
		print "command: $command\n";

		#### SET JOB
		my $job = $self->setJob( [ $command ], $label, $outputdir);
		push @$jobs, $job;
	}

	#### RUN ALIGNMENT JOBS
	my $label = "bowtie-indexRef";
	$self->runJobs($jobs, $label);	
}









} #### Aligner::BOWTIE

__END__

=head2

	SUBROUTINE		generateBatchJobs
	
	PURPOSE
	
		GENERATE LIST OF BATCH JOBS TO RUN BOWTIE AGAINST ALL REFERENCES
		
		USING SUBFILES OF INPUT FILES
		
=cut

sub generateBatchJobs {
	my $self			=	shift;
	my $outputdir		=	shift;
	my $referencefiles 	=	shift;
	my $splitfiles		=	shift;	

#my $DEBUG = 1;
	print "BOWTIE::generateBatchJobs    BOWTIE::generateBatchJobs(outputfile, referencefile, splitfiles)\n" if $DEBUG;
	print "BOWTIE::generateBatchJobs    outputdir: $outputdir\n" if $DEBUG;
	print "BOWTIE::generateBatchJobs    Number referencefiles: ", scalar(@$referencefiles), "\n" if $DEBUG;
	print "BOWTIE::generateBatchJobs    Number splitfiles: ", scalar(@$splitfiles), "\n" if $DEBUG;

	#### COLLECT ALL JOBS FOR EACH INPUT FILE AGAINST ALL REFERENCE FILES
	my $jobs = [];
	my $number_splitfiles = scalar(@$splitfiles);
	
	my $reference_counter = 0;
	foreach my $referencefile ( @$referencefiles )
	{
		print "Bowtie::generateBatchJobs    referencefile: $referencefile\n" if $DEBUG;
		$reference_counter++;
		print "Bowtie::generateBatchJobs    reference_counter: $reference_counter\n" if $DEBUG;
		
		#### CREATE A BATCH JOB
		my ($reference) = $referencefile =~ /^.+?\/([^\/]+)$/;
		print "Bowtie::generateBatchJobs    reference: $reference\n" if $DEBUG;

		#### SET OUTPUT DIR
		my $outdir = "$outputdir/$reference";
		File::Path::mkpath($outdir) if not -d $outdir;
		print "Bowtie::generateBatchJobs    outdir: $outdir\n" if $DEBUG;

		my $command = $self->batchCommand($outdir, $referencefile, $splitfiles);

		#### SET LABEL
		my $label = "bowtie-$reference";

		#### SET *** BATCH *** JOB 
		my $job = $self->setBatchJob([$command], $label, $outdir, $number_splitfiles);

		push @$jobs, $job;
	}
	print "Bowtie::generateBatchJobs    length(jobs): ", scalar(@$jobs), "\n" if $DEBUG;

	return $jobs;
}





