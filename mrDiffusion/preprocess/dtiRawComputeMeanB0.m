function [outFile,mnB0] = dtiRawComputeMeanB0(dwRaw, bvals, outFile, doAlign)
%
% [outFile,mnB0] = dtiRawComputeMeanB0([dwRaw=uigetfile], [bvals=uigetfile], outFile, doAlign)
%
% Aligns all the b0 volumes in dwRaw (NIFTI format) to the first
% b0 volume and averages them. The b0 volumes are extracted based
% on bvals==0. If doAlign is set to false, then the b0 volumes are just
% extracted and averaged.
%
% HISTORY:
% 2007.04.23 RFD: wrote it.

% Default is to do the alignment
if ~exist('doAlign','var') || isempty(doAlign)
    doAlign=1;
end

% Initialize SPM default params for the coregistration.
estParams        = spm_get_defaults('coreg.estimate');
estParams.params = [0 0 0 0 0 0];% Rigid-body (6-params)


%% Load the raw DW data (in NIFTI format)
if(~exist('dwRaw','var') || isempty(dwRaw))
    [f,p] = uigetfile({'*.nii.gz;*.nii';'*.*'}, 'Select the raw DW NIFTI dataset...');
    if(isnumeric(f)) error('User cancelled.'); end
    dwRaw = fullfile(p,f);
end
if(ischar(dwRaw))
    % dwRaw can be a path to the file or the file itself
    [dataDir,~] = fileparts(dwRaw);
else
    [dataDir,~] = fileparts(dwRaw.fname);
end
%[~,inBaseName,~] = fileparts(inBaseName);
if(isempty(dataDir)), dataDir = pwd; end

if(~exist('bvals','var') || isempty(bvals))
    bvals = fullfile(dataDir,'bvals');
    [f,p] = uigetfile({'*.bvals';'*.*'},'Select the bvals file...',bvals);
    if(isnumeric(f)), disp('User canceled.'); return; end
    bvals = fullfile(p,f);
end
if(~exist('outFile','var') || isempty(outFile))
    outFile = fullfile(dataDir,'b0.nii.gz');
    [f,p] = uigetfile({'*.nii.gz;*.nii';'*.*'},'Save the mean b0 file here...',outFile);
    if(isnumeric(f)), disp('User canceled.'); return; end
    outFile = fullfile(p,f);
end

if(ischar(dwRaw))
    disp(['Loading raw data ' dwRaw '...']);
    dwRaw = niftiRead(dwRaw);
end

if(dwRaw.qform_code>0)
    xformToScanner = dwRaw.qto_xyz;
elseif(dwRaw.sform_code>0)
    xformToScanner = dwRaw.sto_xyz;
else
    error('Requires that dwRaw qform_code>1 OR sform_code>1.');
end

nvols = size(dwRaw.data,4);
dtMm  = dwRaw.pixdim(1:3);

if(ischar(bvals))
    %bvals = dlmread(bvals, ' ');
    bvals = dlmread(bvals);
end
if(size(bvals,2) < nvols)
    error(['bvals: need at least one entry for each of the ' num2str(nvols) ' volumes.']);
elseif(size(bvals,2)>nvols)
    warning('More bvals entries than volumes- clipping...');
    bvals = bvals(:,1:nvols);
end

interpParams = [1 1 1 0 0 0];
b0AlignSecs = 0;

tic

% Find the indices of the bvals in the nifti image
b0inds = find(bvals==0);

%% Align and average all the b=0 volumes
if doAlign
    mnB0 = double(dwRaw.data(:,:,:,b0inds(1)));
    VG.uint8 = uint8(round(mrAnatHistogramClip(mnB0,0.4,0.99)*255));
    VG.mat = [diag(dtMm), [-[size(VG.uint8)/2].*dtMm]'; 0 0 0 1];
    VF.mat = VG.mat;
    %xform{1} = eye(4);
    bb = [1 1 1; size(mnB0)];
    tic;
    for ii=2:length(b0inds)
        fprintf('[%s] Aligning b=0 volume %d of %d to first b=0 image...\n', mfilename, ii, length(b0inds));
        im = double(dwRaw.data(:,:,:,b0inds(ii)));
        VF.uint8 = uint8(round(mrAnatHistogramClip(im,0.4,0.99)*255));
        % Use evalc to suppress the annoying output from spm_coreg
        xformParams = []; % FP I added this line bacause matlab was complaining of line 97 where xformParasm was addressed without being defined
        msg = evalc('xformParams = spm_coreg(VG,VF,estParams);');
        %xformParams = spm_coreg(VG,VF,estParams);
        %coregSecs(ii-1) = toc;
        b0Xform{ii} = VF.mat\spm_matrix(xformParams(end,:))*VG.mat;
    end
    b0AlignSecs = b0AlignSecs+toc;
    fprintf('[%s] Finished aligning %d vols in %0.1f minutes.\n', mfilename, length(b0inds)-1, b0AlignSecs./60);
    tic
    for ii=2:length(b0inds)
        fprintf('[%s] Resampling b=0 volume %d of %d to first b=0 image...\n', mfilename, ii, length(b0inds));
        im = double(dwRaw.data(:,:,:,b0inds(ii)));
        im = mrAnatResliceSpm(im, b0Xform{ii}, bb, [1 1 1], [1 1 1 0 0 0], 0);
        im(im<0) = 0;
        mnB0 = mnB0+im;
    end
    fprintf('[%s] Finished resampling %d vols in %0.1f seconds.\n', mfilename, length(b0inds)-1, toc);
    mnB0 = mnB0./length(b0inds);
    mnB0(isnan(mnB0)) = 0;
    mnB0 = int16(round(mnB0));
else
    mnB0 = int16(round(mean(dwRaw.data(:,:,:,b0inds),4)));
end
dtiWriteNiftiWrapper(mnB0, xformToScanner, outFile, 1, 'Mean of b0 volumes');
if(nargout<1), clear outFile; end
return;
