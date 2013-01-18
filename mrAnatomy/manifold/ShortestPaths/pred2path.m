function p = pred2path(pred,s,t)
%PRED2PATH Convert predecessor indices to shortest path from node 's' to 't'.
%     p = pred2path(pred,s,t)
%  pred = predecessor indices
%       = n-element vector, where pred(s) = 0 
%       = n x n matrix, where P(s,t) is the index of the predecessor to
%         node 't' on the path from node 's' to 't'
%     s = FROM node
%     t = TO node
%     p = path from 's' to 't'
%
% (Used with output of SHORTPATH and ALLSHORTPATH)

% Copyright (c) 1998-1999 by Michael G. Kay
% Matlog Version 1.2 19-Oct-99

% Input Error Checking ******************************************************
error(nargchk(3,3,nargin));

[rpred,n] = size(pred);
if n == 1, n = rpred; rpred = 1; pred = pred'; end

if isempty(pred) | isempty(s) | isempty(t)
   error('Empty input argument');
elseif s < 1 | s > n | round(s) ~= s
   error(['''s'' must be integer between 1 and ',num2str(n)]);
elseif t < 1 | t > n | round(t) ~= t
   error(['''t'' must be integer between 1 and ',num2str(n)]);
elseif s == t
   error('''s'' and ''t'' must be different nodes');
end
% End (Input Error Checking) ************************************************

if rpred > 1, pred = pred(s,:); end
p = t;
while t ~= s
   if t < 1 | t > n | round(t) ~= t
      error('Invalid ''pred'' element found prior to reaching ''s''');
   end
   p = [pred(t) p];
   t = pred(t);
end

