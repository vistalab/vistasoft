% Venogram alignment code
%
% 8/2009 JW
% TODO: Make this a proper function
%
% Background:
% The venograms we currently use are 3D-phase contrast gradient echo scans.
% They are often abbreviated 3DPC in the literature and in the scanner.
% These scans are contrast scans. The scanner produces two sets of images,
% one showing the contrast and the other showing the magnitude. Typically
% all of the images are outputted to the same directory. Dicom images
% [1:n/2-1] are the contrast images, which highlight bloodflow. The second
% set of dicoms, images [n/2:n], comprise the magnitude image. In addition
% to the venogram, we also acquire a quick t1 reference anatomy, usually
% with the same coverage (slice presrciption) as the venogram. The venogram
% and the reference anatomy typically only cover the back of the brain.
%
% Instructions:
% Before doing the alignment, locate the folder with the veogram dicoms
% (probably called 3DPC). Copy the first half of the images to a direcotry
% called 'Venogram'. Copy the second half of the images to a directory
% called 'VenogramAnat'.
%
% Notation:
% Once you have split the 3DPC scan into two directories, we refer to the
% first set of images (or the nifti that the images will become) as the
% 'venogram'. We refer to the second set of images as the 'venogram
% anatomy' or 'venogramAnat' becomes it comes from the venogram scan but
% shows background anatomical structure. We refer to the SPGR T1-anatomical
% scan as the 'reference anatomy' or 'refAnat'. Finally, we refer to the
% stored, hi-resolution t1 anatomy simply as the 't1' or the 'stored t1'.
%
% Decisions:
% (1) We can align either the reference antomy or the venogram antomy to
% the t1. The advantage of the venogram anatomy is that it has the same
% distortions as the venogram and it is guaranteed to be aligned with it.
% The advantage of the reference anatomy is that it has the same
% distortions as the stored t1, and it also has gray-white structure. Try
% both.
% (2) We do the alignment either with spm regisgration tools, using the
% wrapper function mrAnatMultiAcpcNifti, or mrRx tools. The advantage of
% the spm tools is that the method is automated. It will find an alignment,
% then apply it to the reference antomy and the venogram and then we are
% done. The disadvantage is that it might not work if the reference anatomy
% does not cover the whole brain. It might also be off by a few mm in the
% solution if there are different distortions in the reference anatomy and
% the venogram. The other option is to use mrRx tools, which generally
% involves an intitial coare alignment done manually by the user, followed
% by Nestares algorithm or a mutual information algorithm. In short, try
% both and see which works better.
%

%% Directories
% parentDir:
%   The directory where all the venogram scans live.
% dicomRefAnatDir:
%   The direcotry containing dicom files from t1-SPGR anatomy (the
%   reference anatomy).
% dicomVenogramDir:
%   The direcotry containing dicom files from the FIRST HALF of the venogram
%   (3D PhaseContrast).These are the key dicoms that actually show the
%   vessels.
% dicomVenogramAnatDir:
%   The directory containing dicom files from SECOND half of the venogram.
%   As discussed above, we may or may not use these. They are a crude
%   anatomy that is perfectly aligned to the venogram.
% t1
%   Path to the stored, hi-resoution t1 anatomy. This must be a NIFTI file.

parentDir            = uigetdir('/biac2/wandell2/data/anatomy/', 'Select the parent directory');
dicomRefAnatDir      = uigetdir(parentDir, 'Select DIR with Ref Anatomy');
dicomVenogramDir     = uigetdir(parentDir, 'Select DIR with venogram dicoms (FIRST half of the dicom images)');
dicomVenogramAnatDir = uigetdir(parentDir, 'Select DIR with venogram anatomy (SECOND half of the dicom images)');

cd (parentDir);
opts = {'*.nii;*.nii.gz', 'NIFTI files (*.nii,*.nii.gz)'; '*.*','All Files (*.*)'};
[f, p]               = uigetfile(opts, 'Select stored t1 file');
t1 = fullfile(p,f);

%% (1) Convert DICOMs to NIFTI
niftiRefAnat        = niftiFromDicom(dicomRefAnatDir,dicomRefAnatDir);
niftiVenogram       = niftiFromDicom(dicomVenogramDir, dicomVenogramDir);
niftiVenogramAnat   = niftiFromDicom(dicomVenogramAnatDir, dicomVenogramAnatDir);


%% (2) Reslice NIFTIs to resolution of stored t1-anatomy
ni = niftiRead(t1);
res = ni.pixdim; clear ni;

% paths to resliced niftis from venogram (resolution of stored t1)
reslicedRefAnat         = 'reslicedRefAnat.nii.gz';
reslicedVenogram        = 'reslicedVenogram.nii.gz';
reslicedVenogramAnat    = 'reslicedVenogramAnat.nii.gz';

mrAnatResampleT1(niftiRefAnat, reslicedRefAnat, res);
mrAnatResampleT1(niftiVenogram, reslicedVenogram, res);
mrAnatResampleT1(niftiVenogramAnat, reslicedVenogramAnat, res);

%% Align
% Note that there are two decisions to make.
%
% (1) Which anatomical file should we use as the reference volume for the
% alignment to the stored t1? One option is the ref t1-antomy acquired at
% the same time as the venogram. The other option is to use the anatomical
% images from the venogram itself. This set can be used for the alignment).
% The advantage of using the reference antomy  is that it has high contrast
% and should align well to the stored t1. The advantage of using the
% venogram anatomy is that is perfectly aligned to the venogram.
alignedRefAnat      = 'refAnatAlignedtoT1.nii.gz';
alignedVenogram     = 'venogramAlignedtoT1.nii.gz';
alignedVenogramAnat = 'venogramAnatAlignedtoT1.nii.gz';


% Decisions:
% Try either 3a or 3b. They are alternate methods, not a sequence of steps.
% Also, you might modify the code to use the venogramAnat instead of the
% refAnat for the alignment. This applies to either alignment procedure.

% **********************************************************************
% (3a) Align venogram to t1 using SPM tools
% **********************************************************************

% start with the resliced files
filesToAlign{1} = reslicedRefAnat; % note: put t1 anat in as first arg because we want to use this one for the alignment!
filesToAlign{2} = reslicedVenogram;
filesToAlign{3} = reslicedVenogramAnat;

% set outpaths for the 3 aligned files
alignedFiles{1}  = alignedRefAnat;
alignedFiles{2}  = alignedVenogram;
alignedFiles{3}  = alignedVenogramAnat;

% do the alignment
mrAnatMultiAcpcNifti(filesToAlign, alignedFiles, t1, res);


% **********************************************************************
% (3b) Align venogram to t1 using mrRx tools
% **********************************************************************

% Do the alignment manually in mrRx
mrRx(reslicedRefAnat, t1, 'volRes', res, 'refRes', res);

% Once you are happy with the alignment
rxSaveSettings([],'venogramAlignmentSettingsMrRx');


% optionally, we can store the transformed volume (we really only need the
% transformed volume for the venogram though)
rxSaveVolume(rx, alignedRefAnat, 'nifti')

% Close mrRx
rxClose;

% Now appy the same settings to the venogram and venogram anat files
for ii = 1:2;
    % choose a file
    if ii == 1,
        toAlign = reslicedVenogramAnat;
        aligned = alignedVenogramAnat;

    else
        toAlign = reslicedVenogram;
        aligned = alignedVenogram;
    end

    % open mrRx with the saved settings
    mrRx(toAlign, t1, 'volRes', res, 'refRes', res);
    rx = rxLoadSettings([], 'venogramAlignmentSettingsMrRx');

    % save the venogram with the new settings
    rxSaveVolume(rx,aligned,'nifti')

    % close mrRx
    rxClose;

    % copy the nifti fields from the t1
    ni  = niftiRead(aligned);
    ni2 = niftiRead(t1);
    ni3 = ni2;
    ni3.data = ni.data;
    ni3.fname = ni.fname;
    writeFileNifti(ni3);

end




%% Text from: http://spinwarp.ucsd.edu/NeuroWeb/Text/MR-ANGIO.htm
% ***2D Phase Contrast
%
%       Phase contrast (PC) methods use an entirely different technique to
%       generate vascular contrast. Following the initial 90o rf pulse,
%       bipolar phase-encoding gradients are applied separately along the
%       three axes to impart phase shifts to moving protons. Protons in
%       stationary tissues acquire no net phase change with the bipolar
%       gradient pulses, but flowing protons within vessels accumulate
%       phase as they move through the gradient fields. For a second
%       excitation, the polarity of the bipolar gradient is inverted. A
%       vector subtraction technique essentially eliminates background
%       signal, yielding high contrast angiograms with PC methods.
%
%       Another important parameter in PC is the velocity encoding (VENC)
%       factor, which can be set to select out arteries or veins. Higher
%       VENC factors (60-80 cm/sec) will selectively image the arteries,
%       whereas a VENC factor of 20 cm/sec will highlight the veins and
%       sinuses.
%
%       2D PC collects and displays data as a series of thick slices or a
%       single slab. The data is not processed by the MIP algorithm but
%       rather viewed as a single projection in the plane of acquisition,
%       similar to a collapse image. One major benefit of this MRA sequence
%       is that the phase images can be displayed to show direction of
%       flow. This information may be useful for assessing collateral flow
%       about the circle of Willis in cases of carotid or vertebrobasilar
%       occlusive disease or for showing direction of flow to and from
%       AVMs. Potentially more important, PC sequences can quantify
%       velocities within a vessel. If the cross-sectional area is
%       measured, flow can be calculated. Flow data is valuable for
%       assessing occlusive vascular disease Endnote and likely will have a
%       role in measuring blood flow to AVMs before and following partial
%       resection, embolization, or radiation therapy.
%
% *** 3D Phase Contrast
%
%       3D PC is similar to 2D except that volume acquisition is employed,
%       multiple thin slices (0.7-1.0 mm) are stacked, and the MIP
%       algorithm is used to generate projection angiograms from multiple
%       angles. By using short TRs and lower flip angles (15-20 degrees),
%       the entire head can be imaged with relatively little signal loss
%       from saturation effects, but the imaging times can be quite long
%       (20-30 minutes). Usually, the volume size is limited to the region
%       of interest to maintain reasonable imaging times. Visualization of
%       more distal smaller arteries can be improved with Gd-enhancement
%       without the offsetting effect of increased signal from stationary
%       tissues observed with TOF techniques.
