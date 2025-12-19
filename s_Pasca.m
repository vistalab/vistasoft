%{
MR acquisition parameters:
fMRI: T2star FID EPI
      TR/TE = 1000/11.5 ms, 600 repetitions, BW=300 KHz, FOV=18x x13 mm2, matrix 90 x 65 (200 um in-plane resolution), Slice thk=0.5mm, 28 interleaved slices. 
      2nd order map shim B0 map. 3 FOV Sat bands

There is also a resolution matching T2w (200 x 200 x 500 um3) and 
              a high resolution T2w (100 x 100 x 300 um3) 
for template co-registration.

Re: Gari
DTI: B=1000 s/mm2, 40 dirs, small delta = 4.5 ms, large delta = 10.3 ms, 5 A0 images, same 2nd order shim as fMRI.
     TR/TE = 3500/21 ms,  BW250 KHz, FOV=18x x15 mm2, matrix 120 x 100 (150 x 150 in-plane resolution). 4 segment EPI

%}

% From the office
%{
pascaData = '/Users/wandell/Library/CloudStorage/GoogleDrive-wandell@stanford.edu/My Drive/Data/MRI_Pasca/flywheel/pasca/Kaganovsky-Pasca/Apallial_20_R1F/Pasca_Apallial_20_R1F_9-9-24 - 240909094232';
%}
% From home
%{
pascaData = '/Users/wandell/Library/CloudStorage/GoogleDrive-wandell@stanford.edu/My Drive/Data/MRI_Pasca/flywheel/pasca/Kaganovsky-Pasca/Apallial_20_R1F/Pasca_Apallial_20_R1F_9-9-24 - 240909094232';
%}

chdir(pascaData)

% I think the low res matches the bold (see above).

% For an anatomical, look at this
cd ../5_T2w_highres/
fname = '1_5_T2w_HR_100x100x300_E4_multiframe_5_T2w_highres_20240909094232_40001.nii.gz';
high_res_anat = niftiRead(fname);
niftiView(high_res_anat,'slice',10);

% Here is the BOLD data
cd ../T2star_FID_EPI_300KHz_200micron/
fname = '1_T2star_FID_EPI_300KHz_200micron_E2_multiframe_T2star_FID_EPI_300KHz_200micron_20240909094232_20001.nii.gz';
boldData = niftiRead(fname);
size(boldData);

% The low_res anatomical should match the bold
cd ../4_T2w_lowres
fname = '1_4_T2w_200x200x500_E5_multiframe_4_T2w_lowres_20240909094232_50001.nii.gz';
low_res_anat = niftiRead(fname);
niftiView(low_res_anat,'slice',10);

%%