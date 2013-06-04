function smoothFrames = detrendFrames(vw,scan)
% Number of frames used for the detrending (smoothing?) calculation 
%
%    smoothFrames = detrendFrames(view,[scan])
%
% The number of detrending frames depends on dataTYPE setting
% blockedAnalysis vs eventAnalysis
%
% Should be replaced by
%   viewGet(view,'detrendFrames',scan)
%

if notDefined('scan'), scan = viewGet(vw,'curScan'); end

dt    = viewGet(vw,'dtStruct');
aType = dtGet(dt,'eventOrBlock',scan);

smoothFrames = dtGet(dt,'smoothFrames',scan,vw);

return;

