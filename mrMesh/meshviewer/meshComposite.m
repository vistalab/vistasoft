function [colors] = meshComposite(msh, overlays, alphaMethod);
% Composite mutiple color overlays into a single set of colors for a mesh.
%
% [colors] = meshComposite(msh, overlays, <alphaMethod=1>);
%
% INPUTS:
%   msh: VTK mesh structure.
%
%   overlays: 3D array of color overlays, size N x 4 x nOverlays, where N 
%   is the # of mesh vertices. The first 3 columns are R, G, B
%   values for each vertex, respectively, and the fourth is the alpha layer
%   (not currently used). All should range from 0 to 255.
%
%   alphaMethod: a flag of how to handle overlap between overlays:
%
%   1: for two overlays which overlap, average the two values
%       (e.g. [1 0 0] + [.2 0 1] => [.6 0 .5]);
%
%   2: for two overlays, add the values, saturating at 1
%       (e.g. [1 0 0] + [.2 0 1] => [1 0 1]);
%
%   3: overlays are opaque; the 2nd overlay covers the 1st
%       (e.g. [1 0 0] + [.2 0 1] => [.2 0 1]);
%
% Note that if the pref 'alphaMethod' is defined for the group 'VISTA'
% (i.e., you've run "setpref('VISTA', 'alphaMethod', [value])"), the
% mapping will use this preference setting as the default. (It can be
% overridden if alphaMethod is given as a third argument). Otherwise, 
% if alphaMethod is not set, will use the first value, averaging overlap.
%
%
% OUTPUTS:
%   colors: 4xN set of colors reflecting the combined overlays. 
%
%
%
% ras, 07/14/06.
if notDefined('alphaMethod')
    if ispref('VISTA', 'alphaMethod')
        alphaMethod = getpref('VISTA', 'alphaMethod');
    else
        alphaMethod = 1;
    end
end

nVertices = size(overlays, 1);
nOverlays = size(overlays, 3);

% get the curvature colors, as the de facto 'mask': divergence
% from these colors indicates there's data in a given overlay:
anatColors = meshCurvatureColors(msh)';

% compute mask vector for each overlay (nVertices x nOverlays)
mask = logical(zeros(nVertices, nOverlays));
for n = 1:nOverlays
    anyDiff = (overlays(:,:,n) ~= anatColors);
    mask(:,n) = anyDiff(:,1) | anyDiff(:,2) | anyDiff(:,3);
end

% initialize the colors to be these anatomy colors; we'll plug in the
% map values below.
colors = anatColors;

% main step: composite according to alphaMethod:
switch alphaMethod
    case 1, % average overlapping regions
        % to average, we need a weight matrix (W), which is based
        % on the number of overlays at each vertex:
        opv = sum(double(mask), 2); % overlays per vertex        
        W = zeros(nVertices, 1);         
        W(opv>0) = 1 ./ opv(opv>0); 
        W = repmat(W, [1 4]);       % replicate for easy math, below
        
        % find color vertices w/ no overlays, and set them to 0 for now:
        ok = repmat(permute(mask, [1 3 2]), [1 4 1]);
        overlays(~ok) = 0;
        
        % do the averaging
        colors = sum(overlays, 3) .* W;
        
        % add back in the anatomy colors where there's no data
        noData = find(sum(mask, 2) == 0);
        colors(noData,:) = anatColors(noData,:);
        
        
    case 2, % add and saturate overlapping regions
        % find color vertices w/ no overlays, and set them to 0 for now:
        ok = repmat(permute(mask, [1 3 2]), [1 4 1]);
        overlays(~ok) = 0;
        
        % add
        colors = sum(overlays, 3);
        
        % saturate: clip at the max value (255)
        colors(colors>255) = 255;
        
        % add back in the anatomy colors where there's no data
        noData = find(sum(mask, 2) == 0);
        colors(noData,:) = anatColors(noData,:);
        
        
    case 3, % opaque overlays, later ones cover up earlier ones
        for n = 1:nOverlays
            vertices = find(mask(:,n)>0);
            colors(vertices,:) = overlays(vertices,:,n);
        end
end    

return

