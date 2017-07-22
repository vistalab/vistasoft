function flat = vol2flatTSeriesLevels(gray,flat,selectedScans)
%
% function flat = vol2flatTSeriesLevels(gray,flat,[selectedScans])
%
% This converts tSeries from a volume to flat view separately
% for each gray level in the segmentation, and also computes
% a mean tSeries across the gray levels.
%
% After examining the code, I feel the way this is done is reasonably
% correct (it interpolates data separately for each gray level). The
% original code for this came with a warning that it was not implemented
% properly; the main error I saw was that it interpolated even though
% many gray nodes might project to the same x/y coordinates on the 
% interpolated surface.
%
% There is a flatMulti view for viewing this data. See 
% openFlatLevelWindow.m.
%
% selectedScans: 
%   0 - do all scans
%   number or list of numbers - do only those scans
%   default - prompt user via selectScans dialog
%
% If you change this function make parallel changes in:
%    ip2volCorAnal, ip2volParMap, ip2volSpatialGradient, ip2volTSeries, 
%    vol2flatCorAnal, vol2flatParMap
%
% djh, 2/2001
% ras, 8/2004: made to work with flat multi-level view

% Don't do this unless gray is really a gray and flat is really a flat
if ~strcmp(gray.viewType,'Gray') || ~strcmp(flat.viewType,'Flat')
    myErrorDlg('vol2flatParMap can only be used to transform from gray to flat.');
end


% Check that both gray & flat are properly initialized
if isempty(gray)
    myErrorDlg('Gray view must be open.  Use "Open Gray Window" from the Window menu.');
end

if isempty(flat)
    myErrorDlg('Flat view must be open.  Use "Open Flat Window" from the Window menu.');
end

nScans = numScans(gray);

% (Re-)set scanList
if ~exist('selectedScans','var')
    selectedScans = selectScans(gray);
elseif selectedScans == 0
    selectedScans = 1:nScans;
end

if isempty(selectedScans)
  disp('Analysis aborted')
  return
end

% Check that dataType is the same for both views. If not, doesn't make
% sense to do the xform.
% because for example the two dataTypes may have a different number of
% scans.
checkTypes(gray,flat);

% Mask image for masking the flat map away from where we have data
% (ras 05/06/04: make it if it's not made ... this is true for
% hidden flat views):
if ~isfield(flat.ui,'mask'), flat = makeFlatMask(flat);   end
mask = flat.ui.mask;

% find the gray levels in the flat view
nodes = viewGet(gray,'nodes');
grayLevels = unique(nodes(6,:));
    

% Error check on flatIndices.  
% (the rules for this have changed -- update)

% Loop through the scans, slices
waitHandle = mrvWaitbar(0,'Converting tSeries...');

for scan = selectedScans
    % Load the tSeries
    grayTSeries = loadtSeries(gray,scan,1);

    for slice = 1:numSlices(flat)
        
        % init tSeries to be same size as the flat coords
		tSeries = zeros(size(grayTSeries,1),size(flat.coords{slice},2));
	
        % Intersect the coords from the gray view and the Flat view.
		[subCoords, grayIndices, flatIndices] = ...
            intersectCols(gray.coords,flat.grayCoords{slice});
        
        % Get the data corresponding to flat coords
        tSeries(:,flatIndices) = grayTSeries(:,grayIndices);
                    
        % Save tSeries
        % Should not be saved since this occurs on a 'flat' view
        savetSeries(tSeries,flat,scan,slice);
    end

    mrvWaitbar(find(selectedScans==scan)/length(selectedScans),waitHandle);
    fprintf('Saved flat tSeries for scan %i.\n',scan);
end

close(waitHandle);

% compute mean map across gray levels
meanTSeriesFlatLevels(flat,selectedScans);

return


% The original warning, cautiously removed: ...
% mrErrorDlg('vol2flatTSeries not properly implemented yet. Do not use this function.'); 

% used to compute mean tSeries across levels at this time, now do
% it separately:
%         % compute mean tSeries across levels at the same time
%         tSeries = meanTSeriesFlatLevels(flat,tSeries);

