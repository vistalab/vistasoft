function acpcXform = dtiRawAlignToT1(b0File, t1, outAcpcXform, t1MaskFile, useStdXformFlag, figNum, unwarpDti, sepParam)
%
% acpcXform = dtiRawAlignToT1([b0File=uigetfile], [t1=uigetfile], [outAcpcXform], [t1MaskFile=[]], [useStdXformFlag=true], [figNum=0], [unwarpDti=false])
%
% Returns a transforms that aligns the B0 image to the t1-weighted image in
% acpc space.  It also writes that matrix to disk in the file ::
%
% b0File:  File name
% t1:      File name
% outAcpcXform: The output file name containing the transform.  Default is
% XX
% 
% If useStdXformFlag==false, the b0 qto_xyz transform will be used for the
% coarse alignment. Otherwise, this transform will be used to estimate
% mirror-flips, but it's detailed rotation and translations components will
% be ignored. If your subjects were positioned in the scanner to be
% roughly ac-pc aligned, then use useStdXformFlag==false. If they were
% positioned any-which-way, but the Rx was adjusted to acquire roughly
% ac-pc aligned images, then use useStdXformFlag==true. If you have no clue
% what this all means, try useStdXformFlag==true and hope for the best.
%
% Set unwarpDti to true to allow a 12 parameter fit of the mean
% b=0 to the t1. Be careful- if you don't have quality, whole-brain
% DTI data, this can do bad things! Also, if you don't brain-mask
% the t1, you will often get the dti data aligned to the scalp .

%
% If figNum>0, then a figure displaying the alignment will be shown.
%
% HISTORY:
% 2007.04.23 RFD: wrote it.

%% Set defaults

if(~exist('t1MaskFile','var')), t1MaskFile = []; end
if(~exist('unwarpDti','var') || isempty(unwarpDti))
  unwarpDti = false;
end
if(~exist('sepParam','var') || isempty(sepParam))
  sepParam = [16 8 4 2];
end


% Initialize SPM default params for the coregistration.
estParams        = spm_get_defaults('coreg.estimate');
estParams.params = [0 0 0 0 0 0];% Rigid-body (6-params)
estParams.sep    = sepParam; 

if (unwarpDti)
  estParams.params = [0 0 0 0 0 0 1 1 1 0 0 0]; % 12-param affine
else
  estParams.params = [0 0 0 0 0 0]; % 6-param Rigid body
end

%% Load the b0 data (in NIFTI format)
if(~exist('b0File','var') || isempty(b0File))
    [f,p] = uigetfile({'*.nii.gz;*.nii';'*.*'}, 'Select the mean b0 NIFTI dataset...');
    if(isnumeric(f)) error('User cancelled.'); end
    b0File = fullfile(p,f);
end
if(ischar(b0File))
    % b0File can be a path to the file or the file itself
    [dataDir,inBaseName] = fileparts(b0File);
else
    [dataDir,inBaseName] = fileparts(b0File.fname);
end
[~,inBaseName,~] = fileparts(inBaseName);
if(isempty(dataDir)) dataDir = pwd; end

if(~exist('t1','var') || isempty(t1))
    [f,p] = uigetfile({'*.nii.gz';'*.mat'},'Select a T1 file or acpc transform mat file...',fullfile(dataDir,'t1.nii.gz'));
    if(isnumeric(f)), disp('Conversion canceled.'); return; end
    t1 = fullfile(p,f);
end

if(~exist('outAcpcXform','var') || isempty(outAcpcXform))
    outAcpcXform = fullfile(dataDir,[inBaseName 'AcpcXform']);
end

if(~exist('useStdXformFlag','var') || isempty(useStdXformFlag))
    useStdXformFlag = true;
end

if(~exist('figNum','var') || isempty(figNum))
    figNum = 0;
end

if(ischar(b0File))
    disp(['Loading b0 data ' b0File '...']);
    b0File = niftiRead(b0File);
end


%% Align the mean B0 to the T1 to get the ac-pc xform
%
fprintf('[%s] Aligning mean b=0 to t1...\n',mfilename);

source.uint8 = uint8(round(mrAnatHistogramClip(double(b0File.data),0.4,0.99)*255));
% % Blur images given the specified highest-resolution sampling density
fwhm = sqrt(max([1 1 1]*estParams.sep(end)^2 - b0File.pixdim.^2, [0 0 0]))./b0File.pixdim;
source.uint8 = mrAnatSmoothUint8(source.uint8,fwhm);
% We also need a reasonable starting guess at the mnB0 ac-pc xform.
if (b0File.qform_code>0)
  source.mat = b0File.qto_xyz;
elseif (b0File.sform_code>0)
  source.mat = b0File.sto_xyz;
else
  error('Requires that b0File qform_code>1 OR sform_code>1.');
end

if(ischar(t1))
    t1 = niftiRead(t1);
end

target.uint8 = uint8(round(mrAnatHistogramClip(double(t1.data),0.50,0.995)*255));
fwhm = sqrt(max([1 1 1]*estParams.sep(end)^2 - t1.pixdim(1:3).^2, [0 0 0]))./t1.pixdim(1:3);
target.uint8 = mrAnatSmoothUint8(target.uint8,fwhm);
if(t1.qform_code>0)
  target.mat = t1.qto_xyz;
elseif(t1.sform_code>0)
  target.mat = t1.sto_xyz;
else
  error('Requires that t1 qform_code>0 OR sform_code>0.');
end
if(~isempty(t1MaskFile))
  brainMask = niftiRead(t1MaskFile);
  target.uint8(~brainMask.data) = 0;
  clear brainMask;
end
% Sanity check for rough alignment xforms from image header. If the center
% coordinate falls outside the image volume, then we replace the
% translations with a default to the image center. This WILL NOT fix bad
% rotations or bad scales.
centerCoord = inv(target.mat)*[0 0 0 1]'; centerCoord = centerCoord(1:3)';
if (any(centerCoord<1) || any(centerCoord>size(target.uint8)))
    [t,r,s] = affineDecompose(target.mat);
    t = size(target.uint8)./2.*s;
    im2std = mrAnatComputeCannonicalXformFromDicomXform(target.mat,size(target.uint8));
    im2std(:,4) = [0 0 0 1]';
    target.mat = im2std*affineBuild(-t,[0 0 0],s);
    %t = t.*-sign(target.mat(1:3,1:3)*[size(target.uint8)./2]')';
    %target.mat = affineBuild(t,[0 0 0],s);
end
centerCoord = inv(source.mat)*[0 0 0 1]'; centerCoord = centerCoord(1:3)';
if (useStdXformFlag || any(centerCoord<1) || any(centerCoord > size(source.uint8)))
    [t,r,s] = affineDecompose(source.mat);
    t = size(source.uint8)./2.*s;
    im2std = mrAnatComputeCannonicalXformFromDicomXform(source.mat,size(source.uint8));
    im2std(:,4) = [0 0 0 1]';
    source.mat = im2std*affineBuild(-t,[0 0 0],s);
    %t = t.*-sign(source.mat(1:3,1:3)*[size(source.uint8)./2]')';
    %source.mat = affineBuild(t,[0 0 0],s);
end
%headerMI = mrAnatComputeMutualInfo([0 0 10 0 0 0],source,target,[1 1 1],estParams.cost_fun,estParams.fwhm);
sc = fileparts(b0File.fname); if(length(sc)>25) sc = ['...' sc(end-18:end)]; end
if (figNum>0)
  figure(figNum);
  dtiShowAlignFigure(figNum, target, source, [], [], ['initial align ( ' sc ' )']);
end


if(figNum>0)
    transRot = spm_coreg(source,target,estParams);
else
    % suppress the verbose optimizer output.
    msg = evalc('transRot = spm_coreg(source,target,estParams);');
end
acpcXform = spm_matrix(transRot(end,:))*source.mat;
source.mat = acpcXform;
if(figNum>0)
  figure(figNum);
  dtiShowAlignFigure(figNum, target, source, [], [], ['final align ( ' sc ' )']);
end
disp(['Saving b0 acpcXform to ' outAcpcXform '...']);
save(outAcpcXform, 'acpcXform');
%dlmwrite([outAcpcXform '.txt'],acpcXform,'delimiter',' ','precision',6);

return;
