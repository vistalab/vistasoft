function dt = dtCreate(param)
% Create a dataTYPES structure
%
%  dt = dtCreate(param)
%
% We should allow the param to be at least 'block' or 'event' or 'mixed'.
%
% At present, these are not distinguished.  These dataTYPES should be
% distinguished over time. 

global mrSESSION;

if notDefined('param'), param = 'block'; end
dt = [];

switch(lower(param))
    case {'default','block','event','mixed'}            }
      dt = CreateNewDataTypes(mrSESSION);
    otherwise
        error('Unknown param %s\n',param);
end

return;


