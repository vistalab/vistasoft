% mrManDist.m
% --------------------
%
% function [dist, nPntsReached] = mrManDist(grayNodes, grayEdges,
%                                           startPt, :dimdist, :noVol, :radius)
%
%  AUTHOR:  S. Engel, B. Wandell
%    DATE:  May, 1995
% PURPOSE:
%   Computes the distances within the gray matter manifold between 
%   the start point and other gray matter points. 
%
% ARGUMENTS:
%   grayNodes, grayEdges : gray matter graph.
%       startPt: grayNode index where to start the flood fill.
%
%    (Optional)
%       dimdist: N.B.: Array of y, x and z separations between points. 
%         noVol: The value returned for unreached locations (default 0).
%       nRadius: The max distance to flood out.
%                (default 0 == flood as far as can)
%
% RETURNS:
%          dist: Vector of distances to each point from startPt. 
%                (Length = number of elements in grayM)
%  nPntsReached: The number of points reached from startPt.  To check
%                continuity each gray matter point should have been reached.
%
%  N.B.  The computations in mrManDist use the 7th and 8th rows
%   of nodes.  Hence, these values are changed after calls to
%   mrManDist.  Sometimes the values can be quite large and this
%   makes it confusing to read out the values in nodes(:,X).  To
%   see the values clearly, just look at the first 6 rows, which
%   are the only ones that contain data relevant to our purpose,
%   that is nodes(1:6,X).
%   
%   MODIFIED:  
%     Completely re-written by Patrick Teo, 1996
%     
%     08.05.98 Modified again by S. Chial and BW
%     Started to re-write for sub-Graph computations and new unfolding.
%     We updated for the new format of Matlab 5.2 in the mexFunction prototype
%      and we changed the obsolete calls to mxCreateFull.
%      SJC/BW
%
%   TO COMPILE:
%     
%      We are using mcc (ver 5.2) to compile this function.   
%      To simplify compilation, we have inserted 
%      pqueue.c  into the mrManDist.c source code we type
%     
%           mcc mrManDist.c
%	 
%       Make sure that /usr/pubsw/bin is early in your path so 
%       that consistent versions of gcc and the assembler, as are called.
%     
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
