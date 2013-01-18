function inplane = checkSelectedInplane;
% inplane = checkSelectedInplane;
%
% checks for a selected inplane view. If one exists, returns it;
% otherwise, initializes an empty inplane.
mrGlobals;
inplane = getSelectedInplane;
if isempty(inplane)
    % open a hidden view, but warn that you're doing this
    warning('No INPLANE view found. Initializing a hidden inplane view.')
    inplane = initHiddenInplane;
end
return
