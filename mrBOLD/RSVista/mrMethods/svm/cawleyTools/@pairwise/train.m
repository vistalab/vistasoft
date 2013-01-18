function net = train(net, tutor, varargin)

% TRAIN
%
% Train a max-win multi-class support vector classifier network using the
% specified tutor to train each component two-class network.  
% 
%    load data/iris x y;
%
%    C      = 100;
%    kernel = rbf(0.5);
%
%    net = train(pairwise, smosvctutor, x, y, C, kernel);

%
% File        : @pairwise/train.m
%
% Date        : Wednesday 13th September 2000
%
% Author      : Dr Gavin C. Cawley
%
% Description : Gateway function used to train a max-win multi-class support
%               vector classifier network using a given tutor.  Part of an
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

x = varargin{1};
y = varargin{2};
n = 1;

if size(y, 2) == 1

   for i=1:max(y)

      for j=1:i-1

         idx = [find(y == i) ; find(y == j)];

         varargin{1} = x(idx, :); 

         varargin{2} = 2*(y(idx) == i) - 1; 

         net.net = [net.net train(svc, tutor, varargin{:})];

         n = n + 1;

      end

   end

else

   for i=1:size(y, 2)

      for j=1:i-1

         idx = [find(y(:,i) > 0) ; find(y(:,j) > 0)];

         varargin{1} = x(idx,:); 

         varargin{2} = y(idx,i); 

         net.net(n) = train(svc, tutor, varargin{:});

         n = n + 1;

      end

   end

end

% bye bye...

