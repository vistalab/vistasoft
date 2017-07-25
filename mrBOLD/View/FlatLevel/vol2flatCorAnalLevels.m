function flat = vol2flatCorAnalLevels(gray,flat,selectedScans,interpFlag,forceSave)
%
% function vol2flatCorAnalLevels(gray,flat,[selectedScans,interpFlag,forceSave])
%
% This converts a corAnal from a gray view to 
% a flat across-levels view. (It used to work
% on a traditional view, creating multiple maps,
% but that's been removed in favor of a single
% useful flat view).
%
% selectedScans: 
%   0 - do all scans
%   number or list of numbers - do only those scans
%   default - prompt user via chooseScans dialog
%
% interpFlag: if 1, will use the interp3 command to interpolate
% the map smoothly within a level. Otherwise, uses nearest-neighbor
% approach: each value in the map has exactly one corresponding
% point on the flat (may look artificially patchy, b/c of the 
% mesh points, but is kosher if e.g. the map represents statistical
% values like p-values).
%
% forceSave: if entered as 1, will save the par map without prompting
% even if it already exists in the flat directory. Added this to 
% help with automated xformation of many maps.
%
% If you change this function make parallel changes in:
%    ip2volCorAnal, ip2volParMap, ip2volSpatialGradient, ip2volTSeries, 
%    vol2flatCorAnal, vol2flatTSeries
%
% djh, 2/2001, mrLoadRet-3.0
% ras, 5/2004, added forceSave argument
% ras, 5/2004, based on vol2flatParMap
% ras, 9/2004, updated to work with flat multi-level view
if ieNotDefined('interpFlag')   interpFlag = 1;     end

if ieNotDefined('forceSave')    forceSave = 0;      end

% Don't do this unless gray is really a gray and flat is really a flat
if ~strcmp(gray.viewType,'Gray') | ~strcmp(flat.viewType,'Flat')
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
    selectedScans = chooseScans(gray);
elseif selectedScans == 0
    selectedScans = 1:nScans;
end
if isempty(selectedScans)
  disp('Analysis aborted')
  return
end

% Check that dataType is the same for both views. If not, doesn't make sense to do the xform.
% because for example the two dataTypes may have a different number of scans.
checkTypes(gray,flat);

% Initialize co, amp, and ph.
% If empty, initialize to cell array.
% If non-empty, grab it so that it can be updated
if isempty(flat.co)
    loadCorAnal(flat);
end

if ~isempty(flat.co)
    co = flat.co;
else
    co = cell(1,nScans);
end

if ~isempty(flat.amp)
    amp = flat.amp;
else
    amp = cell(1,nScans);
end

if ~isempty(flat.ph)
    ph = flat.ph;
else
    ph = cell(1,nScans);
end

% Mask image for masking the flat map away from where we have data
% (ras 05/06/04: make it if it's not made ... this is true for
% hidden flat views):
if ~isfield(flat.ui,'mask')    flat = makeFlatMask(flat);   end
mask = flat.ui.mask;

% find the gray levels in the flat view
nodes = viewGet(gray,'nodes');
grayLevels = unique(nodes(6,:));

% main loop: xform a separate map for each gray level slice
% this is ignoring the first two slices, which are avg across levels
for slice = 3:numSlices(flat)
    
    % figure out the hemisphere, gray level we're on
    if slice <= (2+flat.numLevels(1))
        h = 1;
    else
        h = 2;
    end
    level = slice - (h-1)*flat.numLevels(1) - 2;

    % get the subset of gray / flat coords for this slice
    sliceCoords = flat.coords{slice};
    sliceGrayCoords = flat.grayCoords{slice};

	% Intersect the coords from the gray view and the flat view
    [intersectCoords grayIndices flatIndices] = intersectCols(gray.coords,sliceGrayCoords);
        
    % check if any coords were lost (a weak error-check: when the 
    % flat level coords were built, the coords put in flat.coords
    % should all already be in the Rx; if not, something's changed)
    if ~isequal(intersectCoords,sliceCoords)
        warning('vol2flatCorAnalLevels: Hmm, some coords were lost...');
    end
    
    % Put up mrvWaitbar (progress for current gray level)
    waitMsg = sprintf('Transforming CorAnal Fields, Gray Level %i...',level);
	waitHandle = mrvWaitbar(0,waitMsg);
    
	% Loop through the scans
	for scan = selectedScans
        
        % if there are corAnal fields for this scan, xform 'em
        if ~isempty(gray.co{scan})
            % Get the data corresponding to gray coords
            coData = gray.co{scan}(grayIndices);
            zData = gray.amp{scan}(grayIndices) .* exp(i*gray.ph{scan}(grayIndices));
                        
            % Map the data (interpolate if selected)
            % The operator .' is the NON-CONJUGATE transpose.  Very important.
            if interpFlag==1
                % JL 200705 NaNs in griddata will ruin flat. remove them.
                nonans = find(~isnan(coData)); coords = coords(:,nonans);
                coData = coData(:,nonans); zData = zData(:,nonans);
                
                coIm = myGriddata(sliceCoords,coData.',mask(:,:,slice));
                zIm = myGriddata(sliceCoords,zData.',mask(:,:,slice));
            else
                % do nearest-neighbor mapping -- not clean, but
                % more kosher for things like p-values
                coIm = zeros(size(flat.anat(:,:,slice)));
                zIm = zeros(size(flat.anat(:,:,slice)));
                if ~isempty(sliceCoords)
                    sliceCoords = round(sliceCoords);
                    imgInd = sub2ind(size(coIm),sliceCoords(1,:),sliceCoords(2,:));
                    coIm(imgInd) = coData;
                    zIm(imgInd) = zData;
                end
            end
            
            % pull amp and phase out of the complex z values
            ampIm = abs(zIm);
            phIm = angle(zIm);	

            % Wrap the phases > 0
            phIm(phIm<0) = phIm(phIm<0) + (2*pi);

            % Fill the corAnal matrices
            co{scan}(:,:,slice) = coIm;
            amp{scan}(:,:,slice) = ampIm;
            ph{scan}(:,:,slice) = phIm;
        end
        
        % compute 'mean' value across levels
		% For many statistical maps, the mean may be non-kosher
		% median may work, but I like the max:
		% (acutally, just set zeros for now):
        co{scan}(:,:,1:2) = 0;
        amp{scan}(:,:,1:2) = 0;
        ph{scan}(:,:,1:2) = 0;

        % update mrvWaitbar
        mrvWaitbar(find(selectedScans==scan)/length(selectedScans),waitHandle);
	end    
    
	close(waitHandle);
end

% Fill the fields
disp('Setting co, amp, and ph fields in flat.');
flat.co = co;
flat.amp = amp;
flat.ph = ph;

% Save the new co, amp, and ph arrays in the flat subdirectory.
% if a corAnal file already exists, query user about over-writing
% it.
% NOTE: This will save over an existing normal
% flat view corAnal -- need to figure out a 
% way to resolve this conflict!
saveCorAnal(flat);

return




