function view = cmapRedgreenblue(view, displayMode, hemi);
%
% view = cmapRedgreenblue(view, [displayMode='ph'], [hemi=1]);
%
% Set the color map for a view's display mode (default phase mode) to 
% be a 'redgreenblue' cmap, a custom map Rory has found is useful in 
% lookint at retinotopy data.
%
% The 'hemi' flag can be set to 0, 1 or 2: if 1, will make the second half of
% the colors be uniform gray, as if it was representing a non-mapped range
% of phases. If 0, will fill it with a blue->yellow->red submap, for
% looking at bilateral activations (e.g., in two hemispheres). If 2, will
% fill the entire cmap with the r->g->b cmap. (You can later reduce the range 
% using cmapExtended. [Default is 1: only show 1 hemifield.] 
%
% The redgreenblue cmap shows simple transititions between three colors
%
%
% ras, 10/2006.
% ras, 04/2009 -- got the 'both' option to work well.
if notDefined('view'),              view = getCurView;      	end
if notDefined('displayMode'),       displayMode = 'ph';         end
if notDefined('hemi'),              hemi = 1;                   end
modeInfo = view.ui.([displayMode 'Mode']);

nG = modeInfo.numGrays;
nC = modeInfo.numColors;

% build two colormaps: a red->green->blue map, 
% and a blue->yellow->red map, each using half
% the available colors:
rgb = mrvColorMaps('redgreenblue', round(nC/2));
switch hemi
	case 0
		byr = repmat(.6, [nC/2 3]);
		subCmap = [rgb; byr];

	case 1
			byr = mrvColorMaps('redyellowblue', round(nC/2));
			byr = flipud(byr);

% 		% alternate mnemonic:
% 		% red is RIGHT, green is LEFT, blue is UP (like sky), yellow is DOWN
% 		% (like sand)
% 		gbr = mrvColorMaps('greenbluered', round(nC/2), 2);
% 		ryg = flipud(gbr);
% 		ryg(:,2) = ryg(:,2) + ryg(:,3); 
% 		ryg(:,1) = ryg(:,1) + ryg(:,3);
% 		ryg(:,3) = 0;
% 		ryg(ryg > 1) = 1;  ryg(ryg < 0) = 0;
% 		subCmap = flipud([gbr; ryg]);
% 		subCmap = circshift(subCmap, round(nC/4));
		subCmap = [rgb; byr];
		
	case 2
		byr = flipud( mrvColorMaps('redgreenblue', nC-size(rgb,1)) );
		subCmap = [rgb; byr];

	otherwise
		error('Invalid hemifield flag.');
end

modeInfo.cmap = [gray(nG); subCmap];
modeInfo.name = 'redgreenblue cmap';

% override: let you set a the rgb cmap as the whole deal:
if hemi==2, modeInfo.cmap = [gray(nG); mrvColorMaps('redgreenblue', nC)]; end
% if hemi==2, modeInfo.cmap = [gray(nG); mrvColorMaps('gbr', nC, 4)]; end
    
view.ui.([displayMode 'Mode']) = modeInfo;

% view = refreshScreen(view);

return
