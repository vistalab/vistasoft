function vw = selectCurROISlice(vw,findPeakOfMap)
%
%  vw = selectROISlice(vw,[findPeakOfMap=[]])
%
% Changes to a slice in the VOLUME containing the currently
% selected ROI. If findPeakOfMap==[], then the center-of-mass of the ROI is
% selcted. Otherwise, the maximum value of the map specified by
% findPeakOfMap is selected. E.g., findPeakOfMap='map' will find the
% maximum value in vw.map within the ROI and select that location.
%
% 12/10/98 rmk
% 2003.11.18 RFD: added code to also set the 3d cursor in mrMesh, if
% appropriate. Also, we now take the center of mass of the roi, rather than
% the first coord. -- Deleted said code (BW).
% 2007.02.06 RFD & MBS: added option to select the peak map value instead
% of center-of-mass.

if ~strcmp(vw.viewType,'Volume') && ~strcmp(vw.viewType,'Gray')
    myErrorDlg('selectSliceCoords only for Volume view.');
end
if ~exist('findPeakOfMap','var'), findPeakOfMap = []; end

if vw.selectedROI==0
    % Exit gracefully
    fprintf('No selected ROI.\n');
    return
end

roi = vw.ROIs(vw.selectedROI);
if(size(roi.coords,2)==1)
    centerOfMass = roi.coords;
else
    centerOfMass = round(mean(roi.coords,2));
end

if(~isempty(findPeakOfMap))
    %eval(['map=vw.' findPeakOfMap ';'],'error(''specified map does not
    %exist'');');
    roiData = getCurDataROI(vw, findPeakOfMap, [], roi);
    if(isempty(roiData)), error('specified ROI region of map is empty.'); end
    maxValInds = find(roiData==max(roiData));
    if(isempty(maxValInds))
        setLoc = centerOfMass;
        warning('No valid data in ROI- setting center-of-mass.');
    elseif(length(maxValInds)==1)
        setLoc = roi.coords(:,maxValInds);
    else
        maxValCenterOfMass = round(mean(roi.coords(:,maxValInds),2));
        if(ismember(maxValCenterOfMass',roi.coords(:,maxValInds)','rows'))
            % The center-of-mass of the cluster is also one of the peak
            % values- so we use that.
            setLoc = maxValCenterOfMass;
        else
            % The center-of-mass of the set of peak values is not one of
            % the peak values, so we have to do something else. We'll take
            % the peak value that is closest to the entire ROI
            % center-of-mass.
            maxValCoords = roi.coords(:,maxValInds);
            comDistSq = (maxValCoords(1,:)-centerOfMass(1)).^2 + ...
                        (maxValCoords(2,:)-centerOfMass(2)).^2 + ...
                        (maxValCoords(3,:)-centerOfMass(3)).^2;
            closestInd = comDistSq==min(comDistSq);
            setLoc = maxValCoords(:,closestInd);
        end        
    end
else
    setLoc = centerOfMass;
end

% Set the sliceNum editable text fields
vw = viewSet(vw, 'CursorLoc', setLoc);
   	 
% Set the 3d cursor coordinates, if appropriate. 	 
% (Reinstated by ras, 06/06, but only if a pref is set):
if ispref('VISTA', 'sessionCursor') && getpref('VISTA', 'sessionCursor')==1    
     if isfield(vw, 'mesh')
         for i = 1:length(vw.mesh)	 
            mrmSetCursorCoords(vw.mesh{i}, centerOfMass); 	 
         end
     end 	 
end

return;

