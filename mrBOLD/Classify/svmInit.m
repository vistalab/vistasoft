function svm = svmInit(varargin)
% svm = svmInit(varargin)
% SUPPORT VECTOR MACHINE - INITIALIZE 
% ---------------------------------------------------------
% Initializes an SVM structure.  Used to classify using svmRun.
%
% INPUTS
%	OPTIONS
%       'Measure' - DEFAULT: 'Betas'
%           'Betas'
%           'PeakBsl'
%           'TimeSeries'
%       'View' - View structure created with initHiddenInplane. DEFAULT:
%           Generated with path and parameters. 
%       'Path' - Path to directory containing valid mrSESSION file.
%           DEFAULT: Prompt user.
%       'ROI' - Name of ROI. DEFAULT: Prompt user.
%       'DataType' - DEFAULT: 'MotionComp'
%           'MotionComp'
%           'Original'
%           ... any other valid mrVista data type
%       'scans' - vector specifying which scans (within DataType) to use.
%           DEFAULT:  use the scan group that has already been set and saved
%           for the mrSESSION
%
% OUTPUTS
%   svm - Structure to be passed to svmRun.
%
% USAGE
%   Setting up a standard SVM, using betas for each voxel with the V1 ROI.
%       svm = svmInit('Path', '/myexperiment/subject1/', 'ROI', 'V1', ...
%           'Measure', 'Betas');
%
%   Let prompts handle input of relevant SVM parameters.
%       svm = svmInit();
%
% See also SVMRUN, SVMEXPORTMAP, SVMBOOTSTRAP, SVMRELABEL, SVMREMOVE,
% SVMRUNOPTIONS, SLINIT.
%
% renobowen@gmail.com [2010]
%

    %% Load/error check parameters
	measure = [];
	view = [];
	path = [];
	roi = [];
    svm = [];
    preserveCoords = 0;
    dataType = 'MotionComp';

	for i = 1:2:length(varargin)
		switch (lower(varargin{i}))
			case {'measure'}
				measure = varargin{i + 1}; 
			case {'view'}
				if (~isempty(path))
					fprintf(1, 'Path already defined. Bad input.\n');
					return;
				end
				view = varargin{i + 1}; 
			case {'path'}
				if (~isempty(view))
					fprintf(1, 'View already defined.  Bad input.\n');
					return;
				end
				path = varargin{i + 1};
			case {'roi'}
				roi = varargin{i + 1};
            case {'datatype'}
                dataType = varargin{i + 1};
            case {'preservecoords'}
                preserveCoords = varargin{i + 1};
            case {'scans'}
                scansToGroup = varargin{i + 1};
			otherwise
				fprintf(1, 'Unrecognized option: ''%s''\n', varargin{i}); 
				return;
		end
    end
    
    % Catch missing view or session path
	if (isempty(view) && isempty(path))
    	[path] = uigetdir('', 'Select Session Path');
        if (~path), return; end
    end

    % Catch missing measure
	if (isempty(measure))
        list = {'Betas', 'Peak - Baseline', 'Full Time Series'};
   		response = listdlg( ...
            'PromptString', 'Select a measure to load:', ...
            'Name', 'Select Measure', ...
            'SelectionMode', 'single', ...
            'ListString', list);
        if (isempty(response)), return; end
		switch (list{response})
            case {'Betas'}
                measure = 'betas';
			case {'Peak - Baseline'}
				measure = 'peakbsl';
			case {'Full Time Series'}
				measure = 'timeseries';
			otherwise
				fprintf(1, 'Unrecognized measure selected.\n');
				svm = [];
				return;
		end
    end

    % If we have a path, load an inplane
	if (~isempty(path))
		currentPath = pwd;
		cd(path);

		try
			view = initHiddenInplane();
		catch
			cd(currentPath);
			fprintf(1, 'Failed to load inplane.');
			return;
		end
    end

    % If we have a view, load an ROI
	if (~isempty(view))
		if (view.selectedROI == 0 || ~isempty(roi))
            [view success] = loadROI(view, roi, 1, [], isempty(roi)); % brings up dialog if roi is empty
            if (~success), return; end
		end
    end
    
    if notDefined('scansToGroup')
        scansToGroup = [];
    end

    %% Retrieve data in SVM friendly format
    view = selectDataType(view, existDataType(dataType));
    
    % Switch scans and regroup scan group if needed
    if ~isempty(scansToGroup)
        view.curScan = scansToGroup(1);
        view = er_groupScans(view,scansToGroup,[],dataType);
        saveSession;
    end
    
	% Use Rory's Multi Voxel UI tools to get data
    mv = mv_init(view, [], [], [], preserveCoords);
    
	switch (lower(measure))
        case {'tscores'} % I do not suggest this... we've abandoned this method but we're leaving the code here
            svm = GetBetas(mv);
            svm.measure = 'T-Scores';  % this will be a flag in svmRun for converting to Tscores for each set of training runs
        case {'betas'}
            svm = GetBetas(mv);
		case {'peakbsl'}
			svm = GetPeakBsl(mv);
		case {'timeseries'}
			svm = GetTimeSeries(mv);
		otherwise	
			svm = [];
			fprintf(1, 'Unrecognized measure: ''%s''\n', measure); 
			return;
    end
    
    mrGlobals;
    svm.selectedROI = view.ROIs(view.selectedROI).name;
    svm.dataType    = dataType;
    svm.sessionPath = HOMEDIR;

end

function svm = GetTScores(mv)
% GetTScores
%	Get t-scores for all voxels within the selected ROI.
%

    % Grab betas
    mv.params.ampType = 'trialbetas';
    tmpVoxData = mv_amps(mv);
    
    indices = mv.trials.cond(mv.trials.cond > 0);
    
    voxData = [];
    for i = mv.trials.condNums(mv.trials.condNums > 0)
        voxData = [voxData permute(tmpVoxData(:, indices == i), [2 3 1])];
    end
    
    % Get SVM formatted struct with basic params
	svm = VoxDataToStruct(mv, voxData);
    
    % Normalize by standard deviation within each voxel
    svm.data = svm.data./repmat((std(svm.data)),size(svm.data,1),1);
    
    svm.measure = 'T-Scores';
	
end

function svm = GetBetas(mv)
% GetBetas
%	Get beta values for all voxels within the selected ROI.
%
    
    % Grab betas
    mv.params.ampType = 'trialbetas';
    tmpVoxData = mv_amps(mv);
    
    indices = mv.trials.cond(mv.trials.cond > 0);
    
    voxData = [];
    for i = mv.trials.condNums(mv.trials.condNums > 0)
        voxData = [voxData permute(tmpVoxData(:, indices == i), [2 3 1])];
    end
    
    % Get SVM formatted struct with basic params
	svm = VoxDataToStruct(mv, voxData);
    
    svm.measure = 'Betas';
	
end

function svm = GetPeakBsl(mv)
% GetPeakBasl
%	Get voxel amplitudes (peak - baseline) for all voxels within the selected
%	ROI.
%
	
	% Grabs only peak - baseline  
	voxData = er_voxAmpsMatrix(mv.voxData, mv.params);

    % Reshape the matrix for compatibility with VoxDataToStruct fxn
	voxData = permute(voxData, [1 3 2]);

	% Get SVM formatted struct with basic params
	svm = VoxDataToStruct(mv, voxData);

	svm.measure = 'Peak - Baseline';

end

function svm = GetTimeSeries(mv)
% GetTimeSeries
%	Get time series measurements for all voxels within the selected ROI.
%

	% Use Rory's Multi Voxel UI tools to get data
    mv = mv_init(view, [], [], [], 0);
	
    % Reshape the matrix for compatibility with VoxDataToStruct fxn
	voxData = permute(mv.voxData, [2 4 3 1]);

	% Get SVM formatted struct with basic params
	svm = VoxDataToStruct(mv, voxData);

	% Generate timepoint field based on the fact we have the same # of
	% timepoints for every trial.  Thus, repmat with the knowledge of how many
	% timepoints we have creates this nicely
	svm.timepoint = repmat(1:size(voxData, 4), 1, size(voxData, 3));

	svm.measure = 'Full Time Series';

end
    
function svm = VoxDataToStruct(mv, voxData)
% VoxDataToStruct
% 	Helper function designed to populate a struct with svm formatted fields.
% 	Requires the data enter in a specific format:
%
% 		size(voxData) = nTrials x nConds x nVoxels x nMeasuresPerVox
%
%	This is useful for handling both len = 17 sets of time series data at each
%	voxel, as well as single measures such as the mean peak - baseline.
%

	voxels 		= size(voxData, 3);
	dataPerVox 	= size(voxData, 4);
	dataTotal 	= voxels * dataPerVox;

	% Remove null data, such as fixation intervals
	svm.grouplabel 	= mv.trials.condNames(mv.trials.condNums > 0);
	nonNullIndices 	= mv.trials.cond > 0;
	mv.trials.cond 	= mv.trials.cond(nonNullIndices);
	mv.trials.run 	= mv.trials.run(nonNullIndices);

	% Allocate space for all of our data
	totalInstances = size(voxData, 1) * size(voxData, 2);
	svm.group   = zeros(totalInstances, 1);
	svm.run		= zeros(totalInstances, 1);
	svm.trial	= zeros(totalInstances, 1);
	svm.data 	= zeros(totalInstances, dataTotal);

	% Generate indices for each voxel, and stretch based on how many
	% data points we have per voxel for good measure
	voxelInds   = 1:voxels;
	voxelInds  	= repmat(voxelInds, dataPerVox, 1);
	voxelInds 	= reshape(voxelInds, 1, dataTotal);

	% Save out indices and coordinates they correspond to
	svm.voxel  = voxelInds;

	% Set coordinates to proper generated indices into inplane
	svm.coordsAnatomy = mv.coordsAnatomy;
    svm.coordsInplane = mv.coordsInplane;

	% For use in propering labeling the conditions
	labelIndices = unique(mv.trials.cond);	

	% Keeps track of the trial # we are on in the iteration
	trialCount 	= ones(1, max(mv.trials.condNums));
	lastRun 	= -1;

	% Things get a little hairy here, so I'll step the comments up.  We walk
	% across every instance, grabbing the relevant information out of voxData
	% and Rory's mv structure.  The result is an svm friendly formatted set of
	% data in a convenient structure.
	for i = 1:length(mv.trials.cond)
		% Use the trial, condition, voxel, and number of data point's we have
		% per voxel to yank out the info from voxData
		relevantSubset 		= reshape(voxData( ...
			trialCount(mv.trials.cond(i)), mv.trials.cond(i), :, :), ... 
			voxels, dataPerVox);

		% Reshape it into one long vector to make it nice and svm friendly
		reshapedSubset 		= reshape(relevantSubset', ...
			1, dataTotal);

		% Insert into data field of structure
		svm.data(i, :) 		= reshapedSubset; 

		% Find out what group/condition the data we grabbed corresponds to
		svm.group(i, 1) 	= find(labelIndices == mv.trials.cond(i));

		% Similarly, find the run
		svm.run(i, 1) 		= mv.trials.run(i);

		% This is to ensure that when we get to a new run in the data, we start
		% over our trial count.  The idea being we have trials WITHIN runs, not
		% trials OVER runs.  So Run 1 might have trials 1, 2, and 3, and 2
		% would have 1, 2, and 3 as well, instead of 4, 5, and 6.
		if (lastRun ~= svm.run(i,1))
			lastRun = svm.run(i,1);
			trialNumber 	= ones(1, max(mv.trials.condNums));
		end
	
		% Save out the trial, and increment the trial counter.
		svm.trial(i, 1) 	= trialNumber(mv.trials.cond(i));
		trialNumber(mv.trials.cond(i)) 	= trialNumber(mv.trials.cond(i)) + 1;
		trialCount(mv.trials.cond(i)) 	= trialCount(mv.trials.cond(i)) + 1;
	end
end	
