#!/usr/bin/perl -w

my $sleep = $ARGV[0];
$sleep = 5 if not defined $sleep;

while ( 1 )
{
    qsum();
    sleep($sleep);
}

sub qsum {
    my $command = "qstat -f";
    my $output = `$command`;
    
#    my $output = qq{queuename                      qtype resv/used/tot. load_avg arch          states
#---------------------------------------------------------------------------------
#Project1-Workflow1\@master      BIP   0/0/1          0.95     lx24-amd64    
#---------------------------------------------------------------------------------
#Project1-Workflow1\@node001     BIP   0/0/1          0.80     lx24-amd64    
#---------------------------------------------------------------------------------
#Project1-Workflow1\@node002     BIP   0/0/1          0.67     lx24-amd64    
#---------------------------------------------------------------------------------
#Project1-Workflow2\@master      BIP   0/0/1          0.95     lx24-amd64    
#---------------------------------------------------------------------------------
#Project1-Workflow2\@node001     BIP   0/0/1          0.80     lx24-amd64    
#---------------------------------------------------------------------------------
#Project1-Workflow2\@node002     BIP   0/0/1          0.67     lx24-amd64    
#
#############################################################################
# - PENDING JOBS - PENDING JOBS - PENDING JOBS - PENDING JOBS - PENDING JOBS
#############################################################################
#    597 0.00000 bamToSam-c root         qw    05/23/2011 09:55:53     1        
#};
#
#$output = qq{queuename                      qtype resv/used/tot. load_avg arch          states
#---------------------------------------------------------------------------------
#Project1-Workflow1\@master      BIP   0/0/1          0.95     lx24-amd64    
#---------------------------------------------------------------------------------
#Project1-Workflow1\@node001     BIP   0/0/1          0.80     lx24-amd64    
#---------------------------------------------------------------------------------
#Project1-Workflow1\@node002     BIP   0/1/1          0.67     lx24-amd64    
#    597 0.55500 bamToSam-c root         r     05/23/2011 09:55:58     1        
#---------------------------------------------------------------------------------
#Project1-Workflow2\@master      BIP   0/0/1          0.95     lx24-amd64    
#---------------------------------------------------------------------------------
#Project1-Workflow2\@node001     BIP   0/0/1          0.80     lx24-amd64    
#---------------------------------------------------------------------------------
#Project1-Workflow2\@node002     BIP   0/0/1          0.67     lx24-amd64    
#};
    
    my ($nodes, $jobs);
    if ( $output =~ /PENDING JOBS/ )
    {
        ($nodes, $jobs) = $output =~ /^(.+)\n#{10,}\n.+?PENDING JOBS.+?\n#{10,}\n(.+)?$/ms;
    }
    else {
        $nodes = $output;
    }
    print "=================================================================================\n";
    print "$nodes\n";
    return if not defined $jobs;
    
    my @lines = split "\n", $jobs;
    my $jobcounts = {};
    foreach my $line ( @lines )
    {
        my ($jobname) = $line =~ /^\s*\S+\s+\S+\s+(\S+)/;
        if ( exists $jobcounts->{$jobname} )
        {
            $jobcounts->{$jobname}++;
        }
        else
        {
            $jobcounts->{$jobname} = 1;
        }
    }
    
    foreach my $key ( sort keys %$jobcounts )
    {
        print "$key: $jobcounts->{$key}\n";
    }
}