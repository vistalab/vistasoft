function y = fwd(net, x)

% FWD
%
% Compute the output of a dag-svm multi-class support vector classification
% network.
%
%    y = fwd(net, x);
%
% where x is a matrix of input patterns, in which each column represents a 
% variable and each row represents an observation.

%
% File        : @dagsvm/fwd.m
%
% Date        : Friday 15th September 2000
%
% Author      : Dr Gavin C. Cawley
%
% Description : Part of an object-oriented implementation of Vapnik's Support
%               Vector Machine, as described in [1].
%
% References  : [1] V.N. Vapnik,
%                   "The Nature of Statistical Learning Theory",
%                   Springer-Verlag, New York, ISBN 0-387-94559-8,
%                   1995.
%
% History     : 13/09/2000 - v0.01 haven't quite got it worked out yet!
%               15/09/2000 - v1.00 first working version
%
% Copyright   : (c) Dr Gavin C. Cawley, September 2000.
%
%    This program is free software; you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation; either version 2 of the License, or
%    (at your option) any later version.
%
%    This program is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with this program; if not, write to the Free Software
%    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
%

% compute the number of classes

nc = 0.5 + sqrt(0.25 + 2*size(net.net, 2));

% we have not excluded any class at the start

y = ones(size(x,1), nc);

% perform dag-svm algorithm

for i=1:nc-1

   for j=1:i

      % a and b are the two classes involved in the decision made by this node

      a = j + nc - i;
      b = j;

      % n is the index in the vector of SVCs of the approprite classifier

      n = 0.5*(a - 1)*(a - 2) + b;

      % find all patterns for which a and b are viable hypotheses

      idx = unique([find(y(:, a) > 0) ; find(y(:, b) > 0)]);

      % compute output of 2-class SVC for this node

      Y = fwd(net.net(n), x(idx,:));

      % either a of b has been rejected as a hypothesis for each pattern

      y(idx(find(Y >  0)), b) = -1;
      y(idx(find(Y <  0)), a) = -1;

   end

end

% bye bye...

