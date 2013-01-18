function params = mrParamsCorAnal(mr);
% Put up a dialog to get params for a coherence analysis.
%
% params = mrParamsCorAnal(mr);
%
% This is an attempt to emulate the style of mrLoadRet end+1.0,
% in which analyses have related GUIs to get params.
% So, corAnal has a corresponding corAnalGUI to get cor anal
% params. This is the equivalent mrVista 2.0 implementation.
% 
% Thought on naming conventions: for other analyses, it might
% be good to also start with mrParams -- mr since the params are
% operating on mr objects, and params, because that is the output
% of this dialog.
%
% Note: an mr struct must be entered, since it's needed for
% the default set of frames (all).
%
% ras, 07/05.

%%%%% default params (if omitted from params struct):
nCycles = 6;   % just a guess that many scans use
noiseBand = 0; % use all available spectral bands for analysis
saveDir = fileparts(mr.path);
detrend = 1;

% put up dialog to get params
dlg(1).fieldName = 'nCycles';
dlg(1).style = 'edit';
dlg(1).string = 'Number of Cycles in Time Series';
dlg(1).value = num2str(nCycles);

dlg(end+1).fieldName = 'detrend';
dlg(end).style = 'checkbox';
dlg(end).string = 'Detrend Time Series?';
dlg(end).value = detrend;  

dlg(end+1).fieldName = 'noiseBand';
dlg(end).style = 'edit';
dlg(end).string = 'Noise Band Option';
dlg(end).value = num2str(noiseBand);    

dlg(end+1).fieldName = 'frames';
dlg(end).style = 'edit';
dlg(end).string = 'Frames to Analyze';
dlg(end).value = sprintf('1:%i',size(mr.data,4));

dlg(end+1).fieldName = 'saveDir';
dlg(end).style = 'edit';
dlg(end).string = 'Save directory';
dlg(end).value = saveDir;        
    
params = generalDialog(dlg,sprintf('Coherence Analysis: %s',mr.name));

% if canceled, exit quietly
if isempty(params), disp('User Aborted corAnal.'); return;   end   

% parse params
params.nCycles = str2num(params.nCycles);
params.noiseBand = str2num(params.noiseBand);
params.frames = str2num(params.frames);

return

