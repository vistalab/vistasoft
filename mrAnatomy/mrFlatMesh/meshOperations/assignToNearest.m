% [nearest, distances] = assignToNearest(toPoints, fromPoints)
%
% (mex file)
%
% PURPOSE:
% Takes two sets of 3D coordinates and returns an index list mapping toPoints to the 
% closest (euclidian distance) points in fromPoints. Also returns the squared distances.
% ARGUMENTS:
%   fromPoints: Nx3 array of y,x,z points to be assigned a nearest toPoint.
%   toPoints:   Mx3 array of y,x,z points that form the pool of points from 
%               which the nearest will be found.
%
% RETURNS:
%   nearestPoints:  Nx1 array of indices into fromPoints
%   distances:      Nx1 array of squared distances from the corresponding fromPoint
%                   to the nearest toPoint.
%
% This is a mex file.
% Similar to dsearchn. Except much faster for this particular (specialized)
% task.
% 