function val = tcGet(tc, property, varargin);
% Get a property from a time course object.
%
% val = tcGet(tc, property, [options]);
%
% tc can be a tc struct (see tc_init) or a handle
% to a timeCourseUI figure. 
%
% Possible values of property are:
%   't':    time points corresponding to the peri-stimulus time courses,
%           in units of seconds relative to event onset, sampled every 
%           MR frame. E.g., if tc.params.timeWindow is -4:10, and the frame
%           period is 2, then t = [-4 -2 0 2 4 6 8 10].
%
%   'meanTcs', [conds]: mean peri-stimulus time courses for the specified
%           conditions. [Defaults to all selected conditions (determined by
%           tc_selectedConds).]
%
%   'selconds': list of selected condition numbers. These are usually
%               toggled by the 'Conditions' menu in the TCUI, but can also
%               be set in tc.params.selConds.
%
%
% Running tcGet without input arguments will return the tc struct
% associated with the 'selected' time course UI. This is the current
% figure, if it is a TCUI; otherwise it will look for other figures which
% are TCUI figures (they have a special tag) and return the most recent
% one, returning empty if no TCUI is found.
% 
%
% ras, 05/2007.
if nargin==0
    %% return tc struct from 'selected' TCUI
    % first, check if the current figure is a TCUI
    tag = get(gcf, 'Tag');
    if isequal(tag, 'TimeCourseUI')
        % it is -- return the tc associated with this figure and return
        val = get(gcf, 'UserData');
        
    else
        % it isn't -- check if there are other TCUI figures
        h = findobj('Tag', 'TimeCourseUI');
        if isempty(h)
            warning('[tcGet]: No Time Course UI figures found.');
            val = [];
        else
            % return the most recently-created figure
            val = get(h(1), 'UserData');
        end
    end

    return
end

%% args check
if notDefined('property')
    error('Need to specify a property.');
end

if ishandle(tc)
    % get struct associated with this figure
    tc = get(tc, 'UserData');
end


%%%%% main property list
switch lower(property)
    case {'t' 'timewindow' 'peristimtimewindow'} % peri-stimulus sample times
        timeWindow = tc.params.timeWindow;
        framePeriod = tc.params.framePeriod;
        t1 = min(timeWindow);  t2 = max(timeWindow);
        f1 = fix(t1 / framePeriod);  f2 = fix(t2 / framePeriod);
        val = [f1:f2] .* framePeriod;
        
    case {'t_all' 'scantime' 'wholetctimewindow'}
        val = [0:length(tc.wholeTc)-1] .* tcGet(tc, 'tr');
        
    case 'meantcs'          % mean peri-stimulus time courses
        if ~isempty(varargin)
            conds = varargin{1};
        else
            conds = tcGet(tc, 'selconds');
        end
        I = find(ismember(tc.trials.condNums, conds));
        val = tc.meanTcs(:,I);
        
    case {'sems' 'meantcs_sem'}           % peri-stimulus time course SEMs
        if ~isempty(varargin)
            conds = varargin{1};
        else
            conds = tcGet(tc, 'selconds');
        end
        I = find(ismember(tc.trials.condNums, conds));
        val = tc.sems(:,I);
        
	case {'bslframes' 'baselineframes'} % peristim frames for baseline period
		t = tcGet(tc, 'timeWindow');
		bslMin = min(tc.params.bslPeriod);
		bslMax = max(tc.params.bslPeriod);
		val = find( t >= bslMin & t <= bslMax );
		
	case {'tcweights' 'peakframes'}		% peristim frames for peak period
		t = tcGet(tc, 'timeWindow');
		peakMin = min(tc.params.peakPeriod);
		peakMax = max(tc.params.peakPeriod);
		val = find( t >= peakMin & t <= peakMax );
		
    case {'selconds' 'selectedconds' 'selectedconditions'}
        val = tc_selectedConds(tc);
        
    case {'tr' 'frameperiod' 'temporalresolution'}
        val = tc.params.framePeriod;
end
        

return
