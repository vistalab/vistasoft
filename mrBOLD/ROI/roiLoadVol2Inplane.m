function [inplane ok] = roiLoadVol2Inplane(inplane, roiName, saveFlag)
%
% [inplane ok] = roiLoadVol2Inplane(inplane, <roiName>, <saveFlag=1>);
%
% A convenient accessor function: for an inplane view,
% load an ROI defined on the volume, and convert it over into
% the inplanes. Saves loading a separate Volume view, if this is
% all you want to do.
%
% If the ROI name is omitted, will prompt the user.
%
% If saveFlag=1, will save the xformed inplane ROI (provided it
% is nonempty).
%
% ras, 05/06.
if notDefined('inplane'), inplane = getSelectedInplane; end
if notDefined('saveFlag'), saveFlag = 1;                end

if ~isequal(inplane.viewType, 'Inplane')
    error('Works only on inplane views.')
end
    
hV = getSelectedGray;

if notDefined('roiName')
    % dialog
    roiName = getROIfilename(hV, 0);
end

% ensure cell ROI name
if ~iscell(roiName), roiName = {roiName};  end

for i = 1:length(roiName)
    [hV, ok] = loadROI(hV, roiName{i}, 1, [], 1);

    if ~ok
        fprintf('Couldn''t load Volume ROI %s \n', roiName{i});
        continue
    end

    ipROI = vol2ipROI(hV.ROIs(end), hV, inplane);	
	
	% is the ROI empty? Go ahead and xform it, but warn the user and set
	% the 'ok' status to zero:
	if isempty(ipROI.coords)
		warning('[%s]: Xformed empty ROI %s.', mfilename, ipROI.name);
		ok = 0;
	end
	
    inplane = addROI(inplane, ipROI, 0);

    if saveFlag & ~isempty(ipROI.coords)
        inplane = saveROI(inplane, inplane.ROIs(end), [], saveFlag);
    end
end

inplane = selectROI(inplane, length(inplane.ROIs));

clear hV

return

