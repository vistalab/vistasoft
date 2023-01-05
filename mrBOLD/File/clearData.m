function view = clearData(view)
%
% view = clearData(view)
%
%AUTHOR:  Wandell
%DATE:    12.29.00
%PURPOSE: 
%   Clear the data fields in a view
%
% $Author: wade $
% $Date: 2002/09/30 23:43:18 $
global mrSESSION
view.co = []; 
view.ph = []; 
view.amp = [];
view.map = [];
view.mapName = '';
view.tSeries = [];

% we need to clear the rm field as well, otherwise rm-definition can
% transfer (unwantedly) from datatype to datatype.
if isfield(view,'rm')
    view = rmfield(view,'rm');
end
return;
