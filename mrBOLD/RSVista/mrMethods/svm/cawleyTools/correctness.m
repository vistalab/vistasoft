function c = correctness(e, zeta)

% CORRECTNESS
%
% This function computes the correctness (i.e. the proportion of patterns
% classified correctly), given a vector, e, where each element represents
% a pattern; a value of 1 indicates an error, a value of 0 represents a
% correct classification.  An optional parameter, zeta, specifies a pattern
% replication factor for each pattern, for example if zeta(42) = 7 this
% implies that the value of e(42) represents the error for 7 similar
% patterns.
%
%    c = correctness(e, zeta)

%
% File        : correctness.m
%
% Date        : Satuday 16th September 2000
%
% Author      : Dr Gavin C. Cawley
%
% Description :
%
% History     : 09/07/2000 - v1.00
%               16/09/2000 - v1.01 minor improvements to comments and help
%                                  message
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

if nargin == 1

   zeta = ones(size(e));

end

c = 1.0 - sum(e.*zeta)/sum(zeta);

% bye bye...

