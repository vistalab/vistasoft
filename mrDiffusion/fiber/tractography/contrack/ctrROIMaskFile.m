function [ctr, xformToAcpc, img_mask] = ctrROIMaskFile(p, ctr)
%Create ROI Mask file for Contrack fiber generation
%
%   ctrROIMaskFile(p, xformToAcpc)
%
%The file is stored in the dt6Dir\bin\p.roiMaskFile
%

% Get dimensions for mask image
b0File = fullfile(p.dt6Dir,'bin','b0.nii.gz');
ni = niftiRead(b0File);
xformToAcpc = ni.qto_xyz;
img_mask = zeros(size(ni.data));
clear ni;

% Process ROI1
roi = dtiReadRoi(p.roi1File);
ctr = ctrSet(ctr,'roi',roi.coords,1,'coords');
roi.coords = mrAnatXformCoords(inv(xformToAcpc), roi.coords);
for ii = 1:size(roi.coords,1)
    if (round(min(roi.coords(ii,:))) > 0 && all(round(roi.coords(ii,:))<=size(img_mask)))
        img_mask(round(roi.coords(ii,1)),round(roi.coords(ii,2)),round(roi.coords(ii,3))) = 1;
    end
end

% Process ROI2
roi = dtiReadRoi(p.roi2File);
ctr = ctrSet(ctr,'roi',roi.coords,2,'coords');
roi.coords = mrAnatXformCoords(inv(xformToAcpc), roi.coords);
for ii = 1:size(roi.coords,1)
    if (round(min(roi.coords(ii,:))) > 0 && all(round(roi.coords(ii,:))<=size(img_mask)))
        img_mask(round(roi.coords(ii,1)),round(roi.coords(ii,2)),round(roi.coords(ii,3))) = 2;
    end
end

% % ROI Waypoint - Not always needed.
% if ~isempty(p.wayPointFile)
%     roi = dtiReadRoi(p.wayPointFile);
%     roi.coords = mrAnatXformCoords(inv(xformToAcpc), roi.coords);
%     for ii = 1:size(roi.coords,1)
%         if (round(min(roi.coords(ii,:))) > 0 && all(round(roi.coords(ii,:))<=size(img_mask)))
%             img_mask(round(roi.coords(ii,1)),round(roi.coords(ii,2)),round(roi.coords(ii,3))) = 3;
%         end
%     end
% end

% Write binary mask of all ROIs
dtiWriteNiftiWrapper(uint8(img_mask),xformToAcpc,fullfile(p.dt6Dir,'bin',p.roiMaskFile));

return;
