function view = makePointROI(view, pt, createNew)
% Create a region of interest comprising a single voxel.
%
% view = makePointROI([view], [pt=get from UI], [createNew=1]);
%
% view: mrVista view structure. [Default: current view]
%
% pt: 3-element vector specifying the point. In inplane, this is
%	  [row col slice] of the coordinates, relative to the inplane anatomy;
%	  in gray/volume views, this is [axi cor sag] slice specification; in
%	  flat views, it's [x y hemisphere].
%	  [Default: for 3-view windows, take from the crosshairs position. For
%	  other views, prompts the user to type in the coords.]
%
% createNew: flag to make a new ROI with the point. [default 1] Otherwise,
% will add the point to the view's selected ROI -- much like addROIpoints,
% but allows for a more precise way of specifying the coords.
%
% ras, 09/2008.
if notDefined('view'),			view = getCurView;				end
if notDefined('createNew'),		createNew = 1;					end
if notDefined('pt')
	if checkfields(view, 'loc')
		pt = view.loc;
	else
		pt = inputdlg({'Enter the point coordinates:'}, mfilename, 1);
		pt = str2num(pt{1});
	end
end

% check that the point is valid
if length(pt)~=3
	error('point must be a 3-element vector.')
end


if createNew==1
	view = newROI(view, sprintf('Point %s', num2str(pt)), [], [], pt(:));

else
	if isempty(view.ROIs) || view.selectedROI < 1
		error('No existing ROIs in view.')
	end
	roi = view.ROIs(view.selectedROI);
	if isempty(roi.coords)
		roi.coords = pt(:);
	else
		roi.coords(:,end+1) = pt(:);
	end
	view.ROIs(view.selectedROI) = roi;
end

return
