function ker = polynomial(arg)

% POLYNOMIAL
%
% Construct a polynomial kernel object,
%
%    K(x1, x2) = (x1*x2' + 1).^d;
%
% Examples:
%
%    % default constructor (quadratic kernel, d = 2)
%
%    ker1 = polynomial;
%
%    % copy constructor
%
%    ker2 = polnomial(ker1);
%
%    % construct polynomial kernel, d = 0.5
%
%    ker3 = polynomial(5);

%
% File        : @polynomial/polynomial.m
%
% Date        : Tuesday 12th September 2000 
%
% Author      : Dr Gavin C. Cawley
%
% Description : Constructor for a class implementing a polynomial kernel,
%               forming part of a Matlab toolbox implementing Vapnik's
%               Support Vector Machine, as described in [1].
%
% References  : [1] V.N. Vapnik,
%                   "The Nature of Statistical Learning Theory",
%                   Springer-Verlag, New York, ISBN 0-387-94559-8,
%                   1995.
%
% History     : 07/07/2000 - v1.00
%               12/09/2000 - v1.01 minor improvements to comments and help
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

if nargin == 0
   
   % this is the default constructor
   
   ker.d = 2;
   ker   = class(ker, 'polynomial');
   
elseif isa(arg,'polysvm');
   
   % this is the copy constructor
   
   ker = arg;
   
elseif nargin == 1
   
   ker.d = arg;
   ker   = class(ker, 'polynomial');
  
else

   % there are no other constructors

   help polynomial;

end

% bye bye...

