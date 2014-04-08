#!/usr/bin/perl -w

=head   TEST    Hapmap

=head2  PURPOSE

    PRINT THE HETEROZYGOTE SNPS FOR EACH INDIVIDUAL 
    
    THAT WHILE ALL OTHER MEMBERS OF THE GROUP HAVE 
    
    HOMOZYGOTE OR UNKNOWN GENOTYPES AT THAT POSITION

=head2  INPUTS
    
    1. TSV INPUTFILE CONTAINING HAPMAP ENTRIES
    
    2. OUTPUTFILE
    
    3. LIST OF IDS
    

=head2  OUTPUTS
    
    1. TSV OUTPUTFILE CONTAINING ONLY THOSE SNPS WHERE THE INDIVIDUAL
    
        HAS THE ONLY HETEROZYGOTE GENOTYPE AMONGST ALL THE GROUP
        
        MEMBERS.
        
        THE OUTPUT FILE HAS THESE FIELDS:

        snp_id  chromosome  position    strand  person_id genotype
        rs2075511	chr16	15725642	+	NA12156	AC
        rs16967494	chr16	15728364	+	NA12156	CT
        rs1050113	chr16	15746535	+	NA12156	AG
        rs2272554	chr16	15757705	+	NA12156	AG
        rs4781689	chr16	15772973	+	NA12878	AG
        rs1050111	chr16	15824698	+	NA12878	AG


=head2  NOTES

    TAB-SEPARATED INPUT FILE FORMAT:
    
    marker id	chromosome	position	strand	list of sample IDs	genotype
rs9593836	chr13	83350752	+	NA19625 NA19700 NA19701 NA19702 NA19703 NA19704 NA19705 NA19708 NA19712 NA19711 NA19818 NA19819 NA19828 NA19835 NA19834 NA19836 NA19902 NA19901 NA19900 NA19904 NA19919 NA19908 NA19909 NA19914 NA19915 NA19916 NA19917 NA19918 NA19921 NA20129 NA19713 NA19982 NA19983 NA19714 NA19985 NA20128 NA20126 NA20127 NA20277 NA20276 NA20279 NA20282 NA20281 NA20284 NA20287 NA20288 NA20290 NA20289 NA20291 NA20292 NA20295 NA20294 NA20297 NA20300 NA20301 NA20302 NA20317 NA20319 NA20322 NA20333 NA20332 NA20335 NA20334 NA20337 NA20336 NA20340 NA20341 NA20343 NA20342 NA20344 NA20345 NA20346 NA20347 NA20348 NA20349 NA20350 NA20357 NA20356 NA20358 NA20359 NA20360 NA20363 NA20364	TT GT TT TT TT GT TT TT GT GT GT TT TT GT TT GT GT GT GT TT TT GT TT TT TT TT GG GT TT TT TT TT TT TT TT TT TT TT GT TT TT TT GT TT TT TT TT TT GT TT TT TT TT GT TT GT TT TT TT TT TT TT GT TT TT GT TT TT TT TT TT GT GT TT TT TT TT GT GT GT GT TT TT

=cut


my $DEBUG = 0;
#$DEBUG = 1;

use strict;

use FindBin qw($Bin);
use lib "$Bin/../../../lib";

use Hapmap;
use Data::Dumper;

#### EXTERNAL MODULES
use Data::Dumper;
use Test::More qw(no_plan);
use File::Compare;

#### TEST PARAMS

#### LARGE SINGLE (100 M READS)
my $inputfile   	=   "$Bin/inputs/hapmap-ceph-uzoezi-all.txt";
my $expectedfile	=   "$Bin/inputs/unique-heterozygotes-all.txt";
my $outputfile   	=   "$Bin/outputs/unique-heterozygotes-all.txt";
#my $ids         	=   "NA19625,NA19700,NA19701,NA19702,NA19703,NA19704,NA19705,NA19708";
my $ids         	=	"NA12156,NA12878,NA12878,NA18507,NA18517,NA18555,NA18956,NA19129,NA19240";


#### INSTANTIATE Hapmap
my $hapmap = Hapmap->new(
	{
		#### GENERAL USER INPUTS 
        inputfile  => $inputfile,
        outputfile  => $outputfile,
		ids         => $ids
	}
);

runUniqueHeterozygotes($hapmap);

sub runUniqueHeterozygotes {
=head2      SUBROUTINE		runUniqueHeterozygotes
	
=head2  	PURPOSE
	
		RUN BATCH ALIGNMENT ON CLUSTER
	
=cut

	my $self			=	shift;

	my $inputfile	=	$self->get_inputfile();
	my $outputfile	=	$self->get_outputfile();
	my $ids	        =	$self->get_ids();
	#print "Hapmap::uniqueHeterozygotesBatchDoAlignment    inputfile: $inputfile\n" if $DEBUG;
	#print "Hapmap::uniqueHeterozygotesBatchDoAlignment    ids: $ids\n" if $DEBUG;

	$self->uniqueHeterozygotes($inputfile, $outputfile, $ids);
    my $diff = `diff $expectedfile $outputfile`;
    ok($diff eq '', "uniqueHeterozygotes: correct output in file");	
}

