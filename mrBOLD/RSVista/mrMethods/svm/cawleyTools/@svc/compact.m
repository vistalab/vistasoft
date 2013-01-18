function net = compact(net)

% COMPACT
%
% Remove duplicate support vectors, adjusting Lagrange multipliers of
% remaining support vectors to compensate.
%
% net = compact(net);

%
% File        : @svc/compact.m
%
% Date        : Tuesday 12th September 2000
%
% Author      : Dr Gavin C. Cawley
%
% Description : Remove duplicate support vectors, adjusting Lagrange
%               multipliers of remaining support vectors to compensate. 
%               Part of an object-oriented implementation of Vapnik's Support
%               Vector Machine, as described in [1].
%
% References  : [1] V.N. Vapnik,
%                   "The Nature of Statistical Learning Theory",
%                   Springer-Verlag, New York, ISBN 0-387-94559-8,
%                   1995.
%
% History     : 07/07/2000 - v1.00
%               12/09/2000 - v1.01 minor improvements to comments and help
%                                  messages
%               13/09/2000 - v1.10 zeta (pattern replication factors) and C
%                                  fields removed from svc objects
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

[sv, i, j] = unique(net.sv, 'rows');

w = zeros(1, length(i));

for i=1:length(j)

   w(j(i)) = w(j(i)) + net.w(i); 

end

net.sv   = sv;
net.w    = w;

% bye bye...

