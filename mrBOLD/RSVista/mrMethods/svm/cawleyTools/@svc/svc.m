function net = svc(arg, sv, w, bias)

% SVC
%
% Construct a support vector classification (SVC) network object.
%
% Examples:
%
%    % default constructor (linear, hardmargin SVC with no support vectors)
%
%    net1 = svc;
%
%    % copy constructor
%
%    net2 = svc(net1);
%
%    % construct svc
%
%    net3 = svc(ker, sv, w, bias)

%
% File        : @svc/svc.m
%
% Date        : Tuesday 12th September 2000
%
% Author      : Dr Gavin C. Cawley
%
% Description : Part of an object-oriented implementation of Vapnik's Support
%               Vector Machine, as described in [1].  This file implements the
%               constructor for the svm class.
%
% References  : [1] V.N. Vapnik,
%                   "The Nature of Statistical Learning Theory",
%                   Springer-Verlag, New York, ISBN 0-387-94559-8,
%                   1995.
%
% History     : 07/07/2000 - v1.00
%               12/09/2000 - v1.01 minor improvements to comments and help
%                                  message 
%               13/09/2000 - v1.10 removed zeta (pattern replication factor)
%                                  and C fields as these are really to do with
%                                  the training algorithm rather than the net
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
   
   net.kernel = linear;
   net.sv     = [];
   net.w      = [];
   net.bias   = 0;
   net        = class(net, 'svc');
   
elseif nargin == 1

   if isa(arg, 'svc');
   
      % this is the copy constructor
   
      net = arg;

   end
   
elseif nargin > 6

   % there are no other constructors
   
   help svc

else
   
   net.kernel = arg;
   net.sv     = sv;
   net.w      = w;
   net.bias   = bias;
   net        = class(net, 'svc');
   
end

% bye bye...

