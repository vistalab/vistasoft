function motion = motionComp(vw, tgtDt, scan, nSmooth, baseFrame, baseScan)
%
% motion = motionComp(vw, mcView, [scan, nSmooth, baseFrame])
%
% Robust 3D rigid body motion compensation
%
% If you change this function make parallel changes in:
%   betweenScanMotComp, inplaneMotionComp
%
% INPUTS:
%	vw:         mrVista view struct
%   mcView:     ??? why do we need two view stuctures?
%   scan:       the scan in which to do to motion compensation
%   nSmooth:    number of consecutive frames to smooth for calculating motion
%                   compensation (integer)
%   baseFrame:  align all frames to this frame (integer)
%   baseScan:   scan to align all frames to. if empty, then baseScan = scan
%
% OUTPUTS:
%	motion:     2 x nFrames matrix, with row 1 representing estimated
%               rotational motion for each frame (relative to the reference
%               frame),savetSeries and row 2 representing translational motion.
%
% djh & on, 2000
% Ress, 3/05: Added temporal smoothing option to deal with low SNR
% functionals and artifacts. Moved default base frame to center of time
% series.
% hh 09/2010: Added a new parameter - baseScan to get a fixed reference
% scan, which allow us to do motion compensation at once instead of two
% steps.
%
%
%

if ~exist('scan','var'),    scan     = viewGet(vw, 'curscan');  end
if isempty(baseScan),       baseScan = 0;                       end
if exist('nSmooth', 'var'), nSmooth  = 2*fix(nSmooth/2) + 1;
else                        nSmooth  = 1;                       end

nSlices = viewGet(vw, 'num slices', scan);
nFrames = viewGet(vw, 'num frames', scan);
dims    = viewGet(vw, 'slice dims',scan);
motion  = zeros(2, nFrames);
%srcDt   = viewGet(vw, 'curDt');

if ~exist('baseFrame','var') || isempty(baseFrame)
    baseFrame = round(nFrames/2);
end

% Load tSeries from all slices into one big array
[~, nii] = loadtSeries(vw, scan);
volSeries = niftiGet(nii, 'data');

midX = [dims/2 nSlices/2]';


%% Get base volume.  Other frames will be motion compensated to this one.

baseMin = baseFrame - fix(nSmooth/2);
if baseMin < 1, baseMin = 1; end
baseMax = baseFrame + fix(nSmooth/2);
if baseMax > nFrames, baseMax = nFrames; end


if baseScan,
    % if we are aligning to a separate base scan, load that scan
    [~, nii] = loadtSeries(vw,baseScan);
    bvolSeries = niftiGet(nii, 'data');
    baseVol = mean(bvolSeries(:,:,:,baseMin:baseMax),4);
    clear bvolSeries
else
    % otherwise use the baseFrames in the currently loaded scan
    baseVol = mean(volSeries(:,:,:,baseMin:baseMax),4);
end

%% Do motion estimation/compensation for each frame.
warpedVolSeries = zeros(size(volSeries));
% filling the base frame
warpedVolSeries(:,:,:,baseFrame) = baseVol;


% if the number of slices is too small, repeat the first and last slice
% to avoid running out of data (the derivative computation discards the
% borders in z, typically 2 slices at the begining and 2 more at the end)
if size(baseVol,3)<=8
    baseVol = cat(3,baseVol(:,:,1),baseVol(:,:,1),baseVol,...
        baseVol(:,:,end),baseVol(:,:,end));
end

waitHandle = mrvWaitbar(0,'Computing motion estimates. Please wait...');
for frame = 1:nFrames
    mrvWaitbar(frame/nFrames)
    if (frame~=baseFrame) || ((baseScan ~= scan) && baseScan ~= 0) % hh added it...
        frameMin = frame - fix(nSmooth/2);
        if frameMin < 1, frameMin = 1; end
        frameMax = frame + fix(nSmooth/2);
        if frameMax > nFrames, frameMax = nFrames; end
        vol = mean(volSeries(:,:,:,frameMin:frameMax), 4);
        % if the number of slices is too small, repeat the first and last slice
        % to avoid running out of data (the derivative computation discards the
        % borders in z, typically 2 slices at the begining and 2 more at the end)
        if size(vol,3)<=8
            vol = cat(3, vol(:,:,1),vol(:,:,1),vol,...
                vol(:,:,end),vol(:,:,end));
        end
        
        M = estMotionIter3(baseVol,vol,2,eye(4),1,1); % rigid body, ROBUST
        % warp the volume putting an edge of 1 voxel around to avoid lost data
        warpedVolSeries(:,:,:,frame) = warpAffine3(volSeries(:,:,:,frame),M,NaN,1);
        midXp = M(1:3, 1:3) * midX;
        motion(1, frame) = sqrt(sum((midXp - midX).^2)); % Rotational motion
        motion(2, frame) = sqrt(sum(M(1:3, 4).^2)); % Translational motion
    end
end
close(waitHandle)

% Save warped tSeries 

waitHandle = mrvWaitbar(0,'Saving tSeries. Please wait...');

vw = viewSet(vw, 'curdt', tgtDt);

% put time first rather than last, consistent with old .mat tseries
warpedVolSeries = permute(warpedVolSeries, [4, 1, 2, 3]);

% put the two slice dimensions into one dimension, consistent with old .mat
% tseries
sz = size(warpedVolSeries);
warpedVolSeries = reshape(warpedVolSeries, sz(1), sz(2)*sz(3), sz(4));

savetSeries(warpedVolSeries, vw, scan);
close(waitHandle)

return
