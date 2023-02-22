function [montage, vw] = inplaneMontage(vw, slices, mode, zoom)
% [montage, vw] = inplaneMontage(vw, [slices], [mode], [zoom]):
%
% display a montage of all the inplane slices in the Inplane vw window,
% with the selected mode overlayed.
%
% 'slices:' vector specifying which slices to show. If omitted, shows all
% slices.
%
% 'mode', if not entered, defaults to the currently selected vw mode.
%
% For hidden views, mode can be entered as a struct, with info that
% would otherwise be gotten from the UI:
%   mode.clipMode -- 'auto' or [min max] of clipping for any overlay
%   mode.numGrays -- # gray values for underlay/anat
%   mode.numColors -- # colors for overlay
%   mode.cmap -- a color map
%   mode.cothresh -- coherence threshold for overlay
%   mode.mapWindow -- window of parm map vals for overlay
%   mode.phWindow -- phase window for overlay
%   mode.displayMode -- name of display mode to use
%   These fields aren't all required, and reasonable defaults will
%   be selected if any are omitted.
%
% 'zoom', if entered, will only make a montage of the selected zoomed
% region. zoom should be a 1x4 vector of values in the format of axis
% values [xmin xmax ymin ymax]
%
% 02/20/04 ras. (a lot of this is taken from recomputeImage)
% 09/04 ras -- changed name to inplaneMontage, to be consistent
% with the term used elsewhere (OED seems to suggest this is also
% a better description).
% 06/05 ras -- added ability to pass in mode struct for hidden views.
% 03/06 ras -- for auto clip modes, now sets clip range to be min/max of
%              all rendered slices, not just the last one.
if ~exist('slices','var') || isempty(slices),
	slices = 1:viewGet(vw, 'numSlices');
end

if ~exist('mode','var') || isempty(mode),
	mode = viewGet(vw,'Display Mode');
    %Old: vw.ui.displayMode;
end

if ~exist('zoom','var') || isempty(zoom),
	% TO DO: upate viewGet to get zoom properly for all vw types
	if checkfields(vw, 'ui', 'zoom');
		zoom = viewGet(vw,'zoom');
        %Old: vw.ui.zoom;
	else
		dims = viewGet(vw,'Size');
		zoom = [1 dims(2) 1 dims(1)];
	end
end

% check that 1st zoom pt is < 2nd zoom pt
if zoom(1) > zoom(2), zoom(1:2) = zoom([2 1]); end
if zoom(3) > zoom(4), zoom(3:4) = zoom([4 3]); end

% Initialize images
montage = [];
overlay = [];

if isstruct(mode)
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% for hidden views, get mode info from struct %
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	if ~isfield(mode,'clipMode'), mode.clipMode = 'auto'; end
	if ~isfield(mode,'numGrays'), mode.numGrays = 128; end
	if ~isfield(mode,'numColors'), mode.numColors = 128; end
	if ~isfield(mode,'cmap'), mode.cmap = hotCmap(128,128); end

	if ~isfield(mode,'cothresh'),   mode.cothresh   =  0;       end
	if ~isfield(mode,'mapWindow'),  mode.mapWindow  = [0 1000]; end
	if ~isfield(mode,'phWindow'),   mode.phWindow   = [0 2*pi]; end

	if ~isfield(mode,'displayMode'), mode.displayMode = 'anat'; end

	numColors = mode.numColors;
	numGrays  = mode.numGrays;
	cothresh  = mode.cothresh;
	mapWindow = mode.mapWindow;
	phWindow  = mode.phWindow;

	mode = mode.displayMode;
else
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% non-hidden views: get info from UI %
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	modeInfo = viewGet(vw,[mode 'Mode']);

	% Get cothresh, phWindow, and mapWindow from sliders
	cothresh    = viewGet(vw, 'cothresh');
	phWindow    = viewGet(vw, 'phWindow');
	mapWindow   = viewGet(vw, 'mapWindow');
	numGrays = modeInfo.numGrays;
	numColors = modeInfo.numColors;
end

% now decide appropriate [min max] vals for the clip mode, in clim:
clim = viewGet(vw,'cmap cur mode clip');
    %Old: vw.ui.([mode 'Mode']).clipMode;
if (isequal(clim, 'auto') || isempty(clim))
	switch mode
		case 'anat', clim = [0 0];  % shouldn't apply, no overlay
		case 'ph', clim = phWindow;
		case 'co', 
			data = viewGet(vw,'Scan Co');
			%Old: vw.co{vw.curScan}
            clim = [cothresh max(data(:))];
		case 'amp',
			data = viewGet(vw,'Scan Amp');
            %Old: vw.amp{vw.curScan};
			co = viewGet(vw, 'Scan Co');
            %Old: vw.co{vw.curScan};  % assuming this is assigned... -
            %Should never assume! This is now working correctly.
			ok = find(co >= cothresh);
			clim = [min(data(ok)) max(data(ok))];
		case 'map', 
			try
				data = viewGet(vw, 'Scan Map');
                %Old: vw.map{vw.curScan};
				ok = find(data >= mapWindow(1) & data <= mapWindow(2));
				clim = [min(data(ok)) max(data(ok))];
			catch
				clim = getMapWindow(vw);
			end
	end
end
	 

% get # of slices; figure out a good # of rows, cols for montage
nSlices = length(slices);
nrows = ceil(sqrt(nSlices));
ncols = ceil(nSlices/nrows);

for row = 1:nrows
	rowIm = [];

	for col = 1:ncols
		sliceind = (row-1)*ncols + col;

		if sliceind <= length(slices)
			% if there's a slice for this row/col
			slice = slices(sliceind);
		else
			% otherwise, set it to show black space below
			slice = slices(end) + 1;
		end

		if slice <= slices(end)
			% Get anatomy image
			anatIm = recomputeAnatImage(vw, 'anat', slice);            
			% Get overlay
			overlay = [];
			if ~strcmp(mode,'anat')
				overlay = cropCurSlice(vw,mode,slice);
			end

			% Select pixels that satisfy cothresh, phWindow, and mapWindow
			pts = [];
			if ~isempty(overlay)
				pts = ones(size(overlay));

				if cothresh>0
					if strcmpi(mode,'cor'); % correlation coefficient mode special handling
						ptsCo = abs(overlay) > cothresh; % double-sided using coThresh
					else % normal mode: coherence
						curCo = cropCurSlice(vw,'co',slice); ptsCo = 1;
						if ~isempty(curCo); ptsCo = curCo > cothresh; end;
					end
					pts = pts & ptsCo;
				end

				curPh = cropCurSlice(vw, 'ph', slice);
				if ~isempty(curPh)
					if diff(phWindow) > 0
						ptsPh = (curPh>=phWindow(1) & curPh<=phWindow(2));
					else
						ptsPh = (curPh>=phWindow(1) | curPh<=phWindow(2));
					end
					pts = pts & ptsPh;
				end

				%               if strcmp(vw.ui.displayMode, 'amp')
				%                 curAmp = cropCurSlice(vw, 'amp', slice);
				%                 mnv = min(curAmp(:));
				%                 mxv = max(curAmp(:));
				%                 curMap = (curAmp - mnv) ./ (mxv - mnv);
				%               end

				curMap = cropCurSlice(vw,'map',slice);
				if ~isempty(curMap)
                    if diff(mapWindow)>0
                        ptsMap = (curMap>=mapWindow(1) & curMap<=mapWindow(2));
                    else
                        ptsMap = (curMap>=mapWindow(1) | curMap<=mapWindow(2));
                    end
                    
                    pts = pts & ptsMap;
				end
			end

			% Rescale overlay to map to the color part of the cmap range
			if ~isempty(overlay)
				overlayRange = numGrays + [1 numColors];
				overlay = rescale2(overlay, clim, overlayRange);				
			end

			% Combine overlay with anatomy image
			if ~isempty(overlay)
				% Combine them in the usual way
				im = anatIm;
				indices = find(pts);
				im(indices) = overlay(indices);
			else
				% No overlay.  Just show anatomy image.
				im = anatIm;
			end

			% zoom
			zoom = round(zoom);
			im = im(zoom(3):zoom(4), zoom(1):zoom(2));
		else
			% there may be blank spaces at the end of the montage image
			im = zeros(size(im));
		end
        if viewGet(vw, 'flipUD'),im = flipud(im);   end
		rowIm = [rowIm im];
	end

	montage = [montage; rowIm];
end


if isfield(vw,'ui') && ~isequal(viewGet(vw,'name'),'hidden')
	if isempty(montage)
		vw = zoomInplane(vw, 1);
		myWarnDlg('Zoom produces an empty image. Resetting...')
		return
	end

	if isempty(overlay)
		vw.ui.cbarRange = [];
	else
		vw.ui.cbarRange = clim;
	end

	% show the montage in the vw window
	figure(vw.ui.windowHandle);
	axes(vw.ui.mainAxisHandle);
	cmap = eval(['vw.ui.' mode 'Mode.cmap']);
	image(montage);
	colormap(cmap);
	axis image;
	axis off;
	montage = ind2rgb(montage,cmap); % make truecolor
	%     imshow(montage);

	% set as the vw's image
	vw.ui.image = montage;
end

return
