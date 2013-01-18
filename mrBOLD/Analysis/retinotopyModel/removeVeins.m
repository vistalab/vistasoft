function [view] = removeVeins(view, threshold)
% a wrapper for a group of functions to make an ROI for low-signal areas
% (surface veins)

%BMH July 2010

view=loadMeanMap(view);
[indices]=find(view.map{1}(:)<threshold);
newROInumber=size(view.ROIs, 2)+1;

ROI.color='w';
ROI.comments='ROI of thresholded mean map for removing vein areas';
ROI.coords=view.coords(:,indices);
ROI.name='VeinROI';
ROI.viewType='Gray';
ROI.created = datestr(now);
ROI.modified = datestr(now);
view = addROI(view,ROI,1);

for roiIndex=1:newROInumber-1
    [view] = combineROIs(view, {roiIndex newROInumber}, 'A not B', strcat(view.ROIs(roiIndex).name, '-vein', num2str(threshold)), view.ROIs(roiIndex).color);    
end

if isfield(view, 'rm')
    view = rmSelect(view , 2, view.rm.retinotopyModelFile); 
    view = rmLoadDefault(view); 
end

end

