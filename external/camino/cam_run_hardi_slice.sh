#!/usr/bin/env bash 

PROC=$1
NUMPROC=$2
RE=$3
XSIZE=$4
YSIZE=$5
ZSIZE=$6
COMPONENTS=$7
BGTHRESH=$8
SCHEMEFILE=$9
REID=${10}
TMP=${11}

SFP_X=$((${XSIZE}*32))
SFP_Y=$((${YSIZE}*32))

# How many processors do we have and will we loop through:
#for ((i=${PROC}; i<=${PROC}; i=i+${NUMPROC})); do
for ((i=${PROC}; i<=${ZSIZE}; i=i+${NUMPROC})); do

    echo
    echo $i
    SNUM="`StringZeroPad $i 2`"
    
    echo "Getting axial slice $i..."     
    echo "shredder $((${COMPONENTS}*${XSIZE}*${YSIZE}*(i-1)*4)) $((${COMPONENTS}*${XSIZE}*${YSIZE}*4)) $((${COMPONENTS}*${XSIZE}*${YSIZE}*${ZSIZE}*4)) < raw.Bfloat > ${TMP}/raw_Slice${SNUM}.Bfloat"
    shredder $((${COMPONENTS}*${XSIZE}*${YSIZE}*(i-1)*4)) $((${COMPONENTS}*${XSIZE}*${YSIZE}*4)) $((${COMPONENTS}*${XSIZE}*${YSIZE}*${ZSIZE}*4)) < raw.Bfloat > ${TMP}/raw_Slice${SNUM}.Bfloat
    echo
    
    echo "Running MESD..."     
    echo "mesd -schemefile ${SCHEMEFILE} -filter PAS 1.4 -fastmesd -mepointset $RE -bgthresh ${BGTHRESH} < ${TMP}/raw_Slice${SNUM}.Bfloat > ${TMP}/raw_Slice${SNUM}_PAS${REID}.Bdouble"
    time mesd -schemefile ${SCHEMEFILE} -filter PAS 1.4 -fastmesd -mepointset $RE -bgthresh ${BGTHRESH} < ${TMP}/raw_Slice${SNUM}.Bfloat > ${TMP}/raw_Slice${SNUM}_PAS${REID}.Bdouble
    echo

    echo "Running SFPEAKS..."
    echo "sfpeaks -schemefile ${SCHEMEFILE} -inputmodel maxent -filter PAS 1.4 -mepointset $RE -inputdatatype double < ${TMP}/raw_Slice${SNUM}_PAS${REID}.Bdouble > ${TMP}/raw_Slice${SNUM}_PAS${REID}_PDs.Bdouble"
    time sfpeaks -schemefile ${SCHEMEFILE} -inputmodel maxent -filter PAS 1.4 -mepointset $RE -inputdatatype double < ${TMP}/raw_Slice${SNUM}_PAS${REID}.Bdouble > ${TMP}/raw_Slice${SNUM}_PAS${REID}_PDs.Bdouble
    echo
    
    echo "Plotting peaks..."
    sfplot -xsize ${YSIZE} -ysize ${XSIZE} -inputmodel maxent -filter PAS 1.4 -mepointset $RE -pointset 2 -minifigsize 30 30 -minifigseparation 2 2 -inputdatatype double -dircolcode -projection 1 2 < ${TMP}/raw_Slice${SNUM}_PAS${REID}.Bdouble > ${TMP}/raw_Slice${SNUM}_PAS${REID}.rgb
    convert -size ${SFP_X}x${SFP_Y} -depth 8 ${TMP}/raw_Slice${SNUM}_PAS${REID}.rgb ${TMP}/raw_Slice${SNUM}_PAS${REID}.png
    echo

done