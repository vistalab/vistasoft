function [Dt, totalDist] = InterfiberZhangDistance(curve1, curve2, Tt)
%Distance between two 3D paths, defined as two 3xN sets of 3d coordinates. 
%
% [Dt, totalDist] = InterfiberZhangDistance(curve1, curve2, [Tt=2])
%
% The terms Dt and totalDist need better definition here.
%
% The metric is described in Zhang et al. (2003) IEEE Transactions on
% Vizualization and Computer Graphics 9(4).  They write:
%
% �In order to emphasize important differences between a pair of
% trajectories, we average the distance between the curves only over the
% region where they are at least Tt apart; smaller differences are assumed
% to be insignificant�. 
% 
% Although arguable, it is natural to set Tt to data voxel size /not sure,
% before or after resampling/ (as Zhang 2003 did). Here the default value
% is set to 1mm despite the fact that out data are commonly 2x2x2. 
%
% Calculated on a point by point basis.
% Note: by definition, if a point on a shorter fiber is closer to the other
% fiber than Tt, this point does NOT contribute to the overall
% curve-to-curve distance measure.
%
%Dt is above-the-threshold (that is, minus Tt) average point-to-curve
%distance  across all points on a shortest fiber to another fiber.  
%
%  CLARIFY.
% The output variable totalDist is Dt+Tt, the average point-to-curve
% distance between the two fibers. These output arguments are different by
% a constant,  however included since the first one is the "definition" of
% the distance by Zhang et al., and the second one is easier to interpret.
% Also totalDist is reported as at least at Tt (even for two fibers which
% are closer than Tt).
%
%  Example:
%    curve1 = 10*rand(3,10);
%    curve2 = curve1 + 1;
%    Tt = 0;
%    [Dt, totalDist] = InterfiberZhangDistance(curve1, curve2,Tt)
%    [Dt, totalDist] = InterfiberZhangDistance(curve1, curve2,2)
%
%ER 11/2008
%ER 04/2009 added "totalDist" output and introduced a default value for Tt
%to be 0 (all points contribute to the distance measure). 
%
% (c) Stanford VISTA Team

%Pairs of points in closer than Tt are not included when summing the
%distance between fibers. 
if (~exist('Tt', 'var')), Tt=0; end

% Check curve sizes.
if size(curve1, 1) ~= 3 || size(curve2, 1) ~= 3
   error('Fiber coordinates must be represented as 3xN');
end

% Use  "nearpoints" to find the nearest point in curve 1 to curve 2.
% [indices, bestSqDist] = nearpoints(src, dest)
%-  src is a 3xM array of points
%-  dest is a 3xN array of points
%-  indices is a 1xM vector, whose elements identifies the closest point
%   in dest for each entry in src.  
%   "bestSqDist" is the distance.
%

% For efficiency, choose which is the first term
if size(curve1, 2) < size(curve2, 2), 
    [indices, bestSqDist] = nearpoints(curve1, curve2);
else
    [indices, bestSqDist] = nearpoints(curve2, curve1);
end

% Have a look at the data in the two curves.
% mrvNewGraphWin; 
%  plot3(curve1(1,:),curve1(2,:),curve1(3,:),'bo'); hold on
%  plot3(curve2(1,:),curve2(2,:),curve2(3,:),'r.');
% 

% I don't understand.  If there are no entries bigger than Tt, we set Dt to
% zero, I guess.
nPoints = length(find(bestSqDist > Tt));
if nPoints <= 0
    % Expansive but useless. Precisely,
    % Tt=sum(sqrt(bestSqDist))/length(bestSqDist); 
    % We keep it as a constant Tt. 
    Dt = 0; 
else
    % Otherwise, we set Dt to this average.
    Dt = sum(sqrt(bestSqDist(bestSqDist > Tt)) - Tt) / nPoints; 
end

% Then we add Tt back in.
totalDist = Dt + Tt;

return;



%%The slow way (gives equivalent result)
if size(curve1, 2)<size(curve2, 2)
    scurve=curve1;  %shorter
    lcurve=curve2; %longer curve
else
    scurve=curve2;
    lcurve=curve1;
end

countpoints=0;  sumdist=0;

for pnt=1:size(scurve,2)
    distVector = sqrt((lcurve(1, :)-scurve(1, pnt)).^2 + (lcurve(2, :)-scurve(2, pnt)).^2+(lcurve(3, :)-scurve(3, pnt)).^2);
    p2curveDist=min(distVector); %Shortest point to curve distance

    if p2curveDist>Tt
        countpoints=countpoints+1;
        sumdist= sumdist+ (p2curveDist-Tt);
    end

end

if countpoints>0
    Dt=sumdist/countpoints;
else
    Dt=0;
end
