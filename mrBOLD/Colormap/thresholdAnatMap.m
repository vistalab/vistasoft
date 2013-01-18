function view = thresholdAnatMap(view, thresh);
% view = thresholdAnatMap(view, [thresh]);
%
% makes the part of the color map that deals with the anatomical 
% image a thresholded gray scale, to see sulci and gyri more clearly. 
% Sets these values for all modes (but doesn't touch the overlay color
% maps).
%
% This is what the current curvature map in mrMesh looks like, and it's
% particularly useful to do this on flat maps, to map between the inflated
% brain and the flat map. 
%
% The optional 'thresh' argument is the minimum gray value for (brighter colored)
% gyri (as opposed to darker sulci); it defaults to 0.5. 
%
% written 01/27/04 ras.
% 04/2009 ras: alternate method: this function now thresolds the view.anat
% directly, rather than messing with the color maps and callbacks. Use
% loadAnat to restore the 
if notDefined('view'), mrGlobals; view=getSelectedFlat; end
if notDefined('thresh'), thresh = 0.5;   end

darkRng = [.3 .5];
lightRng = [.6 .8];

% we start with the existing anatomy, which we'll modify below.
view = loadAnat(view);

% set up the color map
cmap = gray(view.ui.anatMode.numGrays);
cmap(cmap < thresh) = normalize(cmap(cmap < thresh),darkRng(1),darkRng(2));
cmap(cmap >= thresh) = normalize(cmap(cmap >= thresh),lightRng(1),lightRng(2));

% rescale the anatomy as an index into the cmap
cmapRange = [0 size(cmap, 1)-1];

for h = 1:2
	mask = isnan(view.anat(:,:,h));  % no-data mask
	
    newAnat = ind2rgb( rescale2(view.anat(:,:,h), [], cmapRange), cmap );
	newAnat(mask) = 0;
	
	% brutal hack: because the recomputeImage function auto-scales the
	% anatomy image to match the grayscale range, the patch will always
	% look high-contrast with the default color map. Unless we put in a
	% single pixel at max value, which we do here:
	newAnat(mask(1)) = 1;
	
	view.anat(:,:,h) = newAnat(:,:,1);  % grayscale
end

refreshScreen(view);

return