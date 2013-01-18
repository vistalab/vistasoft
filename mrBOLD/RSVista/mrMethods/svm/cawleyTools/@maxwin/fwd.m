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
% File        : @maxwin/fwd.m
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

% compute output for each two-class SVC

for i=1:length(net.net)

   y(:,i) = fwd(net.net(i), x);

end

% two-class SVC with the highest output wins

y = 2*(y == repmat(max(y')', 1, size(y,2))) - 1;

% bye bye...

