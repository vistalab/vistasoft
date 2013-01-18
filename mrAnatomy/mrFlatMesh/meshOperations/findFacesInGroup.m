function facesInGroup=findFacesInGroup(mesh,nodes);
% 
%  facesInGroup=findFacesInGroup(mesh,nodes);
%
% Returns a list of all the faces that are in the group specified by nodes
% Have identified good vertices (nodes that are in the group). Now make a list of good faces - faces that contain 3 good vertices
% ARW 040202

ufl=mesh.uniqueFaceIndexList(:,1);
ufi(:,1)=ismember(ufl,nodes);
ufl=mesh.uniqueFaceIndexList(:,2);
ufi(:,2)=ismember(ufl,nodes);
ufl=mesh.uniqueFaceIndexList(:,3);
ufi(:,3)=ismember(ufl,nodes);

facesInGroup=squeeze(find(sum(ufi')==3)); % These faces contain only nodes from the node list supplied
fprintf('Found %d faces\n',length(facesInGroup));

return;