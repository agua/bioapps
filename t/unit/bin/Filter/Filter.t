#!/usr/bin/perl -w

use Test::More;
plan skip_all => 'Onworking tests';

=head2

    TEST        Filter.t
    
    PURPOSE
    

=cut

use strict;

#### DEBUG
my $DEBUG = 0;
$DEBUG = 1;

#### USE LIBS
use FindBin qw($Bin);
use lib "$Bin/../../lib";
use lib "$Bin/../../../lib";
use lib "$Bin/../../../../lib";

#### EXTERNAL MODULES
use Data::Dumper;

#### INTERNAL MODULES
use Test::Filter::SNP;


my $SHOWLOG     = 3;
my $PRINTLOG    = 3;

my $logfile = "/tmp/apps.t.filter.log";

my $object = Test::Filter::SNP->new(
    logfile     =>  $logfile,
    SHOWLOG     =>  2,
    PRINTLOG    =>  2
);


#### ALL POSITIVES (CODING dbSNPs IN dbSNP)
testScrollMatch(
    {
        queryfile   =>  "$Bin/inputs/snp130CodingDbSnp-chrY-dbsnp.txt",
        targetfile  =>  "$Bin/inputs/snp130-chrY.txt",
        outputfile  =>  "$Bin/inputs/snp130CodingDbSnp-chrY-dbsnp-scrollMatch-allpositives.txt",
        expectfile  =>  "$Bin/outputs/snp130CodingDbSnp-chrY-dbsnp-scrollMatch-allpositives.txt",
        querytype   =>  "dbsnp",
        targettype   => "dbsnp"
    }
);

exit;

##### ALL POSITIVES (CODING dbSNPs IN dbSNP)- INDEXES
#testScrollMatch(
#    {
#        queryfile   =>  "$Bin/inputs/snp130CodingDbSnp-chrY-dbsnp.txt",
#        targetfile  =>  "$Bin/inputs/snp130-chrY.txt",
#        outputfile  =>  "$Bin/inputs/snp130CodingDbSnp-chrY-dbsnp-scrollMatch-allpositives.txt",
#        expectfile  =>  "$Bin/outputs/snp130CodingDbSnp-chrY-dbsnp-scrollMatch-allpositives.txt",
#        querytype   =>  "dbsnp",
#        targettype   => "dbsnp",
#        queryindexes    => [1, 2, 3],
#        targetindexes   => [1, 2, 3]
#    }
#);


#### MOSTLY POSITIVES snp130CodingDbsnp IN CCDS
#testScrollMatch(
#    {
#        queryfile   =>  "$Bin/inputs/snp130CodingDbSnp-chrY-dbsnp.txt",
#        targetfile  =>  "$Bin/inputs/CCDS-chrY-gtf.txt",
#        outputfile  =>  "$Bin/inputs/scrollMatch-codingDbSnpInCcds.txt",
#        expectfile  =>  "$Bin/outputs/scrollMatch-codingDbSnpInCcds.txt",
#        querytype   =>  "dbsnp",
#        targettype   => "gtf"
#    }
#);


#### MOSTLY POSITIVES snp130CodingDbsnp IN CCDS - COMPLEMENT
#testScrollMatch(
#    {
#        queryfile   =>  "$Bin/inputs/snp130CodingDbSnp-chrY-dbsnp.txt",
#        targetfile  =>  "$Bin/inputs/CCDS-chrY-gtf.txt",
#        outputfile  =>  "$Bin/inputs/scrollMatch-codingDbSnpInCcds-complement.txt",
#        expectfile  =>  "$Bin/outputs/scrollMatch-codingDbSnpInCcds-complement.txt",
#        querytype   =>  "dbsnp",
#        targettype  =>  "gtf",
#        complement  =>  1
#    }
#);
#



#### MOSTLY POSITIVES snp130CodingDbsnp IN CCDS - **SHORT**
#testScrollMatch(
#    {
#        queryfile   =>  "$Bin/inputs/snp130CodingDbSnp-chrY-dbsnp-short.txt",
#        targetfile  =>  "$Bin/inputs/CCDS-chrY-gtf-short.txt",
#        outputfile  =>  "$Bin/inputs/scrollMatch-codingDbSnpInCcds-short.txt",
#        expectfile  =>  "$Bin/outputs/scrollMatch-codingDbSnpInCcds-short.txt",
#        querytype   =>  "dbsnp",
#        targettype  =>  "gtf"
#    }
#);



#### MOSTLY POSITIVES snp130CodingDbsnp IN CCDS - SHORT, FLANKS
#testScrollMatch(
#    {
#        queryfile   =>  "$Bin/inputs/snp130CodingDbSnp-chrY-dbsnp-short.txt",
#        targetfile  =>  "$Bin/inputs/CCDS-chrY-gtf-short.txt",
#        outputfile  =>  "$Bin/outputs/scrollMatch-codingDbSnpInCcds-short-flanks-output.txt",
#        expectfile  =>  "$Bin/outputs/scrollMatch-codingDbSnpInCcds-short-flanks.txt",
#        querytype   =>  "dbsnp",
#        targettype  =>  "gtf",
#        flanks      =>  10
#    }
#);




### MOSTLY POSITIVES snp130CodingDbsnp IN CCDS - COMPLEMENT **SHORT**
#testScrollMatch(
#    {
#        queryfile   =>  "$Bin/inputs/chrY/snp130CodingDbSnp-chrY-dbsnp-short.txt",
#        targetfile  =>  "$Bin/inputs/chrY/CCDS-chrY-gtf-short.txt",
#        outputfile  =>  "$Bin/outputs/scrollMatch-codingDbSnpInCcds-short-complement-output.txt",
#        expectfile  =>  "$Bin/outputs/scrollMatch-codingDbSnpInCcds-short-complement.txt",
#        querytype   =>  "dbsnp",
#        targettype  =>  "gtf"
#        ,
#        complement  =>  1
#    }
#);


##### CHECK LATER: File::Compare::compare RETURNS 1 ALTHOUGH OUTPUT AND EXPECT FILES ARE IDENTICAL
#
### MOSTLY POSITIVES snp130CodingDbsnp IN CCDS - FLANKS COMPLEMENT **SHORT**
#testScrollMatch(
#    {
#        queryfile   =>  "$Bin/inputs/chrY/snp130CodingDbSnp-chrY-dbsnp-short.txt",
#        targetfile  =>  "$Bin/inputs/chrY/CCDS-chrY-gtf-short.txt",
#        outputfile  =>  "$Bin/inputs/scrollMatch-codingDbSnpInCcds-short-complement.txt",
#        expectfile  =>  "$Bin/outputs/scrollMatch-codingDbSnpInCcds-short-complement.txt",
#        querytype   =>  "dbsnp",
#        targettype  =>  "gtf",
#        complement  =>  1
#    }
#);




#
##### ALL NEGATIVES, snp130CodingDbsnp NOT IN CCDS
#testScrollMatch(
#    {
#        queryfile   =>  "$Bin/inputs/scrollMatch-codingDbSnpNotInCcds.txt",
#        targetfile  =>  "$Bin/inputs/chrY/CCDS-chrY-gtf.txt",
#        outputfile  =>  "$Bin/inputs/scrollMatch-codingDbSnpNotInCcds-output.txt",
#        expectfile  =>  "$Bin/outputs/scrollMatch-codingDbSnpNotInCcds.txt",
#        querytype   =>  "dbsnp",
#        targettype  => "gtf"
#    }
#);
#



### MOSTLY POSITIVES snp130CodingDbsnp IN CCDS - COMPLEMENT **SHORT**
#testScrollMatch(
#    {
#        queryfile   =>  "$Bin/inputs/chrY/454HCDiffs-headers-chrY.txt",
#        targetfile  =>  "$Bin/inputs/chrY/CCDS-chrY-gtf-short.txt",
#        outputfile  =>  "$Bin/outputs/scrollMatch-codingDbSnpInCcds-short-complement-output.txt",
#        expectfile  =>  "$Bin/outputs/scrollMatch-codingDbSnpInCcds-short-complement.txt",
#        querytype   =>  "454",
#        targettype  =>  "gtf"
#    }
#);
#


##### MAQ ALIGNMENT AGAINST CCDS, CHR22 ONLY, INTERSECT WITH CCDS
#testScrollMatch(
#    {
#        queryfile   =>  "$Bin/inputs/chr22/454HCDiffs-header-chr22-sorted.txt",
#        targetfile  =>  "$Bin/inputs/chr22/CCDS-chr22-gtf.txt",
#        outputfile  =>  "$Bin/outputs/chr22/scrollMatch-maq-chr22-intersect-CCDS-chr22-output.txt",
#        expectfile  =>  "$Bin/outputs/chr22/scrollMatch-maq-chr22-intersect-CCDS-chr22.txt",
#        querytype   =>  "454",
#        targettype  =>  "gtf"
#    }
#);
#




#### TEST scrollMatch FUNCTION
sub testScrollMatch
{
    my $args    =   shift;
    
    my $queryfile       =   $args->{queryfile}; 
    my $targetfile      =   $args->{targetfile};
    my $outputfile      =   $args->{outputfile};
    my $expectfile      =   $args->{expectfile};
    my $querytype       =   $args->{querytype};
    my $targettype      =   $args->{targettype};
    my $queryindexes    =   $args->{queryindexes};
    my $targetindexes   =   $args->{targetindexes};
    my $complement      =   $args->{complement};
    my $flanks      =   $args->{flanks};


    #### TIMING    
    #my $time1 = [gettimeofday()];	

    print "03.Filter.t::testScrollMatch    outputfile: $outputfile\n";
    print "03.Filter.t::testScrollMatch    expectfile: $expectfile\n";
    print "03.Filter.t::testScrollMatch    targetfile not found: $targetfile\n" and return if not -f $targetfile;
    #print "03.Filter.t::testScrollMatch    queryfile: $queryfile\n";
    print "03.Filter.t::testScrollMatch    queryfile not found: $queryfile\n" and return if not -f $queryfile;

    #### DO SCROLL MATCH
    $object->scrollMatch(
        {
            queryfile       =>  $queryfile,
            targetfile      =>  $targetfile,
            queryindexes    =>  $queryindexes,
            targetindexes   =>  $targetindexes,
            complement      =>  $complement,
            flanks          =>  $flanks,
            outputfile      =>  $outputfile,
            querytype       =>  $querytype,
            targettype      =>  $targettype
        }
    );
    print "03.Filter.t::testScrollMatch    Finished scrollMatch\n";

    #### TIMING    
    #my $milliseconds = tv_interval($time1) * 1000;
    #printf "Elapsed time: $milliseconds milliseconds\n";
    
    #### File::Compare::compare:
    #### return 0 if the files are equal,
    #### 1 if the files are unequal, or
    #### -1 if an error was encountered.
    print "03.Filter.t::testScrollMatch    expectfile: $expectfile\n";
    print "03.Filter.t::testScrollMatch    outputfile: $outputfile\n";

    my $comparison = File::Compare::compare($expectfile, $outputfile);
    print "03.Filter.t::testScrollMatch    comparison: $comparison\n";
#exit;

}