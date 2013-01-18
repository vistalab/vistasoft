function params = mrInitGUI_preprocessing(params);
% Set preprocessing options for mrInit2.
%
% params = mrInitGUI_preprocessing(params);
%
%
% ras, 07/2007.

%% set up the dialog
n = 1;
dlg(n).fieldName = 'motionComp';
dlg(n).style	 = 'popup'; 
dlg(n).string	 = 'Motion Compensation?';
dlg(n).list		 = {'none' 'between scans' 'within scans' ...
					'between + within scans'};
dlg(n).value	 = params.motionComp + 1;

n = 2;
dlg(n).fieldName = 'motionCompRefScan';
dlg(n).style	 = 'edit'; 
dlg(n).string	 = 'If Doing Between-Scans Motion Compensation, Ref Scan?';
dlg(n).value	 = num2str(params.motionCompRefScan);

n = 3;
dlg(n).fieldName = 'motionCompRefFrame';
dlg(n).style	 = 'edit'; 
dlg(n).string	 = 'If Doing Between-Scans Motion Compensation, Ref Frame?';
dlg(n).value	 = num2str(params.motionCompRefFrame);

n = 4;
dlg(n).fieldName = 'sliceTimingCorrection';
dlg(n).style	 = 'checkbox'; 
dlg(n).string	 = 'Perform Slice Timing Correction?';
dlg(n).value	 = params.sliceTimingCorrection;

n = 5;
dlg(n).fieldName = 'applyGlm';
dlg(n).style	 = 'checkbox'; 
dlg(n).string	 = 'Apply GLM to each scan group?';
dlg(n).value	 = params.applyGlm;

n = 6;
for i = 1:length(params.annotations)
	annotations{i} = sprintf('%i: %s', i, params.annotations{i});
end
dlg(n).fieldName = 'applyCorAnal';
dlg(n).style	 = 'listbox'; 
dlg(n).string	 = 'Apply Coherence Analysis to which scans?';
dlg(n).list		 = annotations;
dlg(n).value	 = params.applyCorAnal;


%% put up the dialog
[resp ok] = generalDialog(dlg, 'Preprocessing Options', 'center');
if ~ok, return; end

%% parse the response
params.motionComp =cellfind(dlg(1).list, resp.motionComp) - 1;
params.motionCompRefScan = str2num(resp.motionCompRefScan);
params.motionCompRefFrame = str2num(resp.motionCompRefFrame);
params.sliceTimingCorrection = resp.sliceTimingCorrection;
params.applyGlm = resp.applyGlm;
params.applyCorAnal = find( ismember(annotations, resp.applyCorAnal) );

return
