function view=mrv_dilateCurrentROI(view,iterations)
% function d=mrv_dilateCurrentROI(view)
% PURPOSE: Dilates the current ROI in the Gray view.
% HISTORY: 100704: ARW: Wrote it.
% Note: Large numbers of iterations can result in long processing times.
if (~exist('iterations','var'))
    iterations=1; 
end
if ~(strcmp(view.viewType,'Gray') | strcmp(view.viewType,'Volume'))
    error('This routine requires you to be in the Gray view');
end

thisROI=view.ROIs(view.selectedROI);
if(~isfield(view,'grayConMat') | isempty(view.grayConMat));
    disp('Computing connection matrix...');
    view.grayConMat = makeGrayConMat(view.nodes,view.edges,0);
end
thisROI.coords=mrv_dilateGrayROI(view,thisROI.coords,iterations);
thisROI.name=[thisROI.name,'_dilated'];
view=addROI(view,thisROI);
return;
