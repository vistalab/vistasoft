function lineIdx = ...
  mrGeodesic(grayNodes,grayEdges,dimdist,radius,spacing,crit,seed1,seed2)  
% 
% lineIdx = 
%    mrGeodesic(grayNodes,grayEdges,dimdist, ...
%        radius,spacing,crit,seed1,[seed2])   
% 
% AUTHOR:  Heeger, Wandell
% DATE:
% PURPOSE:
%   Find the gray node indices along a geodesic between seed1 and
% seed2.  The gray node indices are separated by spacing.
% 
% grayNodes, grayEdges, dimdist:  These are the usual parameters
%      from the unfolding analysis.
% 
% radius:  If one seed, choose the second near this radius
% spacing: Spacing of sample points along the geodesics
% crit:    Criterion level that determines how close does the
%           point have to be to satisfying the "on the line"
% seed1:   Starting point for one end of the geodesic
% [seed2:] Second point on the geodesic.
% 
% TODO:
%   Order of arguments could be better.  I am not sure we handle
% to two seed case properly.  BW
% 

errordlg('This function is obsolete.  Use the method described in mrManDist.  Then implement that method here.');

noVol = -1; 

% Find the distances from seed1 and a second seed that is as far
% away as possible
% 
dist1 = mrManDist(grayNodes, grayEdges, seed1, dimdist, noVol, radius + 1);

if (~exist('seed2'))
  [dist12 idx] = max(dist1);
  seed2 = idx;
else
  dist12 = dist1(seed2);
  if (radius < dist12)
    disp('Increasing radius')
    radius = dist12 + 1;
  end
end
 
% The points along a geodesic between 1 and 2 should have a
% distance from 1 and 2 that sums to the distance between 1 and 2
% 
dist2 = ...
    mrManDist(grayNodes, grayEdges, seed2, dimdist, noVol,radius + 1);
between12 = find( abs(dist1 + dist2 - dist12) < crit);

% This finds the points spaced by an amount sep along the
% geodesic 
% 

sep = [spacing:spacing:dist12];
nSep = length(sep);
lineIdx = ones(nSep,1)*(-1);

for count = 1:nSep;
  [v idx] = min(abs(dist1(between12) - sep(count)));
  lineIdx(count) = between12(idx);
end

return;

% DEBUGGING:
% cd /usr/local/matlab/toolbox/stanford/mri/unfold/Example
% [grayNodes grayEdges] = readGrayGraph('Graph.gray');
% seed1 = 100
% radius = 30
% dimdist = [1.0667 1.0667 1.0000];
% spacing = 1;
% lineIdx = mrGeodesic(grayNodes,grayEdges,dimdist,radius,spacing,crit,seed1,seed2);
% 
% grayNodes(1:3,lineIdx(1:nSep,1))
% To view this, we need to plot these points on top of the volume
% anatomy somehow.
