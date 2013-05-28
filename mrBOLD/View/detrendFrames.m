function smoothFrames = detrendFrames(view,scan)
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

if notDefined('scan'), scan = viewGet(view,'curScan'); end

dt    = viewGet(view,'dtStruct');
aType = dtGet(dt,'eventOrBlock',scan);

switch aType %TODO: Remove this switch statement. It is unnecessary as it has already been wrapped into dtGet
    case 'event'
        smoothFrames = dtGet(dt,'smoothFrames',scan);
    case 'block'
        smoothFrames = dtGet(dt,'smoothFrames',scan,view);
    otherwise
        error('Unknown analysis %s\n',aType);
end

return;

