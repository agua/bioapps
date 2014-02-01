#!/usr/bin/perl -w


=doc

APPLICATION 	shepherd

PURPOSE

	SHEPHERD A SERIES OF JOB COMMANDS, WITH ONLY A SPECIFIED NUMBER OF JOBS RUNNING CONCURRENTLY

HISTORY

	VERSION 0.01	BASIC LOOP WITH THREADS TO MANAGE JOBS

=cut

#### EXTERNAL MODULES
use Term::ANSIColor qw(:constants);
use Data::Dumper;
use Getopt::Long;
use FindBin qw($Bin);

#### USE LIBRARY
use lib "$Bin/../../lib";	
BEGIN {
    my $installdir = $ENV{'installdir'} || "/agua";
    unshift(@INC, "$installdir/lib");
}

use Logic::Shepherd;

##### STORE ARGUMENTS TO PRINT TO FILE LATER
my $arguments;
@$arguments = @ARGV;

my $max			=	0;
my $sleep		=	10;
my $commands;
my $commandfile;
my $SHOWLOG		=	2;
my $PRINTLOG	=	2;
my $logfile		=	"/tmp/agua-shepherd.log";
my $help;
GetOptions (
    'command=s@'  	=> \$commands,
    'commandfile=s'	=> \$commandfile,
    'max=i'  		=> \$max,
    'sleep=i'  		=> \$sleep,
    'SHOWLOG=i'     => \$SHOWLOG,
    'PRINTLOG=i'    => \$PRINTLOG,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

my $object = Logic::Shepherd->new({
    commands    =>  $commands,
	commandfile	=>	$commandfile,
    max			=>	$max,
    sleep		=>	$sleep,

    SHOWLOG     =>  $SHOWLOG,
    PRINTLOG    =>  $PRINTLOG,
    logfile     =>  $logfile
});

my $outputs = $object->run();
for ( my $i = 0; $i < @$outputs; $i++ ) {
	my $output = $$outputs[$i];
	print "[command $i] $$commands[$i]\n";
	print "$output\n\n";
}

exit;

##############################################################

