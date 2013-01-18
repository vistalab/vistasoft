function R = SPMAlign(scans, frames, imgDir, saveDir, actions, flags)
%
% R = SPMAlign(scans, frames, [imgDir], [saveDir], [actions], [flags]);
%
% Robust 3D rigid body motion compensation, based on SPM2 functions
%
% R         - a matrix, returned by spm_realign.
% scans     - a vector of scan (session) numbers (e.g. [1,2,5]).
% frames    - a vector of frame (image file) numbers (e.g. [0,1,2,5]), or
%             a cell-array of scan-specific frame numbers (e.g. {[0,1],[0:2],[0,3]})
% imgDir    - a Directory with Scan folders containing the img-files
%             (default - /Inplane/Original/TSeries_imgFiles/ 
%             within a current Directory set in Matlab)
% saveDir   - a Directory where Scan folders containing the img-files for
%             spatially realigned images must be written
%             (default - /Inplane/Realigned/TSeries_imgFiles/
%             We assume that only existing on hard-drive saveDir will be passed 
%             into SPMAlign; if saveDir is omitted, we will try
%             to create it within a current Directory set in Matlab
% actions   - a vector, defining the actions to do - realign, reslice, or both
%             (default - [1,1] = realign & reslice).
% flags     - a vector of flags, passing into spm_realign and spm_reslice
%             (defaults - defined in the code below).
%
%         All operations are performed relative to the first image.
%         i.e. Coregistration is to the first image, and resampling
%         of images is into the space of the first image.
%
% MA, 10/26/2004

% P - cell array, where each cell should be a matrix of filenames 
% for specific scan (session):
if ~exist('imgDir')
    imgDir = fullfile(cd, 'Inplane','Original','TSeries_imgFiles'); 
end

frms = frames;
for i = 1:length(scans)
    scanIndex = scans(i);
    scanDir = ['Scan', int2str(scanIndex)];
    if iscell(frames)                       %scan-specific frames:
        frms = frames{i};         
    end
    for j = 1:length(frms)
        frameIndex = frms(j);
        frameFile = [sprintf('%03s',int2str(frameIndex)), '.img'];
        scanPath(j,:) = fullfile(imgDir,scanDir,frameFile);
    end
    P{i} = scanPath;
end
R = P;

if ~exist('actions'); actions = [1,1]; end;
realign = actions(1);
if length(actions)>1; reslice = actions(2); end;

spm_defaults;

if ~exist('flags')
	flags(1).quality = 0.7500;
	flags(1).fwhm = 5;
	flags(1).rtm = 0;
	flags(1).interp = 2;
	flags(2).interp = 4;
	flags(2).wrap = [0 0 0];
	flags(2).mask = 1;
	flags(2).which = 2;
	flags(2).mean = 1;
end

myDisp('SPMAlign: Start...');
if realign
%    R = spm_realign(P,flags(1));
    R = SPMRealign(P,flags(1));
end;

if reslice
%	spm_reslice(P,flags(2));
	if ~exist('saveDir')
        saveDir = fullfile('Inplane','Realigned','TSeries_imgFiles'); 
        fullPath = fullfile(cd, saveDir);
        if ~exist(fullPath,'dir')
            mkdir(cd,saveDir);
        end
        saveDir = fullPath;
	end
%	SPMReslice(P,flags(2),saveDir); 
%   we returned R, so we must pass it into SPMReslice:
	SPMReslice(R,flags(2),saveDir);
end
myDisp('SPMAlign: Done!');

return