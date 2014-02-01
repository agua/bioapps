use MooseX::Declare;

class Test::Logic::Shepherd extends Logic::Shepherd with (Test::Agua::Common::Util) {

#### EXTERNAL MODULES
use Data::Dumper;
use Test::More;

use FindBin qw($Bin);
use lib "../../../t/lib";
use lib "../../../lib";

####////}}}}

method testLoadThreads {
	diag("loadThreads");

	my $commands	=	[
		"sleep 1; echo 1",
		"sleep 2; echo 2",
		"sleep 3; echo 3",
		"sleep 4; echo 4",
		"sleep 5; echo 5",
		"sleep 8; echo 8"
	];
	my $expectedcommands	=	[
		[],
		[
			"sleep 4; echo 4",
			"sleep 5; echo 5",
			"sleep 8; echo 8"
		],
		[
			"sleep 8; echo 8"
		],
		[],
		[
			"sleep 1; echo 1",
			"sleep 2; echo 2",
			"sleep 3; echo 3",
			"sleep 4; echo 4",
			"sleep 5; echo 5",
			"sleep 8; echo 8"
		],
		[
			"sleep 1; echo 1",
			"sleep 2; echo 2",
			"sleep 3; echo 3",
			"sleep 4; echo 4",
			"sleep 5; echo 5",
			"sleep 8; echo 8"
		]
	];
	my $expected	=	[
		["1","2","3"],
		["1","2","3","4","5"],
		["1","2","3","4","5","8"]
	];
	#$self->logDebug("commands", $commands);

	#### SET MAX TO 6
	my $max	=	6;	
	my $threads;
	my $returnedcommands;
	my $inputcommands	=	$self->copyArray($commands);
	$self->logDebug("inputcommands", $inputcommands);
	($returnedcommands, $threads) = $self->loadThreads($inputcommands, $threads, $max);
	$self->logDebug("returnedcommands", $returnedcommands);
	is_deeply($returnedcommands, $$expectedcommands[0], "no commands returned");
	$self->logDebug("# threads", scalar(@$threads));
	
	#### FIRST SLEEP - THREE THREADS FINISHED
	sleep(3);
	my $outputs 	= 	[];
	($outputs, $threads)	=	$self->pollThreads($outputs, $threads);
	is_deeply($outputs, $$expected[0], "three threads finished - outputs correct");
	
	#### SECOND SLEEP - FIVE THREADS FINISHED
	sleep(3);
	($outputs, $threads)	=	$self->pollThreads($outputs, $threads);
	is_deeply($outputs, $$expected[1], "five threads finished - outputs correct");
	
	#### THIRD SLEEP - SIX THREADS FINISHED
	sleep(2);
	($outputs, $threads)	=	$self->pollThreads($outputs, $threads);
	is_deeply($outputs, $$expected[2], "six threads finished - outputs correct");

	#### SET MAX TO 3
	$max	=	3;	
	$threads	=	[];
	($returnedcommands, $threads) = $self->loadThreads($self->copyArray($commands), $threads, $max);
	is_deeply($returnedcommands, $$expectedcommands[1], "three commands returned");
	$self->logDebug("# threads", scalar(@$threads));
	ok(scalar(@$threads) == 3, "max = 3, three threads running");
	
	#### MOP UP THREADS
	sleep(3);
	foreach my $thread (@$threads) {
		if ( $thread->is_joinable() ) {
			my $output = $thread->join;
		}
	}
	
	#### SET MAX TO 5
	$max	=	5;	
	$threads	=	[];
	($returnedcommands, $threads) = $self->loadThreads($self->copyArray($commands), $threads, $max);
	is_deeply($returnedcommands, $$expectedcommands[2], "one command returned");
	$self->logDebug("# threads", scalar(@$threads));
	ok(scalar(@$threads) == 5, "max = 5, five threads running");
	
	#### MOP UP THREADS
	sleep(5);
	foreach my $thread (@$threads) {
		if ( $thread->is_joinable() ) {
			my $output = $thread->join;
		}
	}
	
	#### SET MAX TO OVERRUN commands ARRAY
	$max	=	8;	
	$threads	=	[];
	($returnedcommands, $threads) = $self->loadThreads($self->copyArray($commands), $threads, $max);
	is_deeply($returnedcommands, $$expectedcommands[3], "no commands returned (max overran array)");
	$self->logDebug("# threads", scalar(@$threads));
	ok(scalar(@$threads) == 6, "max = 8, six threads running");
	
	#### MOP UP THREADS
	sleep(8);
	foreach my $thread (@$threads) {
		if ( $thread->is_joinable() ) {
			my $output = $thread->join;
		}
	}
	
	#### SET MAX TO ZERO
	$max	=	0;	
	$threads	=	[];
	($returnedcommands, $threads) = $self->loadThreads($self->copyArray($commands), $threads, $max);
	is_deeply($returnedcommands, $$expectedcommands[4], "six commands returned (max = 0)");
	$self->logDebug("# threads", scalar(@$threads));
	ok(scalar(@$threads) == 0, "max = 0, no threads running");
	
	#### SET MAX TO NEGATIVE
	$max	=	-3;	
	$threads	=	[];
	($returnedcommands, $threads) = $self->loadThreads($self->copyArray($commands), $threads, $max);
	is_deeply($returnedcommands, $$expectedcommands[5], "six commands returned (max is negative)");
	$self->logDebug("# threads", scalar(@$threads));
	ok(scalar(@$threads) == 0, "max = -3, no threads running");
}

method testPollThreads {
	diag("pollThreads");

	my $commands	=	[
		"sleep 1; echo 1",
		"sleep 2; echo 2",
		"sleep 3; echo 3",
	];
	my $expected	=	[
		["1","2"],
		["1","2","3"]
	];
	my $threads	=	[];
	for my $i ( 0 .. 2 ) {
		my $command		=	$$commands[$i];
		my $thread = threads->new(
			sub {
				$self->logDebug("thread $i Running command: $command\n");
				my $output =	`$command`;
				chomp($output);
				
				return $output;
			}
		);
		push @$threads, $thread;		
	}

	#### SLEEP
	sleep(2);
	my $outputs 	= 	[];
	($outputs, $threads)	=	$self->pollThreads($outputs, $threads);
	is_deeply($outputs, $$expected[0], "two threads finished - outputs correct");
	ok(scalar(@$threads == 1), "one thread still running");
	sleep(3);
	
	($outputs, $threads)	=	$self->pollThreads($outputs, $threads);
	is_deeply($outputs, $$expected[1], "three threads finished - outputs correct");
	ok(scalar(@$threads == 0), "no threads still running");
}

method testRun {
	diag("run");

	my $commands	=	[
		"sleep 1; echo 1",
		"sleep 2; echo 2",
		"sleep 3; echo 3",
		"sleep 4; echo 4",
		"sleep 5; echo 5",
	];
	my $expected	=	["1","2","3","4","5"];

	$self->max(2);
	$self->sleep(2);
	$self->commands($commands);	
	my $outputs	= 	$self->run();
	is_deeply($outputs, $expected, "five threads finished - outputs correct");
}


}   #### Test::Logic::Shepherd