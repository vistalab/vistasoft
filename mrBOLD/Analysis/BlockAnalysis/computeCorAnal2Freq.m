function view = computeCorAnal2Freq(view, scanList, forceSave, freq, nHarm)
% computeCorAnal2Freq - well just as the name says
%
% view = computeCorAnal2Freq(view, [scanList], [forceSave=0], [freq], [nHarm])
%
% Loops throughs scans and slices, loads corresponding tSeries,
% computes correlation analysis from tSeries, and saves the
% resulting co, amp, and ph to the corAnal.mat file.
%
% INPUTS:
%	view: mrVista view.
%	
%	scanList:
%		0 - do all scans
%		number or list of numbers - do only those scans
%		[default - prompt user via selectScans dialog]
%
%	forceSave: flag to automatically save the corAnal files, saving over
%	files with the same name [default: 0]
%
%	freq: vector of 2 frequencies (in cycles per scan) to use when
%	computing the corAnals. [default: dialog]
%
%	nHarm: # of harmonics to ignore. [default: dialog]
%
%
%	Will save the corAnal files in files named ['corAnal_' # 'cps.mat'].
%
% djh, 2/21/2001, updated to mrLoadRet-3.0
% sod    04/2006, ported from script
% ras	 11/2009, made freq and nHarm input arguments
if notDefined('forceSave'),   forceSave = 0;        end

% some variables
global dataTYPES;
nScans   = numScans(view);
dataType = viewGet(view,'curdatatype');


if notDefined('freq') | notDefined('nHarm')
	% first we need to know the number of cycles per scan and how many
	% harmonics to ignore
	prompt ={'Enter the number of cycles for each component:',...
		'Enter the number of harmonics to ignore:'};
	name   ='Frequency parameters';
	numlines = 1;
	defaultanswer = {'5 7','3'};
	answer = inputdlg(prompt,name,numlines,defaultanswer);
	freq   = str2num(answer{1});

	% first one is smallest
	if freq(1)>freq(2), freq([2 1]);end;
	nHarm  = str2num(answer{2});
end

% remove harmonics and other frequencies all relative to
% fundamental frequency
rmFromNoiseBand{1} = unique([[1:nHarm]*freq(1) [0:nHarm]*freq(2)+diff(freq)])*sqrt(-1);
rmFromNoiseBand{2} = unique([[1:nHarm]*freq(2) [0:nHarm]*freq(1)-diff(freq)])*sqrt(-1);

% define which files to save:
% The corAnaldataType files should be loaded up as corAnals the rest as
% Parameter maps. If no corAnal file exists
%corAnalFile  = fullfile(dataDir(view),'corAnal2_freqRatio.mat');
%mapFile_co   = fullfile(dataDir(view),'freqRatio_coherence.mat');
%mapFile_amp  = fullfile(dataDir(view),'freqRatio_amplitude.mat');
%mapFile_cod  = fullfile(dataDir(view),'freqDiff_coherence.mat');
%mapFile_ampd = fullfile(dataDir(view),'freqDiff_amplitude.mat');
corAnalFile{1} = fullfile(dataDir(view),sprintf('corAnal_%dcps.mat',freq(1)));
corAnalFile{2} = fullfile(dataDir(view),sprintf('corAnal_%dcps.mat',freq(2)));



% now loop over frequencies:
for n=1:length(freq),
	% load the corAnal file if it's not already loaded
	%  if exist(corAnalFile{n},'file')
	%    view = loadCorAnal(view);
	%  end
	%  assumes coranal.mat name.

	% If corAnal file doesn't exist, initialize to empty cell array
	if isempty(view.co)
		co = cell(1, nScans);
		amp = cell(1, nScans);
		ph = cell(1, nScans);
	else
		co = view.co;
		amp = view.amp;
		ph = view.ph;
	end

	% (Re-)set scanList
	if ~exist('scanList','var')
		scanList = er_selectScans(view);
	elseif scanList == 0
		scanList = 1:nScans;
	end

	if isempty(scanList)
		error('Analysis aborted');
	end

	disp('Computing corAnal...');
	waitHandle = mrvWaitbar(0,'Computing corAnal matrices from the tSeries.  Please wait...');
	for scanIndex=1:length(scanList)
		scanNum = scanList(scanIndex);
		disp(['Processing scan ', int2str(scanNum),'...']);
		dims = sliceDims(view,scanNum);

		co{scanNum} = NaN*ones(dataSize(view,scanNum));
		amp{scanNum} = NaN*ones(dataSize(view,scanNum));
		ph{scanNum} = NaN*ones(dataSize(view,scanNum));

		% set noise Band
		if isfield(dataTYPES(dataType).blockedAnalysisParams(scanNum),'noiseBand'),
			oldNoiseBand = ...
				dataTYPES(dataType).blockedAnalysisParams(scanNum).noiseBand;
		else,
			oldNoiseBand = 0; % default behaviour
		end;
		dataTYPES(dataType).blockedAnalysisParams(scanNum).noiseBand = rmFromNoiseBand{n};

		for sliceNum = sliceList(view, scanNum)
			[coSeries, ampSeries, phSeries] = ...
				computeCorAnalSeries(view, scanNum, sliceNum, freq(n));
			switch view.viewType
				case 'Inplane'
					co{scanNum}(:,:,sliceNum) = reshape(coSeries, dims);
					amp{scanNum}(:,:,sliceNum) = reshape(ampSeries, dims);
					ph{scanNum}(:,:,sliceNum) = reshape(phSeries, dims);
				case 'Gray'
					co{scanNum} = coSeries;
					amp{scanNum} = ampSeries;
					ph{scanNum} = phSeries;
				case 'Flat'
					co{scanNum}(:,:,sliceNum) = reshape(coSeries, dims);
					amp{scanNum}(:,:,sliceNum) = reshape(ampSeries, dims);
					ph{scanNum}(:,:,sliceNum) = reshape(phSeries, dims);
			end
		end

		% set back noise band
		dataTYPES(dataType).blockedAnalysisParams(scanNum).noiseBand = oldNoiseBand;

		mrvWaitbar(scanIndex/length(scanList), waitHandle);
	end
	close(waitHandle);

	% Set coranal fields in the view
	view.co = co;
	view.amp = amp;
	view.ph = ph;

	% Save results
	save(corAnalFile{n},'co','amp','ph');
end;


return;

