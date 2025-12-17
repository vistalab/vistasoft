    
% From the office
pascaData = '/Users/wandell/Library/CloudStorage/GoogleDrive-wandell@stanford.edu/My Drive/Data/MRI_Pasca/flywheel/pasca/Kaganovsky-Pasca/Apallial_20_R1F/Pasca_Apallial_20_R1F_9-9-24 - 240909094232';
chdir(pascaData)

cd ../5_T2w_highres/

fname = '1_5_T2w_HR_100x100x300_E4_multiframe_5_T2w_highres_20240909094232_40001.nii.gz';
d = niftiRead(fname);
niftiView(d,'slice',10);

cd ../T2star_FID_EPI_300KHz_200micron/

fname = '1_T2star_FID_EPI_300KHz_200micron_E2_multiframe_T2star_FID_EPI_300KHz_200micron_20240909094232_20001.nii.gz'
boldData = niftiRead(fname);
