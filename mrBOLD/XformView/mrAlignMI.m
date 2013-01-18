function xform = mrAlignMI(sessionDir, vAnatFile, inplaneFile, initXFM, nuCorrect, forceSave)
% function xform = mrAlignMI(sessionDir, vAnatFile, inplaneFile, initXFM, nuCorrect, forceSave)
%
% * sessionDir is where the relevent mrSESSION lives. Defaults to pwd.
%
% * vAnatFile: default is a file browser if it's not found in the usual places.
%
% * inplaneFile: we currently need the first and last slice from the original
% inplane data to compute the coarse alignment. In the future, this info
% should be stored in the Inplane/anat.mat file.
%
% * initXFM : define [x y z] translations (first 3 params of the
% terminal output) from the automatically  computed coarse
% alignment. This is usuful when the algorithm  converges to an
% obviously wrong location (local minima) by allowing a different
% starting position.
%
% forceSave: flag to force saving computed xofrm to the mrSESSION file.
% Default is to show the computed alignment and then ask the user if they
% want to save.
%
% Tries to compute an inplane-to-vAnatomy alignment fully automatically.
% The core algorithm is quite simple (once you get past the file management
% stuff). It generates a coarse alignment by:
%  1. assuming that the vAnatomy is in the standard vAnatomy orientation
%     (sagittal, left-is-left, yxz, etc), and
%  2. using the original inplane header info to bring the inplane into a
%     standard orientation.
% It then uses a rigid body mutual information registration algorithm (from
% spm2) to refine the alignmnet.
%
% It seems to work perfectly when you have non-surface coil, whole-brain or
% most-brain data. YMMV with other data varieties.
%
% HISTORY:
% 2005.05.27 RFD (bob@sirl.stanford.edu) wrote it.
% 2005.06.27 RFD: slight changes to allow gzipped I-files.
% 2005.10.60 SOD: modified so it can refine existing mrSESSION.alignment's,
% put in a correction for an intensity gradient which seems
% to improve the alignment for surface-coil data, and put in
% another check that i foud useful. They come unfortenately with
% two more dialogs.
% 2006.04.03 SOD: added initXFM option


if(isempty(which('spm_coreg')))
    error('Requires spm2 tools! Try adding .../matlab/toolbox/mri/spm2 to your path.');
end
if(~exist('sessionDir','var') || isempty(sessionDir))
    sessionDir = pwd;
end
if(~exist('forceSave','var') || isempty(forceSave))
    forceSave = false;
end
if (~exist('nuCorrect','var') || isempty(nuCorrect))
    nuCorrect = [];
end
loadSession(sessionDir);
global HOMEDIR;
HOMEDIR = sessionDir;
global mrSESSION;
if(~exist('vAnatFile','var') || isempty(vAnatFile))
    % Try to find it
    vAnatFile = getVAnatomyPath;
end
if(~exist('inplaneFile','var') || isempty(inplaneFile))
    % Try to find it
    inplaneDir = fullfile(sessionDir,'Raw','Anatomy','Inplane');
    d = dir(fullfile(inplaneDir, 'I*001*'));
    if ~isempty(d), % ie any Ifiles are found
        inplaneFile = fullfile(inplaneDir, d(1).name);
        if(~exist(inplaneFile,'file'))
            [f,p] = uigetfile({'*.dcm','Dicom';'*.001','I-file';'*.gz','gzipped';'*.*','all'}, ...
                'Select a slice from raw Inplane files...', inplaneFile);
            if(isequal(f,0) || isequal(p,0))
                disp('User canceled.'); return;
            else
                inplaneFile = fullfile(p,f);
            end
        end;
    end
end
inplaneAnatFile = fullfile(sessionDir,'Inplane','anat.mat');
if(~exist(inplaneAnatFile,'file'))
    [f,p] = uigetfile({'*.mat','mat';'*.*','all'}, ...
        'Select the Inplane anat.mat file...', inplaneAnatFile);
    if(isequal(f,0) || isequal(p,0))
        disp('User canceled.'); return;
    else
        inplaneAnatFile = fullfile(p,f);
    end
end
disp(inplaneAnatFile);
disp(vAnatFile);

% check if alignment exists and give option to use this as a
% starting point allowing refinements of an existing alignment
% only do this if no initXFM is defined
useStartingEstimate = 0;
if notDefined('initXFM'),
    if isfield(mrSESSION,'alignment'),
        bn = questdlg(['mrSESSION.alignment exists. Do you want to to use ' ...
            'it as a starting estimate?'],...
            'starting estimate','Yes','No','No');
        if strmatch(bn,'Yes'),
            useStartingEstimate = 1;
        end;
    end;
end;

[v.img,v.mm] = readVolAnat(vAnatFile);
sz = size(v.img);
% Build a very rough xform to axial, ac-pc space
hsz = sz./2;
% ***FIXME: I'm not sure the v.mm is correct here. I've only tested it on
% isotropic data so far, so I can't tell.
vAnatAcpcXform = [0 0 v.mm(3) -hsz(3); 0 -v.mm(2) 0 hsz(1); -v.mm(1) 0 0 hsz(2); 0 0 0 1];
VF.uint8 = uint8(v.img);
VF.mat = vAnatAcpcXform;

ip = load(inplaneAnatFile);
% Correct for intensity gradient.
% yet another anoying dialog, sorry...
% For surface-coil data the results look better with correction - at
% least for the subject I tested.
if isempty(nuCorrect),
    bn = questdlg('Do you want to correct for an intensity gradient?',...
        'intensity gradient','Yes','No','No');
    if strmatch(bn,'Yes'),
        nuCorrect = true;
    else
        nuCorrect = false;
    end
end
if nuCorrect,
    [GradInt GradNoise]  = regEstFilIntGrad(ip.anat);
    ip.anat              = regCorrIntGradWiener(ip.anat,GradInt,GradNoise);
end;

% **** FIXE ME: we should compute and store the cannonical xform when we
% create the anat.mat file. Also, we can do a bit better for the initial
% alignment by taking the crop into account in the translations.
%sz = size(ip.anat);
% We assume that the brain is centered in the crop region.
%cropOffset = ip.inplanes.crop(1,:)-(ip.inplanes.fullSize-diff(ip.inplanes.crop))/2;
%cropOffset = ip.inplanes.crop(1,[2,1]); % OK
% apparently ip.inplanes.crop will not exist for older versions
if ~isfield(ip,'inplanes'),
    sz               = size(ip.anat);
    ip.inplanes.crop = [1 1;sz(1) sz(2)];
end
% not used?!
%cropOffset = [ip.inplanes.crop(1,[2,1])./2 0];%4 (best?)
%cropOffset = [eye(3) cropOffset'; 0 0 0 1];


% If Ifiles exist use them for an initial xform otherwise center on 0.
if ~ieNotDefined('inplaneFile'),
    xformToScanner = inv(computeXformFromIfile(inplaneFile,ip.inplanes.crop));
    xformToScanner(1:3,4) = xformToScanner(1:3,4)+[10 -20 -20]';
    % GE convention is right-to-left, but we want l-to-r (Talairach convention)
    %lrFlip = [-1 0 0 ip.inplanes.fullSize(1); 0 1 0 0; 0 0 1 0; 0 0 0 1];
    %lrFlip = [-1 0 0 0; 0 1 0 0; 0 0 1 0; 0 0 0 1];
    VG.mat = xformToScanner;
else
    % default xform (center on 0,0,0)
    disp(sprintf('[%s]:No Ifiles found centering volume on 0.',mfilename));
    voxSize = mrSESSION.inplanes.voxelSize;
    VG.mat = [diag(voxSize),-(size(ip.anat)'.*voxSize'./2); 0 0 0 1];
    % GE convention is right-to-left, but we want l-to-r (Talairach
    % convention)
    % Careful! If you rerun you don't want to keep flipping your image
    % all the time
    VG.mat(1,:) =  -VG.mat(1,:);
    %VG.mat(2,:) =  -VG.mat(2,:);
    %VG.mat(3,:) =  -VG.mat(3,:);
    VG.mat
end;
%ip.anat = mrAnatHistogramClip(ip.anat, 0.4, 0.99);
ip.anat = mrAnatHistogramClip(ip.anat, 0.2, 0.99);
VG.uint8 = uint8(ip.anat*255+0.5);

if useStartingEstimate,
    revAlignment = spm_imatrix(VF.mat*mrSESSION.alignment/VG.mat);
    flags.params = revAlignment(1:6);
    disp('flags.params :');disp(flags.params);
    flags.sep    = [8 4 2 1];
    rotTrans     = spm_coreg(VG,VF,flags);
    oldAlignment = mrSESSION.alignment;
    disp('Old alignment :');disp(oldAlignment);
else
    % allow manually reset of the starting position
    if ~exist('initXFM','var')
        initXFM =[];
    end
    % max 6 params if less fill with zeros
    if numel(initXFM) < 6,
        flags.params = [initXFM(:)' zeros(1,6-numel(initXFM))];
    else
        flags.params = initXFM;
    end;
    % for dire need
    flags.sep    = [16 8 4 2];
    rotTrans     = spm_coreg(VG,VF,flags);
end;
%xform = spm_matrix(rotTrans)*VG.mat\VF.mat;
% volCoords = xform*[inplaneCoords]
alignment = VF.mat\spm_matrix(rotTrans)*VG.mat;
disp('Alignment matrix :');disp(alignment);

% output
xform = alignment;

sz = size(v.img);
bb = [1,1,1; sz];
ipVol = mrAnatResliceSpm(ip.anat, inv(alignment), bb, [1 1 1], [1 1 1 0 0 0], 0);
ipVol(isnan(ipVol)) = 0;
if(forceSave)
    % Save an image so user can check the alignment
    volIm = makeMontage(v.img); volIm = volIm./255;
    ipIm = makeMontage(ipVol);
    ipIm(ipIm<0)=0;ipIm(ipIm>1)=1;
    ipIm = cat(3,ipIm,volIm,volIm);
    imwrite(ipIm, fullfile(sessionDir,'align.png'));
    % just save it to existing mrSESSION
    mrSESSION.alignment = alignment;
    saveSession;
    % Delete old files that were built using previous alignment.
    cleanAllFlats; cleanGray; cleanVolume;
else
    disp('checking alignment...');
    % another check that i (SOD) found usefull
    % coronal (rotated...)
    % overlayVolumes(shiftdim(ipVol,2),shiftdim(v.img,2));
    % sagittal
    overlayVolumes(ipVol,v.img);
    % horizontal
    overlayVolumes(shiftdim(ipVol,1),shiftdim(v.img,1));

    volIm = makeMontage(v.img,40:9:sz(3)-40); volIm = volIm./255;
    if ~useStartingEstimate,
        ipVolInitial = mrAnatResliceSpm(ip.anat, inv(VF.mat\eye(4)*VG.mat), ...
            bb, [1 1 1], [1 1 1 0 0 0], 0);
        titlestring  = 'Initial coarse alignment';
    else
        ipVolInitial = mrAnatResliceSpm(ip.anat, inv(oldAlignment), ...
            bb, [1 1 1], [1 1 1 0 0 0], 0);
        titlestring  = 'Initial alignment from mrSESSION.alignment';
    end;
    ipVolInitial(isnan(ipVolInitial)) = 0;
    %figure;imagesc(makeMontage(ipVolInitial));axis equal;
    ipIm = makeMontage(ipVolInitial,40:9:sz(3)-40);
    ipIm(ipIm<0)=0;ipIm(ipIm>1)=1;
    figure;
    subplot(2,1,1);
    image(cat(3,ipIm,volIm,volIm)); axis equal tight off;
    title(titlestring);
    subplot(2,1,2);
    ipIm = makeMontage(ipVol,40:9:sz(3)-40);
    ipIm(ipIm<0)=0;ipIm(ipIm>1)=1;
    image(cat(3,ipIm,volIm,volIm)); axis equal tight off;
    title('Final alignment');



    [f,p] = uigetfile('*.mat','Save alignment to mrSESSION file?',fullfile(sessionDir,'mrSESSION.mat'));
    if(isequal(f,0)||isequal(p,0))
        error('Cancelled- alignment NOT SAVED.');
    else
        mrSESSION.alignment = alignment;
        saveSession;
        % Delete old files that were built using previous alignment.
        cleanAllFlats; cleanGray; cleanVolume;
    end
end
return;
