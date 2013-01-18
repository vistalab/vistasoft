function [e, E] = xialpha(net)

% XIALPHA
%
% Evaluate the xi-alpha estimate of the leave-one-out cross-validation 
% error for a support vector machine, net [1].  A vector, e, is returned,
% where the ith element represents the outcome for the ith support vector.
% A value of 1 indicates a leave-one-out error, a value of 0 indicates the
% support vector is correctly classified.  Note that the compact method
% must not previously have been applied to net.
%
%    [e, E] = xialpha(net)
%
% [1] T. Joachims, "Estimating the Generalization Performance
%     of a SVM Efficiently", LS-8 Report 25, Universitat
%     Dortmund, Fachbereich Informatik, 1999.

%
% File        : @svc/xialpha.m
%
% Date        : Saturday 28th September 2000
%
% Author      : Dr Gavin C. Cawley
%
% Description : Part of an object-oriented implementation of Vapnik's Support
%               Vector Machine, as described in [1].  This file provides a
%               method implementing Joachims xi-alpha estimate of the
%               leave-one-out cross-validation error [2].
%
% References  : [1] V.N. Vapnik, "The Nature of Statistical Learning Theory",
%                   Springer-Verlag, New York, ISBN 0-387-94559-8, 1995.
%
%               [2] T. Joachims, "Estimating the Generalization Performance
%                   of a SVM Efficiently", LS-8 Report 25, Universitat
%                   Dortmund, Fachbereich Informatik, 1999.
%
% History     : 08/07/2000 - v1.00 first working version
%               28/07/2000 - v1.10 eliminated the need to provide the training
%                                  data as parameters 
%               28/07/2000 - v1.11 minor changes to help message and comments
%               16/09/2000 - v1.20 efficiency improvements
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

alpha = abs(net.w)';

idx = find(alpha > 1e-12);

% compute xi

xi = 1 - sign(net.w(idx)').*fwd(net, net.sv(idx,:));

xi(find(xi < 0)) = 0.0;

% compute xi-alpha estimate of leave-one-out cross-validation error

E = zeros(size(alpha));
E(idx) = 2.*alpha(idx).*r(net.kernel) + xi;
e = E >= 1;

% bye bye...

