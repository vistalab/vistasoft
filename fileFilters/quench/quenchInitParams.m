function param = quenchInitParams(varargin)
% 
% param = quenchInitParams(varargin)
% 
% Initializes the params structure which gets attached to a quench fg. It
% contains information that Quench uses for visualization and for dynamic
% queries. Pulled out of dtiCreateQuenchStats.m 
% 
% PARAMS STRUCTURE:
%       name    -  Name for a fiber summary statistic. Typically this
%                  will be  something like length or "average FA". THis
%                  statistic is used to limit the range of fibers we see in
%                  the Quench window.
%       uid     -  Unique ID [=1] Subtract 1 so Quench starts from 0 (C-counting)
%       ile     -  Is luminance encoding (used by Quench)
%       icpp    -  Is computed per point [default=1] 
%       ivs     -  Is viewable stat (used by Quench)
%       agg     -  Name for fiber summary aggregate statistic (defaults to
%                  param.name
%       lname   -  Local name name for the per point statistic (e.g., TF, 
%                  FA, eccentricity)
%       stat    -  A (1 x nFibers) array of statistical values 
% 
% WEB: 
%       mrvBrowseSVN('quenchInitParams');
% 
% EXAMPLE USAGE:
%       param = quenchInitParams('name','averageFA');
%
% See also:
%       dtiCreateQuenchStats.m , addStatisticHeader.m
%


%% This statistics parameter field gets attached to the fg.  
% It contains information that Quench uses for visualization and for
% dynamic queries. We should probably write a function for initializing
% this parameter field. (see also addStatisticHeader.m)

param       = struct;       % Initialize structure
param.name  = 'nameStat';   % Stat name
param.uid   = 1;            % Subtract 1 so Quench starts from 0 (C-counting)
param.ile   = 1;            % Is luminace encoding
param.icpp  = 1;            % Visualization per point, not per fiber
param.ivs   = 1;            % is_viewable_stat
param.agg   = param.name;   % Stat name
param.lname = 'localStat';  % Local Name
param.stat  = [];

param = mrVarargin( param, varargin );

% If the users only passes in 'name' then set param.agg = param.name since
% they are essentially the same thing. If the user passes in both, or just
% param.agg then leave it be.
if ~isempty(strmatch('name',varargin)) && isempty(strmatch('agg',varargin))
    param.agg = param.name;
end

return

