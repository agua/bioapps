#!/bin/bash

UUID=$1
BAM_FILE=$2


SPLIT_DIR=/pancanfs/splits


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


while read RG_LINE; do 
	RG=`echo $RG_LINE | sed 's/^.*ID:\([^ tab]\+\).*$/\1/'`
	FA_1=$SPLIT_DIR/$UUID/${RG}_1.fq
	FA_2=$SPLIT_DIR/$UUID/${RG}_2.fq
	if [ ! -e $FA_1 ]; then 
		echo MISSING $FA_1 
	fi 
	if [ ! -e $FA_2 ]; then 
		echo MISSING $FA_2 
	fi
	echo "$RG_LINE" > $SPLIT_DIR/$UUID/${RG}.rg_info
done <<EOT
$(samtools view -H $BAM_FILE | grep "^@RG")
EOT
