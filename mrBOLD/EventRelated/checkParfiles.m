function checkParfiles(view,scans);
%  checkParfiles(view,scans);
%
% For mrVISTA, checks that the specified scans associated with the view
% have par/prt files assigned, and if any aren't provides an interface to
% assign them.
%
% For more info, see readParFile, or ras_assignParfileToScan.
%
% written 03/08/04 by ras.
global dataTYPES;

series = view.curDataType;

allAssigned = 1;
for s = scans
    if ~isfield(dataTYPES(series).scanParams(s),'parfile') | ...
       isempty(dataTYPES(series).scanParams(s).parfile)
        allAssigned = 0;
        break;
    end
end
if ~allAssigned
    er_assignParfilesToScans(view);
end

return