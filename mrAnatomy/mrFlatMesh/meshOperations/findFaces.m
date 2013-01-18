function faceIndexList = findFaces(mesh,busyHandle)
%Extracts the matlab facelist (patch command) from the list of strips and
%triangles in an old format MrM mrGray mesh
%
%  faceIndexList=findFaces(mesh,busyHandle)
%
% The mrGray meshes are not compatible with modern ones we use.  They
% contain a list of strips and triangles in mesh.vertices and
% mesh.stripList 
%
% RETURNS: faceIndexList : nPoints*3 - triplets of indices into the original vertex list that define triangular faces
% DATE: Last modified 020701
% NB: See also findUniqueFaceIndexList.m
% AUTHOR:  Wade
% ARW 021501 : added a busy indicator

if notDefined('busyHandle'), busyHandle=0; end

nVerts=length(mesh.vertices);

% The mesh is encoded by mrGray in terms of strips and pure
% triangles.  Strips are an efficient method of encoding lists
% of triangles that contain common edges.  See mrReadMrm.m
%
triangleVertices=mesh.vertices(mesh.triangleOffset:end,:);
stripVertices=mesh.vertices(1:(mesh.triangleOffset-1),:);

% Striplist is organized as offset,pointsInStrip
% N.B.  The offset is zero-referenced
%
stripList=mesh.stripList;

nStrips=length(stripList);
nTriangles=length(triangleVertices/3);
nFacesInStrip=length(stripVertices-(nStrips*2));

totalFaces=nFacesInStrip+nTriangles;
indexList=[1:length(mesh.vertices)]';

% This is an efficient way to build up the list of triangle vertices.
% A matrix, faces, is built by taking the indexList and shifting it up
% by 1 for the second column and up by two for the third column.  Then the
% first row comprises the first triangle, the second row the second
% triangle, and so forth.  This is appropriate for a single strip.
% We ignore the stuff at the bottom of each strip.
% 
% At this point, faces is really a dummy list of faces that contains
% some bad data.  We will pull out the real faces in a loop below.
%

faces=[indexList,shift(indexList,[-1,0]),shift(indexList,[-2,0])];

% Find the indices to the positions of the triangles.
% During the construction of the faces, above, the triangles 
% have each generated a good row and two bad rows. 
% This is the list of good rows.
triangleList=((mesh.triangleOffset-1):3:(nVerts-3))'; 

% Now the triangles are like little strips, again in the form
% of (offset, pointsInStrip).  pointsInStrip is always
% 3 for a triangle.
triangleList=[triangleList, ones(length(triangleList),1)*3];

% Since triangles are just little strips, put them in the same list
% 
fullStripList=[stripList;triangleList];
% Here, we go through the entire strip list and represent
% all of the faces in a single Nx3 matrix, faceIndexList.
%
% AW:  This loop could really just create the indices and
% then pull out the data afterwards, saving some looping time.
%
faceIndexList=zeros(length(faces),3);

counter=1;
for t=1:length(fullStripList)   
   
   % The +1 is needed because the strip list is zero-referenced
   s=fullStripList(t,1)+1;
   
   % The number of faces (or triangles)
   % in a strip is the number of pointsInStrip - 2
   nFaces=fullStripList(t,2)-2;
   
   % Here we are, pulling out the real faces from faces into the
   % faceIndexList
   %
   faceIndexList(counter:(counter+nFaces-1),:)=faces(s:(s+nFaces-1),:);
   counter=counter+nFaces;

end

% Find the first entry in faceIndexList that was not filled
% with a value.  (faceIndexList is over-allocated above).
% Shrink faceIndexList to the proper size

f=sort(find(faceIndexList<1));
faceIndexList=faceIndexList(1:(f(1)-1),:);

return;
