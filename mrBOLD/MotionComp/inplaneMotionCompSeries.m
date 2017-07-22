function vw=inplaneMotionCompSeries(vw,scan,slice,baseFrame)
%
% vw=inplaneMotionCompSeries(vw,scan,slice,baseFrame)
%
% Loads tSeries, estimates motion between each frame and the baseFrame,
% and warps the image to compensate for the motion.  Holds the warped
% tSeries in vw.tSeries.
%
% Copies the original tSeries.dat file to a origTSeries.dat.
% Saves the new (warped) tSeries in tSeries.dat.
%
% To revert back to the original tSeries, use revertMotionComp.
%
%   scan: default current scan
%   slice: default current slice
%   baseFrame: default 1
%
% djh, 4/16/99

if ~exist('scan','var')
   scan = getCurScan(vw);
end
if ~exist('slice','var')
   slice = viewGet(vw, 'Current Slice');
end
if ~exist('baseFrame','var')
   baseFrame=1;
end

% Load tSeries
[~,nii] = loadtSeries(vw,scan,slice);

dims = niftiGet(nii,'Dim');
data = single(niftiGet(nii,'Data'));

%Now, let us take the tSeries data and transform it into the same
%format as previously saved

nFrames = dims(4);
voxPerSlice = prod(dims(1:2));

tSeries = squeeze(data(:,:,slice,:)); % rows x cols x time
tSeries = reshape(tSeries, [voxPerSlice nFrames])'; % time x voxels

nFrames = numFrames(vw,scan);
dims = sliceDims(vw,scan);
baseIm = reshape(tSeries(baseFrame,:),dims);

% Compute motion estimates and warped tSeries
wtSeries = zeros(size(tSeries));
waitStr = ['Computing motion estimates. scan:' num2str(scan) ' slice:' num2str(slice)];
waitHandle = mrvWaitbar(0,waitStr);
for frame = 1:nFrames
  mrvWaitbar(frame/nFrames)
  im = reshape(tSeries(frame,:),dims);
  M = estMotionIter2(baseIm,im,2,eye(3),1);
  warpedIm = warpAffine2(im,M);
  wtSeries(frame,:) = warpedIm(:)';
end
close(waitHandle)

% Return warped tSeries in vw.tSeries and save it to the tSeries file

size = viewGet(vw,'Functional Slice Dim');
newwtSeries = reshape(wtSeries,size);

%Now let's update the nifti
data(:,:,slice,:) = newwtSeries;
nii = niftiSet(nii,'Data',data);
dim = size(niftiGet(nii,'Data'));
nii = niftiSet(nii,'Dim',dim);

savetSeries(wtSeries,vw,scan,slice,nii);

return

%%% Debug
mrLoadRet
INPLANE{1} = inplaneMotionComp(INPLANE{1});
INPLANE{1} = revertMotionComp(INPLANE{1});
