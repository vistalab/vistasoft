#!/usr/bin/env bash 

# Command line variables
PROC=$1

# Variables that change
RE=16
BGTHRESH=200
XSIZE=128
YSIZE=141
ZSIZE=30
COMPONENTS=130
SCHEMEFILE="b04609.scheme1"
NUMPROC=1
VX=50
VY=84
VZ=19

# Don't change below
REID="`StringZeroPad $RE 2`"
TMP="tmpPAS${REID}"

VXNUM="`StringZeroPad $VX 3`"
VYNUM="`StringZeroPad $VY 3`"
VZNUM="`StringZeroPad $VZ 3`"

mkdir ${TMP}

shredder $((${COMPONENTS}*${XSIZE}*${YSIZE}*${VZ}*4 + ${COMPONENTS}*${XSIZE}*${VY}*4 + ${COMPONENTS}*${VX}*4)) $((${COMPONENTS}*4)) $((${COMPONENTS}*${XSIZE}*${YSIZE}*${ZSIZE}*4)) < raw.Bfloat > ${TMP}/raw_Voxel_${VXNUM}_${VYNUM}_${VZNUM}_${PROC}.Bfloat

mesd -schemefile ${SCHEMEFILE} -filter PAS 1.4 -fastmesd -mepointset $RE -bgthresh ${BGTHRESH} < ${TMP}/raw_Voxel_${VXNUM}_${VYNUM}_${VZNUM}_${PROC}.Bfloat > ${TMP}/raw_Voxel_${VXNUM}_${VYNUM}_${VZNUM}_${PROC}_PAS${REID}.Bdouble

sfpeaks -schemefile ${SCHEMEFILE} -inputmodel maxent -filter PAS 1.4 -mepointset $RE -inputdatatype double < ${TMP}/raw_Voxel_${VXNUM}_${VYNUM}_${VZNUM}_${PROC}_PAS${REID}.Bdouble > ${TMP}/raw_Voxel_${VXNUM}_${VYNUM}_${VZNUM}_${PROC}_PAS${REID}_PDs.Bdouble
