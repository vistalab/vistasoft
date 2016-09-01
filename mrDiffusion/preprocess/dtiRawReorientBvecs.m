function bvecs = dtiRawReorientBvecs(bvecs, ecXform, acpcXform, bvecsOutFile)
%
% bvecs = dtiRawReorientBvecs([bvecs=uigetfile], [ecXform=uigetfile], [acpcXform=uigetfile], [bvecsOutFile=uiputfile])
%
% NOTE: bvecs are assumed to be specified in raw, unaligned image space.
% If bvecs are in scanner space, use dtiRawBuildBvecs, or bundle the
% scanner xform with the eddy-correct xform. 
%
% TO DO: merge this with dtiReorientBvecs?
%
% HISTORY:
% 2007.01.10 RFD: wrote it.
% 2007.03.22 RFD: changed the computation of the rotation matrix slightly.
% It now ignores skews when extracting the rotation component. This change
% is unlikely to affect the tensors much- it typically only changes the
% reoriented bvecs by less than 0.5 degrees.
% 2007.06.07 RFD: change input arg order to be consistent with other
% dtiRaw... functions.

if(~exist('bvecs','var')||isempty(bvecs))
  [f,p] = uigetfile({'*.bvecs','bvecs files';'*.*','All files'},'Select the bvecs file to reorient...');
  if(isnumeric(f)), disp('bvecs file required- aborting.'); return; end
  bvecs = fullfile(p,f);
end
if(ischar(bvecs))
    [datDir,inBaseName,ext] = fileparts(bvecs);
    if(isempty(datDir)), datDir = pwd; end
else
    datDir = pwd;
end

if(~exist('ecXform','var'))
  [f,p] = uigetfile({'*.mat'},'Select an eddy-correct transform file (cancel to skip)...',[datDir filesep]);
  if(isnumeric(f))
    disp('skipping eddy-correct reorientation.'); 
    ecXform = [];
  else
    ecXform = fullfile(p,f);
  end
end

if(~exist('acpcXform','var')||isempty(acpcXform))
  [f,p] = uigetfile({'*.mat'},'Select an ac-pc transform file...',[datDir filesep]);
  if(isnumeric(f)), disp('acpcXformFile required- aborting.'); return; end
  acpcXform = fullfile(p,f); 
end
if(ischar(acpcXform))
    tmp = load(acpcXform);
    acpcXform = tmp.acpcXform;
elseif(numel(acpcXform)==1&&~acpcXform)
   acpcXform = eye(4);
   disp('No acpcXform will be applied.');
end

if(~exist('bvecsOutFile','var')||isempty(bvecsOutFile))
    if(nargout==0)
        bvecsOutFile = fullfile(datDir,[inBaseName 'Aligned.bvecs']);
        [f,p] = uiputfile({'*.bvecs';'*.*'},'File to save the reoriented bvecs...', bvecsOutFile);
        if(isnumeric(f)), disp('User canceled.'); return; end
        bvecsOutFile = fullfile(p,f);
    else
        bvecsOutFile = [];
    end
end

if(ischar(bvecs))
    % Load the bvecs
    %bvecs = dlmread(bvecs, ' ');
    bvecs = dlmread(bvecs);
end
nvols = size(bvecs,2);

if(isempty(ecXform))
    xform = cell(nvols,1);
    for ii=1:nvols, xform{ii} = eye(4); end
else
    if(ischar(ecXform))
        load(ecXform);
    else
        xform = ecXform;
    end
	if(length(xform)<nvols)
	  nvols = length(xform);
	  warning('More bvecs than vols- ignoring some bvecs...');
	end
end

for(ii=1:nvols)
   % acpcXform converts image coords to ac-pc coords. We apply this
   % transform to the images, so we need to also rotate the bvecs by the
   % same angles. The motion correction, however, specifies the target
   % ('reference image') to curVol rotation, so we'll apply the inverse of
   % that to get the bvecs into the reference image coord frame, which can
   % then be rotated to the ac-pc coord frame.
   if(isstruct(xform))
       % Rohde-style deformation params. We just need the rotation
       % component in ecParams 4-6.
       curXform = affineBuild([0 0 0], xform(ii).ecParams([4:6]));
   else
       curXform = xform{ii};
   end
   % Extract the rotation matrix from the xform for rotating the bvecs
   rotCurToRef = inv(affineExtractRotation(curXform));
   rotRefToAcpc = affineExtractRotation(acpcXform);
   % Rotate them
   bvecs(:,ii) = rotRefToAcpc*rotCurToRef*bvecs(:,ii);
end
if(~isempty(bvecsOutFile))
    dlmwrite(bvecsOutFile,bvecs,' ');
end
if(nargout==0)
    clear bvecs;
end
return;
