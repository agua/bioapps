use MooseX::Declare;

class Test::Filter::SNP extends Filter::SNP with Agua::Common::Logger {
use Data::Dumper;
use Test::More;

# Ints
has 'start'     	=>  ( isa => 'Int', is => 'rw' );
has 'submit'  		=>  ( isa => 'Int', is => 'rw' );

# Strings
has 'workflow'  	=>  ( isa => 'Str', is => 'rw' );
has 'project'   	=>  ( isa => 'Str', is => 'rw' );

# Objects
has 'json'		=> ( isa => 'HashRef', is => 'rw', required => 0 );
has 'db'	=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );

method BUILD ($hash) {
	$self->initialise();
}

method initialise () {
	#my $database = $self->conf()->getKey("database", "TESTDATABASE");
	#my $user = $self->conf()->getKey("database", "TESTUSER");
	#my $password = $self->conf()->getKey("database", "TESTPASSWORD");
	#$self->setDbh(
	#	database	=>	$database,
	#	user		=>	$user,
	#	password	=>	$password
	#);
}

method testSetMonitor {
	$self->logDebug("");
	$self->logObject("self->conf", $self->conf());
	my $clustertype =  $self->conf()->getKey('agua', 'CLUSTERTYPE');
	my $classfile = "Agua/Monitor/" . uc($clustertype) . ".pm";
	my $module = "Agua::Monitor::$clustertype";
	$self->logDebug("Doing require $classfile");
	require $classfile;

	my $monitor = $module->new(
		{
			'pid'		=>	$$,
			'conf' 		=>	$self->conf(),
			'db'	=>	$self->db()
		}
	);

	return $monitor;
}





}   #### Test::Agua::Filter::SNP