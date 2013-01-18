function gray = checkSelectedGray
% inplane = checkSelectedGray;
%
% checks for a selected gray view. If one exists, returns it;
% otherwise, initializes an empty gray view.
mrGlobals;
gray = getSelectedGray;
if isempty(gray)
    % open a hidden view, but warn that you're doing this
    warning('No gray VOLUME view found. Initializing a hidden gray view.')
    inplane = initHiddenGray;
end
return
