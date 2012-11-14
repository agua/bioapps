package SAV;

our $DEBUG = 0;
#$DEBUG = 1;

=head2

	PACKAGE		SAV
	
	PURPOSE
	
		WRAPPER SCRIPT FOR DOING SNP ANNOTATION AND VERIFICATION:
		
			1. TAKES AS INPUT THE OUTPUTS OF MAQ.pm, TOPHAT.pm, ETC. WHICH ALL
			
			FOLLOW THE ESSENTIAL DIRECTORY ARCHITECTURE LAID OUT IN THEIR PARENT
			
			Cluster.pm
			

			2. INHERITS Cluster.pm TO ACCESS THE DIRECTORY ARCHITECTURE INFO
			
			TO LOCATE INPUT FILES AND TO RUN SCRIPTS ON AN HPC CLUSTER
		
=cut

use strict;
use warnings;
use Carp;

#### INTERNAL MODULES
use Sampler;
use UCSCBin;

#### HAS A
use Monitor::PBS;
use Monitor::LSF;
use Cluster;
#use LSF::Job;

#### EXTERNAL MODULES
use FindBin qw($Bin);
use Data::Dumper;
use File::Path;
#use MD5;


require Exporter;
our @ISA = qw(Exporter Cluster);
#our @EXPORT_OK = qw();
our $AUTOLOAD;


#### SET SLOTS
our @DATA = qw(

REFERENCEDIR
OUTPUTDIR
INPUTDIRS
BINLEVEL
INPUTFILE
OUTPUTFILE
DBDIR
TEMPFILE
CHUNKSIZE
FILENAME

DBSNP
SPECIES
SAMTOOLS
VERBOSE
CONVERT

MAXJOBS
CPUS
CLUSTER
QUEUE
QSTAT
QSUB
SLEEP
CLEANUP
VERBOSE
TEMPDIR
DOT
WALLTIME

COMMAND
);
our $DATAHASH;
foreach my $key ( @DATA )	{	$DATAHASH->{lc($key)} = 1;	}


=head2

	SUBROUTINE		binSnpToSav
	
	PURPOSE

		1. RUN snpToSav.pl FOR ALL BIN FILES PER INPUT DIR AND CHROMOSOME:
        
            - ANNOTATE WHETHER OR NOT SNP IS FOUND IN dbSNP
            
            - ANNOTATE EFFECT OF SNP IF FOUND IN CCDS GENE

	NOTES
	
		REQUIRES THAT THE *bam FILE THAT PRODUCED THE *snp BIN FILES
		
		IS NAMED 'hit.bam' AND IS AT THIS LOCATION:
		
			inputdir/chromosome/hit.bam

=cut

sub binSnpToSav {
	my $self		=	shift;

my $DEBUG = 1;
	print "SAV::binSnpToSav    SAV::binSnpToSav()\n" if $DEBUG;
	
	my $outputdir 		=	$self->get_outputdir();
	my $referencedir 	=	$self->get_referencedir();
	my $inputdirs		=	$self->get_inputdirs();
	my $binlevel		=	$self->get_binlevel();
	my $samtools		=	$self->get_samtools();
	my $chunksize		=	$self->get_chunksize();


	print "SAV::binSnpToSav    outputdir: $outputdir\n" if $DEBUG;
	print "SAV::binSnpToSav    referencedir: $referencedir\n" if $DEBUG;
	print "SAV::binSnpToSav    inputdirs: @$inputdirs\n" if $DEBUG;
	print "SAV::binSnpToSav    binlevel: $binlevel\n" if $DEBUG;
	print "SAV::binSnpToSav    samtools: $samtools\n" if $DEBUG;
	print "SAV::binSnpToSav    chunksize: $chunksize\n" if $DEBUG;

	my $dbdir			=	$self->get_dbdir();
	my $dbsnp			=	$self->get_dbsnp();
	print "SAV::binSnpToSav    dbdir: $dbdir\n" if $DEBUG;
	print "SAV::binSnpToSav    dbsnp: $dbsnp\n" if $DEBUG;

######	DEBUG COMMENTED OUT
#
##### PRINT ALL RANGE FILES AT ONCE IF FIRST ONE IS MISSING	
#$self->printRangefiles();
#


	#### SET EXECUTABLE TO CONVERT PILEUP FORMAT TO ANNOTATED SNP FORMAT
	my $executable = "$Bin/snpToSav.pl";
	print "SAV::binSnpToSav    executable: $executable\n" if $DEBUG;

	my $chromosomes = $self->listReferenceFiles($referencedir, "\*\.fa");
	foreach my $file ( @$chromosomes )
	{
		($file) = $file =~ /([^\/]+)$/;
		$file =~ s/\.fa$//;
	}

	my $outfile_chunks = {};
	my $jobs = [];
	my $inputdir_counter = 0;
	foreach my $inputdir ( @$inputdirs )
	{
		$inputdir_counter++;

		#### SET DIR NAME
		my ($dirname) = $inputdir =~ /([^\/]+)$/;

		foreach my $chromosome ( @$chromosomes )
		{
			#### SET OUTPUT DIR
			my $outdir = "$outputdir/$dirname/$chromosome";
			print "SAV::binSnpToSav    outdir: $outdir\n" if $DEBUG;
			File::Path::mkpath($outdir) if not -d $outdir;
			print "Can't create outdir: $outdir\n" if not -d $outdir;

			my $bamfile = "$inputdir/$chromosome/hit.bam";
			print "SAV::binSnpToSav    Can't find bamfile: $bamfile\n" and exit if not -f $bamfile;

			#### SET BIN FILES DIRECTORY
			my $bindir = "$inputdir/$chromosome/bins";
			
			#### CREATE BINNER
			my $binner = UCSCBin->new({	samtools	=> $samtools,	outputdir	=>	$bindir	});

			#### GET CHROMOSOME SIZE
			my $chromosome_size = $binner->getChromosomeSize($bamfile);	

			#### GET ARRAY OF BINS
			my $bins = $binner->getBins($binlevel, $chromosome_size);
			#print "SAV::binSnpToSav    bins:\n" if $DEBUG;
			#print Dumper $bins if $DEBUG;
	
			#### GET RANGE FOR BINS
			my $rangefile = "$inputdir/$chromosome/hit.bam.range";

			##### SET BINS BY HIT RANGE	-- DON'T DO THIS JUST IN CASE THE
			##### SNPS ARE CUMULATIVE SNPS (DIFFERENT SOURCE .bam FILES
			##### MAY HAVE DIFFERENT HIT RANGES)
			#$bins = $binner->setBinsByRange($bins, $rangefile);
	
			#### DO EACH BAM BIN FILE
			foreach my $bin ( @$bins )
			{
				#### SET FILE NAMES
				#### E.G.:	"$outputdir/$filestub.binlevel$binlevel.num$bin->{number}.$suffix";
				my $binfile = $binner->setBinfile("hit.bam", $bindir, $binlevel, $bin);
				next if not -f $binfile;

				#### ADD -dirname TO FILESTUB (E.G., hit.binlevel500000.num71-26.snp)
				my ($filestub) = $binfile =~ /([^\/]+)$/;
				$filestub =~ s/\.bam//;
				$filestub .= "-$dirname";
			
				#### SET SNP FILE			
				my $snpfile = "$outputdir/$chromosome/$filestub.snp";
				
				#### SET SUBDIR FOR SAV AND STDOUT FILES AS BIN NUMBER
				#### I.E., POSITION ALONG THE CHROMOSOME
				my $binnumber = $bin->{number};
				if ( not defined $binnumber )
				{
					print "SAV::binSnpToSav    bin->{number} not defined for bin:\n" if $DEBUG;
					print Dumper $bin;
					exit;
				}
				my $chunkdir = "$outputdir/$chromosome/indir$dirname/bin$binnumber";
				
				#### PROCESS INPUT FILE INTO CHUNKS
				my ($chunkjobs, $chunkoutfiles) = $self->setChunkJobs(
				$chunksize,
				$snpfile,
				$chunkdir,
				{
					filestub	=>	$filestub,
					outputdir	=>	$outputdir,
					chromosome	=>	$chromosome,
					executable	=>	$executable,
					binnumber	=>	$binnumber,
					dbdir		=>	$dbdir,
					dbsnp		=>	$dbsnp,
					dirname		=>	$dirname,
					outdir		=>	$outdir,
					dirname		=> $dirname
				});
				print "chunkjobs not defined. Skipping binnumber: $binnumber\n"
					and next if not defined $chunkjobs;
				print "chunkoutfiles not defined. Skipping binnumber: $binnumber\n"
					and next if not defined $chunkoutfiles;

				@$jobs = (@$jobs, @$chunkjobs);

				#### SET SNP FILE			
				my $savfile = "$outputdir/$chromosome/$filestub.sav";
				$outfile_chunks->{$snpfile} = $chunkoutfiles;
				
			} #### bins

			#print "SAV::binSnpToSav    outfile_chunks:\n";
			#print Dumper $outfile_chunks;

		}
	}
	
	#### RUN COMMANDS IN PARALLEL
	print "SAV::binSnpToSav    Running snpToSav.pl\n" if $DEBUG;
	$self->runJobs( $jobs, "binSnpToSav" );	
	print "SAV::binSnpToSav    Completed running binSnpToSav.pl\n" if $DEBUG;

	#### PRINT CHUNK FILE
	my $chunkfile = "$outputdir/binsnptosav.binlevel$binlevel.chunk$chunksize.json";
	use JSON;
	my $jsonparser = new JSON;
	my $json = $jsonparser->objToJson($outfile_chunks, {pretty => 1, indent => 2});
	print "SAV::binSnpToSav    json not defined!! Skipping print to chunkfile: $chunkfile\n";
	open(OUT, ">$chunkfile") or die "Can't open chunkfile: $chunkfile\n";
	print OUT $json;
	close(OUT) or die "Can't close chunkfile: $chunkfile\n";

	#### MERGE ALL CHUNKS INTO SINGLE SNP FILE PER CHROMOSOME PER BIN
	$self->mergeChunks($outfile_chunks);

	print "SAV::run    END binSnpToSav()       ", Timer::current_datetime(), "\n";
}

=head2

	SUBROUTINE		chunkCommand
	
	PURPOSE
	
		SET COMMAND FOR INDIVIDUAL CHUNK
		
=cut

sub chunkCommand {
	my $self		=	shift;
	my $chunknumber	=	shift;
	my $inputfile	=	shift;
	my $chunkdir	=	shift;
	my $args		=	shift;

#my $DEBUG = 1;
	print "SAV::chunkCommand    SAV::chunkCommand(args, chunknumber, inputfile)\n" if $DEBUG;	
	print "SAV::chunkCommand    chunknumber: $chunknumber\n" if $DEBUG;
	print "SAV::chunkCommand    inputfile: $inputfile\n" if $DEBUG;

	my $filestub	=	$args->{filestub};
	my $outputdir	=	$args->{outputdir};
	my $chromosome	=	$args->{chromosome};
	my $executable	=	$args->{executable};
	my $binnumber	=	$args->{binnumber};
	my $dbdir		=	$args->{dbdir};
	my $dbsnp		=	$args->{dbsnp};
	my $outdir		=	$args->{outdir};
	my $inputdir_counter =	$args->{inputdir_counter};

	print "SAV::setChunkJobs    executable: $executable\n" if $DEBUG;

	#### SET SAV AND STDOUT FILES
	my $savfile = "$chunkdir/$filestub.chunk$chunknumber.sav";
	
	my $stdout = "$outputdir/$chromosome/stdout/$filestub.chunk$chunknumber.sav-stdout.txt";
	print "SAV::chunkCommand    savfile: $savfile\n" if $DEBUG;
	print "SAV::chunkCommand    stdout: $stdout\n" if $DEBUG;

	#### SET TEMP DBFILE AND SOURCE DBFILE TO BE COPIED
	my $tempdb = "$chunkdir/$filestub.chunk$chunknumber.dbl";	
	my $dbfile = "$dbdir/$dbsnp-$chromosome.dbl";
	print "tempdb: $tempdb\n" if $DEBUG;
	print "dbfile: $dbfile\n" if $DEBUG;

	my $command = qq{/usr/bin/perl $executable \\\n};
	$command .= qq{ --dbfile $dbfile \\\n};
	$command .= qq{ --inputfile $inputfile \\\n};
	$command .= qq{ --outputfile $savfile \\\n};
	$command .= qq{ --inputtype pileup \\\n};
	$command .= qq{ --stdout $stdout \\\n};
	$command .= qq{ --tempfile $tempdb\n};
	print "SAV::chunkCommand    command:\n\n$command\n" if $DEBUG;	

	my $label = "SAV-$chromosome-inputdir$inputdir_counter-bin$binnumber-chunk$chunknumber";

	##### RUN JOBS
	my $job = $self->setJob( [ $command ], $label, $outdir);

	#### SET CHECKFILE
	$job->{checkfile} = $savfile;

	return $job, $savfile;	
}

=head2

	SUBROUTINE		snpToSav
	
	PURPOSE

		1. RUN snpToSav.pl FOR ALL CHROMOSOMES IN PARALLEL:
        
            - ANNOTATE WHETHER OR NOT SNP IS FOUND IN dbSNP
            
            - ANNOTATE EFFECT OF SNP IF FOUND IN CCDS GENE

	NOTES

=cut

sub snpToSav {
	my $self		=	shift;
	
	print "SAV::run    START snpToSav()       ", Timer::current_datetime(), "\n";

	my $outputdir 		=	$self->get_outputdir();
	my $referencedir 	=	$self->get_referencedir();
	my $inputdirs		=	$self->get_inputdirs();
	my $inputfile		=	$self->get_inputfile();
	my $outfile		=	$self->get_outfile();
	my $dbdir			=	$self->get_dbdir();
	my $dbsnp			=	$self->get_dbsnp();
	my $tempfile		=	$self->get_tempfile();

	#### SET DEFAULT INPUT AND OUTPUT FILES IF NOT DEFINED
	$inputfile = "out.filter" if not defined $inputfile;
	$outfile = "out.filter.sav" if not defined $outfile;
	

#my $DEBUG = 1;

	print "SAV::snpToSav    SAV::snpToSav(outputdir, pileupfiles, label)\n" if $DEBUG;
	print "SAV::snpToSav    outputdir: $outputdir\n" if $DEBUG;
	print "SAV::snpToSav    referencedir: $referencedir\n" if $DEBUG;
	print "SAV::snpToSav    inputfile: $inputfile\n" if $DEBUG;
	print "SAV::snpToSav    outfile: $outfile\n" if $DEBUG;
	print "SAV::snpToSav    dbdir: $dbdir\n" if $DEBUG;
	print "SAV::snpToSav    dbsnp: $dbsnp\n" if $DEBUG;
	print "SAV::snpToSav    tempfile: $tempfile\n" if $DEBUG;

	my $chromosomes = $self->listReferenceFiles($referencedir, "\*\.fa");
	foreach my $file ( @$chromosomes )
	{
		($file) = $file =~ /([^\/]+)$/;
		$file =~ s/\.fa$//;
	}
	print "SAV::snpToSav    references: " if $DEBUG;
	print join "\n", @$chromosomes if $DEBUG;
	print "\n" if $DEBUG;

	my $jobs = [];
	foreach my $inputdir ( @$inputdirs )
	{
		foreach my $chromosome ( @$chromosomes )
		{
			#### SET OUTPUT DIR
			my ($dirname) = $inputdir =~ /([^\/]+)$/;
			my $outdir = "$outputdir/$dirname/$chromosome";
			print "SAV::createIntervals    outdir: $outdir\n" if $DEBUG;
			File::Path::mkpath($outdir) if not -d $outdir;
			print "Can't create outdir: $outdir\n" if not -d $outdir;

			#### SET EXECUTABLE TO CONVERT PILEUP FORMAT TO ANNOTATED SNP FORMAT
			my $executable = "$Bin/snpToSav.pl";
			print "SAV::snpToSav    executable: $executable\n" if $DEBUG;
		
			my $snpfile = "$inputdir/$chromosome/$inputfile";
			my $savfile = "$outdir/$outfile";
			
			my $dbfile = "$dbdir/$dbsnp-$chromosome.dbl";
			print "dbfile: $dbfile\n" if $DEBUG;
	
			my $command = "/usr/bin/perl $executable --dbfile $dbfile --inputfile $snpfile --outfile $savfile --inputtype pileup";
			$command .= qq{ --tempfile $tempfile } if defined $tempfile;
			print "SAV::snpToSav    $command\n" if $DEBUG;
		
			my $job = $self->setJob( [$command], "snpToSav-$inputfile", $outdir );
			push @$jobs, $job;
		}
	}
	
	#### RUN COMMANDS IN PARALLEL
	print "SAV::snpToSav    Running snpToSav\n" if $DEBUG;
	$self->runJobs( $jobs, "snpToSav" );	
	print "SAV::snpToSav    Completed snpToSav\n" if $DEBUG;

	print "SAV::run    END snpToSav()       ", Timer::current_datetime(), "\n";
}

=head2
	
	SUBROUTINE		run
	
	PURPOSE
	
		1. DETERMINE TYPE OF SNP (EXONIC, INTRONIC, ETC.)
		
		2. IF EXONIC, DETERMINE WHETHER SYNONYMOUS OR MISSENSE
		
		3. DETERMINE WHETHER SNP COINCIDES WITH dbSNP ENTRY
		
=cut

sub run {
	my $self			=	shift;
	
my $DEBUG = 1;
	print "SAV::run    SAV::run()\n" if $DEBUG;

	###############################################
	############# ANNOTATE pileup FILE  ###########
	###############################################
	$self->snpToSav() if not defined $self->get_binlevel();
	$self->binSnpToSav() if defined $self->get_binlevel();
	
}	# run



=head2

	SUBROUTINE		convertReference
	
	PURPOSE
	
		**** NOT IMPLEMENTED YET ****
	
		CONVERT REFERENCE dbSNP TSV FILES INTO ONE SQLITE
		
		DATABASE PER CHROMOSOME

=cut

sub convertReference {
	my $self			=	shift;
	my $snpfile	=	shift;

my $DEBUG;	
	print "SAV::convertReference    SAV::convertReference(referencedir)\n" if $DEBUG;
	print "SAV::convertReference    Not implemented yet. Exiting.\n" if $DEBUG;
exit;


	#### SPLIT INTO PER CHROMOSOME FILES
	
	
	#### SELECT ESSENTIAL COLUMNS
	
	
	
	#### REMOVE DUPLICATES
	
	
	
	#### CREATE TABLES AND LOAD DATA
	

}


=head2

	SUBROUTINE		getChromosomes
	
	PURPOSE

		RETRIEVE THE LIST OF CHROMOSOME SUBDIRECTORIES

	NOTES

=cut

sub getChromosomes {
	my $self		=	shift;
	my $inputdir	=	shift;

	print "SAV::getChromosomes    inputdir not defined\n" and exit if not defined $inputdir;
	chdir($inputdir);
	my @chromosomes = <chr*>;

	return \@chromosomes;
}





=head2

	SUBROUTINE		printRangefiles
	
	PURPOSE
	
		PRINT ALL RANGE FILES AT ONCE IF FIRST ONE IS MISSING

=cut

sub printRangefiles {
	my $self	=	shift;
	
	my $inputdirs	=	$self->get_inputdirs();
	my $outputdir	=	$self->get_outputdir();
	my $referencedir=	$self->get_referencedir();
	my $binlevel	=	$self->get_binlevel();
	my $filename	=	$self->get_filename();
	my $params		=	$self->get_params();

my $DEBUG = 1;
	print "SAV::printRangefiles    SNP::printRangefiles(chromosome, inputdirs, outputdir, filename, binlevel)\n" if $DEBUG;
	print "SAV::printRangefiles    inputdirs: @$inputdirs\n" if $DEBUG;

	#### GET REQUIRED VARIABLES
	my $java 		=	$self->get_java();
	my $gatk		=	$self->get_gatk();
	my $samtools	=	$self->get_samtools();

	#### GET ALL REFERENCE CHROMOSOMES
	my $inputdir = $$inputdirs[0];
	print "SAV::printRangefiles    inputdir: $inputdir\n";
	my $chromosomes = $self->getChromosomes($inputdir);
	
	##### PRINT ALL RANGE FILES AT ONCE IF FIRST ONE IS MISSING
	#my $chromosome = $$chromosomes[0];
	#my $bamfile = "$inputdir/$chromosome/$filename";
	#my $rangefile = "$bamfile.range";
	#print "SAV::printRangefiles    rangefile: $rangefile\n";
	
	#if ( not -f $rangefile )
	#{
		#print "SAV::printRangefiles    Printing rangefiles because can't find rangefile: $rangefile\n";

		#### CREATE BINNER
		my $maxjobs = 
		my $binner = UCSCBin->new({
			samtools=> $samtools,
			maxjobs => 	$self->get_maxjobs(),
			queue 	=> 	$self->get_queue(),
			cluster	=>	$self->get_cluster()
		});
		$binner->printRangefiles($inputdirs, $chromosomes);
	#}
}



################################################################################
##################			HOUSEKEEPING SUBROUTINES			################
################################################################################


=head2

	SUBROUTINE		new
	
	PURPOSE
	
		CREATE THE NEW self OBJECT AND INITIALISE IT, FIRST WITH DEFAULT 
		
		ARGUMENTS, THEN WITH PROVIDED ARGUMENTS

=cut

sub new {
 	my $class 		=	shift;
	my $arguments 	=	shift;

	my $self = {};
    bless $self, $class;

#print "SAV:new     arguments: \n";
#print Dumper $arguments;
#print "\n";

	#### SET DEFAULT TEMP DIR
	$self->{_tempdir} = "/tmp";
	
	#### INITIALISE THE OBJECT'S ELEMENTS
	$self->initialise($arguments);
	
	#### SET REFERENCE
	if ( defined $self->{_referencefile} )
	{
		my ($reference) = $self->{_referencefile} =~ /([^\/]+)$/;
		$reference =~ s/\.[^\.]+$//;

		print "SAV::new    reference: $reference\n" if $DEBUG;
		$self->{_reference} = $reference;
	}
	
	#### SET DEBUG IF verbose
	$DEBUG = 1 if defined $self->{_verbose};	

#print "SAV:new     self: \n";
#print Dumper $self;
#print "\n";
#exit;

    return $self;
}






=head2

	SUBROUTINE		initialise
	
	PURPOSE

		INITIALISE THE self OBJECT:
			
			1. LOAD THE DATABASE, USER AND PASSWORD FROM THE ARGUMENTS
			
			2. FILL OUT %VARIABLES% IN XML AND LOAD XML
			
			3. LOAD THE ARGUMENTS

=cut


sub initialise {
    my $self		=	shift;
	my $arguments	=	shift;
	
    #### VALIDATE USER-PROVIDED ARGUMENTS
	($arguments) = $self->validate_arguments($arguments, $DATAHASH);	
    
	#### LOAD THE USER-PROVIDED ARGUMENTS
	foreach my $key ( keys %$arguments )
	{		
		#### LOAD THE KEY-VALUE PAIR
		$self->value($key, $arguments->{$key});
	}
}


1;

