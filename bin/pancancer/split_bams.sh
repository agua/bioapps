#!/bin/bash

SYN_MONITOR="/pancanfs/software/synapseICGCMonitor"
#SPLIT_CODE="/pancanfs/software/bam_split.py"
SPLIT_CODE="/agua/apps/bioapps/bin/pancancer/bam_split.py"

while :
do
	echo "Scanning"
	UUID=`$SYN_MONITOR getAssignmentForWork ucsc_biofarm downloaded`
	if [ $? != 0 ]; then 
		echo "Done, exiting"
		exit 0
	else
		echo Splitting $UUID
    	if [ -e /pancanfs/input/$UUID ]; then
    		BAM_FILE=`ls /pancanfs/input/$UUID/*.bam`
#    		sudo docker run -v /pancanfs:/pancanfs -v /mnt:/mnt icgc-aligner $SPLIT_CODE $BAM_FILE /pancanfs/splits/$UUID --workdir /mnt/$UUID
    		$SPLIT_CODE $BAM_FILE /pancanfs/splits/$UUID --workdir /mnt/$UUID

			if [ $? != 0 ]; then 
				$SYN_MONITOR errorAssignment $UUID "splitting error"
			else
				$SYN_MONITOR returnAssignment $UUID		
			fi
		fi
	fi
done
