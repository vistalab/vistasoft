function [p params] = glm_getHrfParams(params, select);
%
% subParams = glm_getHrfParams(params, [select=0]);
%
% If you're using a pre-defined HRF for GLM analyses,
% such as 'boynton', 'spm', or 'dale&buckner', return those
% arguments which should be called for those canned function.
% These arguments are kept in a params.glmHRF_params field.
% If this field isn't found, or isn't the right size, ask
% the user to specify these, with appropriate defaults.
% Will also return the params struct with the glmHRF_params field
% set properly.
%
% If the select flag is passed in as 1, will put up a dialog for the 
% user to specify the parameters. Otherwise, will set to reasonable
% defaults.
%
% ras, 01/2007.

% EDIT HISTORY:
% ras, 02/2007 -- added select flag, GUI dialogs.
% DY, 02/20/2007 -- removed checks for number of parameters such that
% whenever select ~=1, the parameters are automatically set to the
% defaults, even if there do appear to be the right number of parameters
% (since odd bugs can result if there are the right number of parameters,
% but the values are off). 
% ras, 02/21/2007 -- Davie, I get your point that there is this possibility;
% however, since this function is used to retrieve stored values, your
% change would cause only the defaults to ever be used (see glm_hrf). It
% may be possible to change the way this function is called, but this would
% require additional logic (since you also need a check that the right
% number of HRF params are specified at HRF creation); and the possibility
% you're concerned about could only occur if you manually muck with the
% parameters -- none of the accessor functions can set the wrong # of
% params. So, I'm reverting for now, and we'll see if we need to do more.

p = [];

if ~exist('select', 'var') | isempty(select), select = 0;   end

% this is only needed for predefined HRF options
if ~ismember(params.glmHRF, [2 3 4]), return; end

% init params field
if ~isfield(params, 'glmHRF_params')
    params.glmHRF_params = [];
end

% get params
switch params.glmHRF
    case 2,     % boynton
        if select==1
            params.glmHRF_params = boyntonHIRF_dialog;
        elseif length(params.glmHRF_params) ~= 3 % wrong size
            % [n tau delta]
            params.glmHRF_params = [3 1.08 2.05];
        end

    case 3,     % spm
        if select==1
            params.glmHRF_params = spmHRF_dialog;
            %	p(1) - delay of response (relative to onset)	   6
            %	p(2) - delay of undershoot (relative to onset)    16
            %	p(3) - dispersion of response			   1
            %	p(4) - dispersion of undershoot			   1
            %	p(5) - ratio of response to undershoot		   6
            %	p(6) - onset (seconds)				   0
            %	p(7) - length of kernel (seconds)		  32
		elseif length(params.glmHRF_params) ~= 6 % wrong size
            maxT = max(params.timeWindow);
            params.glmHRF_params = [6 16 1 1 6 0 maxT];
        end

    case 4,     % dale & buckner
        if select==1
            params.glmHRF_params = daleBucknerHIRF_dialog;
            % [delta tau]
%             params.glmHRF_params = [2.25 1.25]; % more event-friendly
        elseif length(params.glmHRF_params) ~= 2 % wrong size
            params.glmHRF_params = [1.25 2.5]; % vals used in er_runSelxavgBlock (old code)
        end
end

p = params.glmHRF_params;

return
% /----------------------------------------------------------------/ %



% /----------------------------------------------------------------/ %
function p = boyntonHIRF_dialog;
% dialog to set [n tau delta] for boyntonHIRF function.
dlg(1).fieldName = 'eqn';
dlg(1).style = 'text';
dlg(1).string = 'HRF equation:';
dlg(1).value = 'h(t) = [(t/tau) ^ (n-1) * exp(-t/tau)] / [tau(n-1)!]';

dlg(2).fieldName = 'n';
dlg(2).style = 'edit';
dlg(2).string = 'n (integer):';
dlg(2).value = '3';

dlg(3).fieldName = 'tau';
dlg(3).style = 'edit';
dlg(3).string = 'tau (decay), secs:';
dlg(3).value = '1.08';

dlg(4).fieldName = 'delta';
dlg(4).style = 'edit';
dlg(4).string = 'delay (delta), secs:';
dlg(4).value = '2.05';

resp = generalDialog(dlg, 'Boynton HRF');
if isempty(resp)
    error('User canceled.')
end
    
p = [str2num(resp.n) str2num(resp.tau) str2num(resp.delta)];
return
% /----------------------------------------------------------------/ %



% /----------------------------------------------------------------/ %
function p = spmHRF_dialog;
% dialog to set the params for spm_hrf:
%	p(1) - delay of response (relative to onset)	   6
%	p(2) - delay of undershoot (relative to onset)    16
%	p(3) - dispersion of response			   1
%	p(4) - dispersion of undershoot			   1
%	p(5) - ratio of response to undershoot		   6
%	p(6) - onset (seconds)				   0
%	p(7) - length of kernel (seconds)		  32
dlg(1).fieldName = 'responseDelay';
dlg(end).style = 'edit';
dlg(end).string = 'delay of response (relative to onset)';
dlg(end).value = '6';

dlg(end+1).fieldName = 'undershootDelay';
dlg(end).style = 'edit';
dlg(end).string = 'delay of undershoot (relative to onset)';
dlg(end).value = '16';

dlg(end+1).fieldName = 'responseDispersion';
dlg(end).style = 'edit';
dlg(end).string = 'dispersion of response';
dlg(end).value = '1';

dlg(end+1).fieldName = 'undershootDispersion';
dlg(end).style = 'edit';
dlg(end).string = 'dispersion of response';
dlg(end).value = '1';

dlg(end+1).fieldName = 'ratio';
dlg(end).style = 'edit';
dlg(end).string = 'ratio of response to undershoot';
dlg(end).value = '6';

dlg(end+1).fieldName = 'onset';
dlg(end).style = 'edit';
dlg(end).string = 'onset (seconds)';
dlg(end).value = '0';

dlg(end+1).fieldName = 'kernelLength';
dlg(end).style = 'edit';
dlg(end).string = 'length of kernel (seconds)';
dlg(end).value = '32';

resp = generalDialog(dlg, 'SPM HRF');
if isempty(resp)
    error('User canceled.')
end
    
p = [str2num(resp.responseDelay) str2num(resp.undershootDelay) ...
     str2num(resp.responseDispersion) str2num(resp.undershootDispersion) ...
     str2num(resp.ratio) str2num(resp.onset) str2num(resp.kernelLength)];

return
% /----------------------------------------------------------------/ %



% /----------------------------------------------------------------/ %
function p = daleBucknerHIRF_dialog;
% dialog to set [delta tau] for fmri_hemodyn function.
dlg(1).fieldName = 'eqn';
dlg(1).style = 'text';
dlg(1).string = 'HRF equation:';
dlg(1).value = {'h(t>delta)  = ((t-delta)/tau)^2 * exp(-(t-delta)/tau)'; ...
                 'h(t<=delta) = 0;'};

dlg(2).fieldName = 'delta';
dlg(2).style = 'edit';
dlg(2).string = 'delay (delta), secs:';
dlg(2).value = '1.25';

dlg(3).fieldName = 'tau';
dlg(3).style = 'edit';
dlg(3).string = 'tau (decay), secs:';
dlg(3).value = '2.5';


resp = generalDialog(dlg, 'Dale & Buckner HRF');
if isempty(resp)
    error('User canceled.')
end
    
p = [str2num(resp.delta) str2num(resp.tau)];

return

