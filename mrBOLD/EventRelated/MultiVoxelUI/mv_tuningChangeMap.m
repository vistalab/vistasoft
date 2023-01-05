function mv = mv_tuningChangeMap(mv);
%
% mv = mv_tuningChangeMap(mv);
%
% For multi-voxel UI, create a map in which the value for each voxel 
% measures the change in stimulus "tuning" (i.e., the N-dimensional 
% vector of response amplitudes to each of the N selected stimulus 
% conditions) between that voxel and its neighbors.
%
% Note that the determination of what a voxel's neighbors are depends on
% the view:
%   Inplane views: the neighbors are neighboring 6-connected voxels in the
%                  inplane data, independent of whether these neighbors
%                  are in the gray, white matter, csf, or other;
%   Gray views:    determined using the gray graph.
%   
% Flat and Volume views are not yet supported.
%
% ras, 11/05.
if ieNotDefined('mv'), mv = get(gcf, 'UserData'); end

switch mv.roi.viewType
    case 'Inplane',  
        nVoxels = size(mv.coords, 2);

        % get amplitudes for each voxel
        amps = mv_amps(mv);
        
        % initialize map vals
        vals = zeros(1, nVoxels);
        
        % create an 'offset' matrix describing where neighbors in 
        % 6-connected data would be -- this will be useful for finding 
        % neighbor coords in the main loop:
        offsets = [-1 0 0; 1 0 0; 0 -1 0; 0 1 0; 0 0 -1; 0 0 1]';
        
        %%%%%main loop
        hwait = mrvWaitbar(0, 'Computing Tuning Change Map...');
        for v = 1:nVoxels
            % find indices I of neighboring voxels
            pt = mv.coords(:, v);
            neighbors = repmat(pt, [1 6]) - offsets;
            [found I] = intersectCols(mv.coords, neighbors);
            
            if isempty(I)
                % no neighbors contained in the multi-voxel data:
                % set value for this point to -1:
                vals(v) = -1;
            else
                % get amplitudes for this voxel, neighbors
                A = amps(v, :); % amplitudes for this voxel
                B = amps(I, :); % amplitudes for neighbors

                % compute mean Euclidean distance between A and columns
                % in B:
                diff = [B - repmat(A, [1 size(B,2)])];            
                dist = sqrt(sum(diff.^2));
                vals(v) = mean(dist);
            end
            
            mrvWaitbar(v/nVoxels, hwait);
        end
        close(hwait);
        
        % Create a map volume with the tuning values
        mrGlobals; loadSession;
        hI = initHiddenInplane(mv.params.dataType, mv.params.scans(1));
        mapvol = zeros(dataSize(hI));
        mapvol(roiIndices(hI, mv.coords)) = vals;

        % export as map        
        hI.map = cell(1, numScans(hI));
        hI.map{mv.params.scans(1)} = mapvol;        
        hI.mapName = 'Tuning_Change_Map';
        saveParameterMap(hI, [], 1); 
        
        
    case 'Gray', 
        nVoxels = size(mv.coords, 2);

        % get amplitudes for each voxel
        amps = mv_amps(mv);
        
        % initialize map vals
        vals = zeros(1, nVoxels);
        
        % create an 'offset' matrix describing where neighbors in 
        % 6-connected data would be -- this will be useful for finding 
        % neighbor coords in the main loop:
        offsets = [-1 0 0; 1 0 0; 0 -1 0; 0 1 0; 0 0 -1; 0 0 1]';
        
        %%%%%main loop
        hwait = mrvWaitbar(0, 'Computing Tuning Change Map...');
        for v = 1:nVoxels
            % find indices I of neighboring voxels
            pt = mv.coords(:, v);
            neighbors = repmat(pt, [1 6]) - offsets;
            [found I] = intersectCols(mv.coords, neighbors);
            
            if isempty(I)
                % no neighbors contained in the multi-voxel data:
                % set value for this point to -1:
                vals(v) = -1;
            else
                % get amplitudes for this voxel, neighbors
                A = amps(v, :); % amplitudes for this voxel
                B = amps(I, :); % amplitudes for neighbors

                % compute mean Euclidean distance between A and columns
                % in B:
                diff = [B - repmat(A, [size(B,1) 1])];            
                dist = sqrt(sum(diff.^2, 2));
                vals(v) = mean(dist(:));
            end
            
            mrvWaitbar(v/nVoxels, hwait);
        end
        close(hwait);
        
        % Create a map volume with the tuning values
        mrGlobals; loadSession;
        hG = initHiddenGray(mv.params.dataType, mv.params.scans(1));
        mapvol = zeros(dataSize(hG));
        mapvol(roiIndices(hG, mv.coords)) = vals;

        % export as map        
        hG.map = cell(1, numScans(hG));
        hG.map{mv.params.scans(1)} = mapvol;        
        hG.mapName = 'Tuning_Change_Map';
        saveParameterMap(hG, [], 1, 0); 
        
    otherwise, % not yet supported 
        error('Sorry, this view type is not yet supported.');
end

return

       
        