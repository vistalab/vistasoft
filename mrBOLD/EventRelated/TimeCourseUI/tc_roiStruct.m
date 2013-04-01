function roi = tc_roiStruct(view,roi);
%
% roi = tc_roiStruct(view,roi);
%
% A tool for parsing arguments specifying ROIs.
%
% Problem: you may want to specify ROIs in many
% ways: by giving the name of a mrVista ROI struct,
% or the index, or the whole structure, or giving
% arbitrary roi coordinates. This happens several
% times in my code.
%
% Solution: be flexible about specification; infer
% how the roi is passed by its class and size.
%
% This has come up a couple of times in my
% code, so I thought I'd dedicate a function
% to parse this roi argument. This always
% returns a mrVista ROI structure, with
% color, coords, name, and viewType fields.
%
% ras, 04/05.
% ras, 06/05: now if roi is a cell w/ many ROI
% designations, will return a struct array.
% ras, 03/28/07: if the ROI is specified by name, and that name is not
% loaded but exists in the roiDir, load the ROI.
if iscell(roi)
    % get many ROI structs, recursively
    for i = 1:length(roi)
        tmp(i) = tc_roiStruct(view, roi{i});
    end
    roi = tmp;
    return
end

if ischar(roi)
    % assume name of ROI
    r = findROI(view,roi);
	
	if r==0
		% not loaded in view: but does the file exist?
		roiPath = fullfile(roiDir(view), [roi '.mat']);
		if exist(roiPath, 'file')
			roi = load(roiPath);
			roi = roi.ROI;  % 'ROI' variable saved in file
		else
			error( sprintf('%s not found.', roi) );
		end
	else
		% already loaded in view: grab it
		roi = view.ROIs(r);
	end

elseif isnumeric(roi)
    if size(roi,1)==3
        % assume specifying 3xN ROI coords; build an roi struct
        coords = roi;
        roi = struct('color','coords','name','viewType');
        roi.color = 'b';
        roi.coords = coords;
        roi.viewType = viewGet(view,'View Type');
        if size(roi,2)==1
            roi.name = sprintf('Point %i, %i, %i',coords(1),coords(2),coords(3));
        else
            roi.name = '(Multiple selected points)';
        end

	else
        % index into view's ROIs	
        roi = view.ROIs(roi);  
		
    end
end


return
