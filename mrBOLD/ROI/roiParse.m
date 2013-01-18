function roi = roiParse(roi, mr);
% Parse an ROI specification.
%
%  roi = roiParse(roi, [mr or UI]);
%
% The ROI can be specified as: (1) loaded ROI struct (see roiCreate);
% (2) 2xN coords specification; (3) path to an ROI file (new mrVista2
% format or mrVista 1 inplane/volume ROI file); (4) index into a set of
% ROIs saved in a mrViewer UI.
%
% Always returns an ROI struct.
%
% The optional second argument can be an mr data structure or
% a mrViewer ui structure. The mr structure is used as the reference
% space for the new ROI (i.e., the ROI coordinates will be interpreted
% as coordinates in that MR data). The ui structure is needed if 
% specifying the ROI as an index; it will grab that index from
% the ui.rois field.
%
% ras, 10/2005.
if notDefined('mr'), mr = []; end

if isnumeric(roi) 
    if size(roi,1)>=3  
        % coords
        roi = roiCreate(mr, roi);
    elseif checkfields(mr, 'rois')
        % index /indices into ROIs in UI
        roi = mr.rois(roi);
    else
        error('Invalid ROI specification.')
    end        
end

if iscell(roi)                      % list of ROIs; recursive loop
    for i = 1:length(roi)
        tmp(i) = roiParse(roi{i}, mr);
    end
    roi = tmp;
	return
end
    

if ischar(roi)                      % ROI file path
	roi = roiLoad(roi, '', mr);
    
    % check for valid ROI structure
    roi = roiParse(roi, mr);
end
        

if isstruct(roi)            % enfore proper fields (back-compatible ROIs)
    template = roiCreate;
    for f = fieldnames(roi)'
        template.(f{1}) = roi.(f{1});
    end
    roi = template; % fields all in correct order
end
    
    

return
