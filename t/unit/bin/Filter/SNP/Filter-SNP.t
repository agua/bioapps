#!/usr/bin/perl -w

my $DEBUG = 0;
#$DEBUG = 1;

=head2

    TEST        04.Filter-SNP.t
    
    PURPOSE
    
        TEST Filter::SNP MODULE:
        
            -   FILTER SNP POSITION BY:
            
                    UPSTREAM (MARGIN)
                    5' UTR
                    NON-CODING
                    EXONIC
                    INTRONIC
                    3' UTR
                    DOWNSTREAM (MARGIN)
        
            -   CONVERT SNP POSITION TO CODON
            
            -   CONVERT CODON TO AA: MISSENSE, SYNONYMOUS, NOCHANGE
            
            -   FILTER ONE GENOMIC FEATURE FILE BASED ON THE START/STOP
            
                POSITIONS OF FEATURES IN A SECOND GENOMIC FEATURE FILE


EXON REFERENCE SNP PREDICTION TEST SETS:

/p/NGS/syoung/base/pipeline/nimblegen-run1/SID9637_exon_Map/ccds

/p/NGS/syoung/base/pipeline/nimblegen-run1/SID9639_exon_Map/ccds/454AllDiffs-headers-SNPs.txt


=cut

use strict;

use FindBin qw($Bin);

use lib "$Bin/../../../lib";
use lib "$Bin/../../../../lib";
use lib "$Bin/../../../../../lib";


#### INTERNAL MODULES
use Filter::SNP;
use Agua::Common::Logger;
use Agua::DBaseFactory;
use Feature;

#### EXTERNAL MODULES
use Data::Dumper;
use File::Compare;
use Test::Simple tests => 283;

#### INITIALISE DATABASE HANDLE TO THESE TABLES:
#### ccdsGene - exonStarts, exonStops
#### ccdsSeq - sequence
#### snp130 - SNP positions
my $dbtype = "SQLite";
my $dbfile = "$Bin/dbfile/filtersnp.dbl";
my $database = "filtersnp";
my $db = 	Agua::DBaseFactory->new( $dbtype, {
		dbfile		=>	$dbfile,
		database	=>	$database
	}
) or print "Can't create database: $database: $!\n" and exit;

#### INITIALISE Filter::SNP OBJECT 
my $filterSNP = Filter::SNP->new({
	'DBOBJECT' => $db
});

testVariationType({
        queryfile   =>  "$Bin/inputs/chr22/454HCDiffs-header-chr22-sorted.txt",
        querytype   =>  "454",
        outputfile  =>  "$Bin/outputs/variationType/positives-output.txt",
        expectfile  =>  "$Bin/inputs/variationType/positives.txt",
        complement  =>  1
    }
);
testGeneLocation ({
	inputfile   =>  "$Bin/inputs/chrY/snp130CodingDbSnp-chrY-dbsnp.txt",
	outputfile  =>  "$Bin/outputs/geneLocation-codingDbSnpInCcds-output.txt",
	expectfile  =>  "$Bin/outputs/geneLocation-codingDbSnpInCcds.txt",
	inputtype   =>  "dbsnp",
	db    =>  $db
});

testSnpEffect ({
        inputfile   =>  "$Bin/inputs/chrY/snp130CodingDbSnp-chrY-dbsnp.txt",
        outputfile  =>  "$Bin/outputs/snpEffect-codingDbSnpInCcds-output.txt",
        expectfile  =>  "$Bin/outputs/snpEffect-codingDbSnpInCcds.txt",
        inputtype   =>  "dbsnp",
        db    =>  $db
});


sub testGeneLocation {
=head2

    SUBROUTINE      testGeneLocation

    PURPOSE
    
        TEST METHOD Filter::SNP::geneLocation USING ccdsGene DATABASE
        
        TABLE TO PROVIDE CCDS TO BE SUPPLIED TO METHOD


#### 
#### TEST METHOD geneLocation 
####        
####    snp130CodingDbSnp-chrY-dbsnp.txt
####        
####        AMONG dbSNP
####        AMONG CCDS
####        CHECK CORRECT CODON
####        CHECK SNP EFFECT
####        
####	605	chrY	2655179	2655179	rs11575897	NM_003140	3	2	8,3,	C,T,	AGC,AGT,	S,S,
####	605	chrY	2712236	2712236	rs11538309	NM_001008	3	2	8,3,	A,G,	CAA,CAG,	Q,Q,
####	605	chrY	2722706	2722706	rs11538308	NM_001008	1	2	8,42,	G,C,	GAT,CAT,	D,H,
####	605	chrY	2722726	2722726	rs72625370	NM_001008	3	2	8,3,	C,T,	TAC,TAT,	Y,Y,
####    ...
#### 


=cut

    my $args    =   shift;
    
    my $inputfile       =   $args->{inputfile}; 
    my $outputfile      =   $args->{outputfile};
    my $expectfile      =   $args->{expectfile};
    my $inputtype       =   $args->{inputtype};
    my $db       =   $args->{db};


    #### TIMING    
    #my $time1 = [gettimeofday()];	

#my $DEBUG = 1;

    #### CHECK INPUTS
    print "04.Filter-SNP.t::testGeneLocation    inputfile not found: $inputfile\n" and return if not -f $inputfile;
    print "04.Filter-SNP.t::testGeneLocation    outputfile: $outputfile\n" if $DEBUG;

    #### OPEN OUTPUT FILE
    open(OUTFILE, ">$outputfile") or die "Can't open output file: $outputfile\n";
    

    #print "04.Filter-SNP.t::testGeneLocation    queryfile: $queryfile\n";
    #print "04.Filter-SNP.t::testGeneLocation    outputfile: $outputfile\n";
    #print "04.Filter-SNP.t::testGeneLocation    expectfile: $expectfile\n";

    #### CREATE A FEATURE OBJECT FOR TRAVERSING THE LINES
	my $feature = Feature->new(
		{
			file 		=>	$inputfile,
			type		=>	$inputtype,
			outputfile	=>	$outputfile
		}
	);
    #print "04.Filter-SNP.t::testGeneLocation    feature:\n";
    #print Dumper  $feature;    

    #### DO ALL FEATURES IN FILE
    my $current_feature = $feature->get_current();
    #$current_feature = $feature->nextFeature();

    my $counter = 0;
    while ( defined $current_feature )
    {
        print "04.Filter-SNP.t::testGeneLocation    current_feature:\n" if $DEBUG;
        print $current_feature->{line} if $DEBUG;

        #### NOTE: THIS IS SPECIFIC TO snp130CodingDbSnp FILE FORMAT
        #### LATER: ADAPT IF OTHER INPUT FILE FORMATS USED
        my @elements = split " ", $current_feature->{line};
        my $bases = $elements[9];
        my ($reference_base, $variant_base) = $bases =~ /^([^,]+),([^,]+)/;
        my $codons = $elements[10];
        my ($reference_codon, $variant_codon) = $codons =~ /^([^,]+),([^,]+)/;
        my $aas = $elements[11];
        my ($reference_aa, $variant_aa) = $aas =~ /^([^,]+),([^,]+)/;
        
        print "bases: $bases\n" if $DEBUG;
        print "codons: $codons\n" if $DEBUG;
        print "aas: $aas\n" if $DEBUG;
        print "04.Filter-SNP.t::testGeneLocation    reference_base: $reference_base\n" if $DEBUG;
        print "04.Filter-SNP.t::testGeneLocation    variant_base: $variant_base\n" if $DEBUG;
        print "04.Filter-SNP.t::testGeneLocation    reference_codon: $reference_codon\n" if $DEBUG;
        print "04.Filter-SNP.t::testGeneLocation    variant_codon: $variant_codon\n" if $DEBUG;
        print "04.Filter-SNP.t::testGeneLocation    reference_aa: $reference_aa\n" if $DEBUG;
        print "04.Filter-SNP.t::testGeneLocation    variant_aa: $variant_aa\n" if $DEBUG;

        #### GET CHROMOSOME AND START POSITION
        my $chromosome = $feature->get_current()->{chromosome};
        my $start = $feature->get_current()->{start};

        #### GET CCDS SPANNING SNP POSITION
        my $query = qq{SELECT * FROM ccdsGene
WHERE chrom='chr$chromosome'
AND txStart <= $start
AND txEnd >= $start
};
        #print "query: $query\n";
        my $ccds = $db->queryhash($query);
        if ( not defined $ccds or not %$ccds )
        {
            #### NEXT FEATURE
            $current_feature = $feature->nextFeature();
            next;
        }
        #print "ccds: \n" if $DEBUG;
        #print Dumper $ccds if $DEBUG;

        #### GET STRAND
        my $strand = $ccds->{strand};
        print "04.Filter-SNP.t::testGeneLocation    strand: $strand\n" if $DEBUG;

        #### GET GENE POSITION
        my $gene_position = $filterSNP->geneLocation($ccds, $start);
        print "04.Filter-SNP.t::testGeneLocation    gene_position: \n" if $DEBUG;
        print Dumper $gene_position if $DEBUG;

        #### PRINT GENE POSITION TO OUTPUT FILE
        print OUTFILE "$gene_position->{type}\t$gene_position->{number}\t$gene_position->{position}\n" if defined $gene_position;
        
        #### NEXT FEATURE
        $current_feature = $feature->nextFeature();
        
        #### INCREMENT COUNTER
        $counter++;
        print "04.Filter-SNP.t::testGeneLocation    counter: $counter\n" if $DEBUG;
        
        #last if $counter == 44;
        
    }
    close(OUTFILE) or die "Can't close output file: $outputfile\n";
    print "04.Filter-SNP.t::testGeneLocation    Printed outputfile:\n\n$outputfile\n\n" if $DEBUG;
    print "04.Filter-SNP.t::testGeneLocation    expectfile: $expectfile\n" if $DEBUG;
    
    #### TIMING    
    #my $milliseconds = tv_interval($time1) * 1000;
    #printf "Elapsed time: $milliseconds milliseconds\n";
    
    #### File::Compare::compare.
    #### return 0 if the files are equal,
    #### 1 if the files are unequal, or
    #### -1 if an error was encountered.

    print "Filter-SNP.t::testGeneLocation    outputfile: $outputfile\n" if $DEBUG;
    print "Filter-SNP.t::testGeneLocation    expectfile: $expectfile\n" if $DEBUG;

    ok(File::Compare::compare($expectfile, $outputfile), "Expected file identical to output file");	
}

sub testSnpEffect {
=head2

    SUBROUTINE      testSnpEffect
    
    PURPOSE
    
        TEST FUNCTION Filter::SNP::snpEffect

    NOTES
    
        POSITIVE QUERY FILE: snp130CodingDbSnp-chrY-dbsnp.txt
        
        AMONG dbSNP
        AMONG CCDS
        CHECK CORRECT CODON
        CHECK CODON EFFECT
        
	605	chrY	2655179	2655179	rs11575897	NM_003140	3	2	8,3,	C,T,	AGC,AGT,	S,S,
	605	chrY	2712236	2712236	rs11538309	NM_001008	3	2	8,3,	A,G,	CAA,CAG,	Q,Q,
	605	chrY	2722706	2722706	rs11538308	NM_001008	1	2	8,42,	G,C,	GAT,CAT,	D,H,
	605	chrY	2722726	2722726	rs72625370	NM_001008	3	2	8,3,	C,T,	TAC,TAT,	Y,Y,
    ...

=cut
    my $args    =   shift;
    
    my $inputfile       =   $args->{inputfile}; 
    my $outputfile      =   $args->{outputfile};
    my $expectfile      =   $args->{expectfile};
    my $inputtype       =   $args->{inputtype};
    my $db       =   $args->{db};

    #### TIMING    
    #my $time1 = [gettimeofday()];	

    #### OPEN OUTPUT FILE
    open(OUTFILE, ">$outputfile") or die "Can't open output file: $outputfile\n";

    #### CHECK INPUTS
    print "04.Filter-SNP.t::testSnpEffect    inputfile not found: $inputfile\n" and return if not -f $inputfile;
    #print "04.Filter-SNP.t::testSnpEffect    queryfile: $queryfile\n" if $DEBUG;
    #print "04.Filter-SNP.t::testSnpEffect    outputfile: $outputfile\n" if $DEBUG;
    #print "04.Filter-SNP.t::testSnpEffect    expectfile: $expectfile\n" if $DEBUG;

	my $feature = Feature->new(
		{
			file 		=>	$inputfile,
			type		=>	$inputtype,
			outputfile	=>	$outputfile
		}
	);
    #print "04.Filter-SNP.t::testSnpEffect    feature:\n" if $DEBUG;
    #print Dumper  $feature if $DEBUG;

    #### DO ALL FEATURES IN FILE
    my $current_feature = $feature->get_current();

    my $counter = 0;
    while ( defined $current_feature )
    {
        #### NOTE: THIS IS SPECIFIC TO snp130CodingDbSnp FILE FORMAT
        #### LATER: ADAPT IF OTHER INPUT FILE FORMATS USED
        my @elements = split " ", $current_feature->{line};
        my $bases = $elements[9];
        my ($reference_base, $variant_base) = $bases =~ /^([^,]+),([^,]+)/;
        my $codons = $elements[10];
        my ($reference_codon, $variant_codon) = $codons =~ /^([^,]+),([^,]+)/;
        my $aas = $elements[11];
        my ($reference_aa, $variant_aa) = $aas =~ /^([^,]+),([^,]+)/;

        #### IGNORE DELETIONS
        if ( not defined $variant_base or not defined $variant_codon )
        {
            #### NEXT FEATURE
            $current_feature = $feature->nextFeature();
            $counter++;
            next;
        }

        #print "04.Filter-SNP.t::testSnpEffect    reference_base: $reference_base\n" if $DEBUG;
        #print "04.Filter-SNP.t::testSnpEffect    variant_base: $variant_base\n" if $DEBUG;
        #print "04.Filter-SNP.t::testSnpEffect    reference_codon: $reference_codo if $DEBUG;\n";
        #print "04.Filter-SNP.t::testSnpEffect    variant_codon: $variant_codon\n" if $DEBUG;
        #print "04.Filter-SNP.t::testSnpEffect    reference_aa: $reference_aa\n" if $DEBUG;
        #print "04.Filter-SNP.t::testSnpEffect    variant_aa: $variant_aa\n" if $DEBUG;

        #### GET CHROMOSOME AND START POSITION
        my $chromosome = $feature->get_current()->{chromosome};
        my $start = $feature->get_current()->{start};

        #### GET CCDS SPANNING SNP POSITION
        my $query = qq{SELECT * FROM ccdsGene
WHERE chrom='chr$chromosome'
AND txStart <= $start
AND txEnd >= $start
};
        my $ccds = $db->queryhash($query);
        if ( not defined $ccds or not %$ccds )
        {
            #### NEXT FEATURE
            $current_feature = $feature->nextFeature();
            $counter++;
            next;
        }
        #print "ccds: \n" if $DEBUG;
        #print Dumper $ccds if $DEBUG;

        #### GET STRAND
        my $strand = $ccds->{strand};
        print "\n04.Filter-SNP.t::testSnpEffect    COUNTER $counter current_feature:\n" if $DEBUG;
        print $current_feature->{line} if $DEBUG;
        print "04.Filter-SNP.t::testSnpEffect    strand: $strand\n" if $DEBUG;

        #### GET GENE POSITION
        my $gene_position = $filterSNP->geneLocation($ccds, $start);
        print "04.Filter-SNP.t::testSnpEffect    gene_position:\n" if $DEBUG;
        print Dumper $gene_position if $DEBUG;
        my $position = $gene_position->{position};
        if ( not defined $position or $gene_position->{type} ne "exon" )
        {
            #### NEXT FEATURE
            $current_feature = $feature->nextFeature();
            $counter++;
            next;
        }

        #### GET SEQUENCE
        my $sequence = $filterSNP->geneSequence($ccds->{name});
        if ( not defined $sequence or not $sequence )
        {
            #### NEXT FEATURE
            $current_feature = $feature->nextFeature();
            $counter++;
            next;
        }

        #### GET REFERENCE AND VARIANT CODONS
        my $reference_actual_codon = $filterSNP->referenceCodon($strand, $position, $sequence);
        my $variant_actual_codon = $filterSNP->variantCodon($strand, $position, $reference_codon, $variant_base);

        #### GET AMINO ACID
        my $reference_actual_aa = $filterSNP->codonToAa($reference_actual_codon, "oneletter");
        my $variant_actual_aa = $filterSNP->codonToAa($variant_actual_codon, "oneletter");

        ok( $reference_codon eq $reference_actual_codon, "testSnpEffect: reference codons match");
        ok( $variant_codon eq $variant_actual_codon, "testSnpEffect: variant codons match");
        ok( $reference_aa eq $reference_actual_aa, "testSnpEffect: reference aas match");
        ok( $variant_aa eq $variant_actual_aa, "testSnpEffect: variant aas match");
        #print "04.Filter-SNP.t::testSnpEffect    reference_actual_aa: $reference_actual_aa\n";
        #print "04.Filter-SNP.t::testSnpEffect    reference_aa: $reference_aa\n";
        #
        #print "04.Filter-SNP.t::testSnpEffect    variant_actual_aa: $variant_actual_aa\n";
        #print "04.Filter-SNP.t::testSnpEffect    variant_aa: $variant_aa\n";


        my $check_reference_aa = $filterSNP->codonToAa($reference_codon, "testSnpEffect: oneletter");
        my $check_variant_aa = $filterSNP->codonToAa($variant_codon, "testSnpEffect: oneletter");
        #print "04.Filter-SNP.t::testSnpEffect    check_reference_aa: $check_reference_aa\n";
        #print "04.Filter-SNP.t::testSnpEffect    check_variant_aa: $check_variant_aa\n";

        #### GET EFFECT
        my $effect = "synonymous";
        $effect = "missense" if $reference_aa ne $variant_aa;
        $effect = "nonsense" if $variant_aa eq "X";
        print "04.Filter-SNP.t::testSnpEffect    effect: $effect\n" if $DEBUG;
        print OUTFILE "$effect\n";

        #### NEXT FEATURE
        $current_feature = $feature->nextFeature();

        $counter++;
    }
    
    #### TIMING    
    #my $milliseconds = tv_interval($time1) * 1000;
    #printf "Elapsed time: $milliseconds milliseconds\n";
    
    #print "04.Filter-SNP.t::testSnpEffect    expectfile: $expectfile\n" if $DEBUG;
    #print "04.Filter-SNP.t::testSnpEffect    outputfile: $outputfile\n" if $DEBUG;

    #### File::Compare::compare.
    #### return 0 if the files are equal,
    #### 1 if the files are unequal, or
    #### -1 if an error was encountered.
    print "04.Filter-SNP.t::testSnpEffect    expectfile: $expectfile\n" if $DEBUG;
    print "04.Filter-SNP.t::testSnpEffect    outputfile: $outputfile\n" if $DEBUG;
    ok(File::Compare::compare($expectfile, $outputfile), "testSnpEffect outputfile correct");
}



sub testCodonToAa {
=head2

    SUBROUTINE      testCodonToAa
    
    PURPOSE
    
        TEST FUNCTION Filter::SNP::codonToAa

    NOTES
    
        POSITIVE QUERY FILE: snp130CodingDbSnp-chrY-dbsnp.txt
            
            AMONG dbSNP
            AMONG CCDS
            CHECK CORRECT CODON
            CHECK CODON EFFECT
            
        605	chrY	2655179	2655179	rs11575897	NM_003140	3	2	8,3,	C,T,	AGC,AGT,	S,S,
        605	chrY	2712236	2712236	rs11538309	NM_001008	3	2	8,3,	A,G,	CAA,CAG,	Q,Q,
        605	chrY	2722706	2722706	rs11538308	NM_001008	1	2	8,42,	G,C,	GAT,CAT,	D,H,
        605	chrY	2722726	2722726	rs72625370	NM_001008	3	2	8,3,	C,T,	TAC,TAT,	Y,Y,
        ...
=cut
    my $args    =   shift;
    
    my $inputfile       =   $args->{inputfile}; 
    my $outputfile      =   $args->{outputfile};
    my $expectfile      =   $args->{expectfile};
    my $inputtype       =   $args->{inputtype};
    my $db       =   $args->{db};

    #### TIMING    
    #my $time1 = [gettimeofday()];	

my $DEBUG = 1;

    #### CHECK INPUTS
    print "04.Filter-SNP.t::testCodonToAa    inputfile not found: $inputfile\n" and return if not -f $inputfile;

    #print "04.Filter-SNP.t::testCodonToAa    queryfile: $queryfile\n";
    #print "04.Filter-SNP.t::testCodonToAa    outputfile: $outputfile\n";
    #print "04.Filter-SNP.t::testCodonToAa    expectfile: $expectfile\n";

	my $feature = Feature->new(
		{
			file 		=>	$inputfile,
			type		=>	$inputtype,
			outputfile	=>	$outputfile
		}
	);
    #print "04.Filter-SNP.t::testCodonToAa    feature:\n";
    #print Dumper  $feature;    

    #### DO ALL FEATURES IN FILE
    my $current_feature = $feature->get_current();
    #$current_feature = $feature->nextFeature();

    my $counter = 0;
    while ( defined $current_feature )
    {
        print "04.Filter-SNP.t::testCodonToAa    current_feature:\n";
        print $current_feature->{line};    

        my @elements = split " ", $current_feature->{line};
        my $codons = $elements[10];
        my ($reference_codon, $variant_codon) = $codons =~ /^([^,]+),([^,]+)/;
        my $aas = $elements[11];
        my ($reference_aa, $variant_aa) = $aas =~ /^([^,]+),([^,]+)/;

        my $reference_actual_aa = $filterSNP->codonToAa($reference_codon, "oneletter");
        my $variant_actual_aa = $filterSNP->codonToAa($variant_codon, "oneletter");


        #print "04.Filter-SNP.t::testSnpEffect    reference_codon: $reference_codon\n";
        #print "04.Filter-SNP.t::testSnpEffect    variant_codon: $variant_codon\n";
        print "04.Filter-SNP.t::testSnpEffect    reference_aa: $reference_aa\n";
        print "04.Filter-SNP.t::testSnpEffect    variant_aa: $variant_aa\n";
        print "04.Filter-SNP.t::testCodonToAa    reference_actual_aa: $reference_actual_aa\n";
        print "04.Filter-SNP.t::testCodonToAa    variant_actual_aa: $variant_actual_aa\n";

        ok( $reference_aa eq $reference_actual_aa, "testSnpEffect: reference aas match");
        ok( $variant_aa eq $variant_actual_aa, "testSnpEffect: variant aas match");
    }
}

sub testVariationType {
=head2


    SUBROUTINE      testVariationType
    
    PURPOSE
    
        TEST FUNCTION Filter::SNP::variationType 

    NOTES
    
		 variationType INPUTS:
		        
		 454HCDiffs-header-chr22-sorted.txt
		 
		 >CCDS13891.1|Hs36.3|chr22	15	15	G	A	3	100%
		 >CCDS43037.1|Hs36.3|chr22	25	25	G	C	3	100%
		 >CCDS14021.1|Hs36.3|chr22	49	51	GAG	AA	3	100%
		 >CCDS13928.1|Hs36.3|chr22	218	225	GAGTGGTC	-	3	100%
		 >CCDS14101.1|Hs36.3|chr22	262	278	CACTGCTTCGTCGGCAA	TACCTTTGTGCCCAAC	5	80%

        variationType ALL POSITIVES: snp130CodingDbSnp-chrY-dbsnp.txt
            
            AMONG dbSNP
            AMONG CCDS
            CHECK CORRECT CODON
            CHECK SNP EFFECT
           
        605	chrY	2655179	2655179	rs11575897	NM_003140	3	2	8,3,	C,T,	AGC,AGT,	S,S,
        605	chrY	2712236	2712236	rs11538309	NM_001008	3	2	8,3,	A,G,	CAA,CAG,	Q,Q,
        605	chrY	2722706	2722706	rs11538308	NM_001008	1	2	8,42,	G,C,	GAT,CAT,	D,H,
        605	chrY	2722726	2722726	rs72625370	NM_001008	3	2	8,3,	C,T,	TAC,TAT,	Y,Y,
        ...

		variationType ALL POSITIVES: snp130-chrY.txt
		585	chrY	95387	95388	rs28377933	0	+	A	A	A/G	genomic	single	unknown	0	0	unknown	exact	3
		585	chrY	95444	95445	rs28422153	0	+	T	T	C/T	genomic	single	unknown	0	0	unknown	exact	3
		
		#### variationType ALL POSITIVES: snp130-chrY.txt
		chrY	hg19_snp130	exon	150860	150860	0.000000	+	.	gene_id "rs9785927"; transcript_id "rs9785927"; 
		chrY	hg19_snp130	exon	150860	150860	0.000000	+	.	gene_id "rs68110282"; transcript_id "rs68110282"; 
		
		##### isCoding ALL POSITIVES: snp130-chrY-intersect-CCDS.fa
		>hg19_snp130_rs9785927 range=chrY:150850-150870 5'pad=10 3'pad=10 strand=+ repeatMasking=none
		CTCTGATGGGTGGGCAGGTGA
		>hg19_snp130_rs68110282 range=chrY:150850-150870 5'pad=10 3'pad=10 strand=+ repeatMasking=none
		CTCTGATGGGTGGGCAGGTGA

=cut

    my $args    =   shift;
    
    my $queryfile       =   $args->{queryfile}; 
    my $outputfile      =   $args->{outputfile};
    my $expectfile      =   $args->{expectfile};
    my $querytype       =   $args->{querytype};

    #### TIMING    
    #my $time1 = [gettimeofday()];	

    #### CHECK INPUTS
    print "04.Filter-SNP.t::testVariationType    queryfile not found: $queryfile\n" and return if not -f $queryfile;

	my $query = Feature->new(
		{
			file 		=>	$queryfile,
			type		=>	$querytype,
			outputfile	=>	$outputfile
		}
	);
    print "04.Filter-SNP.t::testVariationType    query:\n" if $DEBUG;
    print Dumper $query if $DEBUG;

    #### DO ALL FEATURES IN FILE
    my $feature = $query->nextFeature();
    print "04.Filter-SNP.t::testVariationType    feature:\n" if $DEBUG;
    print Dumper $feature if $DEBUG;
    while ( defined $feature )
    {
        my $linehash = $filterSNP->linehash($feature->{line});

        #### LOAD LINE
        my $type = $filterSNP->variationType($linehash);
        my $line = $query->get_current()->{line};
        $line =~ s/\s+$//;
        my $output =  "$line\t$type\n";
        $query->printOut($output);
        $feature = $query->nextFeature();
    }
    
    #### TIMING    
    #my $milliseconds = tv_interval($time1) * 1000;
    #printf "Elapsed time: $milliseconds milliseconds\n";
    #print "04.Filter-SNP.t::testVariationType    expectfile: $expectfile\n" if $DEBUG;
    #print "04.Filter-SNP.t::testVariationType    outputfile: $outputfile\n" if $DEBUG;
    ok(File::Compare::compare($expectfile, $outputfile), "expected and actual variation type output");
}

