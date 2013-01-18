#!/usr/bin/env bash 

# Command line
NUMPROC=$1
RE=$2
XSIZE=$3
YSIZE=$4
ZSIZE=$5
COMPONENTS=$6
BGTHRESH=$7
SCHEMEFILE=$8


# Variables that change

#XSIZE=81
#YSIZE=106
#ZSIZE=76
#COMPONENTS=156
#SCHEMEFILE="dti_g150_b2500_aligned_trilin.scheme2"


# These variables are simpe derivations from cmd line
REID="`StringZeroPad ${RE} 2`"
TMP="tmpPAS${REID}"
LOGROOT="${TMP}/hardi_slice_output_"

#I'm going to run the reconstruction separately for each slice, which is useful for generating nice visualizations of the results using sfplot. 
# This directory will contain the output for each slice
mkdir ${TMP}


for ((p=1; p<=${NUMPROC}; p=p+1)); do

    echo "Sending Process ${p} ... output in ${LOGROOT}_${p}.txt ..."    

    nohup time cam_run_hardi_slice.sh $p ${NUMPROC} ${RE} ${XSIZE} ${YSIZE} ${ZSIZE} ${COMPONENTS} ${BGTHRESH} ${SCHEMEFILE} ${REID} ${TMP}  &> ${LOGROOT}_${p}.txt &
    sleep 1;

done

#echo 'When all processes have finished, please run the following: '
#echo "cat ${TMP}/*PAS${REID}_PDs.Bdouble > PAS${REID}_PDs.Bdouble"

#echo 'Then you can visualize the results with the following two lines: '
#echo "pdview -inputmodel pds -datadims ${XSIZE} ${YSIZE} ${ZSIZE} -scalarfile fa.nii.gz < PAS${REID}_PDs.Bdouble"
