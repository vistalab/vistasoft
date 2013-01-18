function showTheseFgs = dtiFGShowList(handles)
%Set which fibers MIGHT be shown.  Final decision depends on fg.visible
%
%   showTheseFgs = dtiFGShowList(handles)
%
% Decide which fiber groups to show.  The pulldown select None, Current or
% All.  If we have selected choose, then there is a .visible flag that
% governs the display, so, we set the showTheseFgs to the same as 'All'.
%
% (c) Stanford VISTA Team

if (handles.fiberGroupShowMode == 1 || isempty(handles.fiberGroups))
    showTheseFgs = [];
elseif (handles.fiberGroupShowMode == 2),  showTheseFgs = handles.curFiberGroup;  % Current only
elseif (handles.fiberGroupShowMode == 3),  showTheseFgs = (1:length(handles.fiberGroups));  % All
elseif (handles.fiberGroupShowMode == 4),  showTheseFgs = (1:length(handles.fiberGroups));  % Choose
else error('Bad handles.fiberGroupShowMode');
end

return;