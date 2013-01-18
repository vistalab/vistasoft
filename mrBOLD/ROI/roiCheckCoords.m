function roi = roiCheckCoords(roi, mr, preserveCoords);
% Check that an ROI's coords match the coordinates
% of an MR object's data, applying transformations if 
% needed.
%
% roi = roiCheckCoords(roi, mr, [preserveCoords]);
%
% roi: an ROI struct. See roiCreate.
%
% mr: an mr object, which may be the object on which the ROI is 
%     defined, or may be a different object. The ROI can still be used
%     if a common coordinate space can be found (e.g., by scaling the
%     ROI's coords against the MR data, or applying a transformation
%     into a mutual space like Scanner space).
%
% preserveCoords: optional flag; if 1, will have the output roi
% have the same # of columns in roi.coords as the input roi.
% If 0, removes redundant columns. [Default 0]
% NOTE: importantly, setting preserveCoords to 1 risks that some
% functions may not work on the transformed ROI, since it will
% include coordinates which are out-of-range of the mr data. 
% If preserveCoords==0, will prune these automatically.
%
%
% ras, 10/2005.
if nargin<2, help(mfilename); error('Not enough args.');    end 
if notDefined('preserveCoords'), preserveCoords = 0;        end
if notDefined('roi'), error('Empty ROI.');                  end

mr = mrParse(mr);
roi = roiParse(roi, mr);

% recursively check several ROIs if requested
if length(roi) > 1
    for i = 1:length(roi)
        roi(i) = roiCheckCoords(roi(i), mr, preserveCoords);
    end
    return
end

if isempty(roi.coords)	% no need to check
	return
end

xform = [];

% There are a few ways to check if the ROI matches the MR object.
% First, check if the ROI is defined with respect to one of the 
% existing spaces:
if ismember(lower(roi.reference), {'raw data in pixels' lower(mr.name)})
    xform = eye(4);     % defined in same space
    
elseif ischar(roi.reference)
    % see if the roi and mr share a common space
    % (but ignore "standard" spaces: may have the same name but refer to 
    % different coordinates)
    std = {'Raw Data in Pixels' 'Raw Data in mm' 'L/R Flipped'};
    commonSpaces = setdiff({mr.spaces.name}, std);    
    if ~isempty( cellfind(commonSpaces, roi.reference) )        
        fprintf('Coregistering via common space %s \n', roi.reference);        
        I = cellfind({mr.spaces.name}, roi.reference); 
        xform = inv(mr.spaces(I).xform);
    end
end

if isempty(xform)
    % still haven't gotten xform: try the next step: 
    if isfield(roi,'referenceMR') & ~isempty(roi.referenceMR)
        % ensure the reference MR object is loaded
        roi.referenceMR = mrParse(roi.referenceMR);

        % compare the mr name and the referenceMR name
        if isequal(roi.referenceMR.name, mr.name)
            % great, the ROI was defined on this data! We're done.
            return
            
        else
            % check the spaces in the reference MR and the mr file
            try 
                xform = mrBaseXform(mr, roi.referenceMR);
            catch
                disp(lasterr);
                error('Sorry, can''t use this ROI with that MR data.')
            end  
            
        end
        
    else
        error('Sorry, can''t use this ROI with that MR data.');
    end
end

% if we got here, we have an xform -- apply it to the
% current ROI coords to get it into the mr data space:
if ~isequal(xform, eye(4)) % don't waste time on a trivial xform
	roi = roiXformCoords(roi, xform, mr.voxelSize(1:3));
end
roi.voxelSize = mr.voxelSize;
roi.dimUnits = mr.dimUnits;

% remove redundant coords, if desired
if ~preserveCoords
    roi.coords = intersectCols(roi.coords, roi.coords);
    
    % also remove coords out of range of mr data
    ok = find(roi.coords(1,:)>=1 & roi.coords(1,:)<=mr.dims(1) & ...
              roi.coords(2,:)>=1 & roi.coords(2,:)<=mr.dims(2) & ...
              roi.coords(3,:)>=1 & roi.coords(3,:)<=mr.dims(3));
    roi.coords = roi.coords(:,ok);
end

roi.reference = mr.name;

return

   