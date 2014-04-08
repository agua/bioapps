#!/usr/bin/perl -w

use Test::More tests => 24;
use FindBin qw($Bin);
use Getopt::Long;

use lib "/aguadev/apps/bioapps/t/lib";
use lib "/aguadev/lib";
use lib "/aguadev/t/lib";
use lib "/aguadev/apps/bioapps/lib";

#use lib "$Bin/../../../lib";
#use lib "$Bin/../../../../lib";
#use lib "$Bin/../../../../../../lib";
#use lib "$Bin/../../../../../../t/lib";
#
BEGIN {
    #unshift @INC, "/aguadev/lib";
    #unshift @INC, "/aguadev/apps/bioapps/lib";
    #unshift @INC, "/aguadev/apps/bioapps/t/lib";
    use_ok('Test::Web::GetLinks');
}
require_ok('Test::Web::GetLinks');

use Test::Web::GetLinks;

my $logfile = "$Bin/outputs/opsinfo.log";
my $SHOWLOG     =   2;
my $PRINTLOG    =   5;

my $help;
GetOptions (
    'logfile=s'     =>  \$logfile,
    'SHOWLOG=s'     =>  \$SHOWLOG,
    'PRINTLOG=s'    =>  \$PRINTLOG,
    'help'          =>  \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

my $object = Test::Web::GetLinks->new(
    logfile         =>  $logfile,
    SHOWLOG         =>  $SHOWLOG,
    PRINTLOG        =>  $PRINTLOG
);
isa_ok($object, "Test::Web::GetLinks");

#$object->testGetPage();
#$object->testParseLinks();
#$object->testRecursiveLinks();
#$object->testParsePage();
$object->testPrintPages();
#$object->testGetLinks();

exit;

