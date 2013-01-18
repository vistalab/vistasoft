function varargout = segGet(seg, property, varargin);
% Get properties of a segmentation.
% 
% [vals] = segGet(seg, property, [optional arguments]);
%
% Some properties include:
%   'classPath':    path to the .class file describing the white/gray
%                   classification.
%   'grayPath':     path to the .gray graph.
%   'curMeshNum':   # of the currently-selected mesh (0=no meshes loaded).
%   'mesh',[M]:     the M-th loaded mesh <defaults to current mesh if M
%                   omitted.>
%
%   'nodes':        gray nodes. The rows of the 8xN nodes matrix represent:
%                   (1-3) s/i, a/p, l/r coords (in I|P|R space -- see
%                   mrFormatDescription) of each gray node.
%                   (4)
%                   (5)
%                   (6) gray level/layer, counting from white matter up.
%                   (7)
%                   (8)
%                   The number N of nodes will represent all the gray 
%                   nodes for this segmentation, regardless of the 
%                   current mapping.
%   'edges':        gray edges.
%   [nodes edges] = segGet('gray') returns both gray nodes and edges 
%                   (preventing redundant loading of the gray graph).
%
%   'meshCoords',[M],[mmPerPix]:   
%                   3xN coordinates (in IPR space) of each node 
%                   represented by the M-th mesh, using the current
%                   mapping. The current mapping is determined by
%                   mrmPreferences. The number N of columns will
%                   correspond to the columns of mesh{M}.initVertices,
%                   as well as the mesh colors. 
%                   <if M omitted, uses selected mesh; if mmPerPix
%                   omitted, tries to read from segementation's anat file,
%                   or else assumes 1x1x1.>
%
%	'nearestNode',[coord],[tolerance=5mm]:
%					Return the index of the nearest gray node to a given
%					3D coordinate. This simply finds the node with the
%					smallest euclidean distance from the input coordinate. 
%					The input coord should be a 1x3 or 3x1 vector, and should
%					be in the same format as the gray coords. (This is in order
%					The optional tolerance argument specifies how large a
%					distance should be accepted for a nearest node; if no
%					node is less than this amount, the nearestNode will
%					return empty. By default, the tolerance is 5mm.
%
% ras 04/06
if nargin<2, help(mfilename); error('Not enough input args.'); end

switch lower(property)
    case {'classpath' 'classfile'}
        if isstr(seg.class),    varargout{1} = seg.class;
        else,                   varargout{1} = seg.class.filename;
        end
        
    case {'classification' 'classdata' 'voxels' 'wm' 'class'}
        if isstr(seg.class),    varargout{1} = readClassFile(seg.class);
        else,                   varargout{1} = seg.class;
        end
        
    case {'graypath' 'graygraph' 'grayfile'}
        if isstr(seg.gray),     varargout{1} = seg.gray;
        else,                   varargout{1} = seg.gray.path;
        end
        
    case {'curmeshnum' 'curmeshn' 'meshnum' 'selectedmeshnum'}
        varargout{1} = seg.settings.mesh;
        
    case {'mesh' 'curmesh' 'selectedmesh'}
        if length(varargin)==0, M = segGet(seg, 'curMeshNum'); 
        else, M = varargin{1};
        end
        
        if M==0 | isempty(seg.mesh), 
            varargout{1} = [];
        else
            varargout{1} = seg.mesh{M};
        end
        
    case {'nodes' 'graynodes'}
        if isempty(seg.nodes),  varargout{1} = readGrayGraph(seg.gray);
        else,                   varargout{1} = seg.nodes;
        end
        
    case {'edges' 'grayedges'}
        if isempty(seg.edges),  [x varargout{1}] = readGrayGraph(seg.gray);
        else,                   varargout{1} = seg.edges;
        end
        
    case {'gray'}
        if isempty(seg.nodes) | isempty(seg.edges)
            [varargout{1} varargout{2}] = readGrayGraph(seg.gray);
        else
            varargout{1} = seg.nodes;
            varargout{2} = seg.edges;
        end
        
    case {'graycoords'}
        nodes = segGet(seg, 'nodes'); 
        varargout{1} = nodes([2 1 3],:);
        
    case {'meshcoords' 'coords'}
        varargin{3} = []; % fast way to init. args 1 & 2 if unspecified
        M = varargin{1};  mmPerPix = varargin{2};
        if isempty(M), M = segGet(seg, 'curMeshNum'); end
        if isempty(mmPerPix)
            try
                anat = mrLoad(seg.anatFile);
                mmPerPix = anat.voxelSize(1:3);
            catch
                disp(['Couldn''t read segmentation anatomy. Guessing ' ...
                      'mmPerPix as [1 1 1]...'])
                 mmPerPix = [1 1 1];
            end
        end
        
        % get mapping from mesh vertices to gray nodes
        [nodes edges] = segGet(seg, 'gray');
        v2g = mrmMapVerticesToGray(seg.mesh{M}.initVertices, nodes, ...
                                   mmPerPix, edges);
                               
        % grab appropriate coords from nodes
        varargout{1} = nodes(1:3,v2g);
		
	case {'nearestnode'}
        varargin{3} = []; % fast way to init. args 1 & 2 if unspecified
		pt = varargin{1}(:); tolerance = varargin{2};
		if isempty(pt), error('Need an input coordinate.'); end
		if isempty(tolerance), tolerance = 5; end
		
		% compute Euclidean distance of each node from the coord
		C = segGet(seg, 'GrayCoords');
		dist = sqrt( [C(1,:) - pt(1)] .^ 2 + ...
					 [C(2,:) - pt(2)] .^ 2 + ...
					 [C(3,:) - pt(3)] .^ 2 ); 
		if min(dist) > tolerance
			warning(sprintf('[%s]: no node found within tolerance [%i mm]', ...
							 mfilename, tolerance));
			varargout{1} = [];
		else
			I = find(dist==min(dist));
			varargout{1} = I(1);
		end						
			 
        
    otherwise, error('Unknown property.')
        
end

return

         
            