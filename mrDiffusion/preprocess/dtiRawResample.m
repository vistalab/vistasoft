function dtiRawResample(dwRaw, ecXformFile, acpcXformFile, outAlignedRaw, bsplineInterpFlag, dwOutMm, bb)
% Resample the diffusion data
%
%   dtiRawResample([dwRaw=uigetfile], [ecXformFile=uigetfile], ...
%      [acpcXformFile=uigetfile], [outAlignedRaw], ...
%      [bsplineInterpFlag=true], [dwOutMm = [2 2 2]], ...
%      [boundingBox=default])
%
% Web resources:
%    mrvBrowseSVN('dtiRawResample')
%
% HISTORY:
% 2007.01.10 RFD: wrote it.
% 2007.06.05 RFD: changed default interpolation to a 7th-order bspline.
% This makes the variance error (described in Rohde et. al, 2006
% Neuroimage.
% 2009.04.22 RFD: removed log(image) interpolation. It's not the right
% thing to do, since the interpolation is trying to guess what would have
% been measured, which is best approximated on the native image
% intensities.
%
% Stanford, VISTA, 2005

% Define the voxel-size of the resliced DW data in millimeters
if(~exist('dwOutMm','var') || isempty(dwOutMm))
    % 2mm isotropic is the default
    dwOutMm = [2 2 2];
end
% If the person sent in just one number, make it isotropic
if(numel(dwOutMm)==1), dwOutMm = [dwOutMm dwOutMm dwOutMm]; end

%% Set defaults
% Initialize SPM default params
%spm_defaults;
%global defaults;
% estParams = defaults.coreg.estimate;

if(~exist('dwRaw','var')||isempty(dwRaw))
    [f,p] = uigetfile({'*.nii.gz;*.nii';'*.*'}, 'Select the raw DW NIFTI dataset...');
    if(isnumeric(f)), error('User cancelled.'); end
    dwRaw = fullfile(p,f);
end
if(ischar(dwRaw))
    % dwRaw can be a path to the file or the file itself
    [dataDir,inBaseName] = fileparts(dwRaw);
else
    [dataDir,inBaseName] = fileparts(dwRaw.fname);
end
[~,inBaseName,~] = fileparts(inBaseName);
if(isempty(dataDir)), dataDir = pwd; end

if(~exist('ecXformFile','var'))
    fn = [fullfile(dataDir,inBaseName) 'EddyCorrectXforms.mat'];
    [f,p] = uigetfile({'*.mat'},'Select an eddy-correct transform file...',fn);
    if(isnumeric(f)), disp('User canceled.'); return; end
    ecXformFile = fullfile(p,f);
end
if(isempty(ecXformFile))
    xform = [];
elseif(ischar(ecXformFile))
    load(ecXformFile);
else
    xform = ecXformFile;
end

if(~exist('acpcXformFile','var')||isempty(acpcXformFile))
    fn = [fullfile(dataDir,inBaseName) 'AcpcXform.mat'];
    [f,p] = uigetfile({'*.mat'},'Select an ac-pc transform file...',fn);
    if(isnumeric(f)), disp('User canceled.'); return; end
    acpcXformFile = fullfile(p,f);
end
if(ischar(acpcXformFile))
    load(acpcXformFile);
else
    acpcXform = acpcXformFile;
end

if(~exist('outAlignedRaw','var') || isempty(outAlignedRaw))
    fn = [fullfile(dataDir,inBaseName) 'Aligned.nii.gz'];
    [f,p] = uiputfile({'*.nii.gz'},'Save aligned output to...',fn);
    if(isnumeric(f)), disp('User canceled.'); return; end
    outAlignedRaw = fullfile(p,f);
end

if(ischar(dwRaw))
    disp(['Loading raw data ' dwRaw '...']);
    dwRaw = niftiRead(dwRaw);
end
nvols = size(dwRaw.data,4);
% dtMm = dwRaw.pixdim(1:3);

if(numel(dwRaw.pixdim)>3), TR = dwRaw.pixdim(4);
else                       TR = 1;
end

% The interpolation method is defined here.
if(~exist('bsplineInterpFlag','var') || isempty(bsplineInterpFlag))
    % Rohde 7th order spline
    bsplineInterpFlag = true;
end
if(bsplineInterpFlag)
    % Rohde 7th order spline
    interpStr = 'with 7th order bspline interpolation';
    interpParams = [7 7 7 0 0 0];
else
    % This is the processing default (July 2011).
    interpStr = 'with trilinear interpolation';
    interpParams = [1 1 1 0 0 0];
end

%% Reslice everything.
% Apply the ac-pc and eddy/motion correction xforms to all the DW images.
% We also reslice the B0's (again) to bring them to ac-pc space. Finally,
% we must reorient the bvecs to account for these xforms.

if(~exist('bb','var')||isempty(bb))
    % Decide wheather to use a default bounding box or to use the diffusion
    % images themselves.
    bbDef = dtiGet(0,'defaultbb');
    bbDat = round(mrAnatXformCoords(acpcXform, [1 1 1; size(dwRaw.data(:,:,:,1))]));
    
    % We prefer to use a default bb so that all subjects will have a consistent
    % image size. But, if the default bb is very different from the native data
    % bb, then use the data.
    if(any(abs(bbDef(:)-bbDat(:))>300))
        bb = bbDat;
        fprintf('[%s] Using bounding box from data: [%d %d %d; %d %d %d]\n',mfilename,bb');
    else
        bb = bbDef;
    end
end

% Pre-allocate the output (transformed) volumes 
% (08/5/11) LMP commented this out as it was causing a dimension mismatch). 
% newImgs = uint16(zeros(size(dwRaw.data(:,:,:,nvols))));
for ii=1:nvols
    if(mod(ii,10)==0), 
        fprintf('[%s] Resampling vol %d of %d %s...\n', mfilename, ii, nvols, interpStr);
    end
    im = double(dwRaw.data(:,:,:,ii));
    if(isstruct(xform))
        % Rohde et. al. (MRM 2004) style deformation
        curXform = xform(ii);
        % We just need to add the acpc xform. This will be the first xform
        % applied, bringing the target acpc coords to the DTI reference image
        % space. The eddy-current warping and motion correction will then bring
        % the reference image space to the current image space so that we can
        % resample that image.
        % As is our convention, 'acpcXform' converts image coords to acpc
        % coords. So, we need the inverse to transform acpc coords to image
        % coords.Unless it is a struct (e.g., maybe an SPM 'sn'
        % struct?), in which case we just pass it as-is and let the
        % coord xform code sort it out.
        if(isstruct(acpcXform))
            curXform.inMat = acpcXform;
        else
            curXform.inMat = inv(acpcXform);
        end
        % We need to do the intensity correction before reasampling
        im = dtiRawRohdeApplyIntensityCorrection(curXform.ecParams, curXform.phaseDir, im);
    else
        % First we transform acpcCoords to mean b=0 coords with inMat
        % (inv(acpcXform)) and then map b=0 coords to the raw image coord
        % for volume ii with inv(xform{ii}).
        if(isstruct(acpcXform))
            curXform = acpcXform;
            if(~isempty(xform))
                curXform.outMat = inv(xform{ii});
            end
        else
            if(~isempty(xform))
                % Older code
                % curXform = inv(xform{ii})*inv(acpcXform);
                %   curXform = inv(xform{ii})*inv(acpcXform);
                %   A = xform{ii}
                %   b = inv(acpcXform)
                curXform = xform{ii} \ inv(acpcXform);
            else
                curXform = inv(acpcXform);
            end
        end
    end
    % Now resample the the plane of diffusion data using the SPM
    % interpolation method.  The method is either trilinear or bspline
    % according to the values in interpParams.
    [im,newAcpcXform] = mrAnatResliceSpm(im, curXform, bb, dwOutMm, interpParams, 0);
    im( isnan(im) | im <0 ) = 0;
    newImgs(:,:,:,ii) = int16(round(im));
end
%clear dwRaw;

%% Write out eddy/motion-corrected, t1-aligned raw data
try
    dtiWriteNiftiWrapper(newImgs, newAcpcXform, outAlignedRaw, 1, ...
        'Raw Eddy Corrected', [],[],[],[], TR);
catch
    tname = tempname;
    fn = [tname '.nii.gz'];
    fprintf('[%s] error writing %s - saving to %s.\n',mfilename,fn,fn);
    dtiWriteNiftiWrapper(newImgs, newAcpcXform, fn, 1, ...
        'Raw Eddy Corrected', [],[],[],[], TR);
end

return;
