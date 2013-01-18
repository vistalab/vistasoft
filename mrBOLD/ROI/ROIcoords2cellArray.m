function ROIcoords = ROIcoords2cellArray(view,ROIcoords)
%
%  ROIcoords2cellArray(view,ROIcoords)
%
% Convert the ROIcoords from a single ROI into the first entry of a cell array
% Or, convert all of the ROIs in a view into a cell array of nROI ROIcoords
%
% 2003.06.11  BW/AB
%   Dave H. did this several times, so we wrote this function.

% Convert/construct ROIcoords arg so that it is a cell array of coords

if nargin < 2
    error('Requires view and ROIcoords');
end

if iscell(ROIcoords)
    return;
else
    if isempty(ROIcoords)
        ROIcoords = cell(1,length(view.ROIs));
        for r=1:length(ROIcoords)
            ROIcoords{r} = view.ROIs(r).coords;
        end
    else
        tmp{1} = ROIcoords;
        ROIcoords = tmp;
    end
end

return;