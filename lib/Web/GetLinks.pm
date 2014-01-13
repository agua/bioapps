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

class Web::GetLinks with (Agua::Common::Logger, Agua::Common::Util) {

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

method getLinks {
	#### CREATE OUTPUT DIR
	$self->createOutputDir();

	#### GET FIRST PAGE
	my $url	=	$self->url();
	my $contents = $self->getPage($url);
	$self->logDebug("contents", $contents);
	
	#### GET VARIABLES
	my $linkregex	=	$self->linkregex();
	my $linkurl		=	$self->linkurl();
	my $levels		=	$self->levels();
	my $outputdir	=	$self->outputdir();
	my $pageregex	=	$self->pageregex();
	my $nameregex	=	$self->nameregex();
	$self->logDebug("linkurl", $linkurl);
	$self->logDebug("levels", $levels);
	$self->logDebug("outputdir", $outputdir);

	#### GET LINKS IN PAGE
	my $links = [];
	$links = $self->parseLinks($contents, $linkregex);
	$self->logDebug("links", $links);
	
	##### GET LINKS FOR (levels - 1) LEVELS
	#my $currentlevel = 1;
	#$links = $self->recursiveLinks($links, $linkurl, $levels, $currentlevel);
	#$self->logDebug("links", $links);
	#
	##### DOWNLOAD PAGE RECORDS
	#my $pageregex	=	$self->pageregex();
	#my $nameregex	=	$self->nameregex();
	#$self->printPages($outputdir, $links, $linkurl, $pageregex, $nameregex);

	$self->linksToPages($outputdir, $links, $linkurl, $pageregex, $nameregex);
}

method linksToPages ($outputdir, $links, $linkurl, $pageregex, $nameregex) {
	$self->logDebug("outputdir", $outputdir);
	$self->logDebug("links", $links);
	$self->logDebug("linkurl", $linkurl);
	$self->logDebug("pageregex", $pageregex);
	$self->logDebug("nameregex", $nameregex);

	

	
}

method recursiveLinks ($links, $linkurl, $levels, $currentlevel) {
	$self->logDebug("links", $links);
	$self->logDebug("linkurl", $linkurl);
	$self->logDebug("levels", $levels);
	$self->logDebug("currentlevel", $currentlevel);

	my $sublinks = [];
	while ( $currentlevel < $levels - 1 ) {

		foreach my $link ( @$links ) {
			$link = "$linkurl/$link";
			$self->logDebug("link", $link);
		
			my $contents	=	$self->getPage($link);
			my $defaultregex	=	$self->defaultregex();
			my $parsed 		= 	$self->parseLinks($contents, $defaultregex);
			$self->logDebug("parsed", $parsed);
			$parsed = [] if not defined $parsed;
			
			@$sublinks = (@$sublinks, @$parsed);
		}

		$currentlevel++;
		$self->logDebug("Incremented currentlevel", $currentlevel);
	}
	
	return $sublinks;
}

method parseLinks ($contents, $linkregex) {

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

method printPages ($outputdir, $links, $linkurl, $pageregex, $nameregex) {
	foreach my $link ( @$links ) {
		$self->logDebug("link", $link);
		$link				=	"$linkurl/$link";

		my $contents 		=	$self->getPage($link);
		$self->logDebug("contents", $contents);
		next if not defined $contents or not $contents;
		
		my ($name, $text)	=	$self->parsePage($contents, $pageregex, $nameregex);	
		$self->logDebug("name", $name);
		$self->logDebug("text", $text);
		my $label			=	$self->nameToLabel($name);
		$self->logDebug("label", $label);
		
		my $outputfile = "$outputdir/$label";
		$self->logDebug("outputfile", $outputfile);
		$self->printToFile($outputfile, "$name\n\n$text");
	}	
}

method parsePage ($contents, $pageregex, $nameregex) {
	#$self->logDebug("contents", $contents);
	$self->logDebug("pageregex", $pageregex);
	$self->logDebug("nameregex", $nameregex);

	my ($name)	=	 $contents	=~ /$nameregex/ims;
	
	my ($text)	=	 $contents	=~ /$pageregex/ims;
	#$self->logDebug("name", $name);
	#$self->logDebug("text", $text);
	
	return $name, $text;
}

method nameToLabel ($name) {
	my $label = $name;
	$label =~ s/\n//g;
	$label =~ s/\s+/-/g;
	$label =~ s/,.+$//g;
	$self->logDebug("label", $label);

	return $label;
}

method createOutputDir {
	my $outputdir	=	$self->outputdir();

	#### CREATE DIRECTORY IF NOT EXISTS
	File::Path::mkpath($outputdir) if not -d $outputdir;
	$self->logCritical("Can't create output directory: $outputdir") if not -d $outputdir;
}

method getPage ($url) {
	#### GET CONTENTS OF PAGE
	$url =~ s/\/$//;

	print "Doing get($url)\n";
	my $contents = get($url);
	
	return $contents;
}


# PROCESS HTML FROM ONE PAGE
method html2text ($content) {
    $self->logDebug("content", $content);

	#### CLEAN UP SPACES    
    $content =~ s/&nbsp;/ /g;
    $content =~ s/\s\s*/ /g;
    $content =~ s/<p[^>]*>/\n\n/gi;   #<p>  -> \n\n
    $content =~ s/<br>|<\/*h[1-6][^>]*>|<li[^>]*>|<dt[^>]*>|<dd[^>]*>|<\/tr[^>]*>/\n/gi; 
    # <br> or <H*> or <li> or </tr> or <dt> or <dd> -> \n
    $content =~ s/(<[^>]*>)*//g;
    $content =~ s/\n\s*\n\s*/\n\n/g;
    $content =~ s/\n */\n/g;

	my ($ascii, $html);
	my $symbols = $self->parseSymbols();
    foreach my $symbol_pair ( @$symbols ) {
        ($ascii, $html) = split(/\s\s*/,$symbol_pair);
        $content =~ s/$html/$ascii/g;
    }

    return $content;
}

# PARSE HTML SYMBOLS
method parseSymbols {
    return [
    "&	&amp;",
    "\"	&quot;",
    "<	&lt;",
    ">	&gt;",
    "©	&copy;",
    "®	&reg;",
    "Æ	&AElig;",
    "Á	&Aacute;",
    "Â	&Acirc;",
    "À	&Agrave;",
    "Å	&Aring;",
    "Ã	&Atilde;",
    "Ä	&Auml;",
    "Ç	&Ccedil;",
    "Ð	&ETH;",
    "É	&Eacute;",
    "Ê	&Ecirc;",
    "È	&Egrave;",
    "Ë	&Euml;",
    "Í	&Iacute;",
    "Î	&Icirc;",
    "Ì	&Igrave;",
    "Ï	&Iuml;",
    "Ñ	&Ntilde;",
    "Ó	&Oacute;",
    "Ô	&Ocirc;",
    "Ò	&Ograve;",
    "Ø	&Oslash;",
    "Õ	&Otilde;",
    "Ö	&Ouml;",
    "Þ	&THORN;",
    "Ú	&Uacute;",
    "Û	&Ucirc;",
    "Ù	&Ugrave;",
    "Ü	&Uuml;",
    "Ý	&Yacute;",
    "á	&aacute;",
    "â	&acirc;",
    "æ	&aelig;",
    "à	&agrave;",
    "å	&aring;",
    "ã	&atilde;",
    "ä	&auml;",
    "ç	&ccedil;",
    "é	&eacute;",
    "ê	&ecirc;",
    "è	&egrave;",
    "ð	&eth;",
    "ë	&euml;",
    "í	&iacute;",
    "î	&icirc;",
    "ì	&igrave;",
    "ï	&iuml;",
    "ñ	&ntilde;",
    "ó	&oacute;",
    "ô	&ocirc;",
    "ò	&ograve;",
    "ø	&oslash;",
    "õ	&otilde;",
    "ö	&ouml;",
    "ß	&szlig;",
    "þ	&thorn;",
    "ú	&uacute;",
    "û	&ucirc;",
    "ù	&ugrave;",
    "ü	&uuml;",
    "ý	&yacute;",
    "ÿ	&yuml;",
    " 	&#160;",
    "¡	&#161;",
    "¢	&#162;",
    "£	&#163;",
    "¥	&#165;",
    "¦	&#166;",
    "§	&#167;",
    "¨	&#168;",
    "©	&#169;",
    "ª	&#170;",
    "«	&#171;",
    "¬	&#172;",
    "­	&#173;",
    "®	&#174;",
    "¯	&#175;",
    "°	&#176;",
    "±	&#177;",
    "²	&#178;",
    "³	&#179;",
    "´	&#180;",
    "µ	&#181;",
    "¶	&#182;",
    "·	&#183;",
    "¸	&#184;",
    "¹	&#185;",
    "º	&#186;",
    "»	&#187;",
    "¼	&#188;",
    "½	&#189;",
    "¾	&#190;",
    "¿	&#191;",
    "×	&#215;",
    "Þ	&#222;",
    "÷	&#247;"
	];
}


}

