#!/usr/bin/perl -w
use strict;

#### DEBUG
my $DEBUG = 0;
$DEBUG = 1;

#### TIME
my $time = time();

=head2

    APPLICATION     getResources
    
    PURPOSE
    
        1. DOWNLOAD WEB PAGE RESOURCES: *.js AND *.css FILES
        
        2. SAVE DOWNLOADED FILES TO IDENTICAL FILESYSTEM IN OUTPUT FOLDER
    
    INPUT
    
        1. REQUIRED: URL AND OUTPUT DIRECTORY (MUST ALREADY EXIST)
    
        2. OPTIONAL: FILTER TERM AND REGEX TO FILTER FILES BEFORE DOWNLOADING
    
    OUTPUT
    
        1. WEB PAGE RESOURCE FILES PRINTED TO OUTPUT DIRECTORY

    USAGE
    
    ./getResources.pl <--url String> <--outputdir String> [--help]
    
    --url               :   URL OF FTP SITE OR PAGE
	                    :   Must be '.../pagename.html' OR '...directoryname/'
    --outputdir         :   DIRECTORY TO DOWNLOAD FILES TO
    --help              :   PRINT HELP INFO

    EXAMPLES

./getResources.pl \
--url "http://dcc.icgc.org/" \
--outputdir /tmp/dcc \
--SHOWLOG 4

./getResources.pl \
--url "http://dcc.icgc.org/search" \
--outputdir /tmp/dcc/search \
--SHOWLOG 4


./getResources.pl \
--url "file:///home/syoung/annai/request/dcc/dcc.icgc.org.html" \
--outputdir /tmp/dcc \
--SHOWLOG 4


=cut

use strict;

#### USE LIB
use FindBin qw($Bin);
use lib "$Bin/../../lib";

#### INTERNAL MODULES
use Web::GetResources;

#### EXTERNAL MODULES
use Term::ANSIColor qw(:constants);
use Getopt::Long;

#### GET OPTIONS
my $url;
my $outputdir;
my $SHOWLOG = 2;
my $PRINTLOG = 5;
my $logfile =   "/tmp/getresources.$$.log";
my $help;
GetOptions (
	'url=s'         =>  \$url,
	'outputdir=s'   =>  \$outputdir,
	'logfile=s'     =>  \$logfile,
	'SHOWLOG=s'     =>  \$SHOWLOG,
	'PRINTLOG=s'    =>  \$PRINTLOG,
	'help'          =>  \$help
) or die "No options specified. Try '--help'\n";

#### PRINT HELP IF REQUESTED
if ( defined $help )	{	usage();	}

#### CHECK INPUTS
print "Url not defined (option --url)\n" and exit if not defined $url;
print "Url must be '(http|ftp|file)://'" and exit if not $url =~ /^(http|ftp|file):\/\//;

print "Output directory not defined (option --outputdir)\n" and exit if not defined $outputdir;

my $object = Web::GetResources->new({

	url         =>  $url,
	outputdir   =>  $outputdir,
	logfile     =>  $logfile,
	SHOWLOG     =>  $SHOWLOG,
	PRINTLOG    =>  $PRINTLOG,

});
$object->getResources();

exit;

###########################################################################################
####################                 S U B R O U T I N E S                ################# 
###########################################################################################

sub usage
{
    `perldoc $0`;
	exit;
}

