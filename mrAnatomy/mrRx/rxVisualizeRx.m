function h = rxVisualizeRx(rx, loc);
%
% h = rxVisualizeRx(rx, [loc]);
%
% Display a visualization of the current prescription in a separate
% figure. Shows a montage of interpolated slices, and, if the
% Rx Figure is also open, adds a panel with sagittal, coronal, and
% axial views with the prescription on it.
%
% 'loc' is an optional argument for visualizing the rx, specifying
% the [axi cor sag] slices to show in the Rx views.
%
% ras, 01/2007.
if notDefined('rx'), rx = get(findobj('Tag','rxControlFig'), 'UserData'); end
if ishandle(rx),	rx = get(rx, 'UserData');				end

h = figure('Color', 'w');

nSlices = rx.rxDims(3);
for slice = 1:nSlices
	[img2D images{slice}] = rxInterpSlice(rx, slice);
end

montage = imageMontage(images);
imagesc(montage); axis image; axis off;
title('Prescribed Slices');


%% draw ROIs if selected
if ~isempty(rx.rois) & get(rx.ui.rxDrawRx, 'Value')==1
	for r = 1:length(rx.rois)
		% convert coords from vol -> rx
		rxCoords = vol2rx(rx, rx.rois(r).volCoords, 1);

		% now convert these coords to 2-D image coordinates
		pts = rxCoords2Montage(rxCoords, nSlices, size(img2D));

        if isempty(pts), continue; end
        
        % remove pts outside range
        outside = find(pts(1,:) < 1 | pts(1,:) > size(montage, 1) ...
                       | pts(2,:) < 1 | pts(2,:) > size(montage, 2));
        ok = setdiff(1:size(pts, 2), outside);
        pts = pts(:,ok);
        
		% draw the outline of this ROI
		% (rx.rois(r) doubles as a prefs struct, to set the color)
		outline(pts, rx.rois(r));
	end
end


%% add panel with views of the Rx on each plane
if ishandle(rx.ui.rxAxes)
	if notDefined('loc'),   loc = round( rx.volDims / 2 );  end
	if ischar(loc),         loc = str2num(loc);             end
    

	%% open a panel to the right of the main figure w/ the Rxs
	hp = mrvPanel('right', .3);

	%% put up the prescriptions
	for ori = 1:3
		vol = rx.vol;
		volSlice = uint8(loc(ori));

		%% orient the slice properly
		if ori~=3   % do nothing for sagittal view
			% allow for radiological L/R
			hRadiological = findobj('Tag','rxRadiologicalMenu');
			if isequal(get(hRadiological, 'Checked'), 'on')
				vol = flipdim(vol, 3);
			end

			% permute volume as needed
			if ori==1, vol = permute(vol,[2 3 1]); end   % axial
			if ori==2, vol = permute(vol,[1 3 2]); end   % coronal
		end


		%% plot the slice 
		% get slice
		volImg = vol(:,:,volSlice);
		volImg = rxClip(volImg, [], rx.ui.volBright, rx.ui.volContrast);

		% make subplot
		pos = [0 1-(ori/3) 1 .3];
		hax(ori) = axes('Parent', hp, 'Units', 'norm', 'Position', pos);
		
		% put up image
		htmp = image(volImg); colormap gray; axis off; axis equal;
		
		% draw Rx, label directions
		rxDrawRx(rx, volSlice, ori);  hold on
		rxLabelVolAxes(rx, ori);

		%% draw ROIs on prescription, if selected
		if ~isempty(rx.rois) & get(rx.ui.rxDrawRx, 'Value')==1
			for r = 1:length(rx.rois)
				R  = rx.rois(r);  % ROI struct
				C  = R.volCoords; % coords (being terse b/c of indents)

				% map the [axi cor sag] positions in C to the
				% 2D [x y] positions in pts:
				inSlice = find( round(C(ori,:)) == volSlice );
				switch ori
					case 1, % axi
						pts = C([2 3],inSlice);
					case 2, % cor
						pts = C([1 3],inSlice);
					case 3, % sag
						pts = C([1 2],inSlice);
				end
				
				% Draw the ROI outline
				if ~isempty(pts)
					outline(pts, R);
				end
			end
		end


	end
end

return
% /------------------------------------------------------------/ %



% /------------------------------------------------------------/ %
function pts = rxCoords2Montage(coords, nSlices, dims);
% convert 3-D volume coordinates into 2-D points on a montage
% of prescription slices.  This assumes that imageMontage has
% been called on all slices (1:nSlices), with the default #
% of columns and rows.
ncols = ceil( sqrt( nSlices ) );
nrows = ceil( nSlices / ncols );

% initialize pts output:
pts = [];

for slice = 1:nSlices
	% find (row, col) of this slice in the montage
	row = ceil(slice / ncols);
	col = mod(slice-1, ncols) + 1;

	% find columns of coords in this slice
	I = find( round(coords(3,:)) == slice );

	% main part: compute (x,y) locations given the montage offset
	y = coords(1,I) + (row-1) * dims(1);
	x = coords(2,I) + (col-1) * dims(2);

	% add to points list:
	% we will shuffle the order of coordinates in coords,
	% but remove points outside the Rx.
	pts = [pts [y; x]];
end

return
