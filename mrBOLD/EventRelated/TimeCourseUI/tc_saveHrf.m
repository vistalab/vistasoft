function savePath = tc_saveHrf(tc, hrfName, prompt);
%
% savePath = tc_saveHrf([tc], [hrfName], [prompt]);
%
% From Time Course UI,  save a unqiue hemodynamic response
% function (HRF) which can be used to construct predictor
% functions,  e.g. for General Linear Models.
%
% The idea: When applyinga  GLM,  convolving a pre-determined
% hemodynamic impulse response function (HIRF) with delta
% functions determining event onsets may not always produce
% the best results. You may be looking at a subject or brain
% region where the shape of the response doesn't correspond 
% to the pre-defined functions (see glm_convolveHrf for examples).
% Or,  you may have events that have a long duration,  leading
% to a prolonged response.
% 
% This function allows you to save the mean time course 
% within an ROI to certain conditions as an HRF. The function
% will be saved in the following location
% 
% [subject's anatomy path]/HRFs/[hrfName].mat
%
% This directory will be created if needed. The anatomy path
% is the same place that the vAnatomy file is stored.
%
% if tc is omitted,  gets it from the current figure (assumes
% a TCUI has been started). If hrfName is omitted,  prompts
% user.
%
% if the prompt flag is 1,  the function will plot the HRF and
% ask the user to confirm before saving. Otherwise,  will 
% automatically save. Default is 1.
%
% ras,  06/05.
if ieNotDefined('tc'),       tc = get(gcf, 'UserData');   end
if ieNotDefined('prompt'),   prompt = 1;                 end

if ieNotDefined('hrfName')
    def = {['hrf_' tc.roi.name]};
    hrfName = inputdlg('Name of HRF File:', 'TC Save HRF', 1, def);
    hrfName = hrfName{1};
end

savePath = fullfile(hrfDir, hrfName);

% the HRF is computed at the same time as the design matrix:
params = tc.params;
params.glmHRF = 1; % flag to compute from time course
[ignore nh hrf] = glm_createDesMtx(tc.trials, params, tc.wholeTc, 0);

% also need to save the time window the HRF represents, 
% since this will be needed if using the HRF for sessions
% w/ a different frame period:
tr = tc.params.framePeriod;
timeWindow = tc.params.timeWindow(tc.params.timeWindow>=0);
frameWindow = unique(round(timeWindow ./ tr))';


% have user confirm if selected
if prompt==1
    hold off
    plot(frameWindow,  hrf,  'k',  'LineWidth',  1.5);
    xlabel('Time,   sec')
    ylabel('HRF')
    resp = questdlg('Save this HRF?',  ['HRF: ' hrfName]);
    if ~isequal(resp,  'Yes'),   return;    end
end
        
% also allow user to figure out what session the 
% HRF came from
session = tc.params.sessionCode;

save(savePath,   'hrf',   'timeWindow',   'session',   'tr');

fprintf('Saved HRF in %s.mat.\n',  savePath);

return
