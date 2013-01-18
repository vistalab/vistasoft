function rxNudgeInplanesOntoFunctionals(refScan);
% rxNudgeFunctionalsOntoInplanes([refScan=1]);
%
% This function allows the user to use the mrRx tools to "nudge" functionals
% on to the inplane anatomy. 
%
% PROBLEM: The subject in a session moved between the inplanes and the
% closest functional scan.
%
% SOLUTION: call this function to use the mrRx GUI to align the mean
% functional image of the closest scan ('refScan') onto the inplanes. Then
% press the big blue "Save xformed time series" button, which appears below
% the slice slider in the main control figure.
% 
% ras, 04/2008.
mrGlobals; % declares global mrSESSION variable
if isempty(mrSESSION),		loadSession;				end
if notDefined('refScan'),	refScan = 1;				end

%% get params for mrRx
ipRes = mrSESSION.inplanes.voxelSize;
funcRes = mrSESSION.functionals(refScan).voxelSize;


%% get the functional image
% load the mean map
meanMapFile = fullfile( HOMEDIR, 'Inplane', 'Original', 'meanMap.mat' );
if ~exist(meanMapFile)
	computeMeanMap(initHiddenInplane('Original'), 0, 1);
end	
load(meanMapFile, 'map');
func = map{refScan};

% % contrast-invert the functional image, to sorta match the T1 contrast
% thresh = 0.3 * mean(func(:)); 
% func(func > thresh) = max(func(:)) - func(func > thresh);

%% get the anatomy reference image
load( fullfile(HOMEDIR, 'Inplane', 'anat.mat'), 'anat' )

% resample the inplane anatomy to match the functional resolution
% (may be a better way to do this, but this will work for now)
if ~isequal( size(anat), size(func) )
	for z = 1:size(anat, 3)
		tmp(:,:,z) = imresize(func(:,:,z), [size(anat, 1) size(anat, 2)]);
	end
	func = tmp;
end

%% call mrRx
rx = mrRx(anat, func, 'volRes', ipRes, 'refRes', ipRes, 'rxRes', ipRes);

rx = rxOpenCompareFig(rx);

%% add the extra button to save the results
% callback
cb = 'rxSaveVolume(get(gcf, ''UserData''), pwd, ''1.0anat''); rxClose; ';
uicontrol('Style', 'pushbutton', 'Units', 'normalized', ...
          'Position',[.18 .45 .18 .18], 'String', 'Save Xformed Inplanes', ...
          'BackgroundColor', [.4 1 .8], 'ForegroundColor', 'k', ...
           'Callback', cb);
  


return
