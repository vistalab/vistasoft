function net = pairwise(arg)

% PAIRWISE
%
% Construct a pairwise multi-class support vector classification network.
%
% Examples:
%
%    % default constructor (a 0-class pairwise network!)
%
%    net1 = pairwise;
%
%    % copy constructor
%
%    net2 = pairwise(net1);
%
%    % construct pairwise multi-class svc from a vector of two-class networks
%
%    net3 = pairwise(net)

%
% File        : @pairwise/pairwise.m
%
% Date        : Wednesday 13th September 2000
%
% Author      : Dr Gavin C. Cawley
%
% Description : Constructor for a class providing a framework for constructing
%               multi-class support vector classification networks from a set
%               of two-class networks using the pairwise rule.  Part of an
%               object-oriented implementation of Vapnik's Support Vector
%               Machine, as described in [1].
%
% References  : [1] V.N. Vapnik,
%                   "The Nature of Statistical Learning Theory",
%                   Springer-Verlag, New York, ISBN 0-387-94559-8,
%                   1995.
%
% History     : 13/09/2000 - v1.00
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

if nargin == 0
   
   % this is the default constructor
   
   net.net = svc;
   net     = class(net, 'pairwise');
   
elseif nargin == 1

   if isa(arg, 'pairwise');
   
      % this is the copy constructor
   
      net = arg;

   end
   
elseif nargin > 1

   % there are no other constructors
   
   help pairwise

else
   
   net.net = arg;
   net     = class(net, 'pairwise');
   
end

% bye bye...

