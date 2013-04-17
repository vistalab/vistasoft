function [params ok] = er_editParams(params, dtName, scans)
% A dialog to edit event-related analysis parameters.
%
% params = er_editParams(params, [dtName, scans]);
%
% This routine DOES NOT save or set them; use er_setParams
% to do that.
%
% If the data type name and scan numbers are passed as arguments,
% will amend the dialog title text to clarify which parameters are
% being edited
% 
%
% ras, 09/2005.
% ras, 06/2006: added eventsPerBlock, temporarily commented
% out alpha and glmWhiten params (rarely used) -- they can
% be set at the command line, but this makes the dialog a little
% shorter
% DY, 02/20/2007 - changed eventsPerBlock text to ask for number of TRs
% per block, rather than number of trials
if notDefined('params'),  params = er_defaultParams; end

ok = 0;


%%%%%check that all fields are assigned
def = er_defaultParams;
unassigned = setdiff(fieldnames(def), fieldnames(params));
for f = unassigned(:)'
    params.(f{:}) = def.(f{:});
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set up a dialog:                           %
% each parameter to set will be described    %
% by its control settings                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dlg = struct('fieldName','','style','','list',{},'value','',...
             'string','');

% seconds relative to trial onset to take for each trial
dlg(end+1).fieldName = 'timeWindow';
dlg(end).style = 'edit';
dlg(end).list = {};
dlg(end).value = num2str(params.(dlg(end).fieldName));
dlg(end).string = 'Time Window, in seconds (incl. pre-stimulus onset period):';
       
% period to use as baseline for each event, in seconds
dlg(end+1).fieldName = 'bslPeriod';
dlg(end).style = 'edit';
dlg(end).list = {};
dlg(end).value = num2str(params.(dlg(end).fieldName));
dlg(end).string = 'Baseline Period, in seconds:';

% period to look for peak activation for each event, in seconds
dlg(end+1).fieldName = 'peakPeriod';
dlg(end).style = 'edit';
dlg(end).list = {};
dlg(end).value = num2str(params.(dlg(end).fieldName));
dlg(end).string = 'Peak Period, in seconds:';

% flag to zero baseline or not
dlg(end+1).fieldName = 'normBsl';
dlg(end).style = 'checkbox';
dlg(end).list = {};
dlg(end).value = params.(dlg(end).fieldName);
dlg(end).string ='Normalize all trials during the baseline period';

% % threshold for T-test determination of significant activations
% dlg(end+1).fieldName = 'alpha';  % (TEMP DISABLED)
% dlg(end).style = 'edit'; 
% dlg(end).list = {};
% dlg(end).value = num2str(params.(dlg(end).fieldName));
% dlg(end).string = 'Alpha for significant activation (peak vs baseline):';

% # secs to shift onsets in parfiles, relative to time course
dlg(end+1).fieldName = 'onsetDelta';
dlg(end).style = 'edit';
dlg(end).list = {};
dlg(end).value = num2str(params.(dlg(end).fieldName));
dlg(end).string = 'Shift onsets relative to time course, in seconds:';

% conditions to use for calculating signal-to-noise, HRF
dlg(end+1).fieldName = 'snrConds';
dlg(end).style = 'edit';
dlg(end).list = {};
dlg(end).value = num2str(params.(dlg(end).fieldName));
dlg(end).string = 'Use which conditions for computing SNR / HRF?';

% flag for which hemodynamic impulse response 
% function to use if applying a GLM:
% -------------------------------------------
% 0: deconovolve (selective averaging)
% 1: estimate HRF from mean response to all non-null conditions
% 2: Use Boynton et all 1998 gamma function
% 3: Use SPM difference-of-gammas
% 4: Use HRF from Dale and Buckner, 1997 (very similar to Boynton
%    gamma)
% OR, if flag is a char: name of a saved HRF function
%    (stored in subject/HRFs/, where subject is the subject's
%     anatomy directory, where the vAnatomy is stored)dlg(end+1).fieldName = 'snrConds';
glmList = {'Deconvolve' 'Compute From SNR Conds' 'Boynton Gamma' ...
            'SPM Difference-of-gammas' 'Dale & Buckner 99 HIRF' ...
            'Choose from file...'};
dlg(end+1).fieldName = 'glmHRF';
dlg(end).style = 'popup';
dlg(end).list = glmList;
if ischar(params.glmHRF) % saved
    dlg(end).value = 6;
else
    dlg(end).value = params.glmHRF+1;
end
dlg(end).string = 'HRF to use for GLM?';

% flag to set the HRF params in a separate dialog (if using a canned HRF)
dlg(end+1).fieldName = 'setHRFParams';
dlg(end).style = 'checkbox';
dlg(end).list = {};
dlg(end).value = 0;
dlg(end).string = 'Set params for predefined HRF';

% flag for whether or not to estimate temporally-correlated
% noise in data when applying a GLM, referred to as 'whitening':
% (see Dale and Burock, HBM, 2000): (TEMP DISABLED)
dlg(end+1).fieldName = 'glmWhiten';
dlg(end).style = 'checkbox';
dlg(end).list = {};
dlg(end).value = params.(dlg(end).fieldName);
dlg(end).string = 'Estimate temporally-correlated noise (whiten) in GLMS';

dlg(end+1).fieldName = 'eventsPerBlock';
dlg(end).style = 'edit';
dlg(end).list = {};
dlg(end).value = num2str(params.eventsPerBlock);
dlg(end).string = 'If Block Design, # TRs/Block?';


% flag for amplitude type
ampTypeList = {'difference' 'betas' 'zscore' 'deconvolved'};
ampTypeNames = {'Peak-Bsl Difference' 'GLM Betas' ...
                  'Z Score' 'Deconvolved Amps'};
dlg(end+1).fieldName = 'ampType';
dlg(end).style = 'popup';
dlg(end).list = ampTypeNames;
dlg(end).value = cellfind(ampTypeList, params.ampType);
dlg(end).string = 'Method to Calculate Amplitudes?';

% % temporal normalization flag: 
% dlg(end+1).fieldName = 'temporalNormalization';
% dlg(end).style = 'checkbox';
% dlg(end).list = {};
% dlg(end).value = params.(dlg(end).fieldName);
% dlg(end).string = 'Normalize each temporal volume in computing tSeries';

% Options for how to compensate for distance from the coil, depending
% on the value of inhomoCorrection 
%   0 do nothing
%   1 divide by the mean, independently at each voxel
%   2 divide by null condition
%   3 divide by anything you like, e.g., robust estimate of intensity inhomogeneity
% For inhomoCorrection=3, you must compute the spatial gradient
% (from the Analysis menu) or load a previously computed spatial 
% gradient (from the File/Parameter Map menu).
icList = {'Do nothing' 'Divide each voxel by the mean' ...
           'Divide by the null condition' ...
           'Divide by spatial gradient map'};
dlg(end+1).fieldName = 'inhomoCorrect';
dlg(end).style = 'popup';
dlg(end).list = icList;
dlg(end).value = params.(dlg(end).fieldName)+1;
dlg(end).string = 'Inhomogeneity Correction';

% detrend flag: 
%--------------
% -1 linear detrend, 0 no detrend, 1 multiple boxcar smoothing,
% 2 quartic trend removal
dtList = {'Linear Detrend' 'Do Nothing' 'High-Pass Filter' 'Quadratic'};
dlg(end+1).fieldName = 'detrend';
dlg(end).style = 'popup';
dlg(end).list = dtList;
dlg(end).value = params.(dlg(end).fieldName)+2;
dlg(end).string = 'Detrend Option';

dlg(end+1).fieldName = 'detrendFrames';
dlg(end).style = 'edit';
dlg(end).list = dtList;
dlg(end).value = num2str(params.detrendFrames);
dlg(end).string = 'If High-Pass Filter, Filter Period in Frames?';

% flag to edit condition colors in another dialog
dlg(end+1).fieldName = 'assignCondColors';
dlg(end).style = 'checkbox';
dlg(end).list = {};
dlg(end).value = 0;
dlg(end).string = 'Assign Condition Colors (in another dialog)';

% flag to assign parfiles in another dialog
dlg(end+1).fieldName = 'assignParfiles';
dlg(end).style = 'checkbox';
dlg(end).list = {};
dlg(end).value = 0;
dlg(end).string = 'Assign .par files (in another dialog)';

%%%%%title for dialog
ttl = 'Edit Event-Related Parameters';
if exist('dtName', 'var') & exist('scans', 'var')
    ttl = [ttl sprintf(', %s Scans %s', dtName, num2str(scans))];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% put up the dialog, get response   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
params = generalDialog(dlg, ttl, [.3 .2 .4 .5]);
if isempty(params), return;
else
	ok = 1;
	
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % parse response                    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    params.timeWindow     = str2num(params.timeWindow);
    params.bslPeriod      = str2num(params.bslPeriod);
    params.peakPeriod     = str2num(params.peakPeriod);
    % params.alpha = str2num(params.alpha);
    params.onsetDelta     = str2num(params.onsetDelta);
    params.snrConds       = str2num(params.snrConds);
    params.glmHRF         = cellfind(glmList,params.glmHRF) - 1;
    params.eventsPerBlock = str2num(params.eventsPerBlock);
    params.ampType        = ampTypeList{cellfind(ampTypeNames, params.ampType)};
    params.inhomoCorrect  = cellfind(icList, params.inhomoCorrect) - 1;
    params.detrend        = cellfind(dtList, params.detrend) - 2;
    params.detrendFrames  = str2num(params.detrendFrames);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if user requested, assign parfiles, condition color, HRFs %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if params.setHRFParams==1
    params.glmHRF_params = glm_getHrfParams(params, 1);
end

% TODO: make this work!
if params.assignParfiles==1
    hI = initHiddenInplane;
    hI = er_assignParfilesToScans(hI); 
end

if params.assignCondColors==1
    trials = er_assignColors(er_concatParfiles);
    params.condColors = trials.condColors;
end
params = rmfield(params,'assignCondColors');

if params.glmHRF==5
    % choose from file
    [f p] = myUiGetFile(hrfDir, '*.mat', 'Select a saved HRF File...');
    if f==0 % user canceled
        disp('User canceled -- setting HRF to Boynton Gamma')
        params.glmHRF = 2;
    else
        params.glmHRF = f(1:end-4);
    end
end

return
