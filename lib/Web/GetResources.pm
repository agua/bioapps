use MooseX::Declare;
use Method::Signatures::Simple;

=head2

PACKAGE		Deploy

PURPOSE

    1. INSTALL KEY AGUA DEPENDENCIES
    
    
=cut
use strict;
use warnings;
use Carp;

#### USE LIB FOR INHERITANCE
use FindBin::Real;
use lib FindBin::Real::Bin() . "/lib";
use Data::Dumper;

class Web::GetResources with (Agua::Common::Logger, Agua::Common::Util) {

#### USE LIB
use FindBin::Real;
use lib FindBin::Real::Bin() . "/lib";

#### EXTERNAL MODULES
use File::Path;
use LWP::Simple;

# Booleans
has 'levels'		=>  ( isa => 'Int', is => 'rw', default => 1 );  
has 'SHOWLOG'		=>  ( isa => 'Int', is => 'rw', default => 1 );  
has 'PRINTLOG'		=>  ( isa => 'Int', is => 'rw', default => 1 );

# Strings
has 'url'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'linkurl'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'outputdir'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'filter'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'defaultregex'	=> ( isa => 'Str|Undef', is => 'rw', default => 'href=\"([^\"]+)\"' );
has 'linkregex'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'pageregex'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'nameregex'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'user'			=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'password'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );

# Objects
has 'agent'			=> ( isa => 'LWP::UserAgent', is => 'rw', lazy => 1, builder => "setAgent" );

####/////}

method BUILD ($hash) {
	$self->logDebug("self", $self);
	$self->initialise();
}

method initialise {	
}

method setAgent {
	my $agent = LWP::UserAgent->new();
	$self->logDebug("agent", $agent);
	
	$self->agent($agent);
}

method getResources {
	#### CREATE OUTPUT DIR
	my $outputdir	=	$self->outputdir();
	$self->logDebug("outputdir", $outputdir);
	$self->createOutputDir();

	#### SET BASE URL
	my $url			=	$self->url();
	$url =~ /^(file:\/\/)?(.+)$/;
	my ($baseurl) 	= $2;
	$self->logDebug("baseurl", $baseurl);
	$baseurl		=~ 	s/\/[^\/]+$//;
	$self->logDebug("FINAL baseurl", $baseurl);

	#### GET FIRST PAGE
	my $contents = $self->getPage($url);
	#$self->logDebug("contents", $contents);

	#### GET RESOURCE LISTS
	my $jsregex = qq{"([^"]+?\\.js)"};
	my $jsfiles = $self->parseLinks($contents, $jsregex);
	$self->logDebug("jsfiles", $jsfiles);
	
	my $cssregex = qq{"([^"]+?\\.css)"};
	my $cssfiles = $self->parseLinks($contents, $cssregex);
	$self->logDebug("cssfiles", $cssfiles);

	foreach my $jsfile ( @$jsfiles ) {
		$self->createResource($outputdir, $baseurl, $jsfile);
	}
	
	foreach my $cssfile ( @$cssfiles ) {
		$self->createResource($outputdir, $baseurl, $cssfile);
	}
}

method parseLinks ($contents, $linkregex) {
	$self->logDebug("linkregex", $linkregex);

	#### GET LINES
    my @lines = split "\n", $contents;
	#$self->logDebug("lines", \@lines);

	#### GET MATCHING LINKS IN LINES
	my $links = [];
    foreach my $line ( @lines ) {
        next if $line =~ /^\s*$/;
		
		my $match 	=	$self->matchRegex($line, $linkregex);

		push @$links, $match if defined $match;
    }	
	#$self->logDebug("links", $links);

	return $links;
}

method matchRegex ($text, $regex) {
	#$self->logDebug("text", $text);
	#$self->logDebug("regex", $regex);
	if ( $text =~ /$regex/i ) {
		#$self->logDebug("matched", $1);
		return $1;
	}
	
	return undef;
}

method createResource ($outputdir, $url, $link) {
	#$self->logDebug("url", $url);
	#$self->logDebug("link", $link);

	my ($targetdir, $filename)	=	$link =~ /^(.+?)\/([^\/]+)$/;
	$filename	=	$link	if not defined $filename;
	$self->logDebug("targetdir", $targetdir);
	$self->logDebug("filename", $filename);
	print "targetdir is a file\n" and exit if -f $targetdir;
	`mkdir -p $targetdir` if defined $targetdir;

	#### REMOVE TRAILING '/' FROM URL
	$url	=~ s/\/+$//g;

	#### GET PAGE CONTENTS
	my $linkurl			=	"$url/$link";
	#$self->logDebug("linkurl", $linkurl);
	my $contents 		=	$self->getPage($linkurl);
	#$self->logDebug("contents", $contents);
	next if not defined $contents or not $contents;
	
	my $outputfile = "$outputdir/$targetdir/$filename";
	$self->logDebug("outputfile", $outputfile);
	$self->printToFile($outputfile, $contents);
}

method parsePage ($contents, $pageregex, $nameregex) {
	#$self->logDebug("contents", $contents);
	#$self->logDebug("pageregex", $pageregex);
	#$self->logDebug("nameregex", $nameregex);

	my ($name)	=	 $contents	=~ /$nameregex/ims;
	
	my ($text)	=	 $contents	=~ /$pageregex/ims;
	#$self->logDebug("name", $name);
	#$self->logDebug("text", $text);
	
	return $name, $text;
}

method createOutputDir {
	my $outputdir	=	$self->outputdir();

	#### CREATE DIRECTORY IF NOT EXISTS
	File::Path::mkpath($outputdir) if not -d $outputdir;
	$self->logCritical("Can't create output directory: $outputdir") if not -d $outputdir;
}

method getPage ($url) {
	$self->logDebug("url", $url);
	
	#### GET CONTENTS OF PAGE
	$url =~ s/\/$//;

	my $contents;
	if ($url =~ /^file:/) {
		my ($file) = $url =~ /file:[\/]{2}(.+)$/;
		print "Doing get file: $file\n";
		open(FILE, $file) or die "Can't open file: $file\n";
		my $oldend = $/;
		$/ = undef;
		$contents = <FILE>;
		$/ = $oldend;
		close(FILE) or die "Can't close file: $file\n";
	}
	else {
		print "Doing get url: $url\n";
		$contents = get($url);	
	}
	
	
	return $contents;
}



}

