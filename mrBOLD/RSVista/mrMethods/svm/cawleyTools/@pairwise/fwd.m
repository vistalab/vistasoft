function y = fwd(net,x)

% FWD
%
% Compute the output of a multi-class support vector classification network.
%
%    y = fwd(net, x);
%
% where x is a matrix of input patterns, where each column represents a 
% variable and each row represents and observation.

%
% File        : @pairwise/fwd.m
%
% Date        : Wednesday 13th September 2000
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
% History     : 13/09/2000 - v1.00
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

% class with the most votes wins

nc = 0.5 + sqrt(0.25 + 2*size(net.net, 2));

votes = zeros(size(x, 1), nc); 

n = 1;

for i=1:nc

   for j=1:i-1

      y = fwd(net.net(i), x);

      idx = find(y > 0);

      votes(idx, i) = votes(idx, i) + 1; 

      idx = find(y <= 0);

      votes(idx, j) = votes(idx, j) + 1; 

      n = n + 1;

   end

end

y = 2*(votes == repmat(max(votes')', 1, size(votes,2))) - 1;

% bye bye...

