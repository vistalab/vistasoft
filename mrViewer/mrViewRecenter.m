function ui = mrViewRecenter(ui, orientation);
% ui = mrViewRecenter([ui], [orientation]);
%
% This is a callback for the mrViewer UI; it sets
% the cursor position based on where the subject
% has clicked in the mrViewer display.
% 
% orientation is an integer from 1-3 that specifies which ui
% the user has clicked on. 
%       1 -- ui is axial (columns | slices)
%       2 -- ui is coronal (rows | slices)
%       3 -- ui is sagittal (rows | columns)
%
% Alternately,  orientation can be 'roi',  in which
% case the viewer will be recentered to the center-of-mass
% of the current ROI.
%
% 07/05 ras,  based on old recenter3View code.
if ~exist('ui', 'var') | isempty(ui),  ui = mrViewGet; end


if isequal(orientation,  'roi')
    if isempty(ui.rois)
        myErrorDlg('No ROIs specified.');
    end
    roi = mrViewGet(ui,  'roi');
    loc = mean(roi.coords');  
    
elseif isnumeric(orientation)   
    pts = get(gca, 'CurrentPoint');
    locX = round(pts(1, 1));
    locY = round(pts(1, 2));
    
	% initiale vector of cursor loc
	loc = ui.settings.cursorLoc;
	
    if ui.settings.displayFormat==1
        % for montage views,  it may be possible to click on 
        % a slice other than the one specified by the slice
        % slider. Infer from axes' position (may be a more elegant
        % way to do this):
        pos = get(gca, 'Position');
        if ui.settings.displayFormat==1
            nrows = ui.settings.montageRows; 
            ncols = ui.settings.montageCols;
        else
            nrows = 1; ncols = 1;
        end
        ysz = 1/nrows; xsz = 1/ncols; 
        row = nrows - floor(pos(2)/ysz);
        col = floor(pos(1)/xsz) + 1;
        val = ui.settings.slice + (row-1)*ncols + col - 1;
        loc(orientation) = val;
		
    elseif ui.settings.displayFormat==3
        % single slice: set to cur slice
        loc(orientation) = ui.settings.slice;
		
    end

    % figure out 3-D location,  based on orientation
    otherDims = setdiff(1:3, orientation);
    loc(otherDims) = [locY locX];
    	
else
    error('Invalid Orientation');
    
end

ui = mrViewSet(ui, 'cursorLoc', round(loc));

return
