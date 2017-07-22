function tSeries = meanTSeriesFlatLevels(flat,scan,whichLevels);
% tSeries = meanTSeriesFlatLevels(flat,[scan],[whichLevels]);
%
% For Flat multi-level views:
% 
% Compute the mean tSeries across flat levels, and appends it
% to the current tSeries (which should contain tSeries for 
% each level)
%
% scan: scan to use. Defaults to flat view's current scan.
%
% whichLevels: gray/flat levels to use. Defaults to all available.
%
% ras, 08/2004
if ieNotDefined('whichLevels')
    whichLevels = 1:max(flat.numLevels);
end

if ieNotDefined('scan')
    scan = getCurScan(view);
end

coords = flat.coords;
numLevels = flat.numLevels;
nFrames = size(tSeries,1);
hemis = {'left' 'right'};

% use clever indexing to make the calculation of the mean
% tSeries faster:
for h = 1:2    % loop across hemispheres
    
    % initalize tSeries to be empty
    tSeries = [];
    
    % only compute a mean if there
    if ~isempty(numLevels(h))
        % which slices correspond to the data from this hemisphere?
        firstSlice = 2 + (h-1)*numLevels(1) + 1;
        subSlices = firstSlice:firstSlice+length(whichLevels);
        
        % initalize meanCoords, which will contain the x,y
        % positions of all measured 
        
		meanIndices = find(coords(3,:)==h);
        meanCoords = coords(1:2,meanIndices); % just want 2D positions
            
		waitHandle = mrvWaitbar(0,'Computing mean tSeries across gray levels...');
		
        % initialize a 3D matrix, tMat, of nFrames x voxels in level x
        % nLevels
        tMat = NaN*ones(nFrames,size(meanCoords,2),numLevels(h));
        
        % now assign each tSeries to the appropriate location
        % in the tMat matrix:
        for level = whichLevels
            % get coordinates within this slice
            slice = 2 + (h-1)*numLevels(1) + level;
            subInd = find(coords(3,:)==slice);
            subCoords = coords(1:2,subInd); % just want 2D positions
            
            % find the appropriate indices for the subCoords
            [commonCoords sliceInds ib] = intersectCols(meanCoords,subCoords);
            
            % now assign to the 3D matrix
            tMat(:,sliceInds,level) = tSeries(:,subInd(ib));
        end
        
        % average across the levels
        for frame = 1:nFrames
            tmp = permute(tMat(frame,:,:),[3 2 1]);
            tSeries(frame,meanIndices) = nanmean(tmp);
            
            mrvWaitbar(frame/nFrames,waitHandle);
        end
    end
    
    % Save tSeries
	savetSeries(tSeries,flat,scan,1);
    fprintf('Saved %s flat tSeries for scan %i.\n',hemis{h},scan);

    close(waitHandle);
end


return



% tSeries = flatLevelTSeries(flat,tSeries);
