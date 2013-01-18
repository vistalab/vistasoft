function pos = flatBuildGrid(gridType,varargin)
%Build the desired positions for a cartesian or polar grid
%
%    pos = flatBuildGrid(gridType,varargin)
%
% Two types of sampling grids are built here.  These are the grids used to
% find the flattened locations closest to these points.
%
% For a cartesian grid, the arguments are
%   flatBuildGrid('cartestian',gridSpacing,maxDistance)
%
% For a polar grid the arguments are
%   flatBuildGrid('polar',angSpacing,distSpacing,maxDistance)
%
%Example:
%  pos = flatBuildGrid('cartesian',0.5,11);
%

switch(gridType)
    case 'cartesian'
        gridSpacing = varargin{1};
        mxDist =  varargin{2};
        
        [X,Y] = meshgrid( [-1:gridSpacing:1], [-1:gridSpacing:1]); 
        pos = [X(:),Y(:)]*mxDist;
        
    case 'polar'
    
        angSpacing = varargin{1};
        distSpacing = varargin{2};
        mxDist = varargin{3};
        
        [theta,rad] = meshgrid([angSpacing:angSpacing:2*pi],[distSpacing:distSpacing:1]);
        [X,Y] = pol2cart(theta(:),rad(:));
        pos = [X(:),Y(:)]*mxDist;
        
    otherwise
        error('Unknown grid type.')
end

% figure; plot(pos(:,1),pos(:,2),'.')
return;