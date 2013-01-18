function [area smoothedArea] = roiSurfaceArea(vw, roi, msh)
% Get the surface area of an ROI on a mesh
%
% [area smoothedArea] = roiSurfaceArea(vw, roi, msh)
%

% Argument checks
if notDefined('vw'), vw = getSelectedGray; end
switch lower(viewGet(vw, 'viewType'))
    case {'gray' 'volume'}
        % ok
    otherwise
        error('Must be in Gray/Volume view to get ROI surface area');
end
if notDefined('msh'), msh = viewGet(vw, 'curmesh'); end
if notDefined('roi'), roi = viewGet(vw, 'selectedROI'); end

% Set current mesh in view struct
if isnumeric(msh),
    vw = viewSet(vw, 'curmeshn', msh);
    msh = viewGet(vw, 'curmesh');
end

verts = viewGet(vw, 'roivertinds', roi);

if isempty(verts), 
    area = 0;
    smoothedArea = 0;
    return;
end

[areaList, smoothAreaList] = mrmComputeMeshArea(msh, verts);
area            = sum(areaList);
smoothedArea    = sum(smoothAreaList);

fprintf('ROI surface area: %0.1f mm^2 (%0.1f mm^2 on smoothed mesh)\n', area, smoothedArea);

end