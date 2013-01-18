function view = linearizeCmap(view)
%
% AUTHOR: Baseler/Poirson/Huk
% DATE:   3.4.99
% PURPOSE: Correct for the non linear input-output relationship
%	   between colormap entries and colors produced on the
%          the monitor.  This works best for 'hsv' colormaps.
% USAGE:   
% HISTORY:  2.28.97 hab, poirson    Wrote mrLinearCmap
%           3.4.99 huk              Updated to mrLoadRet-2.0
% INPUT:   view (i.e. FLAT, INPLANE, or VOLUME)
% OUTPUT:  view with corrected colormap
%
% 2006/10 SD: updated so it works for every displayMode and colormap.

gammaLeft = 2;
gammaRight = 1.3;
 

cmap = eval(['view.ui.' view.ui.displayMode 'Mode.cmap']);
nGrays = eval(['view.ui.' view.ui.displayMode 'Mode.numGrays']);
nColors = eval(['view.ui.' view.ui.displayMode 'Mode.numColors']);

% different correction for different parts
iiLower = [nGrays+1:nGrays+round(nColors/2)];
iiUpper = [round(nGrays+nColors/2)+1:nGrays+nColors];

cmap(iiLower,:) = cmap(iiLower,:).^(1/gammaLeft);
cmap(iiUpper,:) = cmap(iiUpper,:).^(1/gammaRight);

colormap(cmap);

eval(['view.ui.' view.ui.displayMode 'Mode.cmap=cmap;']);

return





