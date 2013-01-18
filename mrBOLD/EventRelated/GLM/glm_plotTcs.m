function h = glm_plotTcs(model,voxNames,conds,active,control);
%
% h = glm_plotTcs(model,voxNames,conds,active,control);
% 
% Make a figure showing the deconvolved responses
% for each 'voxel'/roi. If voxNames is supplied,
% will title each subplot w/ those names. If active and
% control are supplied, will perform a contrast
% and put up the stats for the peak data point.
%
% if conds is supplied, will only plot the
% specified conditions.
%
% ras 02/05
if ieNotDefined('voxNames')
    voxNames = [];
end

if ieNotDefined('active')
    active = [];
end

if ieNotDefined('control')
    control = [];
end

if ieNotDefined('conds')
    conds = 1:size(model.h_bar,2);
end

h = figure('Color','w',...
           'Units','Normalized',...
           'Position',[0 .2 .4 .6]);
       
Y = model.h_bar;
E = model.h_bar_sem;


peak = find(Y(:,2,1)==max(Y(:,2,1)))
if ~isempty(active) & ~isempty(control)
    sig = er_contrast(model,active,control,'weights',peak);
else
    sig = [];
end

nvoxels = size(Y,3);

nrows = ceil(sqrt(nvoxels));
ncols = ceil(nvoxels/nrows);

for i = 1:nvoxels
    subplot(nrows,ncols,i);
    errorbar(Y(:,conds,i),E(:,conds,i));
    if ~isempty(voxNames)
        title(voxNames{i});
    end
    if ~isempty(sig)
        AX = axis;
        msg = sprintf('p = %1.3f',10^(-1*sig(i)));
        text(AX(1)+0.63*(AX(2)-AX(1)), AX(3)+0.8*(AX(4)-AX(3)), msg);
    end
end

return
    
    
    