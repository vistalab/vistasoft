# This script will (1) run FreeSurfer Segmention and Parcellation,
# (2) write these files out into nifti format, and (3) pull out 
# desired parcellation labels and convert them to binary nifti masks.
#
# Written by ER and AK (2010)
#
#
#from http://www.fmrib.ox.ac.uk/fsl/freesurfer/index.html
#
###############
# Point to FreeSurfer Software:
#
export FREESURFER_HOME=/white/u8/lmperry/software/freesurfer
source $FREESURFER_HOME/SetUpFreeSurfer.sh

###############
# 1. Run the segmentation and parcellation:
#
#Display freesurfer segmentation in FSLVIEW
#Instructions here http://www.fmrib.ox.ac.uk/fsl/freesurfer/index.html

export SUBJECTS_DIR=/biac3/wandell4/data/reading_longitude/freesurfer
datadir=/biac3/wandell4/data/reading_longitude/dti_y1

subjects=(lj); 
for s in ${subjects[@]} 
do
subjID=` ls ${datadir}/${s}??????/t1/t1.nii.gz | sed 's/\/t1\/t1.nii.gz//g' |sed 's/\/biac3\/wandell4\/data\/reading_longitude\/dti_y1\///g'
`;
recon-all -i ${datadir}/${s}??????/t1/t1.nii.gz -subjid $subjID -all & # add '&' to run it in parallel (take out if executing entire script)
done


############# 
# 2. Convert it to NIFTI

#
cd /biac3/wandell4/data/reading_longitude/freesurfer
subjects=(ctr jt lj); 
for s in ${subjects[@]} 
do
subjID=` ls ${datadir}/${s}??????/t1/t1.nii.gz | sed 's/\/t1\/t1.nii.gz//g' |sed 's/\/biac3\/wandell4\/data\/reading_longitude\/dti_y1\///g'`;
mri_convert --out_orientation RAS  -rt nearest   --reslice_like /biac3/wandell4/data/reading_longitude/dti_y1/${subjID}/t1/t1.nii.gz ${subjID}/mri/aseg.mgz ${subjID}/mri/aseg.nii
mri_convert --out_orientation RAS  -rt nearest   --reslice_like /biac3/wandell4/data/reading_longitude/dti_y1/${subjID}/t1/t1.nii.gz ${subjID}/mri/aparc+aseg.mgz ${subjID}/mri/aparc_aseg.nii
done


############# 
# 3.Pull out parcellation labels and convert to nifti (binary mask)
#
#!/bin/bash
export FSLOUTPUTTYPE=NIFTI
for file in  /biac3/wandell4/data/reading_longitude/freesurfer/*/mri/aparc_aseg.nii
do
echo $file
fslmaths $file -thr 1015 -uthr 1015 -bin ${file%.nii}1015.nii 
fslmaths $file -thr 1030 -uthr 1030 -bin ${file%.nii}1030.nii 
done

