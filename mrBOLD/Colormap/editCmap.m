function cmap = editCmap(mode)
%
% cmap = editCmap(numGrays,numColors)
% 
% Opens Colormapeditor withbout gray values.
% 
% Makes colormap array with:
%   gray scale - 1:numGrays
%   edited cmap numGrays+1:numGrays+numColors
%
%   to do:
%   +offer to save colormap - for now need to save via colormap ->
%   utilities
%   +revert to starting cmap when colormapeditor or naming is cancelled
%
% dar 11/06

%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%
%what happens when you cancel colormapeditor??
%set for phase mode currently, if operational, spread to other submenus.
%remove colormapeditor from colormenu!! + comments
%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%
existingCmap = mode.cmap;

if isscalar(mode.numGrays)
    numGrays = mode.numGrays;
else
    numGrays=128;
    fprintf('WARNING: editCmap function did not recieve length information for existing colormap- \n');
    fprintf('         defaulting to %i GRAY values \n\n',numGrays);
end

if isscalar(mode.numColors)
    numColors = mode.numColors;
else
    numColors=96;
    fprintf('WARNING: editCmap function did not recieve length information for existing colormap- \n');
    fprintf('         defaulting to %i COLOR values \n\n',numColors);
end

%what about setting this based on existing cmap?
%find where existing cmap gray-scale ends, then length to end of cmap.
%?how to cleanly find the end of gray-scale? looking for non-equal
%column values could work, but prog would balk at white, black, or gray as
%end elements of an existing cmap.
    
colormap(existingCmap(numGrays+1:length(existingCmap),:));
colormapeditor;
uiwait(msgbox('Press "OK" when finished editing colormap')); 
%too clunky - find a better way to wait for colormapeditor to finish.

newcolors = colormap;
colormap([existingCmap(1:numGrays,:);newcolors])

cmap=colormap;
return;