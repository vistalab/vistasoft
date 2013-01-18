function handles = dtiDeleteFG(fgNum,handles)
%
%   handles = dtiDeleteFG(fgNum,handles)
%
%Author: Wandell
%Purpose:
%
% Example:
%    handles = dtiDeleteFG(handles.curFiberGroup,handles)

if ieNotDefined('fgNum'), error('Fiber Group number required.'); end
if isempty(handles.fiberGroups), warning('No Fiber Groups to delete'); return;  end

nFG = length(handles.fiberGroups);
if (fgNum < 1) | (fgNum > nFG), error('Bad Fiber Group number.'); end

handles.fiberGroups(fgNum) = [];
if (fgNum <= handles.curFiberGroup), handles.curFiberGroup = handles.curFiberGroup - 1; end

if isempty(handles.fiberGroups), handles.curFiberGroup = 0; 
elseif handles.curFiberGroup < 1, handles.curFiberGroup = 1; end

return;
