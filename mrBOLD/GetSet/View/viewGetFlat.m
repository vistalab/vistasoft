function val = viewGetFlat(vw,param,varargin)
% Get data from various view structures
%
% This function is wrapped by viewGet. It should not be called by anything
% else other than viewGet.
%
% This function retrieves information from the view that relates to a
% specific component of the application.
%
% We assume that input comes to us already fixed and does not need to be
% formatted again.

if notDefined('vw'), vw = getCurView; end
if notDefined('param'), error('No parameter defined'); end

mrGlobals;
val = [];


switch param
    
    case 'graycoords'
        % 'graycoords' is also an alias for coords in volume/gray views:
        if ~isequal(vw.viewType, 'Flat')
            val = viewGet(vw, 'Coords');
            return
        end
        
        % Example usage for FLAT view:
        % val = viewGet(vw{1},'graycoords','left');
        if length(varargin) ~= 1,
            error('You must specify which hemisphere.');
        end
        hname = varargin{1};
        switch hname
            case 'left'
                val = vw.grayCoords{1};
            case 'right'
                val = vw.grayCoords{2};
            otherwise
                error('Bad hemisphere name');
        end
    case 'leftpath'
        if checkfields(vw,'leftPath'), val = vw.leftPath; end
    case 'rightpath'
        if checkfields(vw,'rightPath'), val = vw.rightPath; end
    case 'fliplr'
        if checkfields(vw,'flipLR'), val = vw.flipLR; end
    case 'imagerotation'
        if checkfields(vw,'rotateImageDegrees'),val = vw.rotateImageDegrees; end
    case 'hemifromcoords'
        if ~exist('varargin', 'var') || isempty(varargin)
            val = [];
            warning('vista:viewError','Need coords to determine hemisphere');
            return;
        else
            % get left and right nodes to compare to the coords
            l = viewGet(vw, 'allLeftNodes');
            r = viewGet(vw, 'allRightNodes');
            l = l(1:3, :);
            r = r(1:3, :);
            % get coords in proper orientation
            coords = varargin{1};
            if ~isequal(size(coords, 1), 3) && isequal(size(coords, 2), 3)
                coords = coords';
            end
            % nodes are [cor axi sag] but coords are [axi cor sag]
            x = coords(2, :);
            y = coords(1, :);
            z = coords(3, :);
            [~, right] =  intersectCols(single([x; y; z]), r);
            [~, left]  =  intersectCols(single([x; y; z]), l);
            val = nan(1,length(x));
            val(left) = 1;
            val(right) = 2;
            val(intersect(left , right)) = nan;
        end
    case 'roihemi'
        if ~exist('varargin', 'var') || isempty(varargin)
            coords = viewGet(vw, 'roiCoords');
        else
            coords = varargin{1};
        end
        hemi = viewGet(vw,  'hemiFromCoords', coords);
        hemi = round(nanmean(hemi));
        if hemi == 1, val = 'left' ;
        elseif hemi == 2, val = 'right';
        else val = []; warning('vista:viewError','Could not determine hemifield');
        end
        
    otherwise
        error('Unknown viewGet parameter');
        
end

return
