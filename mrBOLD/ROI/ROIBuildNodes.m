function ROIdata = ROIBuildNodes(ROIdata, flatView, grayView)
%
%  ROIdata = ROIBuildNodes(ROIdata,flatView, grayView)
%
%  Finds the gray matter nodes for the coords of a FLAT line ROI. This is a necessary and
%  slow step torward computing the distance along the ROI. Next step is
%  binning and getting the ph and co info with ROIBuildBins.
%
% HISTORY:
%   2003.01.05 AAB adapted it to measure flat line ROI distances based on the 
%   cortical magnification code by Dougherty, Wandell, Baseler and Brewer.
%   
%   2008.04.02 JW fixed a minor bug : defined the var slice to come from the
%    input ROI, not the currently selected ROI

mrGlobals;

%slice = flatView.ROIs(flatView.selectedROI).coords(3,1);
nodes = double(grayView.nodes);
edges = double(grayView.edges);
coords = ROIdata.coords;
slice = coords(3,1);

if(isempty(coords))
    error('ROI coords are empty')
else
    % the third coordinate is the 'slice', which, for flat views, means left or right hemisphere.
    if(~all(slice==coords(3,:)))
        myErrorDlg([ROIdata.name ': Some coords are not from the correct hemisphere!']);
    end
    nodeIndices = zeros(1,size(coords,2));
    
    % Find the nearest gray node for each coordinate.
    %
    for(ii=1:size(coords,2))
        % get nearest flat coordinate (not all points on the flat correspond to flat coordinates)
        flatDistances = (flatView.coords{slice}(1,:) - coords(1,ii)).^2 + ...
            (flatView.coords{slice}(2,:) - coords(2,ii)).^2;
        % There is a one-to-many mapping of flatCoords to grayCoords,
        % but we ignore that here by using 'min', which will always reuturn one value,
        % even if there are several identical minima. 
        % FIX THIS- we should always grab layer 1, or something more consistent 
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
            disp([mfilename,': WARNING- ',ROIdata.name,', coord ',num2str(ii),...
                    '- more than one coordIndex was found!']);
            coordIndex = coordIndex(1);
        end
        nodeIndices(ii) = coordIndex;
    end
end

ROIdata.nodeIndices = nodeIndices;

return;