function view = flipCmap(view)
% view = rotateCmap(view)
%
% AUTHOR:  Niell, Press
% DATE:    03.11.99
% PURPOSE: Flips the colormap so that it's easy to compare
%	   one hemisphere's retinotopy phases with the others
%	   (must still rotate a little to account for the hemodynamic
%	   delay).
%
% 09/2005 SOD: removed phasemap requirement so any colormap can be
% flipped.


% Check to see if phases are on display
%if ~strcmp(view.ui.displayMode,'ph')
%  disp(' Must be displaying phase data to rotate the colormap');
%  return
%end
 
whichMode = [view.ui.displayMode 'Mode'];
disp(sprintf('Flipping %s colormap.',whichMode));

nG = view.ui.(whichMode).numGrays;
nC = view.ui.(whichMode).numColors;
cmap=view.ui.(whichMode).cmap;

cmap(nG+1:nG+nC,:) = flipud(cmap(nG+1:nG+nC,:));
view.ui.(whichMode).cmap=cmap;


return;
% old code
nG = view.ui.phMode.numGrays;
nC = view.ui.phMode.numColors;
cmap=view.ui.phMode.cmap;

cmap(nG+1:nG+nC,:) = flipud(cmap(nG+1:nG+nC,:));
view.ui.phMode.cmap=cmap;


