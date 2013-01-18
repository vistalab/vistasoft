function [colors, msh] = meshOverlay(msh, data, mask, cmap, clim, varargin)
%
% Overlay data on top of a mesh, returning the new mesh colors and the
% updated mesh.
%
%  [colors, msh] = meshOverlay(msh, data, <mask>, <cmap>, <clim>, <options>);
%
% OUTPUTS: 
%   colors: 4 x N array of values representing the colors / alpha value
%           for the mesh. N is the # of vertices on the mesh; the first
%           3 rows are the R, G, B values respectively (0-255), while the 
%           fourth is the alpha channel (transparency) level (0-1?).
%   msh: The modified mesh. (Only modified if 'showData' option is used.)
%
% INPUTS:
%   msh: loaded mesh struct or path to a mesh file.
%   data: 1xN array of data, where N is the number of vertices on the mesh.
%   mask: optional argument specifying where to show the overlay (w/ the
%       curvature showing elsewhere). Can be 1xN logical or index array.
%   cmap: 3xN color map for the overlay. Default is hot(256).
%   clim: color clip mode. Can be 'auto' <default> in which case the colors
%       in the cmap are scaled so that the first entry maps to the lowest
%       value in the overlay (contained within the mask if there is one),
%       and the last to the highest. Otherwise, should be [clipMin
%       clipMax].
%
% Options include: 
%    'showData': put the new colors intothe mrMesh window. (Otherwise
%                returns colors w/o updating)
%    'phaseData': indicates that the data are circular (like phasic data),
%               so for certain operations such as smoothing, will shift
%               into complex domain first (or else there would be errors).
%    'noScale': indicates that the data are direct indices into the cmap,
%               so the function shouldn't scale the data when mapping.
%    
% Otherwise, prefs are set by mrmPreferences.
%    
%
% ras, 04/2006: created off of meshColorOverlay for mrVista2. Several
% fundamental changes on this, though: some parts were deleted (e.g.,
% call to meshCODM, all view-related parts), some parts moved to 
% mrViewDrawROIs.
if nargin<2, help(mfilename); error('Not enough input args.'); end
if ~exist('cmap','var') || isempty(cmap), cmap = hot(256); end
if ~exist('clim','var') || isempty(clim), clim = 'auto'; end
if ~exist('mask','var') || isempty(mask)
    mask = true(size(data)); 
end
if ~islogical(mask)
    if isequal(size(mask), size(data))
        mask = logical(mask>0); 
    else
        mask = logical(find(mask)); 
    end
end

%%%%%mesh preferences, to be used throughout the mapping
prefs = mrmPreferences;

%%%%%parse the options
showData = 0;  phaseFlag = 0;  scaleFlag = 1;
for ii = 1:length(varargin)
    switch lower(varargin{ii})
        case 'showdata', showData = 1;
        case 'phasedata', phaseFlag = 1;
        case 'noscale', scaleFlag = 0;
    end
end

%%%%%% Initialize the new color overlay to middle-grey. This reduces
%%%%%% edge artifacts when we smooth.
sz = size(meshGet(msh,'colors'),2);
colors = repmat(127, [4 sz]);

% figure out range of values to use for color mapping
if isequal(clim, 'auto'), dataRange = [min(data(mask)) max(data(mask))];
else                      dataRange = clim;
end

%%%%%% We need the connection matrix to compute clustering and smoothing, below.
conMat = meshGet(msh,'connectionmatrix');
if isempty(conMat)
    msh = meshSet(msh,'connectionmatrix',1);
    conMat = meshGet(msh,'connectionmatrix');
end

% Remove vertices that have fewer than clusterThreshold neighbors.
if prefs.clusterThreshold > 1
    mask = (sum(double(conMat)*double(mask'), 2) > prefs.clusterThreshold);
end

%%%%% Smoothing (if selected)
if prefs.dataSmoothIterations > 0 
    for t = 1:prefs.dataSmoothIterations
        % Smooth and re-threshold the data mask
        mask = connectionBasedSmooth(conMat, double(mask));
        mask = mask>=0.5;

        % smoothing the data can only be done if the
        % data is non-circular (ie not valid for phase maps). So
        % two ways depending on the data:
        if ~phaseFlag,
            data = connectionBasedSmooth(conMat,data);
        else
            % phase data, so go complex, smooth and go back
			
			% allow for phasic data whose data range isn't in the
			% range [0, 2*pi] needed for the EXP and ANGLE functions.
			% (e.g., polar angle in �); map to appropriate range
			data = rescale2(data, dataRange, [0 2*pi], 0);
			
            data = -exp(1i * data); % make sure not to use i as an index var.
            data = connectionBasedSmooth(conMat,data);
            data = angle(data) + pi;
			
			data = rescale2(data, [0 2*pi], dataRange, 0);
        end
    end
end

%%%%% compute colors now after data smoothing
if any(mask) & sum(data(mask)) ~= 0     %#ok<AND2>
    colors(1:3,:) = meshData2Colors(data, cmap', dataRange, scaleFlag);
    colors = rescale2(colors, [0 1], [0 255]);
end

% Assign the anatomy colors (usually representing curvature) to the 
% locations where there are no data values.
anatColors = meshCurvatureColors(msh); 
colors(1:3,~mask) = anatColors(1:3,~mask);

% Manually apply an alpha channel the overlay colors- adjusting them
% to allow the underlying mesh colors to come through. (Ie. simulate
% transparency). This is useful when your mesh is completely painted, but
% you need some clue about the surface curvature (which is presumable what
% the original mesh colors represent). -Bob
if prefs.overlayModulationDepth > 0
    a = prefs.overlayModulationDepth; % 'alpha' level
    colors(:,mask) = ((1-a) * colors(:,mask)) + (a * double(anatColors(:,mask)));
end

% clip and round values
colors(colors>255) = 255;
colors(colors<0) = 0;
colors = uint8(round(colors))';

% show data if asked
if showData, msh = mrmSet(msh, 'colors', colors); end

return;
