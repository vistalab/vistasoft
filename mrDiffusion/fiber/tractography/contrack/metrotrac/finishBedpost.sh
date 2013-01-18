#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: ${0} bedpost_directory"
else
    avwmerge -z $1.bedpost/merged_thsamples `imglob -oneperimage $1.bedpost/diff_slices/data_slice_*/th_samples`
    avwmerge -z $1.bedpost/merged_phsamples `imglob -oneperimage $1.bedpost/diff_slices/data_slice_*/ph_samples`
    avwmerge -z $1.bedpost/merged_fsamples `imglob -oneperimage $1.bedpost/diff_slices/data_slice_*/f_samples`

    avwmaths $1.bedpost/merged_thsamples -Tmean $1.bedpost/mean_thsamples
    avwmaths $1.bedpost/merged_phsamples -Tmean $1.bedpost/mean_phsamples
    avwmaths $1.bedpost/merged_fsamples -Tmean $1.bedpost/mean_fsamples

    make_dyadic_vectors $1.bedpost/merged_thsamples $1.bedpost/merged_phsamples $1.bedpost/nodif_brain_mask $1.bedpost/dyadic_vectors
fi
