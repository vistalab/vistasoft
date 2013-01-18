function volume = checkSelectedVolume
% volume = checkSelectedVolume;
%
% checks for a selected volume view. If one exists, returns it;
% otherwise, initializes an empty volume view.
mrGlobals;
volume = getSelectedVolume;
if isempty(volume)
    % open a hidden view, but warn that you're doing this
    warning('No  VOLUME view found. Initializing a hidden volume view.')
    inplane = initHiddenVolume;
end
return
