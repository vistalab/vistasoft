function [stat, units] = tc_contrast(tc,active,control,varargin)
%
% [stat, units] = tc_contrast(tc,[active,control,options]);
%
% Compute a statistical contrast between two conditions on
% the given time course. Displays the results in a mrMessage
% window, unless the 'silent' option is entered.
% 
% If the active or control conditions are omitted, a dialog
% pops up.
%
%
% ras, 07/01/05.
if ~exist('tc','var') || isempty(tc), tc = get(gcf,'UserData'); end

%%%%% default params
test = 'tm';
units = 'p';
silent = 0;

if notDefined('active') || notDefined('control')
	% dialog
	condList = tc.trials.condNames; 
	
	ui(1).fieldName = 'active';
	ui(1).style = 'listbox';
	ui(1).list = condList(2:end); % omit null condition
	ui(1).string = 'Active condition(s):';
	ui(1).value = 1; 

	ui(2).fieldName = 'control';
	ui(2).style = 'listbox';
	ui(2).list = condList;	
	ui(2).string = 'Control condition(s):';
	ui(2).value = 1; 

	ui(3).fieldName = 'test';
	ui(3).style = 'popup';
	ui(3).string = 'Test Type?';
	ui(3).list = {'T test' 'F test'};
	ui(3).value = 1; 

	resp = generalDialog(ui, 'Time Course Contrast...'); % , [.2 .6 .15 .15]);
	if isempty(resp), return; end % leave quietly
	[tmp active] = intersect(condList, resp.active);
	[tmp control] = intersect(condList, resp.control); 
	active = active - 1;
	control = control - 1; % null = 0
	tests = {'tm' 'fm'};
	test = tests{cellfind(ui(3).list, resp.test)};

	% check that the conditions are defined
	if all(ismember([active control], tc.trials.condNums))
		ok = 1;
	else
		warndlg(['You sepecified a condition which isn''t defined. '... 
				   ' Please specify again.']);
	end            
end

% parse the options
for i = 1:length(varargin)
    switch lower(varargin{i})
        case 'test', test = varargin{i+1};
        case 'f', test = 'f';
        case 't', test = 't';
        case 'tm', test = 'tm';
        case 'fm', test = 'fm';
        case 'silent', silent = 1;
        case 'units', units = varargin{i+1};
        case 'log10p', units = 'log10p';
        case 'p', units = 'p';
    end
end

% run a glm if one hasn't been run
if ~isfield(tc,'glm')
    disp('Applying GLM to time course data ... ')
    tc = tc_applyGlm(tc);
end

% run contrast
if tc.glm.nh==1
	[stat ces vSig] = glm_contrast(tc.glm, active, control, 'test', test, 'p');
else
	% selective average: we need to add weights for particular points in
	% the time course
	tcWeights = tcGet(tc, 'peakframes');
	[stat ces vSig] = glm_contrast(tc.glm, active, control, 'test', test, ...
								   'tcWeights', tcWeights, 'p');
end
    
% display results if selected
if silent==0
    aa = find(ismember(tc.trials.condNums,active));
    cc = find(ismember(tc.trials.condNums,control));
    namesA = implode(' ',tc.trials.condNames(aa));
    namesC = implode(' ',tc.trials.condNames(cc));
    msg = sprintf('%s > %s Results: \n\n', namesA, namesC);
    msg = [msg sprintf('%s, -log10(p) = %2.2f \n\n',...
                pvalText(abs(stat)), -log10(stat))];
    msg = [msg sprintf('Contrast Effect Size: %2.3f \n\n', ces)];
    msg = [msg sprintf('%s-value: %2.3f \n\n', test(1), vSig)];
    if ces<0
        msg = [msg sprintf('Contrast is NEGATIVE: %s > %s\n', namesC, namesA)];
    end
    figPos = get(tc.ui.fig, 'Position');
    msgPos = [figPos(1)+figPos(3) figPos(2)+figPos(4)-.2 .2 .2];
    mrMessage(msg, 'left', msgPos, 11);
end

return

    
    