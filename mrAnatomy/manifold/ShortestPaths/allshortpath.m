function [D,P] = allshortpath(A)
%ALLSHORTPATH Shortest path of all node pairs using Floyd-Warshall algorithm.
% [D,P] = allshortpath(A)
%     A = n x n node-node arc-length matrix
%         If all arc lengths positive, use A(i,j) = 0 if no arc (i,j);
%         else (some negative lengths), use A(i,j) = Inf if no arc 'i' to 'j' 
%     D = n x n matrix of shortest-path distances, where D(i,j) is the
%         distance from node 'i' to node 'j'
%     P = n x n matrix of predecessor indices, where P(i,j) is the index of
%         the predecessor to node 'j' on the path from node 'i' to 'j'
%
%  (Based on Fig. 5.7 in Ahuja, Magnanti, and Orlin, Network Flows,
%   Prentice-Hall, 1993, p. 148.)

% Copyright (c) 1998-1999 by Michael G. Kay
% Matlog Version 1.2 19-Oct-99

% Input Error Checking ******************************************************
[n,cA] = size(A);

if n ~= cA
   error('A must be square matrix');
end
% End (Input Error Checking) ************************************************

if any(any(A < 0))
   negarcs = 1;
else
   negarcs = 0;
   A(A == 0) = inf;
   A = triu(A,1) + tril(A,-1);
end

if nargout > 1, P = (1:n)'*ones(1,n); end

for k = 1:n
   D = A(:,k*ones(1,n)) + A(k*ones(1,n),:);
   if nargout > 1
      Pk = P(k*ones(1,n),:);
      P(D < A) = Pk(D < A);
   end
   A = min(A,D);
   if negarcs & any(diag(A) < 0)
      error('Network contains a negative cycle');
   end
end

D = A;		% Recycling D to save storage space
if nargout > 1, P = triu(P,1) + tril(P,-1); end