% function y = stg2center(y,m,flag)
%
% (c) JM, NP; SAFIR, Luebeck, 2006
%
% this function performs the grid change between staggered and cell
% centered grids in 2D or 3D. This function is matrix free.
% input:
%   - y   : the grid (see getGrid for more information)
%   - m   : size of grid
%   - flag: the kind of change (one of
%       'Py'  - change from stg to center
%       'PTy' - change from center to stg (realized by 'multipling' with the
%       transposed matrix)
%
% output:
%   - y     : the new grid
% 
function y = stg2center(y,m,flag)

flag = sprintf('%s-%d',flag,length(m));

switch flag,
  case 'Py-2'
    [y1,y2] = vec2array(y,m,'stg');
    y1 = (y1(2:end,:,:) + y1(1:end-1,:,:))/2;
    y2 = (y2(:,2:end,:) + y2(:,1:end-1,:))/2;
    y = array2vec2D(y1,y2,'centered');
  case 'PTy-2'
    [y1,y2] = vec2array(y,m,'centered');
    y = zeros(size(y1,1)+1,size(y1,2));
    y(1:end-1,:) = y1;
    y(2:end,:) = y(2:end,:) + y1;
    y1 = 0.5 * y;
    
    y = zeros(size(y2,1),size(y2,2)+1);
    y(:,1:end-1) = y2;
    y(:,2:end) = y(:,2:end) + y2;
    y2 = 0.5 * y;

    y = array2vec2D(y1,y2,'stg');
  case 'Py-3'
    [y1,y2,y3] = vec2array(y,m,'stg');
    y1 = (y1(2:end,:,:) + y1(1:end-1,:,:))/2;
    y2 = (y2(:,2:end,:) + y2(:,1:end-1,:))/2;
    y3 = (y3(:,:,2:end) + y3(:,:,1:end-1))/2;
    y = array2vec3D(y1,y2,y3,'centered');
  case 'PTy-3',
    [y1,y2,y3] = vec2array(y,m,'centered');
    y = zeros(size(y1,1)+1,size(y1,2),size(y1,3));
    y(1:end-1,:,:) = y1;
    y(2:end,:,:) = y(2:end,:,:) + y1;
    y1 = 0.5 * y;
    
    y = zeros(size(y2,1),size(y2,2)+1,size(y2,3));
    y(:,1:end-1,:) = y2;
    y(:,2:end,:) = y(:,2:end,:) + y2;
    y2 = 0.5 * y;
    
    y = zeros(size(y3,1),size(y3,2),size(y3,3)+1);
    y(:,:,1:end-1) = y3;
    y(:,:,2:end) = y(:,:,2:end) + y3;
    y3 = 0.5 * y;
    
    y = array2vec3D(y1,y2,y3,'stg');
end;
return;
