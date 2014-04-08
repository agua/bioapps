use MooseX::Declare;

#class Test::Web::GetLinks extends Web::GetLinks with Test::Agua::Common::Util {
class Test::Web::GetLinks extends Web::GetLinks with (Test::Agua::Common::Util) {


#### EXTERNAL MODULES
use Data::Dumper;
use Test::More;

use FindBin qw($Bin);
use lib "../../../t/lib";
use lib "../../../lib";

####////}}}}

method testGetLinks {
	diag("getLinks");

	my $inputfile 		=   "$Bin/inputs/ashg.html";
	my $outputdir 		=   "$Bin/outputs/getlinks.logprint Dumper ;";
	
	$self->outputdir($outputdir);
	$self->getLinks();


}

method testGetPage {
	diag("getPage");

	my $inputfile 		=   "file:$Bin/inputs/ashg.html";	
	my $contents = $self->getPage($inputfile);
	#$self->logDebug("contents", $contents);
	ok($contents, "got contents");

	my $infile 		=   "$Bin/inputs/ashg.html";
	my $expected	=	$self->getFileContents($infile);

	is_deeply($contents, $expected, "page contents");
}

method testParseLinks {
	diag("parseLinks");

	my $inputfile 		=   "file:$Bin/inputs/ashg.html";
	my $contents = $self->getPage($inputfile);
	
	my $linkregex	=	qq{<a HREF=\"([^\"]+)\"><};
	my $links 	=	$self->parseLinks($contents, $linkregex);
	#$self->logDebug("links", $links);

	my $expected =	["reglist.pl?c=A","reglist.pl?c=B","reglist.pl?c=C","reglist.pl?c=D","reglist.pl?c=E","reglist.pl?c=F","reglist.pl?c=G","reglist.pl?c=H","reglist.pl?c=I","reglist.pl?c=J","reglist.pl?c=K","reglist.pl?c=L","reglist.pl?c=M","reglist.pl?c=N","reglist.pl?c=O","reglist.pl?c=P","reglist.pl?c=Q","reglist.pl?c=R","reglist.pl?c=S","reglist.pl?c=T","reglist.pl?c=U","reglist.pl?c=V","reglist.pl?c=W","reglist.pl?c=X","reglist.pl?c=Y","reglist.pl?c=Z"];
	
	is_deeply($links, $expected, "links");	
}


method linksToPages {
	diag("linksToPages");


	my $linkurl			=	"file:$Bin/inputs";
	my $linkregex		=	qq{<a HREF=\"([^\"]+)\"><};

	my $inputfile 		=   "file:$Bin/inputs/A.html";
	my $contents 		= 	$self->getPage($inputfile);
	my $links			=	$self->parseLinks($contents, $linkregex);	
	$self->logDebug("links", $links);
	
	my $levels 			=	3;
	my $currentlevel	=	1;
	$links		=	$self->recursiveLinks($links, $linkurl, $levels, $currentlevel);
	$self->logDebug("FINAL links", $links);
	
	my $expected = ["A-1-X.html","A-1-Y.html","A-1-Z.html","A-2-X.html","A-2-Y.html","A-2-Z.html","A-3-X.html","A-3-Y.html","A-3-Z.html","B-1-X.html","B-1-Y.html","B-1-Z.html","B-2-X.html","B-2-Y.html","B-2-Z.html","C-2-X.html","C-2-Y.html","C-2-Z.html","C-3-X.html","C-3-Y.html","C-3-Z.html"];
	
	is_deeply($links, $expected, "links");
}

method testRecursiveLinks {
	diag("recursiveLinks");

	my $inputfile 		=   "file:$Bin/inputs/A.html";
	my $contents = $self->getPage($inputfile);
	my $linkregex	=	qq{<a HREF=\"([^\"]+)\"><};
	my $links	=	$self->parseLinks($contents, $linkregex);	
	$self->logDebug("links", $links);
	
	my $linkurl			=	"file:$Bin/inputs";
	my $levels 			=	3;
	my $currentlevel	=	1;
	$links		=	$self->recursiveLinks($links, $linkurl, $levels, $currentlevel);
	$self->logDebug("FINAL links", $links);
	
	my $expected = ["A-1-X.html","A-1-Y.html","A-1-Z.html","A-2-X.html","A-2-Y.html","A-2-Z.html","A-3-X.html","A-3-Y.html","A-3-Z.html","B-1-X.html","B-1-Y.html","B-1-Z.html","B-2-X.html","B-2-Y.html","B-2-Z.html","C-2-X.html","C-2-Y.html","C-2-Z.html","C-3-X.html","C-3-Y.html","C-3-Z.html"];
	
	is_deeply($links, $expected, "links");
}



method testParsePage {

	my $expectedtextfile	=	"$Bin/inputs/parsepage-expectedtext";
	my $expectednamefile	=	"$Bin/inputs/parsepage-expectedname";

	my $pageregex	=	q{Registrant Information</p>\s+<p class=p>&nbsp;</p>(.+)person to register </p></td></tr>};
	my $nameregex	=	q{<tr><td><p class=h4charcoal> (\D+[^\n^<]+\n[^<^\n]+) </p></td></tr>};
	
	#my $infile		=	"file:$Bin/inputs/C-2-X.html";
	my $infile		=	"file:$Bin/inputs/parsepage-input";
	my $contents	=	$self->getPage($infile);
	#$self->logDebug("contents", $contents);

	my $expectedtext  = $self->getFileContents($expectedtextfile);
	my $expectedname  = $self->getFileContents($expectednamefile);
	
	my ($name, $text)	=	$self->parsePage($contents, $pageregex, $nameregex);
	
	is_deeply($expectedtext, $text, "parsed text");
	is_deeply($expectedname, $name, "parsed name: $name");
}

method testPrintPages {
	#### DOWNLOAD PAGE RECORDS
	$self->logDebug("");
	my $pageregex	=	q{Registrant Information</p>\s+<p class=p>&nbsp;</p>(.+)person to register </p></td></tr>};
	my $nameregex	=	q{<tr><td><p class=h4charcoal> (\D+[^\n^<]+\n[^<^\n]+) </p></td></tr>};

	#my $links = ["A-1-X.html","A-1-Y.html","A-1-Z.html","A-2-X.html","A-2-Y.html","A-2-Z.html","A-3-X.html","A-3-Y.html","A-3-Z.html","B-1-X.html","B-1-Y.html","B-1-Z.html","B-2-X.html","B-2-Y.html","B-2-Z.html","C-2-X.html","C-2-Y.html","C-2-Z.html","C-3-X.html","C-3-Y.html","C-3-Z.html"];

	#my $links = ["ashg2.html"];
	#my $links = ["getlinks.txt"];
	my $links = ["getlinks-test.txt"];

	my $linkurl			=	"file:$Bin/inputs";
	
	my $outputdir	=	"$Bin/outputs/printpages";	
	$self->printPages($outputdir, $links, $linkurl, $pageregex, $nameregex);	
}




}   #### Test::Web::GetLinks