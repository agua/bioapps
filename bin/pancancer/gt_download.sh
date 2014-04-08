#!/bin/bash

SYN_MONITOR="/pancanfs/software/synapseICGCMonitor"
DOWNLOAD_SCRIPT="/agua/apps/bioapps/bin/gt/download.pl"
OUTPUTDIR="/pancanfs/input"
KEYFILE="/home/centos/annai-cghub.key"

while :
do
	echo "Scanning"
	UUID=`$SYN_MONITOR getAssignmentForWork ucsc_biofarm todownload`
	if [ $? != 0 ]; then 
		echo "Done, exiting"
		exit 0
	else
		echo Downloading $UUID
    	if [ ! -e /pancanfs/input/$UUID ]; then

#			gtdownload -c ~/haussl_cghub.key -v -p /pancanfs/input/ -d $UUID
			$DOWNLOAD_SCRIPT --uuid $UUID --outputdir $OUTPUTDIR --keyfile $KEYFILE

			if [ $? != 0 ]; then 
				$SYN_MONITOR errorAssignment $UUID "gtdownload error"
			else
				$SYN_MONITOR returnAssignment $UUID		
			fi
		fi
	fi
done
