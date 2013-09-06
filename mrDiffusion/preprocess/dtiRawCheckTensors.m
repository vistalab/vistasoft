function [pddT1,acpcToImXform,mm] = dtiRawCheckTensors(tensorsFile, t1, maskFile, mm)
%
% [pddT1,acpcToImXform,mm] = dtiRawCheckTensors(tensorsFile, [t1File=t1/t1.nii.gz], [maskFile=[]], [outMm=1 1 1])
%
% Returns an image with PDD overlayed on the t1, using the FA for
% opacity.
%
% For example:
%  [pddT1,xform] = dtiRawCheckTensors;
%  acpcSl = [-26:2:56];
%  imSlices = mrAnatXformGetSlices(xform,acpcSl);
%  m = makeMontage3(pddT1,imSlices);
%
% HISTORY:
% 2007.10.18 RFD wrote it.

if(~exist('tensorsFile','var')||isempty(tensorsFile))
    [f,p] = uigetfile({'*.nii.gz';'*.*'},'Select a NIFTI tensor file...');
    if(isnumeric(f)), disp('User canceled.'); return; end
    tensorsFile = fullfile(p,f);
end
[dt6, dtToAcpcXform, mmPerVox, tensorsFile] = dtiLoadTensorsFromNifti(tensorsFile);
dataDir = fileparts(tensorsFile);

if(~exist('t1','var')||isempty(t1))
    t1 = fullfile(fileparts(fileparts(dataDir)),'t1','t1.nii.gz');
    if(~exist(t1,'file'))
        [f,p] = uigetfile('*.nii.gz','Select the t1-file for alignment check...',t1);
        if(isnumeric(f)) 
            error('user canceled.'); 
        end
        t1 = fullfile(p,f);
    end
end

if(~exist('maskFile','var')||isempty(maskFile))
    maskFile = fullfile(dataDir,'brainMask.nii.gz');
end
if(~exist('mm','var')||isempty(mm))
    mm = [1 1 1];
end

if(ischar(maskFile) && exist(maskFile,'file'))
    maskFile = niftiRead(maskFile);
end
if(isstruct(maskFile))
    mask = maskFile.data;
else
    mask = [];
end

if(~isempty(mask))
    for(ii=1:6)
        tmp = dt6(:,:,:,ii);
        tmp(~mask) = 0;
        dt6(:,:,:,ii) = tmp;
    end
end
[eigVec,eigVal] = dtiEig(dt6);
pdd = squeeze(eigVec(:,:,:,[1 2 3],1));
fa = dtiComputeFA(eigVal);
fa(fa<0) = 0; fa(fa>1) = 1;
%clear eigVec eigVal;

if(ischar(t1))
    if(exist(t1,'file'))
        t1 = niftiRead(t1);
    else
        error(['no t1 file "' t1 '".']);
    end
end

% check if mm=='t1'
if(ischar(mm))
    mm = t1.pixdim;
end

bb = mrAnatXformCoords(t1.qto_xyz, [1,1,1;t1.dim(1:3)]);
%inOrigin = mrAnatXformCoords(t1.qto_ijk,[0 0 0]);
%bb = [-t1.pixdim.*(inOrigin-1); t1.pixdim.*(t1.dim-inOrigin)];

ip = [1 1 1 0 0 0];

[pddIm,imToAcpc] = mrAnatResliceSpm(abs(pdd), inv(dtToAcpcXform), bb, mm, ip, false);
faIm = mrAnatResliceSpm(fa, inv(dtToAcpcXform), bb, mm, ip, false);
t1Im = double(t1.data);
t1Im = mrAnatResliceSpm(t1Im, t1.qto_ijk, bb, mm, ip, false);
t1Im = uint8(round(mrAnatHistogramClip(t1Im,0.4,0.98).*(1-faIm).*255));
%acpcToImXform = t1.qto_ijk;
%mm = t1.pixdim;
acpcToImXform = inv(imToAcpc);

pddT1 = zeros(size(pddIm),'uint8');
for(ii=1:3)
    pddT1(:,:,:,ii) = t1Im+uint8(round(pddIm(:,:,:,ii).*faIm.*255));
end

return;

