function [area,length] = mrmMeasureMeshRoi(msh)
%
% [area,length] = mrmMeasureMeshRoi(msh)
%
% Simple function to measure the current meash ROI area and length.
% Note that area measurements are meaningless for line ROIs, and length
% measurements are meaningless for filled ROIs. I couldn't figure out an
% elegant way to guess which it is that the user drew, so i compute both
% metrics and leave it to the user to decide which is meaningful.
%
% Example:
% mshFile = '/biac1/wandell/data/anatomy/winawer/left_wrinkled.mat';
% msh = mrmReadMeshFile(mshFile);
% msh = meshSet(msh,'windowid',300);
% msh = mrmInitMesh(msh);
% mrmSet(msh,'hidecursor'); 
% name = meshGet(msh,'name');
% if isempty(name), [p,name] = fileparts(mshFile); end
% mrmSet(msh,'title',name);
% while(1)
%   uiwait(msgbox('Draw your ROI in the mesh, then press OK.','Wait for ROI...','modal'));
%   mrmMeasureMeshRoi(msh);
% end
% 
% 2008.06.10 RFD wrote it.

% measure ROI area or length
roi = mrmGet(msh,'roi');

% Check for an enclodes region (measure its area)
% First, associate each vertex in the ROI with a triangle
triAll = ismember(msh.triangles+1,roi.vertices);
% Get only those triangles that have all 3 vertices in the ROI
completeTriangles = unique(find(all(triAll)));
orphanVerts = find(~ismember(roi.vertices,msh.triangles(:,completeTriangles)+1));
nTri = numel(completeTriangles);
if(~isempty(nTri))
    fprintf('ROI contained %d complete triangles (%d orphaned vertices). Computing area...\n',nTri,numel(orphanVerts));
    % We could massage the data structures to use findFaceArea, but it's
    % more fun (and instructive) to write it out:
    v = msh.initVertices;
    t = msh.triangles(:,completeTriangles)+1;
    % Following is a simple distance formula: 
    %    d = sqrt((x1-x2)^2 + (y1-y2)^2 + (z1-z2)^2) 
    % computed on each of the three sides of each triangle
    edgeLen = sqrt([sum((v(:,t(1,:))-v(:,t(2,:))).^2); sum((v(:,t(2,:))-v(:,t(3,:))).^2); sum((v(:,t(3,:))-v(:,t(1,:))).^2)]);
    % Compute the area using heron's formula:
    % A = sqrt(s(s-a)(s-b)(s-c)); where s = 1/2(a+b+c);
    s = 0.5*sum(edgeLen);
    triArea = sqrt(s.*(s-edgeLen(1,:)).*(s-edgeLen(2,:)).*(s-edgeLen(3,:)));
    totalInitArea = sum(triArea);
    % DO it again for smoothed mesh area:
    v = msh.vertices;
    edgeLen = sqrt([sum((v(:,t(1,:))-v(:,t(2,:))).^2); sum((v(:,t(2,:))-v(:,t(3,:))).^2); sum((v(:,t(3,:))-v(:,t(1,:))).^2)]);
    s = 0.5*sum(edgeLen);
    triArea = sqrt(s.*(s-edgeLen(1,:)).*(s-edgeLen(2,:)).*(s-edgeLen(3,:)));
    totalSmoothArea = sum(triArea);
    fprintf('ROI area is %0.2f mm^2 (%0.2f mm^2 on the smoothed surface)\n',totalInitArea,totalSmoothArea);
end
% Find triangles that contain exactly two ROI vertices (ignore complete triangles)
tmp = sum(triAll)==2;
% Take that ROI vertex edge from each triangle
t = msh.triangles(:,tmp);
edges = reshape(t(triAll(:,tmp)),2,size(t,2));
edges = unique(edges','rows')';
v = msh.initVertices;
segLen = sqrt(sum([v(:,edges(1,:))-v(:,edges(2,:))].^2));
roiInitLength = sum(segLen);
v = msh.vertices;
segLen = sqrt(sum([v(:,edges(1,:))-v(:,edges(2,:))].^2));
roiSmoothLength = sum(segLen);
fprintf('ROI length is %0.2f mm (%0.2f mm on the smoothed surface)\n',roiInitLength,roiSmoothLength);

return;


