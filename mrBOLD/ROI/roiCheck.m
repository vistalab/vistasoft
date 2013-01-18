function roi = roiCheck(roi)
% Check that fields are properly defined & ordered for a mrVista 1 format ROI.
%
% roi = roiCheck(roi);
%
% This includes the original fields (coords, name, color, viewType), and
% some expanded fields which are more recently used (such as a comments
% field, date markings for when the ROI is created and modified). If it
% doesn't find the fields, initializes them to empty or sensible values.
%
% ras, 02/2007.
if nargin<1, error('need an ROI input.'); end

template = roiCreate1;

for f = fieldnames(template)'
    if ~isfield(roi, f{1})
        for i=1:length(roi)
            roi(i).(f{1}) = template.(f{1});
        end
    end
end

roi = sortFields(roi);
return



