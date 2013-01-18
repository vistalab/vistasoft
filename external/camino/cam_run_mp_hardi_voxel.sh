#!/usr/bin/env bash 

NUMPROC=$1

for ((p=1; p<=${NUMPROC}; p=p+1)); do
    
    nohup time cam_run_hardi_voxel.sh $p &> hardi_voxel_output_${p}.txt &
    sleep 1;

done
