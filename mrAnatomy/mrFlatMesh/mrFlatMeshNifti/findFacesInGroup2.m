function trianglesInGroup = findFacesInGroup2(mesh,vertices)
% 
%   trianglesInGroup = findFacesInGroup2(mesh,vertices);
%
% Returns a list of all the triangles that are made up of three vertices
% within in the list of vertices passed in.
%
% Previously, we identified good vertices that are in the region we wish to
% unfold. This may be the full mesh, or just a part.
% 
% ARW 040202

verticesInGroup = zeros(size(mesh.triangles'),'uint8');
for ii=1:3
    % The triangles index vertices from 0.  Matlab starts from 1.  Hence the +1.
    % We keep the 0 because of visualization.
    % This makes an array the same size as triangles, with a 1 whenever of
    % the triangle has a member of the node list.
    verticesInGroup(:,ii) = ismember(mesh.triangles(ii,:) + 1, vertices);
end

% All three vertices of these triangles are in the node list 
trianglesInGroup = squeeze(find(sum(verticesInGroup,2)==3)); 

fprintf('Found %d faces\n',length(trianglesInGroup));

return;