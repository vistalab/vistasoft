function ellipseXSection(lmsCov, planeDims, nPts, nSD, ThreeDflag)
% Plot the predictions within a plane for an ellipsoid
% 
%    ellipseXSection(lmsCov, planeDims, nPts, nSD)
%
% For the L,M, set planeDims = [1,2], and for L,S set planeDims [1,3]
%
% Example:
%  
%
% See also:
%
% Copyright HH, Vistalab 2010

if ieNotDefined('lmsCov'), lmsCov = eye(3,3); end
if ieNotDefined('planeDims'), planeDims = [1,2]; end
if ieNotDefined('nSD'), nSD = 2; end
if ieNotDefined('nPts'), nPts = 45; end
if ieNotDefined('ThreeDflag'), ThreeDflag = false; end

% Make points on a circle
[x,y] = circlePoints(2*pi/nPts);
spherePoints = zeros(length(x),3);
spherePoints(:,planeDims(1)) = x(:);
spherePoints(:,planeDims(2)) = y(:);

eVec = zeros(size(spherePoints,1),2);
for ii=1:size(spherePoints,1)
    l = spherePoints(ii,:)*(lmsCov\spherePoints(ii,:)');
    eVec(ii,:) = nSD*(spherePoints(ii,planeDims)/sqrt(l)); % + mn;
end

if ThreeDflag == false,
    plot(eVec(:,1),eVec(:,2),'r.'); axis equal; grid on

elseif ThreeDflag == true,
    z = zeros(size(spherePoints,1));
    
    switch num2str(planeDims)
        case '1  2'
            plot3(eVec(:,1),eVec(:,2),z,'r.'); 
        case '1  3'
            plot3(eVec(:,1),z,eVec(:,2),'r.'); 
        case '2  3'
            plot3(z,eVec(:,1),eVec(:,2),'r.'); 
        otherwise
            error('planeDims should be [1 2],[1 3],[2 3].');
    end
    axis equal; grid on
end

% Not sure if we need a square root to compute the ratio of the longest to
% shortest axes.
% axisLengths = sqrt(eig(cov(eVec)));
% cNum = axisLengths(end)/axisLengths(1);

return