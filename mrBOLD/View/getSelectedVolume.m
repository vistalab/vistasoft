function [volume,s] = getSelectedVolume
% Returns currently selected volume. 
%
%  [volume,selectedVOLUME] = getSelectedVolume
%
% If only one volume open, returns that volume
%
%

mrGlobals;
s = selectedVOLUME;

if notDefined('VOLUME')
    warning('No global VOLUME variable is defined.');
    volume = [];
    return
end

if(~iscell(VOLUME))
    warning('No VOLUME global')
    volume = [];
    return;
end

% There is a global that defines which one is selected
if ~isempty(selectedVOLUME)
    volume = VOLUME{selectedVOLUME};
else
    % The global doesn't exist. We return the highest VOLUME in the cell
    % array of volumes
    warning('No selectedVOLUME. Returning last VOLUME in cell array');
    volumeList = cellfind(VOLUME);
    s = volumeList(end);
    volume = VOLUME{s};
end

return;
% ----------------------------------------
