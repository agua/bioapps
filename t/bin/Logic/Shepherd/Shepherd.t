#!/usr/bin/perl -w

use Test::More tests => 22;
use FindBin qw($Bin);
use Getopt::Long;

#### BIOAPPS MODULES
use lib "$Bin/../../../../lib";
use lib "$Bin/../../../lib";

#### USE LIBRARY
BEGIN
{
    my $installdir = $ENV{'installdir'} || "/agua";
    unshift(@INC, "$installdir/lib");
    unshift(@INC, "$installdir/t/common/lib");
}

BEGIN {
    use_ok('Test::Logic::Shepherd');
}
require_ok('Test::Logic::Shepherd');

use Test::Logic::Shepherd;

my $logfile = "$Bin/outputs/shepherd.log";
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

my $object = Test::Logic::Shepherd->new(
    logfile         =>  $logfile,
    SHOWLOG         =>  $SHOWLOG,
    PRINTLOG        =>  $PRINTLOG
);
isa_ok($object, "Test::Logic::Shepherd");

$object->testLoadThreads();
$object->testPollThreads();
$object->testRun();

exit;

