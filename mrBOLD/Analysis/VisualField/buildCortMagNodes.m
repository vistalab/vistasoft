function cortMag = buildCortMagNodes(cortMag, flatView, grayView)
%
%  cortmag = buildCortMagNodes(cortMag, flatView, grayView)
%
%  Finds the gray matter nodes for all ROI coords. This is a necessary and%  slow
%   step torward computing the cortical magnification function. We should%   avoid doing it
%   more often than necessary.
%
% HISTORY:
%   2002.03.20 RFD (bob@white.stanford.edu) wrote it, based
%   on code by Wandell, Baseler and Brewer.

nodeIndices = {};
data = {};
if(strcmp(cortMag.hemisphere,'left'))
%     nodes = grayView.allLeftNodes;
%     edges = grayView.allLeftEdges;
    slice = 1;
else
%     nodes = grayView.allRightNodes;
%     edges = grayView.allRightEdges;
    slice = 2;
end
nodes = grayView.nodes;
edges = grayView.edges;

for(roiNum=1:length(cortMag.ROIs))
    disp(['Finding nodes for ROI ',num2str(roiNum),' of ',num2str(length(cortMag.ROIs)),'...']);
    coords = cortMag.ROIs(roiNum).coords;
    if(isempty(coords))
        nodeIndices{roiNum} = [];
    else
        % the third coordinate is the 'slice', which, for flat views, means        % left or right hemisphere.
        if(~all(slice==coords(3,:)))
            myErrorDlg(['ROI ',num2str(roiNum),': Some coords are not from the correct hemisphere (',...
                    cortMag.hemisphere,')!']);
        end
        nodeIndices{roiNum} = zeros(1,size(coords,2));
        data{roiNum}.ph = getCurDataROI(flatView, 'ph', cortMag.expNumber, coords);
        data{roiNum}.co = getCurDataROI(flatView, 'co', cortMag.expNumber, coords);
        
        % Find the nearest gray node for each coordinate.
        %
        for(ii=1:size(coords,2))
            % get nearest flat coordinate (not all points on the flat            % correspond to flat coordinates)
            flatDistances = (flatView.coords{slice}(1,:) - coords(1,ii)).^2 + ...
                (flatView.coords{slice}(2,:) - coords(2,ii)).^2;
            % There is a one-to-many mapping of flatCoords to grayCoords,            % but we ignore that
            % here by using 'min', which will always reuturn one value,            % even if there are several
            % identical minima. 
            % FIX THIS- we should always grab layer 1, or something more            % consistent
            % than relying on min's arbitrary sort.
            [val,coordIndex] = min(flatDistances);
            
            % Extract the gray node corresponding to the current coord
            coordIndex = find(nodes(2,:) == flatView.grayCoords{slice}(1,coordIndex) & ...
                              nodes(1,:) == flatView.grayCoords{slice}(2,coordIndex) & ...
                              nodes(3,:) == flatView.grayCoords{slice}(3,coordIndex));
            
            % This should produce exactly one index.

            % Catch errors. 
            if(isempty(coordIndex))
                myErrorDlg('No gray coords were found!');
            end
            if(length(coordIndex)>1)
                disp([mfilename,': WARNING- ROI ',num2str(roiNum),', coord ',num2str(ii),...
                        '- more than one coordIndex was found!']);
                coordIndex = coordIndex(1);
            end
            nodeIndices{roiNum}(ii) = coordIndex;
        end
    end
end

cortMag.nodeIndices = nodeIndices;
cortMag.data = data;

return;