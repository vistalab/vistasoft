function colors = meshCurvatureColors(msh)
% Get the thresholded curvature colors that are initially displayed on a
% mesh.
%
% colors = meshCurvatureColors(msh);
%
%
% ras, 07/14/06. Taken from meshColor.

curvColorIntensity = 128 * meshGet(msh,'mod_depth'); % mesh.curvature_mod_depth;
curvature = (double(msh.curvature>0)*2-1); % thresholded between <0 and >0
monochrome = uint8(round(curvature * curvColorIntensity + 127.5));
colors = meshGet(msh,'colors');
colors(1:3,:) = repmat(monochrome, [3 1]);

return
