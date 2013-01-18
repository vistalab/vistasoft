function [areaList, smoothedAreaList] = mrmComputeMeshArea(msh, vertInds);
% Compute area for all or some triangles in a mesh.
%    [areaList, smoothedAreaList] = mrmComputeMeshArea(msh, [vertInds=[]]);
%
% Computes the area of all triangles in a mesh (vertInds=[]) or the area of
% the subset of triangles whose vertices are in the list of vertInds.
% (NOTE: all 3 of a triangle's vertices must be in the list for it to be
% counted.)
%
% The algorithm uses the initVertices (the vertices from the unsmoothed
% mesh). But, if you catch a second return arg, you can get the areas for
% the smoothed mesh verices too.
%
% HISTORY:
%  2005.08.03 RFD: wrote it.

if(~exist('vertInds','var')), vertInds = []; end

verts(1,:) = msh.initVertices(1,:)*msh.mmPerVox(1);
verts(2,:) = msh.initVertices(2,:)*msh.mmPerVox(2);
verts(3,:) = msh.initVertices(3,:)*msh.mmPerVox(3);

if(~isempty(vertInds))
    currentT = meshGet(msh,'triangles')+1;
    triInds = ismember(currentT(1,:), vertInds) ...
            & ismember(currentT(2,:), vertInds) ...
            & ismember(currentT(3,:), vertInds);
    triangles = currentT(:,triInds);
    clear triInds;
else
    triangles = meshGet(msh,'triangles')+1; 
end

% compute all edge lengths
a = sqrt(sum((verts(:,triangles(1,:))-verts(:,triangles(2,:))).^2));
b = sqrt(sum((verts(:,triangles(2,:))-verts(:,triangles(3,:))).^2));
c = sqrt(sum((verts(:,triangles(3,:))-verts(:,triangles(1,:))).^2));

% find half the perimeter
s = (a+b+c)/2;

% Heron's formula:
areaList = sqrt(s.*(s-a).*(s-b).*(s-c));

% We occasionally get non-real vals for degenerate triangles.
areaList(~isreal(areaList)) = 0;

if(nargout>1)
    % do it again, this time with the smoothed vertices
    currentV = meshGet(msh,'vertices');
    verts(1,:) = currentV(1,:)*msh.mmPerVox(1);
    verts(2,:) = currentV(2,:)*msh.mmPerVox(2);
    verts(3,:) = currentV(3,:)*msh.mmPerVox(3);
    a = sqrt(sum((verts(:,triangles(1,:))-verts(:,triangles(2,:))).^2));
    b = sqrt(sum((verts(:,triangles(2,:))-verts(:,triangles(3,:))).^2));
    c = sqrt(sum((verts(:,triangles(3,:))-verts(:,triangles(1,:))).^2));
    s = (a+b+c)/2;
    smoothedAreaList = sqrt(s.*(s-a).*(s-b).*(s-c));
    smoothedAreaList(~isreal(smoothedAreaList)) = 0;
end


return;