function flat = checkSelectedFlat
% flat = checkSelectedFlat;
%
% checks for a selected flat view. If one exists, returns it;
% otherwise, initializes an empty flat view.
mrGlobals;
flat = getSelectedFlat;
if isempty(flat)
    % open a hidden view, but warn that you're doing this
    warning('No FLAT view found. Initializing a hidden flat view.')
    flat = initHiddenFlat;
end
return
