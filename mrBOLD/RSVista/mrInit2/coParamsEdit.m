function [p, ok] = coParamsEdit(p)
% Edit coherence analysis ("blocked analysis") parameters.
%
%  [params, ok] = coParamsEdit(params);
%
% Brings up a dialog to set coherence parameters, similar
% to er_editParams for GLM/event-related params.
%
% ras, 07/2007.
if notDefined('p'), p = coParamsDefault;  end

ok = 0;

%% Create dialog

% Stimulus frequency, in num cycles / scan
dlg(1).fieldName = 'nCycles';
dlg(end).style = 'edit';
dlg(end).value = num2str( p.(dlg(end).fieldName) );
dlg(end).string = 'Stimulus frequency cycles/scan?';

% detrend flag: 
%--------------
% -1 linear detrend, 0 no detrend, 1 multiple boxcar smoothing,
% 2 quartic trend removal
dtList = {'Linear Detrend' 'Do Nothing' 'High-Pass Filter' 'Quadratic'};
dlg(end+1).fieldName = 'detrend';
dlg(end).style = 'popup';
dlg(end).list = dtList;
dlg(end).value = p.(dlg(end).fieldName)+2;
dlg(end).string = 'Detrend Option';

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
dlg(end).value = p.(dlg(end).fieldName)+1;
dlg(end).string = 'Inhomogeneity Correction';

% temporal normalization flag: 
dlg(end+1).fieldName = 'temporalNormalization';
dlg(end).style = 'checkbox';
dlg(end).list = {};
dlg(end).value = p.(dlg(end).fieldName);
dlg(end).string = 'Normalize each temporal volume in computing tSeries';

% noise band: 
dlg(end+1).fieldName = 'noiseBand';
dlg(end).style = 'edit';
dlg(end).list = {};
dlg(end).value = num2str( p.(dlg(end).fieldName) );
dlg(end).string = 'Noise Band for Coherence Analysis (0=all frequencies)';


%% Put up dialog, get response
[resp, ok] = generalDialog(dlg, mfilename);
if ~ok, return; end

%% parse response
p.nCycles = str2num(resp.nCycles);
p.detrend = cellfind(dtList, resp.detrend) - 2;
p.inhomoCorrect = cellfind(icList, resp.inhomoCorrect)-1;
p.noiseBand = str2num(resp.noiseBand);

return
