function coords = dtiGrowRoiLateral(seedPoint, vecImg, faImg, voxSize, faThresh, angleThresh, maxRadius)
% coords = dtiGrowRoiLateral(seedPoint, vecImg, faImg, voxSize, faThresh, angleThresh, maxRadius)
% 
% Returns Nx3 array of coordiantes (which will include the seed).
%
% The 
%
% HISTORY:
%   2003.11.12 RFD (bob@white.stanford.edu) wrote it.
%

if(~exist('angleThresh','var') | isempty(angleThresh))
    angleThresh = 10;
end
if(~exist('maxRadius','var') | isempty(maxRadius))
    maxRadius = 0; % 0 means no limit.
end

% Parse options
if(~exist('options','var'))
    options = {};
end
%noCrossPath = ~isempty(strmatch('nocrosspath',lower(options)));

seed = round(seedPoint);
% Get direction vector for seed voxel
vDir = [vecImg(seed(1), seed(2), seed(3), 1); ...
        vecImg(seed(1), seed(2), seed(3), 2); ...
        vecImg(seed(1), seed(2), seed(3), 3); ];
% The cross product of two vectors gives a third vector that is
% perpendicular to the plane defined by the two vectors. Thus, we can
% use the cross product of our direction vector with each of our axis vectors 
% to find the plane perpendicular to this direction vector:
perpX = cross(vDir, [1,0,0]);
perpY = cross(vDir, [0,1,0]);
perpZ = cross(vDir, [0,0,1]);
% Get all voxels that intersect this plane:
error('Implement me!');

newCoord = seed;
coords = [];
done = false;
while(~done)
    % Get direction vector for this voxel
    vDir = [vecImg(newCoord(1), newCoord(2), newCoord(3), 1); ...
            vecImg(newCoord(1), newCoord(2), newCoord(3), 2); ...
            vecImg(newCoord(1), newCoord(2), newCoord(3), 3); ];
    
    % Get the FA for this voxel
    fa = faImg(newCoord(1), newCoord(2), newCoord(3));
    coords = [coords; newCoord];
    done = true;
end

return;


% debug
%p = [0,0,0;1/sqrt(3),1/sqrt(3),1/sqrt(3)];
p=[0,0,0;1,0,0];
figure;
np = p;
plot3(np(:,1), np(:,2), np(:,3), 'r'); 
grid on; hold on;
np(2,:) = cross(p(2,:),[1,0,0]);
plot3(np(:,1), np(:,2), np(:,3));
np(2,:) = cross(p(2,:),[0,1,0]);
plot3(np(:,1), np(:,2), np(:,3));
np(2,:) = cross(p(2,:),[0,0,1]);
plot3(np(:,1), np(:,2), np(:,3));
hold off;

