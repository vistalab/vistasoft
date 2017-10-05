function [dataMaskIndices,data,cmap,dataRange,phaseFlag] = meshCODM(vw, clusterThresh, dataScale)
% Mesh Color Overlay / Data Mask function.
%
% [dataMaskIndices, dataOverlay, cmap, dataRange, phaseFlag] = meshCODM(vw, clusterThresh, dataScale)
%
%
% Author: Dougherty/Ress
% Purpose:
%    Build dataMask, dataOverlay and colormap info for 3D window data.
%
% Indices into both of these correspond to vw.nodes indices,
% which is how the functional data are index in the gray view. For the
% functional data, we basically just pull the data out and put it in the
% colorOverlay.
%
% The tricky part is building the dataMask, which tells us which part of
% colorOverlay to show.
%
% Re-written by BW several times.  More clarity still needed.
% ras, 02/04: fixed to be reasonable about parameter maps. For instance, if
% a param map value is == the max win value, it shouldn't be excluded.
% Also, no longer matters if there's a co, amp, or ph map assigned if we're
% in map mode (all my event-related stuff is like this).
% 09/2005 SOD: added a flag which tells whether the data is
% phase-data (circular) or not.
% 2007.08.27 RFD: added volumetric cluster threshold and dataScale options.

if(~exist('clusterThresh')||isempty(clusterThresh)) clusterThresh = 0; end
if(~exist('dataScale')||isempty(dataScale)) dataScale = 1; end

% Table of standard colors (for ROIs).  Should be separate routine.
[stdColVals,stdColLabs]  = meshStandardColors;

scan = viewGet(vw,'currentscan');
dataMaskIndices = zeros(1,viewGet(vw,'numberofnodes'));

% This code finds the node locations whose values are within the range of
% the sliders.  These are indicated by the entries of dataMaskIndices.
% These are determined for the display data here.  If we are in anatomy
% mode, though, they are determined from the ROIs in a different way.  See
% below.
% The code is oddly organized.  We should deal with anat, co, ph, amp and
% map separately.  As it stands, the different variables are all
% interleaved.
if ~strcmp(vw.ui.displayMode, 'anat')

    % Get limits from sliders, find in-range voxels:
    cothresh = viewGet(vw,'cothresh');       %getCothresh(vw);
    phWindow = viewGet(vw,'phasewindow');    %getPhWindow(vw);
    mapWindow = viewGet(vw,'statmapwindow'); %getMapWindow(vw);

    % Determine whether the data are loaded?
    valid = ones(1, viewGet(vw,'ncoords'));  %size(vw.coords,2));
    coOK = ~isempty(viewGet(vw,'co')) | ~isempty(viewGet(vw,'map')); % maps count too!
    if coOK, coOK = ~isempty(viewGet(vw,'scanco',scan)); end  % vw.co{scan}
    if coOK
        co = viewGet(vw,'scanco',scan);
        if(dataScale~=1) co = co.*dataScale; end
        ph = viewGet(vw,'scanphase',scan);
        map = viewGet(vw,'mapn',scan);

        valid = valid & (co >= cothresh);
		if (~isempty(ph))
			if (phWindow(1) > phWindow(2))
				valid = valid & ( ph >= phWindow(1) | ph <= phWindow(2) );
			else
				valid = valid & ( ph >= phWindow(1) & ph <= phWindow(2) );			end
       end

        if (~isempty(map))
            if (mapWindow(2) > mapWindow(1))
                valid = valid & (map <= mapWindow(2));
                valid = valid & (map >= mapWindow(1));
            else
                valid = valid & (map <= mapWindow(2));
                valid = valid | (map >= mapWindow(1));
            end
        end
    end
    
    if strcmp(vw.ui.displayMode, 'amp')
        data = viewGet(vw,'scanamp',scan);
        if(dataScale~=1) data = data.*dataScale; end
    elseif isequal(vw.ui.displayMode,'map')
        data = viewGet(vw,'scanmap',scan);
        if(dataScale~=1) data = data.*dataScale; end
        if ~isempty(data)
            if (mapWindow(2)>mapWindow(1))
                valid = valid & (data <= mapWindow(2));
                valid = valid & (data >= mapWindow(1));
            else
                valid = valid & (data <= mapWindow(2));
                valid = valid | (data >= mapWindow(1));
            end

        end
        dataMaskIndices = find(valid);
    end
    if coOK
        dataMaskIndices = find(valid);
    end
end

% 02/28/2009 JW: mask out regions not in ROIs, if requested
if viewGet(vw, 'mask ROIs')
    roiInd = roiGetAllIndices(vw);
    dataMaskIndices = intersect(dataMaskIndices, roiInd);
end

% 09/2005 SOD: Later on the data may get smoothed
% (meshColorOverlay.m), this smoothing should be done differently
% depending whether the data is phase-data (circular data) or not.
% So we need to have a flag which tells it what kind of data it
% is. Alternatively we could get this info from dataRange since
% phase-data will range from [0 2*pi]. But the may not be correct in the
% rare case that non-phase-data has the same [0 2*pi] range.
phaseFlag = 0;

displayMode = viewGet(vw, 'display mode');
switch displayMode
    case {'co','coherence'}
        if coOK
            cmap = viewGet(vw,'coherenceMap');
            data = co;
            dataRange = vw.ui.coMode.clipMode;
			if isequal(dataRange, 'auto')
				dataRange = mrvMinmax(data);
			end
        end
        
    case {'ph','phase'}
        if coOK
            cmap = viewGet(vw,'phaseMap');
            data = ph;
            dataRange = [0, 2*pi];
            phaseFlag = 1;
        end
        
    case 'amp'
        if coOK
            mnv = min(data);
            mxv = max(data);
            cmap = viewGet(vw,'ampMap');
            dataRange = vw.ui.ampMode.clipMode;
			if isequal(dataRange, 'auto')
				dataRange = [mnv mxv];
			end
        end
        
    case {'map','statisticalmap'}
        mapMode = viewGet(vw,'mapMode');
        numGrays = mapMode.numGrays;
        cmap = round(vw.ui.mapMode.cmap(numGrays+1:end,:) * 255)';
        if isequal(mapMode.clipMode,'auto') | isempty(mapMode.clipMode)
            dataRange = mapWindow;
        else
            dataRange = mapMode.clipMode;
        end
        
    case {'anat','anatomy'}
        data = [];
        dataMaskIndices = [];
        dataRange = [];
        cmap = [];
        
    otherwise
        error('Unknown display mode %s.', displayMode);
end
if(dataScale~=1) data = data.*dataScale; end
dataMaskIndices = unique(dataMaskIndices);

if(clusterThresh>0)
    sz = viewGet(vw,'Size');
    maskVol = false(sz);
    maskCoords = vw.coords(:,dataMaskIndices);
    maskVol(sub2ind(sz,maskCoords(1,:),maskCoords(2,:),maskCoords(3,:))) = true;
    maskVol = bwareaopen(maskVol,clusterThresh,26);
    [x,y,z] = ind2sub(sz,find(maskVol));
	
    % Convert back from volume coords to gray-node indices
    dataMaskIndices = dataMaskIndices(ismember(maskCoords',[x,y,z],'rows'));
end

return
