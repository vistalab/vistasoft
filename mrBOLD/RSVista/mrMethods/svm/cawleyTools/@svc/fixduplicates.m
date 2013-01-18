function net = fixduplicates(net, x, y)

% FIXDUPLICATES
%
% Ensure that identical support vector of each class have identical Lagrange
% multipliers.
%
%    net = fixduplicates(net, x, y)
%
% where x and y are the training data.  The strip or compact methods must not
% previously have been applied to this network.

%
% File        : @svc/fixduplicates.m
%
% Date        : Tuesday 12th September 2000
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
% History     : 07/07/2000 - v1.00
%               12/09/2000 - v1.01 minor improvements to comments and help
%                                  message
%               16/09/2000 - v1.10 fixed a bug requiring the training data
%                                  to be provided as parameters
%
% Copyright   : (c) Dr Gavin C. Cawley, September 2000
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

[foo, i, j] = unique(x, 'rows');

for k = unique(j)'

   idx1 = find(j == k);

   idx2 = find(y(idx1) > 0);

   if ~isempty(idx2)
      net.w(idx1(idx2)) = mean(net.w(idx1(idx2)));
   end

   idx2 = find(y(idx1) < 0);

   if ~isempty(idx2)
      net.w(idx1(idx2)) = mean(net.w(idx1(idx2)));
   end

end

% bye bye...

