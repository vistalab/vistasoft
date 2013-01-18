function nCycles = numCycles(vw,scan)
%Returns the number of cycles for blocked analyses
%
% nScans = numCycles(vw,[scan])
% 
% Scan default is current scan.
%
% djh, 2/21/2001


warning('vistasoft:obsoleteFunction', 'numCycles.m is obsolete.\nUsing\nnumCycles = viewGet(vw, ''num cycles'', scan)\ninstead.');

if notDefined('scan'),  scan = viewGet(vw,'curScan'); end

nCycles = viewGet(vw, 'num cycles', scan);

return

% global dataTYPES;
% curDT = viewGet(vw,'curdt');
% dt    = dataTYPES(curDT);
% % This should be a dtGet()
% blockParms = dtGet(dt,'bparms',scan);
% % THere are some issues with event and block that we need to figure out
% % here.
% if isfield(blockParms,'nCycles'), nCycles = blockParms.nCycles;
% else                              nCycles = 1;
% end
% return
