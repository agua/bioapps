#Fri Dec 23 23:18:26 CST 2011
# THIS MAKEFILE WAS GENERATED BY /agua/0.6/apps/t/makefile.pl

all:
	cd ./bin/Hapmap; perl -MTest::Harness -e '$$Test::Harness::verbose=0; runtests @ARGV;' *.t; cd ../..
	cd ./bin/StatsUtil; perl -MTest::Harness -e '$$Test::Harness::verbose=0; runtests @ARGV;' *.t; cd ../..
	cd ./bin/Filter; perl -MTest::Harness -e '$$Test::Harness::verbose=0; runtests @ARGV;' *.t; cd ../..
	cd ./bin/Filter/SNP; perl -MTest::Harness -e '$$Test::Harness::verbose=0; runtests @ARGV;' *.t; cd ../../..

verbose:
	cd ./bin/Hapmap; perl -MTest::Harness -e '$$Test::Harness::verbose=1; runtests @ARGV;' *.t; cd ../..
	cd ./bin/StatsUtil; perl -MTest::Harness -e '$$Test::Harness::verbose=1; runtests @ARGV;' *.t; cd ../..
	cd ./bin/Filter; perl -MTest::Harness -e '$$Test::Harness::verbose=1; runtests @ARGV;' *.t; cd ../..
	cd ./bin/Filter/SNP; perl -MTest::Harness -e '$$Test::Harness::verbose=1; runtests @ARGV;' *.t; cd ../../..

clean:
#	find . -name '*~' -exec rm -f {} ;
