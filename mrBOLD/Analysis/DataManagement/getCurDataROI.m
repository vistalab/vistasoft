function [subdata, indices] = getCurDataROI(vw, fieldname, scan, roi)
%
% [subdata indices]  = getCurDataROI(vw, <fieldname>, <scan>, <roi>)
%
% Pulls out co, amp, ph, or map for given scan and ROI.  Returns
% a vector that corresponds to roi.coords.  
%
% INPUTS:
% scan: integer
% fieldname: 'co', 'amp', or 'ph'
% roi: can be an ROI struct, name of ROI, index into vw's
%      ROIs, or 3xN array of (y,x,z) coordinates
%
% OUTPUTS:
%   subdata: data from the specified ROI.
%
%   indices: vector of indices, same size as subdata, specifying from where in
%   the relevant field the subdata were drawn. E.g., if you're calling
%   getCurDatROI(INPLANE{1}, 'map', scan), you could also get the data by 
%   calling:
%       subdata = INPLANE{1}.map{scan}(indices);
%
% Treats INPLANE and VOLUME/FLAT differently.
%
% For INPLANE, gets the indices of the roi.coords.  Returns vector
% of subdata for those indices.  
%
% For VOLUME, data is stored as nVoxels x nScans.  Intersect
% the roi.coords with vw.coords, and pull out the corresponding
% indices of the data vector, then construct the subdata vector
% with NaNs where there's no data.
%
% djh, 7/98
%
% djh, 2/19/2001
% - tSeries and corAnal no longer interpolated to inplane size
%
% ras, 01/19/2004
% - fixed a bug with the upSampleFactor in the case where the upSample factor
%   is different in different directions.
%
% ras, 1/16/2006
% - made roi input be flexible as to how it's specified.
%
% ras, 1/2009
% - returns indices variable if requested
if notDefined('vw'),      vw = getCurView;                  end
if notDefined('fieldname'), fieldname = vw.ui.displayMode;    end
if notDefined('scan'),      scan = viewGet(vw, 'curScan');    end
if notDefined('roi'),       roi = viewGet(vw, 'curRoi');      end

roi = tc_roiStruct(vw, roi);

switch viewGet(vw,'View Type')
    
case 'Inplane'
    % Pull out data for this scan
    data = getCurData(vw,fieldname,scan);
    % Construct subdata for voxels in ROI
    % Need to divide the roi.coords by the upSample factor because the
    % data are no longer interpolated to the inplane size.
    rsFactor = upSampleFactor(vw,scan);
    if length(rsFactor)==1
        roi.coords(1:2,:)=round(roi.coords(1:2,:)/rsFactor(1));
    else
        roi.coords(1,:)=round(roi.coords(1,:)/rsFactor(1));
        roi.coords(2,:)=round(roi.coords(2,:)/rsFactor(2));
    end
    indices = coords2Indices(roi.coords,dataSize(vw,scan));
    if ~isempty(data)
        subdata = data(indices);    
    else
        subdata = NaN*ones(size(indices));
    end
    
case {'Volume','Gray'}
    % Pull out data for this scan
    tmp = vw.(fieldname);
    if(isempty(tmp)), error(['No ' fieldname ' data loaded.']); end
    data = tmp{scan};
    
    % Intersect the two sets of indices, filling in data for the
    % intersection, NaNs for ROI voxels where there's no data.
    [commonCoords, indRoi, indView] = intersectCols(roi.coords, vw.coords); %#ok<ASGLU>
    subdata = NaN([1 size(roi.coords,2)]);
    if ~isempty(data)
        subdata(indRoi) = data(indView);
    end
    
    if nargout > 1
        indices = NaN(size(indRoi));
        indices(indRoi) = indView;
    end
    
case 'Flat'
    % Pull out data for this scan
    data = getCurData(vw,fieldname,scan);
    % Construct subdata for voxels in ROI
    indices = coords2Indices(roi.coords,viewGet(vw,'Size'));
    if ~isempty(data)
        subdata = data(indices);   
    else
        subdata = NaN*ones(size(indices));
    end
end
    
return;
    
    