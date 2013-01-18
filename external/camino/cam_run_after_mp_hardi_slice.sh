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
# These variables are simpe derivations from cmd line
REID="`StringZeroPad $RE 2`"
TMP="tmpPAS${REID}"
LOGROOT="${TMP}/hardi_slice_output_"

echo 'Pooling together separate processor results... '
echo "cat ${TMP}/*PAS${REID}_PDs.Bdouble > PAS${REID}_PDs.Bdouble"
cat ${TMP}/*PAS${REID}_PDs.Bdouble > PAS${REID}_PDs.Bdouble

echo 'Starting pdview visualization of results... '
echo "pdview -inputmodel pds -datadims ${XSIZE} ${YSIZE} ${ZSIZE} -scalarfile fa.nii.gz < PAS${REID}_PDs.Bdouble"
pdview -inputmodel pds -datadims ${XSIZE} ${YSIZE} ${ZSIZE} -scalarfile fa.nii.gz < PAS${REID}_PDs.Bdouble
