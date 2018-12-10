function view = getFlatCoords(view)
%
% view = getFlatCoords(view)
%
% view: must be a flat view
%
% Loads gLocs2d and gLocs3d coordinates.  Keeps only those voxels
% that correspond to the inplane coordinates.  Sets FLAT
% fields: coordsRight, coordsLeft, grayCoordsRight,
% grayCoordsLeft.
%
% djh, 7/98
%
% djh, 8/4/99.  Use intersectCols instead of intersecting the indices.
% djh, 8/18/99.  loadGLocs now returns curvature.

if ~strcmp(view.viewType,'Flat')
    myErrorDlg('function getFlatCoords only for Flat view.');
end

pathStr=fullfile(viewDir(view),'coords');

if ~check4File(pathStr)
    imSize=[0,0];
    waitHandle = mrvWaitbar(0,'Computing flat coordinates.  Please wait...');
    for h = 1:2
        mrvWaitbar((h-1)/2)
        
        % Load gLocs2d and gLocs3d
        %
        if h==1
            [gLocs2d,gLocs3d,curvature,leftPath] = loadGLocs('left');
        else
            [gLocs2d,gLocs3d,curvature,rightPath] = loadGLocs('right');
        end
        
        if isempty(gLocs2d) | isempty(gLocs3d)
            coords{h} = [];
            grayCoords{h} = [];
        else
            % Compute imSize
            %
            imSize = max(imSize,(max(gLocs2d,[],2) - min(gLocs2d,[],2) + 1)');
            imSize = round(imSize);
            
            % Find gray nodes that are both in the inplanes and included
            % in the unfold.
            % gray.coords are the gray coords that lie in the inplanes.
            % gLocs3d are the gray coords in the unfold.
            hiddenGray = initHiddenGray;
            [grayCoordsTmp,gLocsIndices,coordsIndices] = ...                
                intersectCols(gLocs3d,hiddenGray.coords);
            grayCoords{h} = grayCoordsTmp;
            
            % Flat locations corresponding to those voxels
            % 
            coords{h} = gLocs2d(:,gLocsIndices);
            
            % Warning if there are any NaNs in the coords.
            NaNs = find(isnan(coords{h}(1,:)) | isnan(coords{h}(2,:)));
            if ~isempty(NaNs)
                myWarnDlg(['You have ',int2str(length(NaNs)),' NaNs in your flat coords.  ',...
                        'Those gray matter nodes will not be rendered in the FLAT view.']);
            end
        end
    end
    close(waitHandle)
    
    % Save to file
    %
    save(pathStr,'coords','grayCoords','imSize','leftPath','rightPath');
end

% Load Flat/coords and fill the fields
% 
load(pathStr);
view.coords = coords;
view.grayCoords = grayCoords;
view.leftPath = leftPath;
view.rightPath = rightPath;
view.ui.imSize = imSize;
