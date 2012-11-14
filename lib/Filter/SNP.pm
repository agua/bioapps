package Filter::SNP;

#### DEBUG
our $DEBUG = 0;
#$DEBUG = 1;

=head2

	PACKAGE		Filter::SNP
	
    VERSION:        0.01

    PURPOSE
      
        IDENTIFY CAPTURED SNPs THAT BELONG TO dbSNP AND DETERMINE
        
        WHETHER THEY ARE SYNONYMOUS OR NON-SYNONYMOUS. SPECIFICALLY:

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
        
    INPUT

        1. MYSQL TABLES:
        
            ccdsGene    -   ALL CCDS GENES
            
                +--------------+------------------------------------+------+-----+---------+-------+
                | Field        | Type                               | Null | Key | Default | Extra |
                +--------------+------------------------------------+------+-----+---------+-------+
                | bin          | smallint(5) unsigned               | NO   |     | 0       |       | 
                | name         | varchar(255)                       | NO   | MUL |         |       | 
                | chrom        | varchar(255)                       | NO   | MUL |         |       | 
                | strand       | char(1)                            | NO   |     |         |       | 
                | txStart      | int(10) unsigned                   | NO   |     | 0       |       | 
                | txEnd        | int(10) unsigned                   | NO   |     | 0       |       | 
                | cdsStart     | int(10) unsigned                   | NO   |     | 0       |       | 
                | cdsEnd       | int(10) unsigned                   | NO   |     | 0       |       | 
                | exonCount    | int(10) unsigned                   | NO   |     | 0       |       | 
                | exonStarts   | longblob                           | NO   |     |         |       | 
                | exonEnds     | longblob                           | NO   |     |         |       | 
                | score        | int(11)                            | YES  |     | NULL    |       | 
                | name2        | varchar(255)                       | NO   | MUL |         |       | 
                | cdsStartStat | enum('none','unk','incmpl','cmpl') | NO   |     | none    |       | 
                | cdsEndStat   | enum('none','unk','incmpl','cmpl') | NO   |     | none    |       | 
                | exonFrames   | longblob                           | NO   |     |         |       | 
                +--------------+------------------------------------+------+-----+---------+-------+

                SELECT * FROM ccdsGene LIMIT 1\G
                
                        bin: 592
                        name: CCDS30551.1
                       chrom: chr1
                      strand: +
                     txStart: 945415
                       txEnd: 980224
                    cdsStart: 945415
                      cdsEnd: 980224
                   exonCount: 36
                  exonStarts: 945415,947443,960519,965907,966415,966720,967198,968481,968780,969065,969351,969576,970403,970601,970975,971206,971402,971639,972062,972569,972815,973018,973254,974109,974478,974808,975145,975475,975669,975968,976495,976695,976970,978995,979690,980066,
                    exonEnds: 945616,947705,960567,966123,966640,966945,967405,968700,968975,969266,969500,969682,970520,970766,971119,971331,971508,971978,972200,972697,972930,973138,973608,974302,974694,975038,975280,975572,975834,976080,976612,976888,977058,979220,979794,980224,
                       score: 0
                       name2: 
                 cdsStartStat: cmpl
                  cdsEndStat: cmpl
                  exonFrames: 0,0,1,1,1,1,1,1,1,1,1,0,1,1,1,1,0,1,1,1,0,1,1,1,2,2,1,1,2,2,0,0,1,2,2,1,

                select chrom, min(txStart), max(txStart) from ccdsGene group by chrom;
                +-------+--------------+--------------+
                | chrom | min(txStart) | max(txStart) |
                +-------+--------------+--------------+
                | chr1  |        58953 |    247178159 | 
                | chr10 |        82996 |    135217783 | 
                | chr11 |       183099 |    133757041 | 
                | chr12 |       117699 |    132231151 | 
                | chr13 |     18646002 |    114107419 | 
                | chr14 |     18447593 |    105066216 | 
                | chr15 |     18848597 |    100279867 | 
                | chr16 |        37429 |     88652259 | 
                | chr17 |        63642 |     78630980 | 
                | chr18 |       148698 |     76018644 | 
                | chr19 |        61678 |     63765250 | 
                | chr2  |        31607 |    242460581 | 
                | chr20 |        16350 |     62361762 | 
                | chr21 |      9928775 |     46881291 | 
                | chr22 |     14828823 |     49584070 | 
                | chr3  |       336459 |    199171489 | 
                | chr4  |       321772 |    191183709 | 
                | chr5  |       193422 |    180726893 | 
                | chr6  |       237539 |    170728571 | 
                | chr7  |       506606 |    158516067 | 
                | chr8  |       106085 |    146248681 | 
                | chr9  |       106799 |    139730906 | 
                | chrX  |       140854 |    154880618 | 
                | chrY  |       140854 |     57739818 | 
                +-------+--------------+--------------+

    
            ccdsSNP     -   INTERSECTION OF dbSNP 129 AND CCDS GENES

                +-----------------+------------------+------+-----+---------+-------+
                | Field           | Type             | Null | Key | Default | Extra |
                +-----------------+------------------+------+-----+---------+-------+
                | chromosome      | varchar(255)     | YES  |     | NULL    |       | 
                | chromosomeStart | int(10) unsigned | YES  |     | NULL    |       | 
                | chromosomeEnd   | int(10) unsigned | YES  |     | NULL    |       | 
                | snp             | varchar(20)      | NO   | PRI |         |       | 
                | score           | int(10)          | YES  |     | NULL    |       | 
                | strand          | char(1)          | YES  |     | NULL    |       | 
                +-----------------+------------------+------+-----+---------+-------+

                select chromosome, min(chromosomeStart), max(chromosomeStart) from ccdsSNP group by chromosome;
               +------------+----------------------+----------------------+
               | chromosome | min(chromosomeStart) | max(chromosomeStart) |
               +------------+----------------------+----------------------+
               | chr1       |                58996 |            247178652 | 
               | chr10      |                83040 |            135222828 | 
               | chr11      |               183111 |            133759013 | 
               | chr12      |               118160 |            132243019 | 
               | chr13      |             18646014 |            114109500 | 
               | chr14      |             18447613 |            105067111 | 
               | chr15      |             18848691 |            100280447 | 
               | chr16      |                37540 |             88652371 | 
               | chr17      |                97057 |             78636327 | 
               | chr18      |               156818 |             76019389 | 
               | chr19      |               232404 |             63774450 | 
               | chr2       |                35894 |            242463731 | 
               | chr20      |                24770 |             62367108 | 
               | chr21      |              9928785 |             46907829 | 
               | chr22      |             14829713 |             49584412 | 
               | chr3       |               336507 |            199235925 | 
               | chr4       |               327612 |            191185332 | 
               | chr5       |               193531 |            180620045 | 
               | chr6       |               256937 |            170735424 | 
               | chr7       |               506655 |            158627934 | 
               | chr8       |               106245 |            146250282 | 
               | chr9       |               106831 |            139848768 | 
               | chrX       |               140859 |            154893028 | 
               | chrY       |               539533 |             57752001 | 
               +------------+----------------------+----------------------+

            
            snp129      -   ALL dbSNP 129
            
                -----------------------------------------------+------+-----+---------+-------+
                | bin        | smallint(5) unsigned            | NO   |     | 0       |       | 
                | chrom      | varchar(31)                     | NO   | MUL |         |       | 
                | chromStart | int(10) unsigned                | NO   |     | 0       |       | 
                | chromEnd   | int(10) unsigned                | NO   |     | 0       |       | 
                | name       | varchar(15)                     | NO   | MUL |         |       | 
                | score      | smallint(5) unsigned            | NO   |     | 0       |       | 
                | strand     | enum('+','-')                   | YES  |     | NULL    |       | 
                | refNCBI    | blob| NO   |     |         |       | 
                | refUCSC    | blob| NO   |     |         |       | 
                | observed   | varchar(255)| NO   |     |         |       | 
                | molType    | enum('genomic','cDNA')| YES  |     | NULL    |       | 
                | class      | enum('unknown','single','in-del','het','microsatellite','named','mixed','mnp','insertion','deletion')| NO   |     | unknown |       | 
                | valid      | set('unknown','by-cluster','by-frequency','by-submitter','by-2hit-2allele','by-hapmap')| NO   |     | unknown |       | 
                | avHet      | float| NO   |     | 0       |       | 
                | avHetSE    | float| NO   |     | 0       |       | 
                | func       | set('unknown','coding-synon','intron','cds-reference','near-gene-3','near-gene-5','nonsense','missense','frameshift','untranslated-3','untranslated-5','splice-3','splice-5') | NO   |     | unknown |       | 
                | locType    | enum('range','exact','between','rangeInsertion','rangeSubstitution','rangeDeletion')| YES  |     | NULL    |       | 
                | weight     | int(10) unsigned | NO   |     | 0       |       | 
                -----------------------------------------------+------+-----+---------+-------+            
            
            codingExons -   ALL CCDS GENES IN THE NIMBLEGEN CAPTURE ARRAY
        
                +----------------------------------+-------------+------+-----+---------+-------+
                | Field                            | Type        | Null | Key | Default | Extra |
                +----------------------------------+-------------+------+-----+---------+-------+
                | CCDS_ID                          | varchar(20) | NO   | PRI |         |       | 
                | GENE_SYMBOL                      | varchar(20) | YES  |     | NULL    |       | 
                | DESCRIPTION                      | text        | YES  |     | NULL    |       | 
                | REFSEQ                           | varchar(20) | YES  |     | NULL    |       | 
                | UCSC_GENE_ID                     | varchar(20) | YES  |     | NULL    |       | 
                | ENSEMBL                          | varchar(20) | YES  |     | NULL    |       | 
                | CHROMOSOME                       | varchar(10) | YES  |     | NULL    |       | 
                | STRAND                           | varchar(1)  | YES  |     | NULL    |       | 
                | CDS_START                        | int(12)     | YES  |     | NULL    |       | 
                | CDS_END                          | int(12)     | YES  |     | NULL    |       | 
                | EXON_COUNT                       | int(6)      | YES  |     | NULL    |       | 
                | ARRAY_COVERAGE                   | varchar(6)  | YES  |     | NULL    |       | 
                | ARRAY_COVERAGE_W_100BP_EXTENSION | varchar(6)  | YES  |     | NULL    |       | 
                +----------------------------------+-------------+------+-----+---------+-------+

                select * from codingExons order by CDS_START limit 10;
                +-------------+-------------+---------------------------------------------------------------+--------------+--------------+-----------------+------------+--------+-----------+---------+------------+----------------+----------------------------------+
                | CCDS_ID     | GENE_SYMBOL | DESCRIPTION                                                   | REFSEQ       | UCSC_GENE_ID | ENSEMBL         | CHROMOSOME | STRAND | CDS_START | CDS_END | EXON_COUNT | ARRAY_COVERAGE | ARRAY_COVERAGE_W_100BP_EXTENSION |
                +-------------+-------------+---------------------------------------------------------------+--------------+--------------+-----------------+------------+--------+-----------+---------+------------+----------------+----------------------------------+
                | CCDS12989.2 | DEFB125     | "defensin, beta 125"                                          | NM_153325    | uc002wcw.1   | ENST00000382410 | chr20      | +      |     16350 |                               |       | 100%
                | CCDS42645.1 | FAM110C     | "family with sequence similarity 110, member C"               | NM_001077710 | uc002qvt.1   | ENST00000327669 | chr2       | -      |     31607 |                                 |     | 0%
                | CCDS10395.1 | POLR3K      | "polymerase (RNA) III (DNA directed) polypeptide K, 12.3 kDa" | NM_016310    | uc002cfi.1   | ENST00000293860 | chr16      | -      |     37429 |                               |       | 100%
                | CCDS10396.1 | C16orf33    | chromosome 16 open reading frame 33                           | NM_024571    | uc002cfj.2   | ENST00000293861 | chr16      | +      |     43989 |                               |       | 100%
                | CCDS32344.1 | RHBDF1      | rhomboid 5 homolog 1 (Drosophila)                             | NM_022450    | uc002cfl.2   | ENST00000262316 | chr16      | -      |     48338 |                               |       | 100%
                | CCDS30547.1 | OR4F5       | "olfactory receptor, family 4, subfamily F, member 5"         | NM_001005484 | uc001aal.1   | ENST00000326183 | chr1       | +      |     58953 |                               |       | 100%
                | CCDS32854.1 | OR4F17      | "olfactory receptor, family 4, subfamily F, member 17"        | NM_001005240 | uc002loc.1   | ENST00000318050 | chr19      | +      |     61678 |                               |       | 100%
                | CCDS10994.1 | RPH3AL      | rabphilin 3A-like (without C2 domains)                        | NM_006987    | uc002frd.1   | ENST00000323434 | chr17      | -      |     63642 |  1                            |       | 100%
                | CCDS32345.1 | MPG         | N-methylpurine-DNA glycosylase                                | NM_001015054 | uc002cfm.1   | ENST00000397817 | chr16      | +      |     68308 |                               |       | 100%
                | CCDS32346.1 | MPG         | N-methylpurine-DNA glycosylase                                | NM_002434    | uc002cfn.1   | ENST00000219431 | chr16      | +      |     69291 |                               |       | 100%
                +-------------+-------------+---------------------------------------------------------------+--------------+--------------+-----------------+------------+--------+-----------+---------+------------+----------------+----------------------------------+
        
        
        2. NIMBLEGEN SNP PIPELINE OUTPUT FILES, E.G.:
                    
            >Reference      Start   End     Ref     Var     Total   Var
            >Accno           Pos    Pos     Nuc     Nuc     Depth   Freq
            >CCDS3.1|Hs36.3|chr1    778     783     CTGGTG  GTGCTAT 5       60%
            >CCDS3.1|Hs36.3|chr1    1016    1016    C       T       4       100%
            >CCDS3.1|Hs36.3|chr1    1078    1078    T       C       4       100%
            >CCDS3.1|Hs36.3|chr1    1084    1084    T       C       4       100%
            >CCDS3.1|Hs36.3|chr1    1102    1102    C       T       4       100%
            >CCDS3.1|Hs36.3|chr1    1166    1166    G       A       5       80%
            >CCDS3.1|Hs36.3|chr1    1182    1182    T       C       5       100%
            >CCDS3.1|Hs36.3|chr1    1359    1359    G       A       6       100%
            
        3. FILTER CRITERIA
        
                % FREQUENCY
                QUALITY
                HETEROZYGOTE/HOMOZYGOTE
                SYNONYMOUS/NON-SYNONYMOUS
        
    OUTPUT
    
        1. FILE CONTAINING A LIST OF SNPS THAT PASS FILTER CRITERIA
        
    USAGE
    
    ./captureSNP.pl  <--inputfile String> <--positionfile String> <--outputfile String> [-h]
    
        --inputfile            :   /full/path/to/input_SNP.txt file
        --positionfile         :   /full/path/to/chromosome_positions.txt file
        --outputfile           :   /full/path/to/output_SNP.txt file
        --help                 :   print help info

    EXAMPLES

ON SOLEXA

./captureSNPs.pl --inputfile /home/syoung/base/pipeline/nimblegen-gsmapper/P_2009_01_09_03_26_14_runMapping/mapping/snps/454HCDiffs-headers.txt --outputfile /home/syoung/base/pipeline/nimblegen-gsmapper/P_2009_01_09_03_26_14_runMapping/mapping/snps/snps.out --positionfile /home/syoung/base/pipeline/human-genome/chromosome_positions.txt

ON KRONOS

./captureSNPs.pl --inputfile /nethome/syoung/base/pipeline/nimblegen-gsmapper/P_2009_01_09_03_26_14_runMapping/mapping/snps/454HCDiffs-headers.txt --outputfile /nethome/syoung/base/pipeline/nimblegen-gsmapper/P_2009_01_09_03_26_14_runMapping/mapping/snps/snps.out --positionfile /nethome/syoung/base/pipeline/human-genome/chromosome_positions.txt


 select * from ccdsSNP limit 1\G
*************************** 1. row ***************************
     chromosome: chr1
chromosomeStart: 58996
  chromosomeEnd: 58997
            snp: rs1638318
          score: 0
         strand: +
1 row in set (0.01 sec)

rs1638318 is A/G

TEST FILE

emacs /nethome/syoung/base/pipeline/nimblegen-gsmapper/P_2009_01_09_03_26_14_runMapping/mapping/snps/test.txt

>Reference      Start   End     Ref     Var     Total   Var
>Accno           Pos    Pos     Nuc     Nuc     Depth   Freq
>CCDS3.1|Hs36.3|chr1    58996     598997     A  G 5       60%

./captureSNPs.pl --inputfile /nethome/syoung/base/pipeline/nimblegen-gsmapper/P_2009_01_09_03_26_14_runMapping/mapping/snps/test.txt --outputfile /nethome/syoung/base/pipeline/nimblegen-gsmapper/P_2009_01_09_03_26_14_runMapping/mapping/snps/snps.out --positionfile /nethome/syoung/base/pipeline/human-genome/chromosome_positions.txt

=cut 

use strict;
use warnings;
use Carp;

require Exporter;
our @ISA = qw(Exporter Filter);
our @EXPORT_OK = qw();
our $AUTOLOAD;

use strict;

#### EXTERNAL MODULES
use POSIX;
use Data::Dumper;

#### INTERNAL MODULES
use Filter;
use Timer;

#### DEFAULT PARAMETERS
our @DATA = qw(
	DBOBJECT
);
our $DATAHASH;
foreach my $key ( @DATA )	{	$DATAHASH->{lc($key)} = 1;	}


=head2

    SUBROUTINE      annotate
    
    PURPOSE
    
        ANNOTATE RAW SNPS:
        
            1. CHECK IF SNP IN GENE (WITHIN RIGHT OR LEFT MARGINS)
            
                IGNORE 'N' POSITIONS
                
                CHECK IF POSITION IN ccdsGene
            
            
            2. IF IN GENE, CALCULATE POSITION OF SNP
                    
            **        UPSTREAM (MARGIN)
                5' UTR
                NON-CODING
                EXONIC
                INTRONIC
                3' UTR
            **        DOWNSTREAM (MARGIN)
            
            
            3. IF CODING, CALCULATE EFFECT OF SNP 
            
                MISSENSE
                SYNONYMOUS
                STOP
                START
                

    INPUTS
    
        1. PILEUP FORMAT SNP FILE
        
        2. DATABASE OBJECT CONTAINING THE FOLLOWING TABLES:
        
            CREATE TABLE ccdsGene (
              bin smallint(5) NOT NULL,
              name varchar(255) NOT NULL,
              chrom varchar(255) NOT NULL,
              strand char(1) NOT NULL,
              txStart int(10) NOT NULL,
              txEnd int(10) NOT NULL,
              cdsStart int(10) NOT NULL,
              cdsEnd int(10) NOT NULL,
              exonCount int(10) NOT NULL,
              exonStarts longblob NOT NULL,
              exonEnds longblob NOT NULL,
              score int(11) NOT NULL,
              name2 varchar(255) NOT NULL,
              cdsStartStat TEXT NOT NULL,
              cdsEndStat TEXT NOT NULL,
              exonFrames longblob NOT NULL,
              PRIMARY KEY (chrom,bin, name)
            );
        
            CREATE TABLE snp130_chr<CHROMOSOME> (
                chrom varchar(31) NOT NULL default '',
                chromStart int(10) NOT NULL default 0,
                chromEnd int(10) NOT NULL default 0,
                name varchar(15) NOT NULL default '',
                PRIMARY KEY (name, chrom, chromStart, chromEnd)
            );
            
            CREATE TABLE ccdsSeq (
                id VARCHAR(20),
                sequence TEXT,
                primary key(id)
            );
    
    OUTPUTS

        1. PRINT OUT EXTENDED PILEUP FILE CONTAINING THE FOLLOWING
        
            TAB-SEPARATED COLUMNS:
        
            PILEUP COLUMNS
            
            1. chromosome                      ('chromosome')
            2. 1-based coordinate
            3. reference base
            4. consensus base                   ('variant')
            5. consensus quality                Phred-scaled probability that the consensus is wrong
            6. SNP quality                      Phred-scaled probability that the consensus is identical to the reference. (For SNP calling, SNP quality is of more importance.)
            7. max. mapping quality of reads covering sites
            8. number of reads covering site    ('depth')
            9. read bases
            10. phred33 base qualities
            
            ADDITIONAL COLUMNS
        
EXAMPLE

11                 12      13           14     15      16          17      18      19      20    21   22 	
rs2845335       0.737   CCDS13744.1     403     exon    5          +       CGC     CCC     R       P       missense
rs2844883       0.517   CCDS13742.1     424     intron  5          -

            Column Definitions        
            11. dbsnp              One or more rs-#, e.g., 'rs71273002,rs2843360'
            12. variantfrequency   Calculated from read bases in pileup column 9
            13. ccdsname           Name of CCDS sequence
            14. ccdsstart          Chromosomal start position of CCDS  sequence
            15. ccds               Position in CCDS sequence (5-utr|non-coding|exonic|intronic|3-utr)
            16. ccdsnumber         Exon number in CCDS, e.g., 1 for first exon
            17. ccdsstrand         Chromosomal strand of CCDS sequence (+|-)
            18. referencecodon     Codon in reference sequence
            19. variantcodon       Possibly changed codon in variant sequence
            20. referenceaa        Amino acid produced using reference codon
            21. variantaa          Amino acid produced using variant codon
             22. effect            Effect of variant on codon (missense|synonymous|stop|start)

=cut

sub annotate
{
    my $self        =   shift;
    my $args        =   shift;
    
    my $inputfile       =   $args->{inputfile}; 
    my $outputfile      =   $args->{outputfile};
    my $inputtype       =   $args->{inputtype};
    my $db       	=   $args->{db};
    my $dbdir       	=   $args->{dbdir};
    my $dbsnp       	=   $args->{dbsnp};
    my $linecount       =   $args->{linecount};

my $DEBUG = 1;

    #### TIMING    
    #my $time1 = [gettimeofday()];	
    my $time = time();

    #### CHECK INPUTS
    print "Filter::SNP::annotate    inputfile not found: $inputfile\n" and return if not -f $inputfile;

    #### DEBUG
    print "Filter::SNP::annotate    inputtype: $inputtype\n" if $DEBUG;
    print "Filter::SNP::annotate    outputfile: $outputfile\n" if $DEBUG;
    print "Filter::SNP::annotate    inputfile: $inputfile\n" if $DEBUG;
    print "Filter::SNP::annotate    inputtype: $inputtype\n" if $DEBUG;
    print "Filter::SNP::annotate    dbdir: $dbdir\n" if $DEBUG;
    print "Filter::SNP::annotate    dbsnp: $dbsnp\n" if $DEBUG;

    #### INITIALISE FEATURE OBJECT TO STEP THROUGH SNP FILE LINES
	my $feature = Feature->new(
		{
			file 		=>	$inputfile,
			type		=>	$inputtype,
			outputfile	=>	$outputfile
		}
	);

    #### SET OUTPUT FILE HANDLE
    $self->setOutfh($outputfile);

    #### SET DBSNP DBOBJECTS FOR ALL CHROMOSOMES
    $self->setDbfiles($dbdir, $dbsnp);

    #### SET FIELDS FOR FILE COLUMNS (ADDITIONAL TO 10 PILEUP COLUMNS)
    $self->setFields();

    #### DO ALL FEATURES IN FILE
    my $current_feature = 1;
    my $counter = -1;
    my $dot = 10;
    while ( defined $current_feature )
    {
        #### NEXT FEATURE
        $current_feature = $feature->nextFeature();
        last if not defined $current_feature;

        #### INCREMENT COUNTER
        $counter++;
        
        print "$counter [total $linecount] ", Timer::current_datetime(), "\n" if $counter % $dot == 0;

        ####  1.  IGNORE 'N' POSITIONS
        ####    
        #### NOTE: THIS IS SPECIFIC TO pileup FILE FORMAT
        ####        ADAPT LATER IF OTHER INPUT FILE FORMAT IS USED
        my ($reference_base, $variant_base, $read_bases);
        my @elements = split "\t", $current_feature->{line};
        if ( $inputtype eq "pileup" )
        {
            $reference_base = $elements[2];
            $variant_base = $elements[3];
            $read_bases = $elements[8];
        }
        #### IGNORE IF 'N' OR AN INDEL
        print "Filter::SNP::annotate    $counter Skipping because indel or N. reference_base: $reference_base\n" if ($reference_base eq "*" or $reference_base eq "N") and $DEBUG;
        next if $reference_base eq "*" or $reference_base eq "N";
        print "Filter::SNP::annotate    $counter Skipping indel. variant_base: $variant_base\n" if $variant_base =~ /^[\+\-]/ and $DEBUG;
        next if $variant_base =~ /^[\+\-]/;

        #### 2. ADD dbSNP IF ONE OVERLAPS WITH POSITION
        $self->addDbsnp($db, $dbsnp, $current_feature);
        
        #### 3. ADD VARIANT FREQUENCY TO THE END OF LINE
        $self->addVariantFreq($current_feature, $variant_base, $read_bases);
        
        #### 4. CHECK IF SNP IN CCDS GENE (WITHIN UPSTREAM AND DOWNSTREAM LIMITS)
        my ($ccds, $type, $position) = $self->addCcds($db, $current_feature);

        #### PRINT FEATURE AND SKIP TO NEXT IF NOT WITHIN A CCDS GENE
        $self->printFeature($current_feature) and next if not defined $ccds or not %$ccds;
        
        #### JUST PRINT AND SKIP THE REST IF NOT AN EXON
        print "Filter::SNP::annotate    dbsnp: $dbsnp\n" if $DEBUG;
        $self->printFeature($current_feature) and next if $type ne "exon";
        #$self->printFeature($current_feature) and last if $type ne "exon";

        #### GET SEQUENCE
        my $sequence = $self->geneSequence($ccds->{name});
        #print "Filter::SNP::annotate    sequence: $sequence\n" if $DEBUG;
        
        #### PRINT FEATURE AND NEXT IF SEQUENCE NOT DEFINED
        print "Filter::SNP::annotate    Doing printFeature and skipping because sequence is not defined\n" if $DEBUG;
        $self->printFeature($current_feature) and next if not defined $sequence or not $sequence;
        $self->addExon($current_feature, $ccds, $position, $variant_base, $sequence);
        
        #### PRINT FEATURE
        $self->printFeature($current_feature);
    }

    print "$counter [total $linecount] COMPLETED ", Timer::current_datetime(), "\n";
    
    #### PRINT RUN TIME
    my $runtime = Timer::runtime( $time, time() );
    print "Run time: $runtime\n";

    #### TIMING    
    #my $milliseconds = tv_interval($time1) * 1000;
    #printf "Elapsed time: $milliseconds milliseconds\n";

    print "Filter::SNP::annotate    outputfile:\n\n$outputfile\n\n";
}

=head2

    SUBROUTINE      printFeature

    PURPOSE

        PRINT FEATURE INCLUDING ORIGINAL PILEUP COLUMNS AND ADDITIONAL

        SNP ANNOTATION COLUMNS
        
=cut

sub printFeature
{
    my $self    =   shift;
    my $feature =   shift;

    print "Filter::SNP::printFeature    Filter::SNP::printFeature(feature)\n" if $DEBUG;
    #print "Filter::SNP::printFeature    feature:\n";
    #print Dumper $feature;

    my $line = $feature->{line};
    $line =~ s/\n$//;
    #print "Filter::SNP::printFeature    line: $line\n";
    my $fields = $self->get_fields();
    #print "Filter::SNP::printFeature    fields: @$fields\n";
    my $fieldvalues = $self->get_fieldvalues();
    #print "Filter::SNP::printFeature    fieldvalues: \n";
    #print Dumper $fieldvalues;
    
    my $index = 0;
    foreach my $field ( @$fields )
    {
        my $value = $fieldvalues->{$$fields[$index]} || "";
        #my $value = $fieldvalues->{$$fields[$index]};
        print "Filter::SNP::printFeature    $field\t$value\n" if $DEBUG;
        $line .= "\t$value";
        $index++;
    }
    
    print "Filter::SNP::printFeature    FINAL line: $line\n" if $DEBUG;
    
    my $outfh = $self->get_outfh();
	print $outfh "$line\n";

}


=head2

    SUBROUTINE      setFields

    PURPOSE

        SET FIELD NAMES OF COLUMNS (ADDITIONAL TO 10 PILEUP COLUMNS)
        
=cut

sub setFields
{
    my $self    =   shift;
    
    #### SET FIELDS/COLUMNS, ADDITIONAL TO 10 PILEUP COLUMNS
    my $fields = [
		'dbsnp',
		'variantfrequency',
		'ccdsname',
		'ccdsstart',
		'ccdstype',
		'ccdsnumber',
		'ccdsstrand',
		'referencecodon',
		'variantcodon',
		'referenceaa',
		'variantaa',
		'effect'
    ];
    $self->set_fields($fields);

    #### INSTANTIATE fieldvalues AND POPULATE WITH ''
    my $fieldvalues = {};
    foreach my $field ( @$fields )
    {
        $fieldvalues->{$field} = '';
    }
    $self->set_fieldvalues($fieldvalues);

    #### SET FIELD-COLUMN ORDER MAPPING
    my $fieldmap;
    my $index = 0;
    %$fieldmap = map { $$fields[$index++] => $index } @$fields;
    $self->set_fieldmap($fieldmap);    
    #print "Filter::SNP::annotate    fieldmap:\n";
    #print Dumper $fieldmap;

}

=head2

    SUBROUTINE      addDbsnp

    PURPOSE

        
        2. IF SO, RETRIEVE RELATED INFO ABOUT THE dbSNP ENTRY
        
=cut

sub addDbsnp
{
    my $self            =   shift;
    my $db        =   shift;
    my $dbsnp           =   shift;
    my $feature         =   shift;

    my $chromosome = $feature->{chromosome};
    my $start = $feature->{start} - 1;
    my $stop = $feature->{start};
    
#my $DEBUG = 1;
    print "Filter::SNP::addDbsnp    Filter::SNP::addDbsnp(chromosome, start, stop)\n" if $DEBUG;
    print "Filter::SNP::addDbsnp    chromosome: $chromosome\n" if $DEBUG;
    print "Filter::SNP::addDbsnp    start: $start\n" if $DEBUG;
    print "Filter::SNP::addDbsnp    stop: $stop\n" if $DEBUG;

    my $chromosome_name = "chr" . $chromosome;
    my $table = $dbsnp . "_chr" . $chromosome;
    print "Filter::SNP::addDbsnp    table: $table\n" if $DEBUG;

    my $dbfiles = $self->get_dbfiles();
    my $dbfile = $dbfiles->{$chromosome_name};
    
    #### ADJUST CHROMOSOME POSITION TO ZERO-INDEXED
    
    my $query = qq{sqlite3 $dbfile "select * from $table WHERE chromStart = $start"};
    #my $query = qq{sqlite3 $dbfile "select * from $table WHERE chromStart = $stop"};
    #my $query = qq{sqlite3 $dbfile "select * from $table WHERE chromStart <= $start and chromEnd >= $stop"};
    print "Filter::SNP::addDbsnp    query: $query\n" if $DEBUG;
    my $result = `$query`;
    return if not defined $result;
    
    #print "Filter::SNP::annotate    $start dbsnp: $result\n";
    print "Filter::SNP::addDbsnp    ref(result): ", ref($result), "\n" if $DEBUG;
    print "Filter::SNP::annotate    result:\n" if $DEBUG;
    print Dumper  $result if $DEBUG;
    if ( ref($result) eq "" )
    {
        my ($snp) = $result =~ /([^\|]+?)\s*$/;
        $self->get_fieldvalues()->{dbsnp} = $snp;
    }
    elsif ( ref($result) eq "ARRAY" ) 
    {
        $self->get_fieldvalues()->{dbsnp} = "";
        foreach my $line ( @$result )
        {
            my ($snp) = $line =~ /([^\|]+?)\s*$/;
            $self->get_fieldvalues()->{dbsnp} .= "$snp,";
        }
        $self->get_fieldvalues()->{dbsnp} =~ s/,$//;
    }
    else
    {
        print "Filter::SNP::addDbsnp    unknown format for dbsnp query result:\n" if $DEBUG;
        print Dumper $result;
        exit;
    }

    return $self->get_fieldvalues()->{dbsnp};
}

=head2

    SUBROUTINE      setDbfiles

    PURPOSE

        1. SET DBSNP DBOBJECTS FOR ALL CHROMOSOMES
        
        2. SEARCHES FOR *dbl SQLITE DATABASE FILES IN <DBDIR>
        
        3. ALL *dbl FILE NAMES MUST BEGIN WITH <FILESTUB>
        
=cut

sub setDbfiles
{
    my $self            =   shift;
    my $dbdir           =   shift;
    my $filestub           =   shift;

#my $DEBUG = 1;
    print "Filter::SNP::setDbfiles    Filter::SNP::setDbfiles(dbdir, filestub)\n" if $DEBUG;
    print "Filter::SNP::setDbfiles    dbdir: $dbdir\n" if $DEBUG;
    print "Filter::SNP::setDbfiles    filestub: $filestub\n" if $DEBUG;

    my @files = <$dbdir/$filestub*dbl>;
    print "files: @files\n" if $DEBUG;

    my $dbfiles = {};
    foreach my $file ( @files )
    {
        my ($name) = $file =~ /$filestub-([^\/]+)\.dbl$/;
        print "Filter::SNP::setDbfiles    file: $file\n" if $DEBUG;
        print "Filter::SNP::setDbfiles    name: $name\n" if $DEBUG;
        $dbfiles->{$name} = $file;
    }

    $self->{_dbfiles} = $dbfiles;
}


=head2

    SUBROUTINE      addCcds
    
    PURPOSE
    
        IF POSITION LIES WITHIN A CCDS GENE (I.E., BETWEEN TRANSCRIPTION
        
        START AND TRANSCRIPTION STOP) GET CCDS INFO AND ADD TO fieldvalues

    INPUTS
    
        1. DATABASE OBJECT CONTAINING ccdsGene TABLE
        
        2. FEATURE WITH CHROMOSOME AND START POSITION


    OUTPUTS
    
        ADDED FIELDS
        
        12. ccds
        13. ccdstype                        (5-utr|non-coding|exonic|intronic|3-utr)
        14. ccdsstrand                      (+|-)
        15. ccdsnumber                      (CCDS1.1)
        16. ccdsstart

=cut

sub addCcds
{
    my $self            =   shift;
    my $db        =   shift;
    my $feature         =   shift;

    my $chromosome = $feature->{chromosome};
    my $start = $feature->{start} - 1;
    my $stop = $feature->{start};
    
#my $DEBUG = 1;
    print "Filter::SNP::addCcds    Filter::SNP::addCcds(chromosome, start, stop)\n" if $DEBUG;
    print "Filter::SNP::addCcds    chromosome: $chromosome\n" if $DEBUG;
    print "Filter::SNP::addCcds    start: $start\n" if $DEBUG;
    print "Filter::SNP::addCcds    stop: $stop\n" if $DEBUG;

    #### GET CCDS SPANNING SNP POSITION
    my $query = qq{SELECT * FROM ccdsGene
WHERE chrom='chr$chromosome'
AND txStart <= $start
AND txEnd >= $start
};
    #print "Filter::SNP::addCcds    query: $query\n";

    my $ccds = $db->queryhash($query);
    return if not defined $ccds or not %$ccds;

    #### GET GENE POSITION
    my $gene_location = $self->geneLocation($ccds, $start);
    my $position = $gene_location->{position};
    my $type = $gene_location->{type};
    print "Filter::SNP::addCcds    type: $type\n" if $DEBUG;
    print Dumper $gene_location if $DEBUG;

    
    #### SET fieldvalues

    #### CCDS INFO
    $self->get_fieldvalues()->{ccdsname} = $ccds->{name};
    $self->get_fieldvalues()->{ccdsstart} = $gene_location->{position};
    
    #### GENE POSITION INFO
    $self->get_fieldvalues()->{ccdstype} = $gene_location->{type} || '';
    $self->get_fieldvalues()->{ccdsnumber} = $gene_location->{number} || '';
    $self->get_fieldvalues()->{ccdsstrand} = $ccds->{strand};
    
    return $ccds, $type, $position;
}





=head2

    SUBROUTINE      addExon
    
    PURPOSE
    
        ADD EXON INFO TO fieldvalues

    INPUTS
    
        1. FEATURE OBJECT
        
        2. CCDS OBJECT

        3. POSITION FROM START OF CCDS
        
        4. VARIANT BASE
        
        5. CCDS NUCLEOTIDE SEQUENCE

    OUTPUTS
    
        ADDED COLUMNS:
    
            17. referencecodon
            18. variantcodon
            19. referenceaa
            20. variantaa
            21. effect                          (missense|synonymous|stop|start)

=cut

sub addExon
{
    my $self        =   shift;
    my $feature     =   shift;
    my $ccds        =   shift;
    my $position    =   shift;
    my $variant_base=   shift;  
    my $sequence    =   shift;  

#my $DEBUG = 1;
    print "Filter::SNP::addExon    Filter::SNP::addExon(feature, ccds, position, variant_base, sequence)\n" if $DEBUG;

    #### GET STRAND
    my $strand = $ccds->{strand};
    print "Filter::SNP::addExon    strand: $strand\n" if $DEBUG;

    #### GET REFERENCE AND VARIANT CODONS
    my $reference_codon = $self->referenceCodon($strand, $position, $sequence);
    my $variant_codon = $self->variantCodon($strand, $position, $reference_codon, $variant_base);

    #### GET AMINO ACID
    my $reference_aa = $self->codonToAa($reference_codon, "oneletter");
    my $variant_aa = $self->codonToAa($variant_codon, "oneletter");
    print "Filter::SNP::addExon    reference_aa: $reference_aa\n" if $DEBUG;
    print "Filter::SNP::addExon    variant_aa: $variant_aa\n" if $DEBUG;

    #### GET EFFECT
    my $effect = $self->effect($reference_aa, $variant_aa);
    print "Filter::SNP::addExon    effect: $effect\n" if $DEBUG;
    #print OUTFILE "$effect\n";

    #### ADD CODON CHANGE INFO TO fieldvalues
    $self->get_fieldvalues()->{referencecodon} = $reference_codon;
    $self->get_fieldvalues()->{variantcodon} = $variant_codon;
    $self->get_fieldvalues()->{referenceaa} = $reference_aa;
    $self->get_fieldvalues()->{variantaa} = $variant_aa;
    $self->get_fieldvalues()->{effect} = $effect;
}


=head2

    SUBROUTINE      addCodonChange
    
    PURPOSE
    
        ADD CCDS INFO TO END OF FEATURE LINE

        SEE 'EXTENDED PILEUP' IN DOCUMENTATION

    ADDED COLUMNS

        17. referencecodon
        18. variantcodon
        19. referenceaa
        20. variantaa
        21. effect                          (missense|synonymous|stop|start)

=cut

sub addCodonChange
{
    my $self            =   shift;
    my $feature         =   shift;
    my $referencecodon  =   shift;
    my $variantcodon    =   shift;
    my $referenceaa     =   shift;
    my $variantaa       =   shift;
    my $effect          =   shift;

#my $DEBUG = 1;

    print "Filter::SNP::addCodonChange    Filter::SNP::addCodonChange(feature, ccds, gene_position)\n" if $DEBUG;

    print "Filter::SNP::addCodonChange    feature:\n" if $DEBUG;
    print Dumper $feature;

    print "Filter::SNP::addCodonChange    referencecodon: $referencecodon\n" if $DEBUG;
    print "Filter::SNP::addCodonChange    variantcodon: $variantcodon\n" if $DEBUG;
    print "Filter::SNP::addCodonChange    referenceaa: $referenceaa\n" if $DEBUG;
    print "Filter::SNP::addCodonChange    referenceaa: $referenceaa\n" if $DEBUG;
    print "Filter::SNP::addCodonChange    effect: $effect\n" if $DEBUG;

    print "Filter::SNP::addCodonChange    referencecodon not defined. Returning\n" and return if not defined $referencecodon;
    print "Filter::SNP::addCodonChange    variantcodon not defined. Returning\n" and return if not defined $variantcodon;
    print "Filter::SNP::addaaChange    referenceaa not defined. Returning\n" and return if not defined $referenceaa;
    print "Filter::SNP::addaaChange    variantaa not defined. Returning\n" and return if not defined $variantaa;
    print "Filter::SNP::addaaChange    effect not defined. Returning\n" and return if not defined $effect;
    
    $feature->{line} .= "\t$referencecodon";
    $feature->{line} .= "\t$variantcodon";
    $feature->{line} .= "\t$referenceaa";
    $feature->{line} .= "\t$variantaa";
    $feature->{line} .= "\t$effect";

}






=head2

    SUBROUTINE      addVariantFreq
    
    PURPOSE
    
        ADD THE VARIANT FREQUENCY VALUE (0 TO 1.0) TO END OF FEATURE LINE
        
=cut

sub addVariantFreq
{
    my $self            =   shift;
    my $feature         =   shift;
    my $variant_base    =   shift;
    my $read_bases      =   shift;

#my $DEBUG = 1;
    print "Filter::SNP::addVariantFreq    Filter::SNP::addVariantFreq(feature, variant_base, read_bases)\n" if $DEBUG;
    print "Filter::SNP::addVariantFreq    variant_base: $variant_base\n" if $DEBUG;
    print "Filter::SNP::addVariantFreq    BEFORE read_bases: $read_bases\n" if $DEBUG;
    
    #### REMOVE ANY QUALITY VALUES
    $read_bases =~ s/\^.//g;
    print "Filter::SNP::addVariantFreq    AFTER read_bases: $read_bases\n" if $DEBUG;

    my $length = length($read_bases);
    my ($count) = $read_bases =~ s/$variant_base//gi;

    print "Filter::SNP::addVariantFreq    length: $length\n" if $DEBUG;
    print "Filter::SNP::addVariantFreq    count: $count\n" if $DEBUG;
    
    my $variant_frequency = sprintf "%.3f", ($count / $length);
    print "Filter::SNP::addVariantFreq    variant_frequency: $variant_frequency\n" if $DEBUG;

    $self->get_fieldvalues()->{variantfrequency} = $variant_frequency if defined $variant_frequency;
}

=head2

    SUBROUTINE      chromosomeStartstop
    
    PURPOSE
    
        GET CHROMOSOME START/STOP OF SNP BASED ON THE SNP POSITION
        
        IN GENE, GENE START/STOP AND EXON START/STOPS
        
=cut

sub chromosomeStartstop
{
    my $self        =   shift;
    
    my $db = $self->{_db};
    my $linehash = $self->{_linehash};

my $DEBUG = 1;

    print "Filter::SNP::chromosomeStartstop()\n" if $DEBUG;
    #print "Filter::SNP::chromosomeStartstop    LINEHASH:\n";
    #print Dumper $linehash;
    
    #### GET SNP CCDS START
    my $snp_ccds_start = $linehash->{ccdsstart};
    print "Filter::SNP::chromosomeStartstop    snp ccds start: $snp_ccds_start\n" if $DEBUG;
    
    #### GET txStart FROM ccdsGene TABLE
    my $query = "SELECT txStart, txEnd, strand, exonStarts, exonEnds FROM ccdsGene WHERE name='$linehash->{name}'";
    print "$query\n" if $DEBUG;
    my $ccds = $db->queryhash($query);
    print "Filter::SNP::chromosomeStartstop    ccds:\n";
    print Dumper $ccds;
#exit;

    return if ( not defined $ccds or not $ccds );
    my $transcription_start = $ccds->{txStart};
    my $transcription_stop = $ccds->{txEnd};
    my $strand = $ccds->{strand};
    
    #### GET CHROMOSOME-SPECIFIC START SITE OF SNP WITHIN CCDS
    my $snp_chromosome_start = my $snp_chromosome_stop = $self->_chromosomeStartstop($ccds, $snp_ccds_start);

    $linehash->{chromosomestart} = $snp_chromosome_start;
    $linehash->{chromosomestop} = $snp_chromosome_stop;

    $self->{_linehash} = $linehash;
    
    return $snp_chromosome_start;
}




=head2

    SUBROUTINE      geneLocation
    
    PURPOSE
    
        CALCULATE A GENE-RELATIVE POSITION GIVEN A CHROMOSOME-RELATIVE
        
        POSITION

    INPUTS
    
        1. POSITION ON CHROMOSOME
        
        2. ENTRY IN ccdsGene TABLE CONTAINING:
        
            CHROMOSOME-RELATIVE EXON START/STOP POSITIONS
        
            STRAND
        
    OUTPUT
    
        POSITION RELATIVE TO GENE START
        
=cut

sub geneLocation
{
    my $self                =   shift;
    my $ccds                =   shift;  
    my $chromosome_position =   shift;

#my $DEBUG = 1;

    print "\nFilter::SNP::geneLocation(ccds, chromosome_position)\n" if $DEBUG;
    print "Filter::SNP::geneLocation    ccds:\n" if $DEBUG;
    print Dumper $ccds if $DEBUG;
    print "Filter::SNP::geneLocation    chromosome_position: $chromosome_position\n" if $DEBUG;

    #### VERIFY SNP CCDS POSITION
    my @exon_starts = split /,/, $ccds->{exonStarts};
    my @exon_stops = split /,/, $ccds->{exonEnds};
    #print "Filter::SNP::geneLocation    exon starts: @exon_starts\n" if $DEBUG;
    #print "Filter::SNP::geneLocation    exon stops: @exon_stops\n" if $DEBUG;

    #### CHECK IF EQUAL NUMBERS OF STARTS AND STOPS
    if ( $#exon_starts != $#exon_stops )
    {
        die "Unequal number of exon_starts (", $#exon_starts + 1, ") and exon_stops (" , $#exon_stops + 1, ")\n";
    }

    #### GET STRAND
    my $strand = $ccds->{strand};
    print "Filter::SNP::geneLocation    strand: $strand\n" if $DEBUG;

    #### DO POSITIVE STRAND
    if ( $strand =~ /^\+$/ )
    {
        #### SET EXONS    
        my $exons;
        my $total_length = 0;
        for ( my $i = 0; $i < $#exon_starts + 1; $i++ )
        {
            $$exons[$i]->{start} = $exon_starts[$i];
            $$exons[$i]->{stop} = $exon_stops[$i];
            $$exons[$i]->{length} = $exon_stops[$i] - $exon_starts[$i];
            $total_length += $$exons[$i]->{length};
        }
        print "Filter::SNP::geneLocation    Total length: $total_length\n" if $DEBUG;

        #### 1. GO THROUGH THE EXONS UNTIL:
        ####     EXON CHROMOSOME START <= INPUT CHROMOSOME POSITION <= EXON CHROMOSOME STOP

        my $cumulative_length = 0;
        my $exon_start = $$exons[0]->{start};
        my $exon_stop = $$exons[0]->{stop};
        my $exon_counter = 0;
        while ( not ( $$exons[$exon_counter]->{start} <= $chromosome_position
                     and $chromosome_position <= $$exons[$exon_counter]->{stop} ) 
            and $exon_counter < @$exons )
        {
            print "Filter::SNP::geneLocation    + STRAND exon $exon_counter searching $chromosome_position in $$exons[$exon_counter]->{start}..$$exons[$exon_counter]->{stop}\n" if $DEBUG;
    
            #### IF THE POSITION IS UPSTREAM OF THE CURRENT EXON START,
            #### IT'S EITHER IN THE 5'-UTR OR IN THE PRECEDING INTRON
            if ( $chromosome_position < $$exons[$exon_counter]->{start} )
            {
                #print "Filter::SNP::geneLocation    Falls between exons\n";

                #### IT'S IN THE 5'-UTR
                if ( $exon_counter == 0 )
                {
                    my $upstream_distance = $chromosome_position - $$exons[$exon_counter]->{stop};
                    print "upstream_distance: $upstream_distance\n";
                    my $gene_location = {
                        type        =>  '5-UTR',
                        position    =>  $upstream_distance,
                        number      =>  ''
                    };
                    
                    #print "gene_position:\n";
                    #print Dumper $gene_location;
                    return $gene_location;
                }
                
                #### IT'S INTRONIC
                else
                {
                    my $intron_distance = $chromosome_position - $$exons[$exon_counter - 1]->{start};

                    my $gene_location = {
                        type        =>  'intron',
                        position    =>  $intron_distance,
                        number      =>  $exon_counter
                    };
                    
                    #print "gene_position:\n";
                    #print Dumper $gene_location;
                    return $gene_location;
                }
            }

            #### ADD EXON LENGTH TO CUMULATIVE LENGTH
            $cumulative_length += $$exons[$exon_counter]->{length};

            #### SET NEW EXON CHROMOSOME START
            $exon_start = $$exons[$exon_counter]->{start};
            
            #### INCREMENT EXON COUNTER
            $exon_counter++;
        }        
        
        print "Filter::SNP::geneLocation    AFTER SEARCH, exon $exon_counter $chromosome_position on ($$exons[$exon_counter]->{start}..$$exons[$exon_counter]->{stop})\n" if $DEBUG;
        print "Filter::SNP::geneLocation    Cumulative length: $cumulative_length\n" if $DEBUG;    

        #### IF THE POSITION IS DOWNSTREAM OF THE LAST EXON STOP (i.e., exon->{stop}),
        #### THEN IT'S IN THE 3-UTR
        if ( $chromosome_position > $$exons[((scalar(@$exons) - 1))]->{stop} )
        {
            my $downstream_distance = $$exons[$exon_counter]->{stop} - $chromosome_position;
            print "downstream_distance: $downstream_distance\n" if $DEBUG;
            my $gene_location = {
                type        =>  '3-UTR',
                position    =>  $downstream_distance,
                number      =>  ''
            };
            
            #print "gene_position:\n";
            #print Dumper $gene_location;
            return $gene_location;
        }

        my $positive_offset = $chromosome_position - $$exons[$exon_counter]->{start};
        my $position = $cumulative_length + $positive_offset;
        my $gene_location = {
            type        =>  'exon',
            position    =>  $position,
            number      =>  $exon_counter + 1
        };
        #print "gene_position:\n";
        #print Dumper $gene_location;
        return $gene_location;
    }

    #### DO NEGATIVE STRAND
    elsif ( $strand =~ /^\-$/ )
    {
        #### SWAP THE EXON START AND STOP ARRAYS AND REVERSE THEM
        my @temp = @exon_starts;
        @exon_starts = reverse @exon_stops;
        @exon_stops = reverse @temp;
        print "Filter::SNP::geneLocation    exon starts: @exon_starts\n" if $DEBUG;
        print "Filter::SNP::geneLocation    exon stops: @exon_stops\n" if $DEBUG;

        #### SET EXONS    
        my $exons;
        my $total_length = 0;
        for ( my $i = 0; $i < $#exon_starts + 1; $i++ )
        {
            $$exons[$i]->{start} = $exon_starts[$i];
            $$exons[$i]->{stop} = $exon_stops[$i];
            $$exons[$i]->{length} = $exon_starts[$i] - $exon_stops[$i];
            $total_length += $$exons[$i]->{length};
        }
        print "Filter::SNP::geneLocation    Total length: $total_length\n" if $DEBUG;

        #### 1. GO THROUGH THE EXONS UNTIL:
        ####     EXON CHROMOSOME START <= INPUT CHROMOSOME POSITION <= EXON CHROMOSOME STOP
        my $cumulative_length = 0;
        my $exon_start = $$exons[0]->{start};
        my $exon_stop = $$exons[0]->{stop};
        my $exon_counter = 0;
        print "Filter::SNP::geneLocation    '-' STRAND STARTING SCROLL THROUGH EXONS\n" if $DEBUG;
        while ( not ( $$exons[$exon_counter]->{stop} <= $chromosome_position
                     and $chromosome_position <= $$exons[$exon_counter]->{start} ) 
            and $exon_counter < @$exons )
        {
            print "Filter::SNP::geneLocation    '-' STRAND exon $exon_counter searching $chromosome_position in $$exons[$exon_counter]->{stop}..$$exons[$exon_counter]->{start}\n" if $DEBUG;

            #### IF THE POSITION IS DOWNSTREAM OF THE CURRENT EXON START,
            #### ITS EITHER IN THE 5-UTR OR IN AN INTRON
            if ( $chromosome_position > $$exons[$exon_counter]->{start} )
            {
                #print "Filter::SNP::geneLocation    Falls between exons: INTRON OR 5'-UTR\n";
                #### THE POSITION IN THE 5'-UTR
                if ( $exon_counter == 0 )
                {
                    my $upstream_distance = $chromosome_position - $$exons[$exon_counter]->{start};
                    my $gene_location = {
                        type        =>  '5-UTR',
                        position    =>  $upstream_distance,
                        number      =>  ''
                    };
                    #print "gene_position:\n";
                    #print Dumper $gene_location;
                    return $gene_location;
                }
                
                #### THE POSITION IS INTRONIC
                else
                {
                    my $intron_distance = $$exons[$exon_counter - 1]->{stop} - $chromosome_position;
                    my $gene_location = {
                        type        =>  'intron',
                        position    =>  $intron_distance,
                        number      =>  $exon_counter
                    };
                    #print "gene_position:\n";
                    #print Dumper $gene_location;
                    return $gene_location;
                }
            }
            #print "Filter::SNP::geneLocation    Checking exon start/stop $$exons[$exon_counter]->{stop}..$$exons[$exon_counter]->{start}\n" if $DEBUG;

            #### ADD EXON LENGTH TO CUMULATIVE LENGTH
            $cumulative_length += $$exons[$exon_counter]->{length};
            print "Filter::SNP::geneLocation    Cumulative length: $cumulative_length\n" if $DEBUG;    

            #### SET NEW EXON CHROMOSOME START
            $exon_start = $$exons[$exon_counter]->{start};
            
            #### INCREMENT EXON COUNTER
            $exon_counter++;
        }        

        print "Filter::SNP::geneLocation    AFTER LAST search for $chromosome_position in exon $exon_counter: $$exons[$exon_counter]->{stop}..$$exons[$exon_counter]->{start}\n" if $DEBUG;

        print "Filter::SNP::geneLocation    AFTER exon_counter: $exon_counter\n" if $DEBUG;

        #### IF THE POSITION IS UPSTREAM OF THE LAST EXON STOP (i.e., exon->{stop}),
        #### ITS IN THE 3-UTR
        if ( $chromosome_position < $$exons[((scalar(@$exons) - 1))]->{stop} )
        {
            my $downstream_distance = $$exons[$exon_counter]->{stop} - $chromosome_position;
            print "downstream_distance: $downstream_distance\n";
            my $gene_location = {
                type        =>  '3-UTR',
                position    =>  $downstream_distance,
                number      =>  ''
            };
            
            #print "gene_position:\n";
            #print Dumper $gene_location;
            return $gene_location;
        }

        my $offset = $$exons[$exon_counter]->{start} - $chromosome_position;        
        my $position = $cumulative_length + $offset;
        my $gene_location = {
            type        =>  'exon',
            position    =>  $position,
            number      =>  $exon_counter + 1
        };

        #print "gene_location:\n";
        #print Dumper $gene_location;
        return $gene_location;
    }
}



=head2

    SUBROUTINE      _chromosomeStartstop
    
    PURPOSE
    
        CALCULATE THE CHROMOSOME POSITION OF A SNP WITHIN A GENE
        
        GIVEN THE SNP'S GENE-SPECIFIC START/STOP AND THE GENE'S
        
        EXON START/STOPS
        
=cut

sub _chromosomeStartstop
{
    my $self    =   shift;
    my $ccds    =   shift;  #### ENTRY IN ccdsGene TABLE
    my $snp_ccds_start    =   shift;

my $DEBUG = 1;

    print "Filter::SNP::_chromosomeStartstop(ccds, snp_ccds_start)\n" if $DEBUG;
    print "ccds:\n" if $DEBUG;
    print Dumper $ccds if $DEBUG;
    print "Snp ccds start: $snp_ccds_start\n" if $DEBUG;
    print "ccds->{exonStarts}: $ccds->{exonStarts};\n" if $DEBUG;

    #### VERIFY SNP CCDS POSITION
    my @exon_starts = split /,/, $ccds->{txStart};
    my @exon_stops = split /,/, $ccds->{txEnd};
    print "exon starts: @exon_starts\n" if $DEBUG;
    print "exon stops: @exon_stops\n" if $DEBUG;

    #### CHECK IF EQUAL NUMBERS OF STARTS AND STOPS
    if ( $#exon_starts != $#exon_stops )
    {
        die "Unequal number of exon_starts (", $#exon_starts + 1, ") and exon_stops (" , $#exon_stops + 1, ")\n";
    }
    
    #### GET LENGTHS OF EXONS
    my $lengths;
    for ( my $i = 0; $i < $#exon_starts + 1; $i++ )
    {
        #### MAKE SURE THE STOP COMES AFTER THE START
        if ( ($exon_stops[$i] - $exon_starts[$i]) < 0 )
        {
            die "exon_stop ($exon_stops[$i]) is before exon_start ($exon_starts[$i])\n"
        }
        
        push @$lengths, $exon_stops[$i] - $exon_starts[$i];
    }
    print "Lengths: @$lengths\n" if $DEBUG;
    my $total_length = $self->sum($lengths);
    print "Total length: $total_length\n" if $DEBUG;

    #### GET CHROMOSOME POSITION OF SNP
    my $strand = $ccds->{strand};

    #### DO POSITIVE STRAND
    if ( $strand =~ /^\+$/ )
    {
        #### 1. GO THROUGH THE EXONS UNTIL THE EXON'S CHROMOSOME START IS GREATER THAN
        ####    THE SNP'S POSITION ON THE CHROMOSOME

        my $cumulative_length = 0;
        my $exon_chromosome_start = $exon_starts[0];
        my $exon_counter = 0;
        while ( $cumulative_length <= $snp_ccds_start
               and $exon_counter < $#exon_starts + 1 )
        {
            #print "Checking if SNP falls within exon start/stop $exon_starts[$exon_counter]..$exon_stops[$exon_counter]\n";
    
            #### ADD EXON LENGTH TO CUMULATIVE LENGTH
            $cumulative_length += $$lengths[$exon_counter];
            #print "Cumulative length: $cumulative_length\n" if $DEBUG;    
            #### SET NEW EXON CHROMOSOME START
            $exon_chromosome_start = $exon_starts[$exon_counter];
            
            #### INCREMENT EXON COUNTER
            $exon_counter++;
        }        
        print "SNP lies in exon ", $exon_counter, "\n" if $DEBUG;
        
        #### DECREMENT 1 FOR PREVIOUS EXON (ZERO INDEXED)
        $exon_counter--;
   
        #### 2. SUBTRACT THE PREVIOUS EXON'S CHROMOSOME POSITION FROM THE SNP'S CHROMOSOME
        ####    POSITION 
        ####    (BACKTRACK ONE TO GET THE PREVIOUS EXON)
        #print "EXON COUNTER: $exon_counter\n" if $DEBUG;
        my $previous_exon_start = $exon_starts[$exon_counter];
        print "exon starts[$exon_counter]: $previous_exon_start\n" if $DEBUG;
        
        #### CALCULATE DIFFERENCE TO ADD TO START OF EXON
        #### TO GET CHROMOSOME POSITION OF SNP
        my $difference = $snp_ccds_start - ($cumulative_length - $$lengths[$exon_counter]);
        #print "Difference = \$snp_ccds_start - ($cumulative_length - \$\$lengths[$exon_counter - 1]) = $snp_ccds_start - ($cumulative_length - $$lengths[$exon_counter - 1]) = $difference\n";

        my $snp_chromosome_start = $exon_starts[$exon_counter] + $difference;
        print "SNP chromosome start: $snp_chromosome_start\n" if $DEBUG;
        
        return $snp_chromosome_start;
    }

    #### DO NEGATIVE STRAND
    elsif ( $strand =~ /^\-$/ )
    {
        #### SWAP THE EXON START AND STOP ARRAYS AND REVERSE THEM
        my @temp = @exon_starts;
        @exon_starts = reverse @exon_stops;
        @exon_stops = reverse @temp;
        @$lengths = reverse @$lengths;

        #### 
        print "After strand (-) reversal and swap of exon start and stop arrays\n" if $DEBUG;
        print "exon starts: @exon_starts\n" if $DEBUG;
        print "exon stops: @exon_stops\n" if $DEBUG;
        print "Lengths: @$lengths\n" if $DEBUG;

        my $cumulative_length = 0;
        my $exon_counter = 0;
        while ( $cumulative_length <= $snp_ccds_start
               and $exon_counter < $#exon_starts + 1 )
        {
            #print "Checking if SNP falls within exon start/stop $exon_starts[$exon_counter]..$exon_stops[$exon_counter]\n";
    
            #### ADD EXON LENGTH TO CUMULATIVE LENGTH
            $cumulative_length += $$lengths[$exon_counter];
            #print "Cumulative length: $cumulative_length\n" if $DEBUG;  
            
            #### INCREMENT EXON COUNTER
            $exon_counter++;
        }

        ####    NB: DECREMENT exon_counter BY 1 FOR PREVIOUS EXON (ZERO INDEXED)
        $exon_counter--;
 
        $cumulative_length = $cumulative_length - $$lengths[$exon_counter];
        print "SNP lies in exon ", $exon_counter, "\n" if $DEBUG;
        
        
        #### 2. ADD THE CUMULATIVE LENGTH OF THE PRECEDING EXONS PLUS THE
        ####    DIFFERENCE BETWEEN THE EXON STOP AND THE SNP CHROMOSOME POSITION
        my $difference = $snp_ccds_start - $cumulative_length;
        print "Difference = \$snp_ccds_start - \$cumulative_length = $snp_ccds_start - $cumulative_length = $difference\n" if $DEBUG;

        my $snp_chromosome_start = $exon_stops[$exon_counter - 1] - $difference;
        print "SNP chromosome start = \$exon_stops[\$exon_counter - 1]  \$difference = $exon_stops[$exon_counter - 1] - $difference = $snp_chromosome_start\n" if $DEBUG;
        
        return $snp_chromosome_start;
    }
}




=head2

    SUBROUTINE      effect
    
    PURPOSE
    
        RETURN EFFECT OF A SNP
        
=cut

sub effect
{
    my $self            =   shift;
    my $reference_aa    =   shift;
    my $variant_aa      =   shift;

#my $DEBUG = 1;
    print "Filter::SNP::effect    Filter::SNP::effect(reference_aa, variant_aa)\n" if $DEBUG;
    print "Filter::SNP::effect    reference_aa: $reference_aa\n" if $DEBUG;
    print "Filter::SNP::effect    variant_aa: $variant_aa\n" if $DEBUG;
    
    my $effect = "synonymous";
    $effect = "missense" if $reference_aa ne $variant_aa;
    $effect = "stop" if $variant_aa eq "X";
    $effect = "start" if $variant_aa eq "M" and $reference_aa ne "M";

    return $effect;    
}

=head2

    SUBROUTINE      geneSequence
    
    PURPOSE
    
        RETURN THE SEQUENCE OF A CCDS BY ID

=cut

sub geneSequence
{
    my $self        =   shift;
    my $id          =   shift;
    
    my $db = $self->get_db();
    
    #### GET SEQUENCE
    my $query = qq{SELECT sequence from ccdsSeq WHERE id='$id'};
    #print "Filter::SNP::geneSequence    query: $query\n";
    my $sequence = $db->query($query);
    #print "Filter::SNP::geneSequence    sequence: $sequence\n";
    
    return $sequence;
}


=head2

    SUBROUTINE      referenceCodon
    
    PURPOSE
    
    1. GET FRAME OF SNP AND HENCE WHETHER SYNONYMOUS OR NON-SYNONYMOUS
    
    2. RETURN

=cut

sub referenceCodon
{
    my $self            =   shift;    
    my $strand          =   shift;
    my $gene_location   =   shift;
    my $sequence        =   shift;
    my $variant_base    =   shift;

#my $DEBUG = 1;

    #### GET CODON
    my $reference_codon;
    if ( $strand eq "-" )
    {
        print "Filter::SNP::referenceCodon    - STRAND\n" if $DEBUG;
        print "Filter::SNP::referenceCodon    gene_position: $gene_location\n" if $DEBUG;

        my $frame = (($gene_location - 1) % 3) + 1;
        my $codon_start = $gene_location - $frame;

        print "Filter::SNP::referenceCodon    frame: $frame\n" if $DEBUG;
        print "Filter::SNP::referenceCodon    codon_start: $codon_start\n" if $DEBUG;
        #print "Filter::SNP::referenceCodon    sequence: $sequence\n" if $DEBUG;
        $reference_codon = substr($sequence, $codon_start, 3);
        print "Filter::SNP::referenceCodon    reference_codon: $reference_codon\n" if $DEBUG;
    }
    else
    {
        print "Filter::SNP::referenceCodon    + STRAND\n" if $DEBUG;
        print "Filter::SNP::referenceCodon    gene_position: $gene_location\n" if $DEBUG;

        my $frame = ($gene_location % 3) + 1;
        my $codon_start = $gene_location - $frame + 1;

        print "Filter::SNP::referenceCodon    frame: $frame\n" if $DEBUG;
        print "Filter::SNP::referenceCodon    codon_start: $codon_start\n" if $DEBUG;
        
        $reference_codon = substr($sequence, $codon_start, 3);
        print "Filter::SNP::referenceCodon    + STRAND reference_codon: $reference_codon\n" if $DEBUG;
    }

    return $reference_codon;    
}





=head2

    SUBROUTINE      variantCodon
    
    PURPOSE
    
        RETURN THE VARIANT CODON GIVEN A REFERENCE CODON
        
        AND ADDITIONAL INFORMATION INCLUDING THE VARIANT BASE
    
=cut

sub variantCodon
{
    my $self            =   shift;    
    my $strand          =   shift;
    my $gene_location   =   shift;
    my $reference_codon =   shift;
    my $variant_base    =   shift;

#my $DEBUG = 1;
    
    #### GET CODON
    my $variant_codon;
    if ( $strand eq "-" )
    {
        #### GET FRAME
        my $frame = ($gene_location %3);
        print "Filter::SNP::variantCodon    frame: $frame\n" if $DEBUG;

        #### GET VARIANT ACTUAL CODON        
        $variant_codon = $reference_codon;
        #my $inverted_frame = 4 - $frame;
        substr($variant_codon, $frame - 1, 1, $variant_base);

        print "Filter::SNP::variantCodon    - STRAND variant_codon: $variant_codon\n" if $DEBUG;
    }
    else
    {
        #### GET FRAME
        my $frame = ($gene_location %3) + 1;
        print "Filter::SNP::variantCodon    frame: $frame\n" if $DEBUG;

        #### GET VARIANT ACTUAL CODON        
        $variant_codon = $reference_codon;
        substr($variant_codon, $frame - 1, 1, $variant_base);
        print "Filter::SNP::variantCodon    + STRAND variant_codon: $variant_codon\n" if $DEBUG;
    }

    return $variant_codon;    
}




=head2

    SUBROUTINE      synonymous
    
    PURPOSE
    
    1. GET FRAME OF SNP AND HENCE WHETHER SYNONYMOUS OR NON-SYNONYMOUS
    
    2. RETURN

=cut

sub synonymous
{
    my $self            =   shift;    

    my $db = $self->{_db};
    return if not defined $db;
    
    my $linehash        =   $self->get_linehash();
    return if not defined $linehash;

    print "Filter::SNP::synonymous()\n" if $DEBUG;
    print "linehash:\n" if $DEBUG;
    print Dumper $linehash if $DEBUG;

    my $chromosome              =   $linehash->{chromosome};
    my $snp_chromosome_start    =   $linehash->{chromosomestart};
    my $variant_nucleotide      =   $linehash->{variantnucleotide};
    my $snp_ccds_start          =   $linehash->{ccdsstart};
    my $name                    =   $linehash->{name};

    #### RETURN IF NO SNP CHROMOSOME START
    return if not defined $snp_chromosome_start;

    #### ADD 1 TO CCDS START
    #$snp_ccds_start++;

    print "Chromosome: $chromosome\n" if $DEBUG;
    #print "SNP chromosome start: $snp_chromosome_start\n";
    print "SNP ccds start: $snp_ccds_start\n" if $DEBUG;
    
    #### CONFIRM IDENTITY OF SPANNING CCDS
    #### GET ALL CCDS THAT SPAN THIS SNP
    my $query = qq{SELECT * FROM ccdsGene
    WHERE txStart <= $snp_chromosome_start
    AND txEnd >= $snp_chromosome_start
    AND chrom = '$chromosome'
    AND name = '$name'};
    #print "$query\n" if $DEBUG;
    
    #### GET RESULT
    my $ccds = $db->queryhash($query);
    
    #### RETURN IF NOT DEFINED
    return if not defined $ccds;
    
    print "CCDS: \n" if $DEBUG;
    print Dumper $ccds if $DEBUG;

    #### GET CCDS SEQUENCE
    $query = qq{SELECT sequence FROM ccdsSeq WHERE id='$name'};
    my $sequence = $db->query($query);
    print "Name: $name\n" if $DEBUG;
    print "Length sequence: ", length($sequence), "\n" if $DEBUG;

    #### GET CCDS STRAND
    $query = qq{SELECT strand FROM ccdsGene WHERE name='$name'};
    my $strand = $db->query($query);
    print "Strand: $strand\n" if $DEBUG;
    if ( $strand !~ /^(\-|\+)$/ )
    {
        die "Strand not +/-: $strand for CCDS $name\n";
    }    

    #### GET REFERENCE BASE
    print "Length(sequence): ", length($sequence), "\n" if $DEBUG;
    print "Doing substr(\$sequence, $snp_ccds_start, 1)\n" if $DEBUG;
    my $reference_nucleotide = substr($sequence, $snp_ccds_start, 1);
    print "Reference nucleotide: $reference_nucleotide\n" if $DEBUG;
    print "Variant nucleotide: $variant_nucleotide\n" if $DEBUG;

    #### SET SNP FRAME    
    my $snp_frame = $snp_ccds_start % 3;
    if ( $snp_frame == 0 )  {   $snp_frame = 3; }
    print "SNP codon frame (0,1,2): $snp_frame\n" if $DEBUG;
    
    #### SET CODON CCDS START
    my $codon_ccds_start = $snp_ccds_start - $snp_frame;
    print "Codon ccds start: $codon_ccds_start\n" if $DEBUG;

    #### GET REFERENCE AND VARIANT CODONS
    my $variant_codon = my $reference_codon = substr($sequence, $codon_ccds_start, 3);
    substr($variant_codon, $snp_frame - 1, 1, $variant_nucleotide);
    print "Reference codon: $reference_codon\n"  if $DEBUG;
    print "Variant codon: $variant_codon\n"  if $DEBUG;
    
    my $reference_aa = $self->codonToAa($reference_codon, "long");
    print "Reference AA: $reference_aa\n"  if $DEBUG;

    my $variant_aa = $self->codonToAa($variant_codon, "long");
    if ( not defined $variant_aa )
    {
        print "NO VARIANT AA FOR variant codon: $variant_codon\n";
        return;
    }
    
    print "Variant AA: $variant_aa\n"  if $DEBUG;
    
    my $sense = "synonymous";
    if ( $reference_aa ne $variant_aa )
    {
        $sense = "missense";
    }
    $linehash->{sense} = $sense;
    $linehash->{referencecodon} = $reference_codon;
    $linehash->{variantcodon} = $variant_codon;
    $linehash->{referenceaa} = $reference_aa;
    $linehash->{variantaa} = $variant_aa;
    $linehash->{strand} = $strand;

    return $linehash;
}


=head2

    SUBROUTINE      variationType
    
    PURPOSE
    
        RETURN 1 IF THE FEATURE IS A SNP-TYPE FEATURE
    
=cut

sub variationType
{
    my $self        =   shift;
    my $linehash    =   shift;

#my $DEBUG = 1;

    print "Filter::SNP::variationType()\n" if $DEBUG;
    print "Filter::SNP::variationType    linehash:\n" if $DEBUG;
    print Dumper $linehash if $DEBUG;

    #### SNP
    #print "Filter::SNP::variationType    length:", abs($linehash->{ccdsstart} - $linehash->{ccdsstop}), "\n";
    return 'snp ' if abs($linehash->{ccdsstart} - $linehash->{ccdsstop}) < 2;

    #### INSERT OR DELETION NUCLEOTIDE IS '-'
    return 'insert' if ($linehash->{referencenucleotide}) =~ /^\-$/;
    return 'deletion' if ($linehash->{variantnucleotide}) =~ /^\-$/;

    #### INVERSION
    my ($complement) = $linehash->{referencenucleotide} =~ s/AGTC/TCAG/i;
    my @array = split "", $complement;
    @array = reverse(@array);
    $complement = join "", @array;
    return 'inversion' if $complement eq $linehash->{variantnucleotide};
    
    #### OTHER VARIATION
    return 'substitution';
}



=head2

    SUBROUTINE      linehash

    PURPOSE

        CONVERT THE ENTRIES IN A UCSC CCDS TABLE FORMAT LINE INTO A HASH
        
=cut

sub linehash
{
    my $self        =   shift;
    my $line        =   shift;
    
    return if $line =~ /^#/ or $line =~ /^\s*$/;
    
    my $hash;
    my @elements = split " ", $line;
    ($hash->{name}, $hash->{chromosome}) = $elements[0] =~ /^>([^\|]+).+?([^\|]+)$/;
    $hash->{ccdsstart} = $elements[1];
    $hash->{ccdsstop} = $elements[2];
    $hash->{referencenucleotide} = $elements[3];
    $hash->{variantnucleotide} = $elements[4];
    $hash->{depth} = $elements[5];
    ($hash->{variantfrequency}) = $elements[6] =~ /^(\S+)/;

    #### RESET LINEHASH
    $self->{_linehash} = undef;
    $self->{_linehash} = $hash;
    
    return $hash;
}


=head2

    SUBROUTINE      sum
    
    PURPOSE
    
        RETURN THE SUM OF VALUES IN AN ARRAY
    
=cut

sub sum
{
    my $self            =   shift;
    my $array           =   shift;
    
    my $sum = 0;
    foreach my $value ( @$array )   {    $sum += $value if defined $value;    }

    return $sum;
}


=head2

	SUBROUTINE		codonToAa
	
	PURPOSE

		TRANSLATE FROM A CODON TRIPLET TO AN AMINO ACID

    INPUT
    
        1. THREE-NUCLEOTIDE CODON
        
        2. OUTPUT TYPE (threeletter, oneletter, long)
		    
    OUTPUT
    
        1. AMINO ACID NAME, 3-LETTER OR 1-LETTER SYMBOL
		
=cut

sub codonToAa
{
    my $self		=	shift;
	my $codon   	=	shift;
    my $type        =   shift;
    
    return if not defined $codon;
    return '' if not $codon;
    return if not $type =~ /^(threeletter|oneletter|long)$/;

    if ( not defined $self->{_codons} )
    {
        my $hash;
        while ( <DATA> )
        {
            $_ =~ /^(\S+)\s+(\S+)\s+(\S+)\s+(\w+)/;
            $hash->{$1}->{threeletter} = $2;
            $hash->{$1}->{oneletter} = $3;
            $hash->{$1}->{long} = $4;
        }
        $self->{_codons} = $hash;
    }
    my $codons = $self->{_codons};
    
    return $codons->{uc($codon)}->{$type};
}

=head2

    SUBROUTINE      setOutfh
    
    PURPOSE
    
        RETURN THE SUM OF VALUES IN AN ARRAY
    
=cut

sub setOutfh
{
    my $self        =   shift;
    my $outputfile  =   shift;
    
    my $outfh;
    open($outfh, ">$outputfile") or die "Filter::SNP::setOutfh    can't open outputfile: $outputfile\n";

    $self->set_outfh($outfh);
    return $outfh;
}



####################################################################
####################################################################
########				HOUSEKEEPING METHODS
####################################################################
####################################################################

=head2

	SUBROUTINE		new
	
	PURPOSE

		CREATE A NEW self OBJECT

=cut

sub new
{
    my $class 		=	shift;
	my $arguments 	=	shift;
   
	my $self = {};
    bless $self, $class;
	
	#### INITIALISE THE OBJECT'S ELEMENTS
	$self->initialise($arguments);
	
    return $self;
}


=head2

	SUBROUTINE		initialise
	
	PURPOSE

		INITIALISE THE self OBJECT

=cut

sub initialise
{
    my $self		=	shift;
	my $arguments	=	shift;

    #### VALIDATE USER-PROVIDED ARGUMENTS
	($arguments) = $self->validate_arguments($arguments);	
	
    #### PROCESS USER-PROVIDED ARGUMENTS
	foreach my $key ( keys %$arguments )
	{
		$self->value($key, $arguments->{$key});
	}    
}

=head2

	SUBROUTINE		value
	
	PURPOSE

		SET A PARAMETER OF THE self OBJECT TO A GIVEN value

    INPUT
    
        1. parameter TO BE SET
		
		2. value TO BE SET TO
    
    OUTPUT
    
        1. THE SET parameter INSIDE THE self OBJECT
		
=cut

sub value
{
    my $self		=	shift;
	my $parameter	=	shift;
	my $value		=	shift;

	$parameter = lc($parameter);
	#print "Parameter: $parameter\n";
	#print "value: ";print Dumper $value;

    if ( not defined $value)	{	return;	}
	$self->{"_$parameter"} = $value;
}

=head2

	SUBROUTINE		validate_arguments

	PURPOSE
	
		VALIDATE USER-INPUT ARGUMENTS BASED ON
		
		THE HARD-CODED LIST OF VALID ARGUMENTS
		
		IN THE data ARRAY
=cut

sub validate_arguments
{
	my $self		=	shift;
	my $arguments	=	shift;
	
	my $hash;
	foreach my $argument ( keys %$arguments )
	{
		if ( $self->is_valid($argument) )
		{
			$hash->{$argument} = $arguments->{$argument};
		}
		else
		{
			warn "'$argument' is not a known parameter\n";
		}
	}

	return $hash;
}


=head2

	SUBROUTINE		is_valid

	PURPOSE
	
		VERIFY THAT AN ARGUMENT IS AMONGST THE LIST OF
		
		ELEMENTS IN THE GLOBAL '$DATAHASH' HASH REF
		
=cut

sub is_valid
{
	my $self		=	shift;
	my $argument	=	shift;
	
	#### REMOVE LEADING UNDERLINE, IF PRESENT
	$argument =~ s/^_//;
	
	#### CHECK IF ARGUMENT FOUND IN '$DATAHASH'
	if ( exists $DATAHASH->{lc($argument)} )
	{
		return 1;
	}
	
	return 0;
}


=head2

	SUBROUTINE		AUTOLOAD

	PURPOSE
	
		AUTOMATICALLY DO 'set_' OR 'get_' FUNCTIONS IF THE
		
		SUBROUTINES ARE NOT DEFINED.

=cut

sub AUTOLOAD {
    my ($self, $newvalue) = @_;

	#print "App::AUTOLOAD(self, $newvalue)\n";
	#print "New value: $newvalue\n";

    my ($operation, $attribute) = ($AUTOLOAD =~ /(get|set)(_\w+)$/);
	#print "Operation: $operation\n";
	#print "Attribute: $attribute\n";

    # Is this a legal method name?
    unless($operation && $attribute) {
        croak "Method name $AUTOLOAD is not in the recognized form (get|set)_attribute\n";
    }
#    unless( exists $self->{$attribute} or $self->is_valid($attribute) )
#	{
#        #croak "No such attribute '$attribute' exists in the class ", ref($self);
#		return;
#    }

    # Turn off strict references to enable "magic" AUTOLOAD speedup
    no strict 'refs';

    # AUTOLOAD accessors
    if($operation eq 'get') {
        # define subroutine
        *{$AUTOLOAD} = sub { shift->{$attribute} };

    # AUTOLOAD mutators
    }elsif($operation eq 'set') {
        # define subroutine4
		
        *{$AUTOLOAD} = sub { shift->{$attribute} = shift; };

        # set the new attribute value
        $self->{$attribute} = $newvalue;
    }

    # Turn strict references back on
    use strict 'refs';

    # return the attribute value
    return $self->{$attribute};
}



# When an object is no longer being used, this will be automatically called
# and will adjust the count of existing objects
sub DESTROY {
    my($self) = @_;
}



1;



#=head2
#
#    SUBROUTINE      dbsnp
#
#    PURPOSE
#
#        1. FIND OUT IF THE SNP IS ALREADY ENTERED IN dbSNP
#        
#        2. IF SO, RETRIEVE RELATED INFO ABOUT THE dbSNP ENTRY
#        
#=cut
#
#sub dbsnp
#{
#    my $DEBUG = 1;
#
#    my $self        =   shift;
#    
#    print "Filter::SNP::dbsnp()\n" if $DEBUG;
#
#    my $db = $self->{_db};
#    return if not defined $db;
#
#    my $linehash = $self->get_linehash();
#    print "Filter::SNP::dbsnp    linehash:\n";
#    print Dumper $linehash;
#
#    #### GET CHROMOSOME START
#    my $chromosome_start = $self->chromosomeStartstop();
#    return if ( not defined $linehash->{chromosomestart} );
#    
#    #### GET CHROMOSOME AND CHANGE chrXY TO chrY
#    my $chromosome = $linehash->{chromosome};
#
#    #### chrXY Used by illumina for diploid snps on XY
#    #### http://www.obiba.org/genobyte/apidocs/org/obiba/genobyte/model/Chromosome.html
#    #### SET chrXY TO chrY TO MATCH NOMENCLATURE IN ccdsGene AND ccdsSNP TABLES
#    #### (I.E., THESE TABLES USE THE NAMES chrX AND chrY)
#    $chromosome = "chrY" if $chromosome =~ /^chrXY$/;
#    
#    #### TEST: SET MARGIN WITHIN WHICH TO FIND dbSNP AROUND OUR PREDICTED SNP
#    #### MARGIN  = 0: dbSNP MUST FALL ON SAME BASE AS PREDICTED SNP
#    my $margin = 5;
#    my $upper = $chromosome_start + $margin;
#    my $lower = $chromosome_start - $margin;
#
#    #### CHECK IF SNP IS WITHIN A GENE
#    my $query = qq{SELECT * FROM ccdsSNP
#    WHERE chromosomeStart <= $upper
#    AND chromosomeStart >= $lower
#    AND chromosome = '$chromosome'};
#    print "SNP QUERY: $query\n" if $DEBUG;
#
#    my $snps = $db->queryhash($query);
#    #print "Fields:\n";
#    if ( defined $snps)
#    {
#        print "dbSNPs FOUND:\n" if $DEBUG;
#        print Dumper $snps if $DEBUG;
#    }
#    else
#    {
#        print "NOT FOUND IN dbSNP\n" if $DEBUG;
#    }
#
##$DEBUG = 0;
#    return $snps;    
#}

    ##### SET FIELD INDEXES
    #my @fieldindexes = values ( %$fieldmap );
    #@fieldindexes  = sort { $a <=> $b } @fieldindexes;
    #my %reversemap = reverse ( %$fieldmap );
    #foreach my $fieldindex ( @fieldindexes )
    #{
    #    print "$fieldindex\t$reversemap{$fieldindex}\n";
    #}
    #$self->set_fieldindexes(\@fieldindexes);
    #
    #print "Filter::SNP::setFields    self:\n";
    #print Dumper $self;
    #exit;

__DATA__
TTT Phe  F Phenylalanine
TTC Phe F Phenylalanine
TTA Leu L Leucine
TTG Leu L Leucine
TCT Ser S Serine
TCC Ser S Serine
TCA Ser S Serine
TCG Ser S Serine
TAT Tyr Y Tyrosine
TAC Tyr Y Tyrosine
TAA Ochre X Stop
TAG Amber X Stop
TGT Cys C Cysteine
TGC Cys C Cysteine
TGA Opal X Stop
TGG Trp W Tryptophan
CTT Leu L Leucine
CTC Leu L Leucine
CTA Leu L Leucine
CTG Leu L Leucine
CCT Pro P Proline
CCC Pro P Proline
CCA Pro P Proline
CCG Pro P Proline
CAT His H Histidine
CAC His H Histidine
CAA Gln Q Glutamine
CAG Gln Q Glutamine
CGT Arg R Arginine
CGC Arg R Arginine
CGA Arg R Arginine
CGG Arg R Arginine
ATT Ile I Isoleucine
ATC Ile I Isoleucine
ATA Ile I Isoleucine
ATG Met M Methionine, Start
ACT Thr T Threonine
ACC Thr T Threonine
ACA Thr T Threonine
ACG Thr T Threonine
AAT Asn N Asparagine
AAC Asn N Asparagine
AAA Lys K Lysine
AAG Lys K Lysine
AGT Ser S Serine
AGC Ser S Serine
AGA Arg R Arginine
AGG Arg R Arginine
GTT Val V Valine
GTC Val V Valine
GTA Val V Valine
GTG Val V Valine
GCT Ala A Alanine
GCC Ala A Alanine
GCA Ala A Alanine
GCG Ala A Alanine
GAT Asp D Aspartic acid
GAC Asp D Aspartic acid
GAA Glu E Glutamic acid
GAG Glu E Glutamic acid
GGT Gly G Glycine
GGC Gly G Glycine
GGA Gly G Glycine
GGG Gly G Glycine


