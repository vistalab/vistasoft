function vw = viewSetTimeSeries(vw,param,val,varargin)
%Organize methods for setting view parameters.
%
% This function is wrapped by viewSet. It should not be called by anything
% else other than viewSet.
%
% This function retrieves information from the view that relates to a
% specific component of the application.
%
% We assume that input comes to us already fixed and does not need to be
% formatted again.

if notDefined('vw'),  error('No view defined.'); end
if notDefined('param'), error('No parameter defined'); end
if notDefined('val'),   val = []; end

mrGlobals;

switch param
    
    case 'tseries'
        vw.tSeries = val;
    case 'tseriesslice'
        vw.tSeriesSlice = val;
    case 'tseriesscan'
        vw.tSeriesScan = val;
        
    otherwise
        error('Unknown view parameter %s.', param);
        
end %switch

return