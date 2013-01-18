function compilemex(ker)

% COMPILMEX - compile all mex files implementing methods for class @rbf

%
% File        : @rbf/compilmex.m
%
% Date        : Friday 31st January 2003
%
% Author      : Dr Gavin C. Cawley
%
% Description : Compile all mex files implementing methods for class @rbf.
%               Part of an object-oriented implementation of Vapnik's Support
%               Vector Machine, as described in [1].
%
% References  : [1] V.N. Vapnik,
%                   "The Nature of Statistical Learning Theory",
%                   Springer-Verlag, New York, ISBN 0-387-94559-8,
%                   1995.
%
% History     : 31/01/2003 - v1.00
%
% Copyright   : (c) Dr Gavin C. Cawley, January 2003.
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

clear mex;

fprintf(1, 'recompiling method @rbf/evaluate ...\n');

mex -outdir @rbf @rbf/evaluate.c -lm

% bye bye...

