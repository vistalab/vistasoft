function [m,p,s] = mrvFitLine3D(C)
%
% x,y,z are n x 1 column vectors of the three coordinates of a set of n
% points in three dimensions. The best line, in the minimum mean square
% orthogonal distance sense, will pass through m and have direction cosines
% in p, so it can be expressed parametrically as 
%
%    x = m(1) + p(1)*t
%    y = m(2) + p(2)*t
%    z = m(3) + p(3)*t
%
% where t is the distance along the line from the mean point at m. 
% Returns:
%  m - a point on the line at t = 0
%  p - the direction vector
%  s - minimum mean square orthogonal distance to the line.
%
% Example:
%   C = [1,1,1; 1,2,1; 1,3,1]';  % Each coordinate in a column
%   [m,p,s] = mrvFitLine3D(C)
%  
%   N = C + randn(size(C))*0.1;
%   [m,p,s] = mrvFitLine3D(N)
%
%   t = [-5:.1:5];
%   for ii=1:3, x(:,ii) = m(ii) + p(ii)*t(:); end
%   figure; 
%   plot3(x(:,1),x(:,2),x(:,3)); hold on
%   plot3(C(1,:),C(2,:),C(3,:),'ro'); hold off
%
% RAS - March 14, 2005
% http://www.mathworks.com/matlabcentral/newsreader/view_thread/90452 

if size(C,1) ~= 3, error('Coordinates must be in columns'); end

x = C(1,:); y = C(2,:); z = C(3,:);

m = [mean(x),mean(y),mean(z)];
w = [x - m(1); y - m(2); z - m(3)];    % Use "mean" point as base
[u,d,v] = svd(w);  % 'eig' & 'svd' get same eigenvalues for this matrix

p = u(:,1)';       % Get eigenvector for largest eigenvalue
s = d(2,2)+d(3,3); % Sum the other two eigenvalues

return