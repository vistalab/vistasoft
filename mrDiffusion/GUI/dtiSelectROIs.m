function sList = dtiSelectROIs(handles,promptStr)
% Select a subset of the ROIS
%
%  sList = dtiSelectROIs(handles,promptStr)
%
%

if ieNotDefined('promptStr'), promptStr = 'Select ROIs '; end

% Empty selected list
sList = []; 
if(isempty(handles.rois)), disp('No ROIs.'); return; end

roiNames = {handles.rois.name};
nRois = length(roiNames);

% For some purposes Bob adjusted the roiNames on the fly.  For general
% selection, I don't think we should translate the names.  For example,
% when writing out, he replaces blank with _.  Here, he adds some more
% description to the name.
for ii=1:nRois
    c = getColorString(handles.rois(ii).color);
    roiNames{ii} = [roiNames{ii},' (',c,')'];
end

[sList,ok] = listdlg('PromptString', promptStr, ...
    'SelectionMode', 'multiple', ...
    'ListString', roiNames);

if ~ok, sList = []; end

return;