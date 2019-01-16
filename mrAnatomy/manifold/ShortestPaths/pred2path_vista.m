function rte = pred2path(P,s,t)
%PRED2PATH Convert predecessor indices to shortest path from node 's' to 't'.
%     rte = pred2path(P,s,t)
%     P   = predecessor indices
%         = n-element vector, where P(s) = 0 
%         = n x n matrix, where P(s,t) is the index of the predecessor to
%         node 't' on the path from node 's' to 't'
%     s   = FROM node
%     t   = TO node
%     rte = path from 's' to 't'
%
% (Used with output of SHORTPATH and ALLSHORTPATH)

% Copyright (c) 1998-1999 by Michael G. Kay
% Matlog Version 1.2 19-Oct-99

% Input Error Checking ******************************************************
narginchk(3,3);

[rpred,n] = size(P);
if n == 1, n = rpred; rpred = 1; P = P'; end

if isempty(P) | isempty(s) | isempty(t)
   error('Empty input argument');
elseif s < 1 | s > n | round(s) ~= s
   error(['''s'' must be integer between 1 and ',num2str(n)]);
elseif t < 1 | t > n | round(t) ~= t
   error(['''t'' must be integer between 1 and ',num2str(n)]);
elseif s == t
   error('''s'' and ''t'' must be different nodes');
end
% End (Input Error Checking) ************************************************

if rpred > 1, P = P(s,:); end
rte = t;
while t ~= s
   if t < 1 | t > n | round(t) ~= t
      error('Invalid ''P'' element found prior to reaching ''s''');
   end
   rte = [P(t) rte];
   t = P(t);
end

