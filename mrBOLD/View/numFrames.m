function nFrames = numFrames(view, scan)
% Number of time samples (frames) for the view/scan combination
%
%   nFrames = numFrames(view, scan)
% 
% Accesses dataTYPES to get this info.
%
% global dataTYPES;
% 
% Example:
%   numFrames(INPLANE{1},1)
if notDefined('scan'), scan = view.curScan; end
nFrames = viewGet(view,'nFrames',scan);

return