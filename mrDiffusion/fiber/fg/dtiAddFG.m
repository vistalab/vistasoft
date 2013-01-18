function [handles, thisFGNum] = dtiAddFG(fg,handles)
%Add a fiber group to mrDiffusison guidata at the end of fiber group list
%
%  handles = dtiAddFG(fg,handles);
%
% See also:  dtiSet(dtiH,'add fiber group'); t_mrdViewFibers
%
%
% (c) Stanford VISTA Team

if ~exist('fg','var') || isempty(fg), error('fiber group required.'); end
if ~exist('handles','var') || isempty(handles), error('handles required.'); end

% We want to first test that fg has the right format


%

% Figure out how many fg we have and allocate space
if isempty(handles.fiberGroups) 
    % This is the first
	handles = rmfield(handles,'fiberGroups');
    thisFGNum = 0;
else
    % Not empty - Force the fields in all the fiber groups to have the same fields.
    thisFGNum = numel(handles.fiberGroups);
    [handles.fiberGroups, fg] = structMatchFields(handles.fiberGroups, fg);
end

% Add the new fiber groups to the end of the current list of fiber groups.
for ii=1:numel(fg)
    thisFGNum = thisFGNum + 1;
    handles.fiberGroups(thisFGNum) = fg(ii);
end

% Set the current fg to be the one we just added.
handles.curFiberGroup = thisFGNum;

% Refresh the window
handles = dtiFiberUI('popupCurrentFiberGroup_Refresh',handles);

return;
