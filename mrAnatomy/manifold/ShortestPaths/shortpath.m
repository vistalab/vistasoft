function [d,p] = shortpath(A,s,t)
%SHORTPATH Shortest path from node 's' to node 't' using Dijkstra algorithm.
% [d,p] = shortpath(A,s,t)
%     A = n x n node-node non-negative arc-length matrix
%     s = FROM node
%       = [] (default), paths from all nodes to node 't' (Reverse Dijkstra)
%     t = TO node
%       = [] (default), paths from node 's' to all nodes
%     d = distance of shortest path from 's' to 't'
%       = [d(i)], where d(i) = distance from 's' to 'i', if 's' to all nodes 
%     p = path from 's' to 't'
%       = predecessor indices, if from 's' to all nodes, where p(i) is the
%         index of the predecessor to node 'i' on the path from 's' to 'i'
%       = successor indices, if from all nodes to 't'
%
%  (Based on Fig. 4.6 in Ahuja, Magnanti, and Orlin, Network Flows,
%   Prentice-Hall, 1993, p. 109.)

% Copyright (c) 1998-1999 by Michael G. Kay
% Matlog Version 1.2 19-Oct-99

% Input Error Checking ******************************************************
narginchk(2,3);

if nargin < 3, t = []; end

[n,cA] = size(A);

if n ~= cA
   error('A must be square matrix');
elseif any(any(A)) < 0
   error('A must be non-negative');
elseif ~isempty(s) & (s < 1 | s > n | length(s(:)) ~= 1)
   error(['''s'' must be an integer between 1 and ',num2str(n)]);
elseif ~isempty(t) & (t < 1 | t > n | length(t(:)) ~= 1)
   error(['''t'' must be an integer between 1 and ',num2str(n)]);
elseif isempty(s) & isempty(t)
   error('''s'' and ''t'' can not both be empty');
end
% End (Input Error Checking) ************************************************

if isempty(s) | isempty(t), doallpaths = 1; else, doallpaths = 0; end
if ~isempty(s)
   A = A';		% Use transpose to speed-up FIND for sparse A
else
   s = t;		% Reverse Dijkstra (original A gives fast column-wise FIND)
end

S = 0; nS = 1:n;
d = inf*ones(n,1); d(s) = 0;
p = zeros(1,n);

i = s;
if doallpaths, t = NaN; end

while S < n & i ~= t
   [di,ii] = min(d(nS));
   i = nS(ii);
   nS(ii) = [];
   S = S + 1;
   
   [iA,jA,Ai] = find(A(:,i));
   
   dj = di + Ai;
   p(iA(dj < d(iA))) = i;
   d(iA) = min(d(iA),dj);
end
d = d';

if ~doallpaths
   d = d(t);
   if nargout > 1, p = pred2path_vista(p,s,t); end
end
