function tSeries = meanTSeriesFlatLevels(flat,scans,whichLevels)
% tSeries = meanTSeriesFlatLevels(flat,[scans],[whichLevels]);
%
% For Flat multi-level views:
% 
% Compute the mean tSeries across flat levels, and appends it
% to the current tSeries (which should contain tSeries for 
% each level)
%
% scans: scans to use. Defaults to flat view's current scan.
%
% whichLevels: gray/flat levels to use. Defaults to all available.
%
% ras, 08/2004
mrGlobals;

if ieNotDefined('whichLevels')
    whichLevels = 1:max(flat.numLevels);
end

if ieNotDefined('scans')
    scans = getCurScan(view);
end

% if many scans entered, go recursively
if length(scans) > 1
    for s = scans
        meanTSeriesFlatLevels(flat,s,whichLevels);
    end
    return
else 
    scan = scans;
end

coords = flat.coords;
numLevels = flat.numLevels;
nFrames = numFrames(flat,scan);
hemis = {'left' 'right'};

% use clever indexing to make the calculation of the mean
% tSeries faster:
for h = 1:2    % loop across hemispheres
    
    % initalize tSeries to be empty
    tSeries = [];
    
    % only compute a mean if there's actually a segmentation for this hemi
    if numLevels(h) > 0
        % put up a wait bar        
        msg = sprintf('Computing mean tSeries across gray levels, %s...',hemis{h});
		waitHandle = mrvWaitbar(0,msg);

        % which slices correspond to the data from this hemisphere?
        firstSlice = 2 + (h-1)*numLevels(1) + 1;
        subSlices = firstSlice:firstSlice+length(whichLevels);
                
        % get the coordinates of all x,y positions 
        % for which data were measured for this hemisphere:
        % these are stored as the first two 'slices' in coords
        meanCoords = coords{h}; 

        % initialize a 3D matrix, tMat, of nFrames x voxels in level x
        % nLevels
        tMat = NaN*ones(nFrames,size(meanCoords,2),numLevels(h));
        
        % load tSeries for each slice, assign to appropriate locations
        % in the tMat matrix:
        for level = 1:length(whichLevels)
            slice = subSlices(level);
            
            % load the tSeries for this scan, slice
            sliceTSeries = loadtSeries(flat,scan,slice);
                        
            % find the appropriate indices for the subCoords
            [commonCoords, ia, ib] = intersectCols(meanCoords,coords{slice});
                
            % error check: all the sub-coords should be containied in
            % mean coords, or else buildFlatLevelCoords was wrong
            if length(commonCoords) ~= length(coords{slice})
                close(waitHandle);
                error('buildFlatLevelCoords did something wrong.');
            end
            
            % now assign to the 3D matrix
            tMat(:,ia,level) = sliceTSeries(:,ib);
        end
        
        % average tMat across the levels
        for frame = 1:nFrames
            tmp = permute(tMat(frame,:,:),[3 2 1]);
            tSeries(frame,:) = nanmean(tmp);
            
            mrvWaitbar(frame/nFrames,waitHandle);
        end
    
        close(waitHandle);
    else
        % this is a fix to a rather stupid problem in the
        % selxavg code: it can't deal with empty tSeries.
        % so, create a single voxel of zeros, at a random
        % (but legitimate) location:
        tSeries = zeros(nFrames,1);
        coords{h} = round(flat.ui.imSize(:) ./ 2);
        grayCoords = flat.grayCoords;
        grayCoords{h} = [NaN; NaN; NaN];
        cPath = fullfile(viewDir(flat),'coordsLevels.mat');
        save(cPath,'coords','grayCoords','-append');
        
        eval(sprintf('%s.coords = coords;',flat.name));
        eval(sprintf('%s.grayCoords = grayCoords;',flat.name));
    end
    
    % Save tSeries
    % This does not need to be changed since it is using a 'flat' view
	savetSeries(tSeries,flat,scan,h);
    fprintf('Saved %s flat tSeries for scan %i.\n',hemis{h},scan);
end %for


return



% tSeries = flatLevelTSeries(flat,tSeries);
