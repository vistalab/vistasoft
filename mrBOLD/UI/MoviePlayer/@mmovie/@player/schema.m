function schema
%SCHEMA Schema for PLAYER class
  
%   Copyright 2003 The MathWorks, Inc.
%   $Revision: 1.1 $  $Date: 2005/01/07 18:00:26 $

package = findpackage('mmovie');
thisclass = schema.class(package,'player');

p = schema.prop(thisclass,'hfig','MATLAB array');
p = schema.prop(thisclass,'fcns','MATLAB array');
