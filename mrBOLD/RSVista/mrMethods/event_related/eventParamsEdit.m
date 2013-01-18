function params = eventParamsEdit(params);
% GUI to edit/set event-related parameters.
%
% params = eventParamsEdit([params]);
%
% If omitted, params uses the default params in eventParamDefault.
% So, this code can be used to modify existing event-related parameters,
% or get a new set.
%
% ras 08/05.
if notDefined('params'), params = eventParamsDefault; end

% This is going to be complicated, and may be better done in GUIDE.

return