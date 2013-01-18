function vertexData = meshMapData(msh, nodeData, phaseFlag, mappingMethod);
%
% vertexData = meshMapData(msh, nodeData, <phaseFlag=0>, <mappingMethod>);
% 
% Given the current mesh preferences, and a set of data values 
% for each gray node in coords, produce a (generally smaller) set
% of data values for each vertex in a mesh.
%
% INPUTS:
%       msh: mesh structure.
%
%       nodeData: data to map, of size 1 x nGrayNodes
%
%       phaseFlag: optional flag to indicate phasic, complex data. If set
%       to 1 and the mapping draws across several nodes, will do a complex
%       average, instead of a simple average. <default 0>
%
%		mappingMethod: method to use to map from multiple gray nodes to
%		mesh vertices. <Default: get from mrmPreferences>
%
% OUTPUTS:
%       vertexData: mapped data, size 1 x nMeshVertices. Vertices for which
%       there is no data will be set to NaN.  
%
% The exact relationship beteween the nodeData and the vertexData
% depends on the prefs set by mrmPreferences (unless you override
% this with the mappingMethod argument). In particular:
%   * if the layerModeMap pref is set to 'layer1', vertexData will be a subset
%   of nodeData, drawn from all layer 1 nodes;
%   * if layerModeMap is set to 'all' and overlayLayerMapMode is 'max', 
%   vertexData will again be a subset of nodeData, only the value at 
%   each vertex will be the max value from all the nodes which map to that
%   vertex (see mrmMapVerticesToGray).
%   * if layerModeMap is set to 'all' and overlayLayerMapMode is 'mean',
%   each vertex will contain the mean data value across all gray nodes
%   which map to it. (again, see mrmMapVerticesToGray).
%
%
% ras, 07/06.
if ~exist('phaseFlag', 'var') | isempty(phaseFlag), phaseFlag = 0; end

if isempty(msh.vertexGrayMap)
    error('Need to load a vertex/gray map in your mesh. See mrmMapVerticesToGray.')
end

%%%%% params
nVertices = size(msh.initVertices, 2);
% nNodes = size(coords, 2);
nNodes = size(nodeData, 2);
v2g = msh.vertexGrayMap; % (actually this strikes me as a gray->vertex map, 
                         % but I didn't name it)

if notDefined('mappingMethod')
	prefs = mrmPreferences;
	
	% condense the two relevant preferences, layerMapMode and
	% overlayLayerMapMode, into a single pref, 'mappingMethod'.
	if isequal(prefs.layerMapMode, 'layer1')
		mappingMethod = 'layer1'; 
	else
		if isequal(prefs.overlayLayerMapMode, 'max')
			mappingMethod = 'max';
		else
			mappingMethod = 'mean';
		end
	end
end

% initialize the vertex data to NaNs:
vertexData = repmat(NaN, [1 nVertices]);

%%%%% map according to the mapping method:
switch lower(mappingMethod)
    case 'layer1'
        I = find( (v2g(1,:)>0) & (v2g(1,:)<nNodes) ); % layer 1 data present
        vertexData(I) = nodeData(v2g(1,I));

    case 'mean' 
        % take mean value across layers             
        if phaseFlag, % move data into complex space -- change back afterwards
            nodeData = -exp(i * nodeData);
        end
            
        % get a value matrix, across which to average
        vals = zeros(size(v2g));
        I = find(v2g>0 & v2g<nNodes);       % data present
        vals(I) = nodeData(v2g(I));

        % average: this has the problem of over-weighing by redundant
        % nodes (as does the old code in meshColorOverlay)
        vals = mean(vals, 1);

        whichVertices = setdiff(1:nVertices, find(sum(v2g,1)==0));
        vertexData(whichVertices) = vals(whichVertices);                        
            
        if phaseFlag, % map back (probably done wrong -- don't care just yet)
            vertexData = angle(vertexData) + pi;
        end
        
    case 'max'
        %%%%% take max value across layers:
        % (1) initially take layer 1 nodes
        I = find( (v2g(1,:)>0) & (v2g(1,:)<nNodes) ); % layer 1 data present
        vertexData(I) = nodeData(v2g(1,I));
        
        % (2) step through the other 'layers' (not strict layers b/c of the
        % vertex mapping, rather the nodes to which each vertex maps),
        % seeing if there are larger values
        nLayers = size(v2g, 1);
        for ii = 1:nLayers
            I = find( (v2g(ii,:)>0) & (v2g(ii,:)<nNodes) ); % layer ii data present
            vertexData(I) = max(vertexData(I), nodeData(v2g(ii,I)));
        end
        
    case 'min'  
        %%%%% take max value across layers:
        % (1) initially take layer 1 nodes
        I = find( (v2g(1,:)>0) & (v2g(1,:)<nNodes) ); % layer 1 data present
        vertexData(I) = nodeData(v2g(1,I));
        
        % (2) step through the other 'layers' (not strict layers b/c of the
        % vertex mapping, rather the nodes to which each vertex maps),
        % seeing if there are larger values
        nLayers = size(v2g, 1);
        for ii = 1:nLayers
            I = find( (v2g(ii,:)>0) & (v2g(ii,:)<nNodes) ); % layer ii data present
            vertexData(I) = min(vertexData(I), nodeData(v2g(ii,I)));
        end
        
end


return
