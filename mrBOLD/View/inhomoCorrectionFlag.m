function flag = inhomoCorrectionFlag(view,scan)
%Determine inhomogeneity correction flag for this scan
%
% flag = inhomoCorrectionFlag(view,[scan])
%
% This routine should be replaced by
%
%   flag = viewGet(view,'inhomogeneityFlag',scan)
%
% The bulk of this routine, then, would be inside of the viewGet function. 
%

global dataTYPES;

if notDefined('scan'), scan = viewGet(view,'curScan'); end
dt   = dataTYPES(viewGet(view,'curdt'));

aType = dtGet(dt,'eventorblock',scan);
switch aType
    case 'block'
        params = dtGet(dt,'bparams',scan);
    case 'event'
        params = dtGet(dt,'eparams',scan);
    otherwise
end
flag = params.inhomoCorrect;

% if ~exist('scan','var')
%     if isfield(view,'ui')
%         scan = getCurScan(view);
%     else
%         scan = 1;
%     end
% end
     
% inhomoCorrect = dt.blockedAnalysisParams(scan).inhomoCorrect;

return;