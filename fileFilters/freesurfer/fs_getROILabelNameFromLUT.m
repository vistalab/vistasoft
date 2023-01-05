function fsLabelName = fs_getROILabelNameFromLUT(labelIndex)
%Initialize a new vista function
%
%  fName(arguments) 
%
%
% INPUTS 
%        index for an ROI returned by the freesurfer LUT 
%        e.g., left calcarine is 1021
%
% RETURNS
%        the name of the freesurfer roi
%        'ctx-lh-pericalcarine'
%
% Web Resources
%     mrvBrowseSVN('fs_getROILabelNameFromLUT')
%
% Example:
%   calcarineROIname = fs_getROILabelNameFromLUT(1021);
%
% Copyright Stanford team, mrVista, 2011
%
% MP, FP 2011.08.20

load fslabel.mat; % load the freesurfer lut

index = find(ismember(fslabel.num, num2str(labelIndex))==1);
if isempty(index)
    fsLabelName = ''; 
    warning('This index does not exit in the fslabel LUT');
else
    fsLabelName = (fslabel.name{index});
end

return

