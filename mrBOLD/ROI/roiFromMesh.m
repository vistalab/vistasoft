function roi = roiFromMesh(seg, mapMethod, mr);
%
% roi = roiFromMesh(seg, [mapMethod='all'], [mr]);
%
% Create an ROI based on vertices in the selected mesh contained
% within a given segmentation struct seg, based on the 
% sepecified mapping method.
%
% mapMethod can be 'layer1' or 'all' ('all' by default).
%
% If an mr struct is passed as an optional third argument, will
% check the new ROI coords against these coords and return it 
% relative to that mr object. (E.g., will xform the ROI from
% segmented volume -> inplanes).
%
% ras, 01/2007.
if nargin < 1, error('Need roi and segmentation inputs.'); end

if notDefined('mapMethod'),     mapMethod = 'all'; end

msh = segGet(seg, 'SelectedMesh');
mrmRoi = mrmGet(msh,'curRoi'); % ROI as defined on mesh
if ~isfield(mrmRoi,'vertices'), error('No ROI defined on mesh!'); end

% initialize empty ROI based on the same anatomy coords as the segmentation
roi = roiCreate('I|P|R');
roi.voxelSize = msh.mmPerVox;


% the main part of this code will be finding the indices I
% from the gray coordinates which are contained within the
% ROI, given the current mapping method.
% We initialize I to include those layer 1 nodes in the ROI:
layer1Nodes = msh.vertexGrayMap(1,mrmRoi.vertices);
curLayer = unique( layer1Nodes(layer1Nodes>0) );
I = curLayer;

if isequal(lower(mapMethod), 'all')
    [nodes edges] = segGet(seg, 'gray');
    
    % Start with the ROI vertices, which *should* be just layer 1 nodes.
    curLayerNum = 1;
    while ~isempty(curLayer)
        nextLayer = [];
        curLayerNum = curLayerNum+1;
        for ii = 1:length(curLayer)
            offset = nodes(5,curLayer(ii));
            if offset>length(edges), continue; end
            numConnected = nodes(4,curLayer(ii));
            neighbors = edges(offset:offset+numConnected-1);
            nextLayer = [nextLayer, neighbors(nodes(6,neighbors)==curLayerNum)];
        end
        nextLayer = unique(nextLayer);
        I = [I nextLayer];
        curLayer = nextLayer;
    end
end

grayCoords = segGet(seg, 'GrayCoords');
roi.coords = grayCoords(:,I);

% give the ROI a name that describes approx where it is
cen = round( mean(roi.coords, 2) );
roi.name = sprintf('MeshROI ~(%i, %i, %i)', cen(2), cen(1), cen(3));


if exist('mr', 'var') | ~isempty(mr)
    mr = mrParse(mr);
    roi = roiCheckCoords(roi, mr);
end
    
return
