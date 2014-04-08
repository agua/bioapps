use MooseX::Declare;

use strict;
use warnings;

class Test::GT::Fuse::Zombies extends GT::Fuse {

use FindBin qw($Bin);
use Test::More;

#####////}}}}}

method testGetZombies {
	diag("getZombies");
	
	my $temp	=	*getPs;
	
	#*getPs = sub {
	#	my $psfile	=	"$Bin/inputs/ps.txt";
	#	#$self->logDebug("psfile", $psfile);
	#	open(FILE, $psfile) or die "Can't open psfile: $psfile\n";
	#	my @lines	=	<FILE>;
	#	close(FILE) or die "Can't close psfile: $psfile\n";
	#	#$self->logDebug("lines", @lines);
	#	
	#	return \@lines;
	#};
	
	my $zombies	=	$self->getZombies();
	$self->logDebug("zombies", $zombies);
	my $expected	=	["11702","12203","12225","12599","12613"];
	
	is_deeply($zombies, $expected, "zombie pids");

	*getPs	=	$temp;
}

method getPs {
	my $psfile	=	"$Bin/inputs/ps.txt";
	$self->logDebug("psfile", $psfile);
	open(FILE, $psfile) or die "Can't open psfile: $psfile\n";
	my @lines	=	<FILE>;
	close(FILE) or die "Can't close psfile: $psfile\n";
	#$self->logDebug("lines", @lines);
	
	return \@lines;
}

}

