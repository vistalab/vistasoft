function centerOfMass = dtiRoiGetCenterOfMassCoord(roi)

% function centerOfMass = dtiRoiGetCenterOfMassCoord(roi)
%
% For a given ROI this simple function will compute the center of mass and
% return the coordinate for that center point. 
%
% User can then use that point to create a new ROI that is centered on the
% center of mass - useful for ROIs that are functionally defined but oddly
% shapped. 
%
%% EXAMPLE USAGE SCRIPT
% roiFile = 'LMT.mat';
% % Read in the roi that we want to take the center of mass for
% roi = dtiReadRoi(roiFile);
% 
% % Set the radius for the new ROI sphere
% radius = 5;
% 
% % Get the coords and find the center of mass
% centerOfMass = dtiRoiGetCenterOfMassCoord(roi);
% 
% % Create a new roi with a X mm radius from the center coord
% coords = dtiBuildSphereCoords(centerOfMass,radius);
% 
% % Set the coords for the new ROI in the old roi struct and change the name
% roi.coords = coords;
% roi.name = [roi.name '_sphere_' num2str(radius) 'mm'];
% 
% % Write out the new roi. 
% cd(mrvDirup(roiFile));
% dtiWriteRoi(roi,roi.name);
%
%
% HISTORY: 
% 2011.04.08 LMP Wrote the thing
% 2011.06.20 LMP Added example usage script to comments
% 2011.07.21 LMP Now accepts roi as a mat file or struct

if ~isstruct(roi) 
 if exist(roi,'file')
    roi = dtiReadRoi(roi);
 else
  keyboard
 end
end

centerOfMass = round(mean(roi.coords,1)*10)/10;
fprintf('Center of mass coordinate: %.1f, %.1f, %.1f\n',centerOfMass);

return






