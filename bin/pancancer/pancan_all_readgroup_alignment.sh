#!/bin/bash

ALIGN=/pancanfs/software/pancan_readgroup_alignment.sh

UUID=$1

INPUT_BASE=/pancanfs/splits
OUTPUT_BASE=/pancanfs/output

if [ ! -e $OUTPUT_BASE/$UUID ]; then
	mkdir $OUTPUT_BASE/$UUID
fi

for BAM in $INPUT_BASE/$UUID/*.bam; do
#	sudo docker run -v /pancanfs:/pancanfs icgc-aligner $ALIGN $BAM $OUTPUT_BASE/$UUID/`basename $BAM`
	$ALIGN $BAM $OUTPUT_BASE/$UUID/`basename $BAM`
done