#!/bin/bash

UUID=$1

INPUT_DIR=/pancanfs/input
OUTPUT_DIR=/pancanfs/output
SPLIT_DIR=/mnt/splits
REF_SEQ=/opt/reference/genome.fa.gz

if [ ! -e $SPLIT_DIR ]; then
	mkdir $SPLIT_DIR
fi

if [ $(ls $INPUT_DIR/$UUID/*.bam | wc -l) != "1" ]; then
	echo $(ls $INPUT_DIR/$UUID/*.bam)
	echo "Unable to find BAM file for $UUID"
	exit 1
fi

BAM_FILE=$(ls $INPUT_DIR/$UUID/*.bam)

DO_SPLIT=0

while read RG_LINE; do 
	RG=`echo $RG_LINE | sed 's/^.*ID:\([^ tab]\+\).*$/\1/'`
	FA_1=$SPLIT_DIR/$UUID/${RG}_1.fq
	FA_2=$SPLIT_DIR/$UUID/${RG}_2.fq
	if [ ! -e $FA_1 ]; then 
		echo MISSING $FA_1 
		DO_SPLIT=1
	fi 
	if [ ! -e $FA_2 ]; then 
		echo MISSING $FA_2 
		DO_SPLIT=1
	fi
done <<EOT
$(samtools view -H $BAM_FILE | grep "^@RG")
EOT

if [ $DO_SPLIT -eq 1 ]; then
	echo "DO_SPLIT"
	if [ ! -e $SPLIT_DIR/$UUID ]; then 
		mkdir $SPLIT_DIR/$UUID
	fi
	bamtofastq filename=$BAM_FILE outputperreadgroup=1 gz=1 level=1 exclude=QCFAIL,SECONDARY,SUPPLEMENTARY outputdir=$SPLIT_DIR/$UUID
	if [ $? != "0" ]; then
		echo "Split Failure"
		rm -rf $SPLIT_DIR/$UUID
		exit 1
	fi
	echo "SPLIT DONE"
else
	echo "Splits Ready" $DO_SPLIT
fi

 
while read RG_LINE; do 
	RG=`echo $RG_LINE | sed 's/^.*ID:\([^ tab]\+\).*$/\1/'`
	FA_1=$SPLIT_DIR/$UUID/${RG}_1.fq
	FA_2=$SPLIT_DIR/$UUID/${RG}_2.fq
	OUTPUT=$OUTPUT_DIR/$UUID.$RG.bam
	echo "Running" $OUTPUT
	bwa mem -t 16 -T 0 -R "$RG_LINE" $REF_SEQ $FA_1 $FA_2 |\
	bamsort inputformat=sam inputthreads=2 outputthreads=2 |\
	bammarkduplicates O=$OUTPUT M=$OUTPUT.metrics markthreads=1 rewritebam=1 rewritebamlevel=1 index=1 md5=1
	if [ $? != "0" ]; then
		echo "Alignment Failure"
		exit 1
	fi
done <<EOT
$(samtools view -H $BAM_FILE | grep "^@RG")
EOT