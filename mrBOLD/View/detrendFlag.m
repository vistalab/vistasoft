function detrend = detrendFlag(view,scan)
%
% detrend = detrendFlag(view,[scan])
%
% Switches off dataType depending on blockedAnalysis vs eventAnalysis
%
% djh, 2/21/2001
if notDefined('scan'), scan = viewGet(view,'curScan'); end

% Get current dataTYPE
dt    = viewGet(view,'dtStruct');
aType = dtGet(dt,'eventOrBlock',scan);

switch aType
    case 'event'
        params = dtGet(dt,'eparms');
    case 'block'
        params = dtGet(dt,'bparms');
    otherwise
        error('Unknown type %s\n',aType)
end

% this might be a cell array of data types; just get the current one
detrend = params(1).detrend;

return;
