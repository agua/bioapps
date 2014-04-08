use MooseX::Declare;

use strict;
use warnings;

class GT::Download extends GT::Main {

#####////}}}}}

# Integers
has 'SHOWLOG'		=>  ( isa => 'Int', is => 'rw', default => 2 );
has 'PRINTLOG'		=>  ( isa => 'Int', is => 'rw', default => 5 );

# Strings
has 'cpus'			=> 	( isa => 'Str|Undef', is => 'rw', lazy	=>	1, 	builder => 	"getCpus");
has 'log'			=> 	( isa => 'Str|Undef', is => 'rw', lazy	=>	1, 	default	=>	"syslog:full");


method download ($outputdir, $uuid, $gtrepo, $cpus) {
	$self->logDebug("outputdir", $outputdir);
	$self->logDebug("uuid", $uuid);
	$self->logDebug("gtrepo", $gtrepo);
	$self->logDebug("cpus", $cpus);

	print "uuid not defined.\n" and return if not defined $uuid;
	print "outputdir not defined.\n" and return if not defined $outputdir;

	if ( not defined $gtrepo ) {
		$gtrepo	=	$self->gtrepo();	
		print "gtrepo not defined. Using default: $gtrepo\n";
	}

	#### CREATE OUTPUTDIR IF NOT EXISTS
	`mkdir -p $outputdir` if not -d $outputdir;

	#### SET KEYFILE
	my $homedir		=	$self->getHomeDir();
	my $username	=	$self->getUserName();
	my $keyfile		=	$self->keyfile();
	my $keypath		=	"$homedir/$username/$keyfile";
	$keypath		=	$self->keyurl() if not -f $keypath;
	$self->logDebug("keypath", $keypath);
	
	#### CHANGE TO OUTPUTDIR
	$self->changeDir($outputdir);

	$cpus	=	$self->cpus() if not defined $cpus;
	my $log	=	$self->log();
	
	#### DOWNLOAD
	my $command	=	qq{time /usr/bin/gtdownload \\
--max-children $cpus \\
-c $keypath \\
-v -d \\
$uuid \\
-l $log
};
	$self->logDebug("command", $command);

	$self->runCommand($command);	
}



}

