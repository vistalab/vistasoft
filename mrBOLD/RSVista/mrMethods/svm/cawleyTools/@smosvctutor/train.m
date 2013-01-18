function net = train(tutor, x, y, C, kernel, zeta, net)

% TRAIN
%
% Train a support vector classification network, using the sequential minimal
% optimisation algorithm.
%
%    net = train(tutor, x, y, C, kernel, zeta, net);
%
%    where:
%
%       tutor  = tutor object
%       x      = input patterns
%       y      = target data
%       C      = regularisation parameter (optional, defaults to Inf)
%       kernel = kernel function (optional, defaults to a linear kernel)
%       zeta   = pattern weighting factor (optional)
%       net    = svc object (optional)

%
% File        : @svctutor/train.m
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
% History     : 08/07/2000 - v1.00 
%               20/08/2000 - v1.10 added pattern replication factor parameter,
%                                  and defaults etc.
%               12/09/2000 - v1.11 minor improvements to comments and help
%                                  messages
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

if size(y, 2) ~= 1 | ~isreal(y)

   error('y must be a real double precision column vector');

end

if size(y, 1) ~= size(x, 1)

   error('x and y must have the same number of rows');

end

if nargin == 4 & isa(C, 'svc')

   net    = C;
   C      = getC(net);
   kernel = getkernel(net);
   zeta   = getzeta(net);
   alpha  = abs(getw(net));
   bias   = getbias(net);

else

   if nargin < 4

      C = Inf;

   end

   if nargin < 5

      kernel = linear;

   end

   if nargin < 6

      zeta = ones(size(y));

   end

   if nargin < 7

      alpha = zeros(size(y));
      bias  = 0;

   else

      old_C = getC(net);
      alpha = abs(getw(net));
      bias  = getbias(net);

      if C ~= Inf 

         alpha = alpha*C/old_C;
         bias  = bias*C/old_C;

      end

   end

end

net = smosvctrain(tutor, x, y, C, kernel, zeta, alpha, bias);

% bye bye...

