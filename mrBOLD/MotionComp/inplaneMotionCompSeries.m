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
tSeries = loadtSeries(vw,scan,slice);
nFrames = numFrames(vw,scan);
dims = sliceDims(vw,scan);
baseIm = reshape(tSeries(baseFrame,:),dims);

% Compute motion estimates and warped tSeries
wtSeries = zeros(size(tSeries));
waitStr = ['Computing motion estimates. scan:' num2str(scan) ' slice:' num2str(slice)];
waitHandle = waitbar(0,waitStr);
for frame = 1:nFrames
  waitbar(frame/nFrames)
  im = reshape(tSeries(frame,:),dims);
  M = estMotionIter2(baseIm,im,2,eye(3),1);
  warpedIm = warpAffine2(im,M);
  wtSeries(frame,:) = warpedIm(:)';
end
close(waitHandle)

% Return warped tSeries in vw.tSeries and save it to the tSeries file
savetSeries(wtSeries,vw,scan,slice);

return

%%% Debug
mrLoadRet
INPLANE{1} = inplaneMotionComp(INPLANE{1});
INPLANE{1} = revertMotionComp(INPLANE{1});
