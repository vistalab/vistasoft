function roi = roiGrayDisk(seg, mr, radius, startPt);
% Create an ROI as a disk of gray matter with the specified startPt
% and radius.
%
% roi = roiGrayDisk(seg, mr, [radius=dialog], [startPt=mesh cursor]);
%
%
% ras, 02/2007.
if nargin<2, error('Not enough input args.');	end
if notDefined('mapMethod'),     mapMethod = 'all'; end

msh = segGet(seg, 'SelectedMesh');
[nodes edges] = segGet(seg, 'gray');

if isempty(msh.vertexGrayMap) | all(msh.vertexGrayMap(:)==0)
    msh.vertexGrayMap = mrmMapVerticesToGray(msh.initVertices, nodes, ... 
							msh.mmPerVox, edges);    
end
    

if notDefined('startPt')
	vtx = mrmGet(msh, 'cursorvertex');
	
	if vtx<1
		error('Mesh Cursor not pointing to a vertex on the mesh.')
	end
	
	I = msh.vertexGrayMap(1,vtx); % layer 1 node for this vertex
	startPt = nodes([2 1 3],I);	
end

if notDefined('radius')
	r = inputdlg({'Enter Gray Disk Radius (mm):'}, mfilename, 1, {'3'});
	radius = r{1};
end

%% initialize empty ROI based on the same anatomy coords as the segmentation
roi = roiCreate('I|P|R');
roi.voxelSize = msh.mmPerVox;
if isstruct(mr)
	roi.referenceMR = mr.name;
else
	roi.referenceMR = mr;
end

%% find index of gray node closest to start point
startNode = segGet(seg, 'NearestNode', startPt);

%% compute the distance between each gray node and the start point
dist = mrManDist(nodes, edges, startNode, msh.mmPerVox, -1, radius);

%% find those nodes whose distance is within the radius
inside = find(dist >= 0); % only searches within radius; invalid is -1

%% get the coords of those nodes, set as ROI coords
roi.definedCoords = nodes([2 1 3],inside);
roi.coords = roi.definedCoords;
roi = roiCheckCoords(roi, mr);
roi.name = sprintf('Disk ROI (%i mm about %s)', radius, num2str(startPt'));
roi.comments = [sprintf('Created by %s %s \n', mfilename, datestr(now)) ...
				sprintf('Start Point %s \n', num2str(startPt)) ...
				sprintf('Start Node %i \n', startNode) ...
				sprintf('Radius %i mm', radius)];

return