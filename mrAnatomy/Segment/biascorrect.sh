#!/bin/csh
if ($#argv < 1) then # must have at least  1 argument
echo ""
echo "Usage: bias_correct niftiVolumeRoot [betLevel]"
echo " (do not use the .hdr or .img suffixes on the rootnames)"
echo ""
echo "example:"
echo "biascorrect origVolumeName"
echo "Requires FSL 4.0 or better"
echo "Original version. KS 2006?"
echo "Last modified 111607 ARW"

exit 1
endif

set betLevel = 0.3;

if ($#argv == 2) then
set betLevel = ${2};
endif


set date = (`date "+%Y%m%d%I%M"`)
set stripvolume = bc_strip$date
set multvolume = bc_mult$date
echo "Skullstripping" ${1}.nii
echo " "
bet ${1}.nii ${stripvolume}.nii -B -f ${betLevel} # Note: This is the FSL4 BET routine. The output (with the -B) option is already bias corrected.
					  # We use the -B to take care of hard skull stripping tasks around the neck. But we have to do the next
					  # step in order to compute the real bias field.

echo "Masking original volume"
echo " "
fslmaths ${1}.nii -mas ${stripvolume}_mask.nii ${stripvolume} # replace the original skull stripped brain with the non-bias corrected one.
 
echo "Running Fast"
echo " "
fast -l 100 -i 8 -oba 100 ${stripvolume}
echo "Done"
echo "Applying final multiplicative bias correction"
# Apply the bias correction
fslmaths -dt float ${1} -mul ${stripvolume}_bias ${multvolume}


# Uncomment this last bit (and set a reasonable reference volume) if you want to add a 6DOF alignment to 
# a reference brain. It makes some sense to do this here while we have access to both the bias-corrected whole head and
# also the skull-stripped brain.

# Do the registration to a reference brain . 6 DOF only
#set outRegBrain = bc_regBrain$date
#set refBrainName = "/raid/MRI/toolbox/FSL/REFImages/meanhumanBrainRef.nii"
#echo "Computing registration of brain to reference brain" ${refBrainName}
# Note the -usesqform flag here. Very important.
#flirt -in ${stripvolume}.nii -ref ${refBrainName} -out ${outRegBrain}.nii -dof 6 -usesqform -omat  ${outRegBrain}.mat
# Apply that registration to the original (bias corrrected) volume
#echo "Applying xform to bias-corrected data"
#flirt -in ${multvolume} -ref ${refBrainName} -out ${1}_final.nii -applyxfm -init ${outRegBrain}.mat -interp sinc 


