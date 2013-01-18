function varargout = hidemexfun(obj, varargin)

%
% HIDEMEXMETHOD - simple trick for hiding MEX files implementing methods
%
%    This m-file demonstrates a simple trick for hiding MEX files from the
%    users by transparently compiling the MEX file the first time it is
%    needed.  This is useful for distributing MATLAB packages containing
%    MEX files that might be used on a variety of platforms.
%
%    There are three things you need to do:
%
%       1 - write a mexfile e.g. foo.c
%
%       2 - save a copy of hidemexfun.m in the same directory as foo.c
%
%       3 - rename hidemexfun.m as foo.m
%
%       4 - alter this comment to provide a help message for foo.
%
%       5 - if you need to do something other than 'mex foo.c -lm' to
%           compile foo.c, you need to ammend line ?? appropriately
%
%       6 - invoke foo
%
%   Basically, the first time you invoke foo, the MEX file will not have
%   been compiled yet, so it will be foo.m that is executed.  foo.m then
%   attempts to compile foo.c and if sucessfull it recursively invokes foo.
%   This time, the MEX file has been recompiled, so on a Linux box,
%   foo.mexglx will now be present and MATLAB will invoke that version
%   instead.  The varargs mechanism is used to pass on all input and output
%   arguments to the compiled MEX function.  The rehash command is used to
%   make sure that MATLAB notices that a compiled MEX version has appeared.

%
% File        : hidemexmethod.m
%
% Date        : Monday 16th August 2004
%
% Author      : Gavin C. Cawley
%
% Description : Simple veneer for hiding MEX files from the user by
%               tranparently compiling them the first time they are used.
%               This version is useful for MEX files implementing methods
%               using MATLABs object oriented programming facilities.
%
% History     : 16/08/2004 - v1.00
%
% Copyright   : (c) Dr Gavin C. Cawley, August 2004.
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

% store the current working directory

cwd = pwd;

% find out name of the currently running m-file (i.e. this one!)

name = mfilename;

% find out the name of the class to which it belongs

class_name = class(obj);

% find out what directory it is defined in

dir             = which([name '(' class_name ')']);
dir(dir == '\') = '/';
dir             = dir(1:max(find(dir == '/')-1));

% try changing to that directory

try

   cd(dir);

catch

   % this should never happen, but just in case!

   cd(cwd);

   error(['unable to locate directory containing ''' name '.m''']);

end

% try recompiling the MEX file

try

   mex('smosvctrain.cpp InfCache.cpp LrrCache.cpp SmoTutor.cpp', '-lm');

catch

   % this may well happen happen, get back to current working directory!

   cd(cwd);

   error('unable to compile MEX version of ''%s''%s\n%s%s', ...
          [name '(' class_name ')' ], ...
         ', please make sure your', 'MEX compiler is set up correctly', ...
         ' (try ''mex -setup'').');


end

% change back to the current working directory

cd(cwd);

% refresh the function and file system caches

rehash;

% try to invoke MEX version using the same input and output arguments

[varargout{1:nargout}] = feval(name, obj, varargin{:});

% bye bye...

