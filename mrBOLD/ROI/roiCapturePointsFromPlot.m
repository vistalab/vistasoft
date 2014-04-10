function vw = roiCapturePointsFromPlot(vw, subX, subY, coIndices, ROIcoords)
%   vw = ROIcapturePointsFromPlot(vw, subX, subY, coIndices, ROIcoords)
%
% create a new ROI by drawing a polygon around a set of plotted points
%
% for example, to plot the center locations of population RFs, and then
% select a subset of these voxels as a new ROI, call:
%      drawROI = true;
%      vw = plotEccVsPhase(vw, [], [], drawROI)
 
 % get the polygon
 f = gcf;
 
 msgbox('Draw polygon on plot. Right click to close');
 [xi,yi] = getline(f,'closed');

 %make sure it is closed
 if (~isempty(xi))
     if ( xi(1) ~= xi(end) || yi(1) ~= yi(end) )
         xi = [xi;xi(1)];
         yi = [yi;yi(1)];
     end
 end

 % find the plotted points inside it
 IN = inpolygon(subX, subY, xi, yi);
 ind = coIndices(IN == 1);
 newCoords = ROIcoords(:,ind);
 message = sprintf('%d voxels in new ROI', size(newCoords, 2));
 msgbox(message)

 % update the view with the new ROI
 vw     = newROI(vw);
 ROInum = viewGet(vw, 'num ROIs');
 vw     = viewSet(vw, 'ROI coords', newCoords, ROInum);
 vw     = viewSet(vw, 'ROI modified', datestr(now), ROInum);
 vw     = refreshScreen(vw, 0);
 
end