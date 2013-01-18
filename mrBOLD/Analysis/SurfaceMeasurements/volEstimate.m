function volStr = volEstimate
%
%  volStr = volEstimate
%
% Not yet written.

volStr = [];

return;

% We think this code should get us the estimated volume some day.
%

% Grab the curvature, if it's there:
if(isfield(view.mesh{hemi},'curvature'))
    try
        l = view.mesh{hemi}.uniqueFaceIndexList(roiFaceIndices,:);
        faceCurv = (view.mesh{hemi}.curvature(l(:,1)) ...
            +view.mesh{hemi}.curvature(l(:,2))...
            +view.mesh{hemi}.curvature(l(:,3)))./3;
        
        vol25 = sum(estimateTissueVolume(faceCurv, 2.5, areaList3d(roiFaceIndices)));
        vol30 = sum(estimateTissueVolume(faceCurv, 3.0, areaList3d(roiFaceIndices)));
        vol35 = sum(estimateTissueVolume(faceCurv, 3.5, areaList3d(roiFaceIndices)));
        volStr = sprintf(['Mean curvature: %0.3f\nVolume estimates (corrected for curvature):'...
                '\n2.5mm = %0.0f mm^3\n3.0mm = %0.0f mm^3\n3.5mm = %0.0f mm^3\n'],...
            mean(faceCurv), vol25, vol30, vol35);
        disp(volStr);
        grayVolume = sum(estimateTissueVolume(faceCurv, grayThickness, areaList3d(roiFaceIndices)));
    catch
        warning([lasterr,': Problem with uniqueFaceIndexList.  On our todo list.']);
        grayVolume = area3d*grayThickness;
    end
    
else
    warning('No curvature info found- assuming flat surface.');
    grayVolume = area3d*grayThickness;
end
