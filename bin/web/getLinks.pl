#!/usr/bin/perl -w
use strict;

#### DEBUG
my $DEBUG = 0;
$DEBUG = 1;

#### TIME
my $time = time();

=head2

    APPLICATION     getLinks
    
    PURPOSE
    
        1. RECURSIVELY FOLLOW LINKS TO ACCESS RECORDS:
        
            FILTER LINKS BY linkregex ON FIRST PAGE ONLY
            
            FILTER RECORDS BY pageregex ON FINAL PAGE ONLY
            

        2. PRINT RECORDS TO FILE
    
    INPUT
    
        1. REQUIRED: URL AND OUTPUT DIRECTORY (MUST ALREADY EXIST)
    
        2. OPTIONAL: FILTER TERM AND REGEX TO FILTER FILES BEFORE DOWNLOADING
    
        3. OPTIONAL: LINK LEVELS (DEFAULT = 1)
    
    OUTPUT
    
        1. DATA FILES PRINTED TO OUTPUT DIRECTORY

    USAGE
    
    ./getLinks.pl <--url String> <--outputdir String> [--filter String] [--regex String] [--help]
    
    --url               :   URL OF FTP SITE OR PAGE
    --outputdir         :   DIRECTORY TO DOWNLOAD FILES TO
    --linkregex         :   Follow only links matching this regular expression
    --pageregex         :   Download only pages matching this regular expression
    --levels            :   Number of levels to follow
    --help              :   PRINT HELP INFO

    EXAMPLES

./getLinks.pl \
--url "https://secure.ashg.org/cgi-bin/ashg13r/reglist.pl" \
--linkurl "https://secure.ashg.org/cgi-bin/ashg13r/" \
--outputdir /tmp/ashg \
--pageregex "Registrant Information</p>\s+<p class=p>&nbsp;</p>(.+)person to register </p></td></tr>" \
--nameregex "Registrant Information</p>(.+)person to register </p>" \
--linkregex "<a HREF=\"([^\"]+)\"><font color=\"#D65A02\">[^<]+<" \
--levels 3


URL: https://secure.ashg.org/cgi-bin/ashg13r/reglist.pl
FINAL RECORD PAGE: https://secure.ashg.org/cgi-bin/ashg13r/reglist.pl?c=1301201653


=cut

use strict;

#### USE LIB
use FindBin qw($Bin);
use lib "$Bin/../../lib";

#### USE FULL PATH TO SCRIPT IN COMMAND SO THAT CORRECT LIBS
#### CAN BE USED IF LINKS ARE INVOLVED
print "Application must be called with full path (e.g., /full/path/to/file.pl)\n" and exit if $0 =~ /^\./;
my $aguadir;
BEGIN {	
	($aguadir) = $0 =~ /^(.+?)\/[^\/]+\/[^\/]+\/[^\/]+\/[^\/]+\/[^\/]+$/;
	unshift @INC, "$aguadir/lib";
}

#### INTERNAL MODULES
use Web::GetLinks;

#### EXTERNAL MODULES
use Term::ANSIColor qw(:constants);
use Getopt::Long;

#### GET OPTIONS
my $url;
my $linkurl;
my $outputdir;
my $linkregex = q{/<a\s*[^>]*\s*href\s*=\s*('|")(\S+)('|")/};
my $pageregex;
my $nameregex;
my $levels = 1;
my $SHOWLOG = 2;
my $PRINTLOG = 5;
my $logfile =   "/tmp/getLinks.log";
my $help;
GetOptions (
	'url=s'         =>  \$url,
	'linkurl=s'     =>  \$linkurl,
	'outputdir=s'   =>  \$outputdir,
	'linkregex=s'   =>  \$linkregex,
	'pageregex=s'   =>  \$pageregex,
	'nameregex=s'   =>  \$nameregex,
	'logfile=s'     =>  \$logfile,
	'levels=i'      =>  \$levels,
	'SHOWLOG=s'     =>  \$SHOWLOG,
	'PRINTLOG=s'    =>  \$PRINTLOG,
	'help'          =>  \$help
) or die "No options specified. Try '--help'\n";

#### PRINT HELP IF REQUESTED
if ( defined $help )	{	usage();	}

#### CHECK INPUTS
print "linkregex not defined (option --url)\n" and exit if not defined $linkregex;
print "Url not defined (option --url)\n" and exit if not defined $url;
print "Output directory not defined (option --outputdir)\n" and exit if not defined $outputdir;

my $object = Web::GetLinks->new({

	url         =>  $url,
	linkurl     =>  $linkurl,
	outputdir   =>  $outputdir,
	linkregex   =>  $linkregex,
	pageregex   =>  $pageregex,
	nameregex   =>  $nameregex,
	logfile     =>  $logfile,
	levels      =>  $levels,
	SHOWLOG     =>  $SHOWLOG,
	PRINTLOG    =>  $PRINTLOG,

});
$object->getLinks();

exit;

###########################################################################################
####################                 S U B R O U T I N E S                ################# 
###########################################################################################

sub usage
{
    `perldoc $0`;
	exit;
}

