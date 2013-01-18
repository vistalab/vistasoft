function nodesInFaces=findFaceNodes(mesh,group)
% Here's a little problem - outsideNodes can contain groups linked by long, thin chains
% These mess up the perimeter-finder since each group contains a closed perim.
% Get rid of them here by finding only those nodes that are in faces


facesInGroup=findFacesInGroup(mesh,group);
nodesInFaces=unique(mesh.uniqueFaceIndexList(facesInGroup,:));


