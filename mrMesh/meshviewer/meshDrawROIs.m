function [colors, allRoiVertInds, dataMask, vw, newColors] = meshDrawROIs(vw, colors, v2g, perimThickness, dataMask, prefs)
%
% Overlay ROI colors on top of the data color overlay
%
% NOTE: an ROI named 'mask' (case-insensitive) will NOT be drawn- it will
% be used to mask away data outside the mask ROI.
%
% NOTE: the following code is slow and should be optimized.
%
% HISTORY:
%  broken off by ras, sometime in 2006.
%  ras 03/07: updated ROI outline parsing to sync with the new way of
%             specifying what ROIs to show (see roiSetOptions).
%  2007.08.23 RFD: fixed broken data masking code.
%  ras, 11/07: streamlined code (broke off two subfunctions), fixed a bug
%				in which perimeters of multiple ROIs were interfering with
%				one another.
%  2009.12.30 JW: allow filling of single ROIs (with name containing
%               string 'fill'), even if other ROIs are drawn as perimeter.
%               Useful for masking out artifacts.
%   

newColors = zeros(size(colors));
% If we want the ROIs to be translucent patches, then make the color of the
% ROIs a weighted sum of the ROI color and the underlay color. If we are
% not drawing the ROIs as translucent patches, then make the weight 1 such
% that we are painting the ROI voxels (presumably just the boundaries) only
% the color of the ROI, with no underlay.
if strcmpi('patches', viewGet(vw, 'roidrawmethod'))
    w = .3;
else 
    w = 1;
end

% get list of ROIs to show
roiList = viewGet(vw, 'ROIsToDisplay');

% roiList can (should) not be 0
if(roiList == 0)
    roiList = [];
end

% Put any mask ROIs at the end of the list.
if ~isempty(roiList)
    ROInames = viewGet(vw, 'ROI names');
    maskRoiIndex = strcmpi('mask',ROInames(roiList));
    if any(maskRoiIndex)
        maskRoiIndex = ismember(roiList, maskRoiIndex);
        [~,inds] = sort(maskRoiIndex);
        roiList = roiList(inds);
    end
end

if notDefined('perimThickness')
    % Option to display only the ROI perimeter.
    % '1' is a good number to use here.
    % ras 01/06: inherits from the view's settings
    if checkfields(vw, 'ui', 'roiDrawMethod')
        switch lower(viewGet(vw, 'roi draw method'))
            case 'boxes', perimThickness = 0;  % filled
            case 'perimeter', perimThickness = 1; % thin outlines
            case 'filled perimeter', perimThickness = 2; % thick outlines
            case 'patches', perimThickness = 0; % filled, translucent patches
        end
    end
end

if ~exist('prefs', 'var'),  
    % this takes a LONG time!
    prefs = mrmPreferences; 
end

% we'll need some standard colors for mapping labels 
% (e.g. 'y') to vals (e.g. [1 1 0]):
[stdColVals, stdColLabs]  = meshStandardColors;

%%%%%%Main part:
% Substitute the ROI color for appropriate nearest neighbor vertices
allRoiVertInds = [];
if ~isempty(viewGet(vw, 'ROIs'))

    %% loop across ROIs
    for iR = roiList
        roi = viewGet(vw, 'ROIs', iR);
        %% find indices of those mesh vertices belonging to this ROI:
        % Note this is a new method of getting roiVertInds. We now use a
        % viewGet. We can also use a viewSet in order to store the indices
        % so that they do not need to be calculated each time. See, e.g,
        % roiSetVertInds.m
        roiVertInds = viewGet(vw, 'roiVertInds', iR, prefs);

        %% modify mesh colors using roiVertInds
		% If this is a mask ROI, don't show the ROI, just mask the data. 
		if strfind(lower(roi.name), 'mask')
			tmp = false(size(dataMask));
			tmp(roiVertInds) = true;
			dataMask = dataMask & tmp;
			clear tmp;
            % The lines below 
            % roiMaskIndices = roiVertInds;
            % roiMaskIndices = adjustPerimeter(roiMaskIndices, [], vw, prefs);
            % dataMask(roiMaskIndices) = 1;
			continue
		end		

		% find ROI perimeter / dilate ROI, depending on the settings
        %   if the roi name contains the string 'fill', we display the ROI
        %   as a solid color instead of a perimeter
        if strfind(lower(roi.name), 'fill'), p = []; else p = perimThickness; end        
        roiVertInds = adjustPerimeter(roiVertInds, p, vw, prefs);
        
		% expand dataMask so that the entire ROI will be drawn
        if exist('roiMaskIndices', 'var'),
    		dataMask(intersect(roiVertInds,roiMaskIndices)) = 1;
        else    
            dataMask(roiVertInds) = 1;
        end
        
		%% modify the colors for this ROI's vertices
        if (ischar(roi.color))
            colVal = stdColVals(:, strfind(stdColLabs, roi.color));
        else
            % Check to see if we have a 3x1 vector.
            colVal = roi.color(:);
            if (length(colVal)~=3)
                error('Bad ROI color');
            end
        end
        
		newColors(1:3,roiVertInds) = repmat(colVal*255, 1, length(roiVertInds));
		
        newColors(newColors>255) = 255;
        newColors(newColors<0) = 0;

        colors(1:3,roiVertInds) = w*newColors(1:3,roiVertInds) + (1-w)*colors(1:3,roiVertInds);
		%% store this ROI's vertices in a list of all ROI vertex locations
		allRoiVertInds = [allRoiVertInds(:); roiVertInds(:)];
    end
end

colors(colors>255) = 255;
colors(colors<0) = 0;

return



