% mrManDist (Mex-file)
% 
%    [dist, nPointsReached, lastPoint] = mrManDist(grayNodes,grayEdges,startPt,dimdist,[noVal],[radius])
%  
% Purpose:
%  This is an important function that measures the distance from a start
%  point to other points in the gray matter.  The gray matter nodes and the
%  edges connecting them are defined in the gray file written out by
%  mrGray.  The Dijkstra algorithm measures the distances within the graph.
%  It is possible to use this routine to find geodesics as well (see
%  below).
% 
%   ARGUMENTS:
%    grayNodes: [8xN] The N vertices are stored in rows 1:3. Other information 
%               about the vertices is stored in other rows. 
%               row 4:   number of edges connected to this node
%               row 5:   offset into edge array where neighbor
%                  node indices are stored
%               row 6:   gray matter layer for this node
%               row 7:   junk used in calculation
%               row 8:   junk used in calculation
%   grayEdges:  A list that contains information about the edges between vertices
%     The first row of this always has a list of edges.  Ordinarily these are computed on the assumption
%       that the edges are on connected grid points separated by dimdist, and
%       grayEdges is a vector.  
%     If there is a second row, the second row describes the edge lengths.  We use this
%       feature when measuring distances on a sub-graph.  
%       We send in the edge lengths measured on geodesics in the larger connected graph.
%
%    startPt:   node index defining where to start the flood fill
%               CAUTIION: node indices are often stored as int32s, and
%               mrManDist expects a double, so force STARTPT to
%               be double to avoid the dist='noVal' error.
%    dimdist:   Vector of y,x and z separations between points.
%               Stored in UnfoldParams in the anatomy directory.
%               Use the routine loadUnfoldParams to get this
%               value returned.
%    noVal:     This is the value returned when a node has not
%               been reached (default = 0)
%    radius:    The distance to flood fill out to find nodes
%               (default = 0 is interpreted as go forever)
%               
%   RETURNS:
%       
%    dist:  distances to each point from startPt -- same size as grayM
%
%    nPntsReached:  The number of points reached from the start point. THIS
%    IS BROKEN- it will always be zero. We think this is due to a minor bug
%    in the c-code that mis-allocates the pointer for the return value (see
%    lines 468 & 363 in mrManDist.c version 2.0).
%
%    lastPoint: The last node on the geodesic starting at the start point
%    and ending here. To find the geodesic from the start point to a given
%    endpoint, you will trace back through this list:
%
%  filename =fullfile(mraRootPath,'ManifoldUtilities','testData','Left.gray');
%  [nodes, edges, vSize] = readGrayGraph(filename);
%  mmPerPix = [1,1,1];
%  startPoint = 500;
%  dist = mrManDist(nodes, edges, startPoint, mmPerPix, -1, 0);
%  figure; hist(dist(:),100);
%
%  startPoint, [1 1 1], NaN, 0);
%  startPoint = 500;
%  endPoint = 1000;
%  [dist, nPntsReached, lastPoint] = mrManDist(nodes, edges, startPoint, [1 1 1], NaN, 0);
%  nextPoint = endPoint;
%  while(nextPoint~=startPoint)
%       geodesic(end+1) = lastPoint(nextPoint);
%       nextPoint = lastPoint(nextPoint);
%  end
%   
%  EXAMPLE:
%      
%      global mrSESSION
%      radius = 5;
%      noVal = -1;
%      SEGMENTATION = loadUnfoldParams(SEGMENTATION);
%      dist = mrManDist(grayNodes,grayEdges,startPt,SEGMENTATION.dimdist,noVal,radius)
%      l = find(dist > 0); 
%      localNodes = grayNodes(:,l);
%      localEdges = grayEdges(:,l);
%      
% Authors:  Completely re-written by Patrick Teo, 1996.
%           Re-written again by Chial, Wandell and others.
%
% 08.05.98 Started to re-write for sub-Graph computations and new unfolding.
%	      This included allowing edges to be a two dimensional to specify
%	      both the edges and the edge lengths in the larger graph. Also, we
%	      updated for the new format of Matlab 5.2 in the mexFunction
%	      prototype and we changed the obsolete calls to mxCreateFull.
%	      SJC/BW
%      
% 07.27.00 (BW, this file)  



