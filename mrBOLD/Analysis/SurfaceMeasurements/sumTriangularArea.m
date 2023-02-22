function [area,areaList] = sumTriangularArea(tri, coords)
% [area,areaList] = sumTriangularArea(triangles, coords)
%
% AUTHOR:  Dougherty
% DATE:    09.16.99
% PURPOSE:
%
% Given the triangles specified by 'triangles' and
% 'coords' (see below), computes the total surface
% area of all the triangles.  
%
% Triangles is an Nx3 set of indices into coords, 
% which should be 3xM.  Thus, triangles(1,:) specifies
% the 3 verticies of the first triangle, which are:
% coords(:,triangles(1,1)),coords(:,triangles(1,2)),
% and coords(:,triangles(1,3)).
%
[numT,n] = size(tri);
if n~=3
   error('triangles must be Nx3!');
end
% Heron's formula for the area of a triangle:
% area = sqrt(s*(s-a)*(s-b)*(s-c))
% where s = (a+b+c)/2 and a,b,c are the lengths
% of the sides.
area = 0;
if nargout>1
   areaList = zeros(numT,1);
end
for ii=1:numT
    % find the side lengths
    a = sqrt(sum((coords(:,tri(ii,1))-coords(:,tri(ii,2))).^2));
    b = sqrt(sum((coords(:,tri(ii,2))-coords(:,tri(ii,3))).^2));
    c = sqrt(sum((coords(:,tri(ii,3))-coords(:,tri(ii,1))).^2));
    % find half the perimeter
    s = (a+b+c)/2;
    % Heron's formula:
    curArea = sqrt(s*(s-a)*(s-b)*(s-c));
    if(~isreal(curArea))
        % this happens sometimes when matlab rounds things off.
        curArea = 0;
    end
    area = area + curArea;
    if nargout>1
        areaList(ii) = curArea;
    end
    areas(ii) = curArea;
end

return;
figure;hist(areas,20);