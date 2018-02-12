function [meanAccuracy model] = svmRun(svm, varargin)
% [meanAccuracy model] = svmRun(svm, varargin)
% SUPPORT VECTOR MACHINE - RUN 
% ---------------------------------------------------------
% Runs classification on a structure initialized by svmInit. 
%
% INPUTS
%   svm - Structure initialized by svmInit.
%	OPTIONS
%       See svmRunOptions (accepts same options).
%
% OUTPUTS
%   meanAccuracy - Mean accuracy of model across iterations.
%   model - Structure containing detailed information about each iteration.
%
% USAGE
%   Run a classification which removes each scan, trains on the remainder,
%   and tests on the excluded scan.  Silence the outputs both from libSVM
%   and from the MATLAB software.
%       svm = svmInit(...);
%       [meanAccuracy model] = svmRun(svm, 'Procedure', 'ScanFolds', ...
%           'Verbose', false, 'Quiet', 1);
%
% See also SVMINIT, SVMEXPORTMAP, SVMBOOTSTRAP, SVMRELABEL, SVMREMOVE,
% SVMRUNOPTIONS, SLINIT.
%
% renobowen@gmail.com [2010]
%
    model = [];
    meanAccuracy = NaN; % try setting this as default?
    if (~exist('svm', 'var'))
        svm = svmInit();
    end

    if (isempty(svm)), return; end
    
    % Set defaults
    options = svmRunOptions(varargin{:});
    
    switch (lower(options.procedure))
        case {'leaveoneout'}
            options.k = size(svm.data, 1);
            if (options.verbose)
                fprintf(1, 'Running k-Folds, k = %02d (Leave One Out)...\n', options.k);
            end
            [model meanAccuracy] = KFoldsCrossValidation(svm, options);
        case {'kfolds'}
            if (options.verbose)
                fprintf(1, 'Running k-Folds, k = %02d...\n', options.k);
            end
            [model meanAccuracy] = KFoldsCrossValidation(svm, options);
        case {'scanfolds'}
            scans = zeros(1, length(svm.run)); scans(svm.run) = 1; scans = find(scans);
            nScans = length(scans);
            nTrials = size(svm.data, 1);
            trials = 1:nTrials;
            options.k = nScans;
            if (options.verbose)
                fprintf(1, 'Running k-Folds, k = %02d (Scan Folds)...\n', options.k);
            end
            nSamples = ones(1, nScans) * (nTrials / nScans);
            [model meanAccuracy] = KFoldsCrossValidation(svm, options, nSamples, trials);
        otherwise
            fprintf(1, 'Unrecognized procedure: ''%s''\n', options.procedure);
            return;
    end
end

function string = CreateOptionsString(options)
    string = '';
    if (~isempty(options.svm_type))
        string = sprintf('%s -s %d', string, options.svm_type);
    end
    if (~isempty(options.kernel_type))
        string = sprintf('%s -t %d', string, options.kernel_type);
    end
    if (~isempty(options.degree))
        string = sprintf('%s -d %d', string, options.degree);
    end
    if (~isempty(options.gamma))
        string = sprintf('%s -g %d', string, options.gamma);
    end
    if (~isempty(options.coef0))
        string = sprintf('%s -r %d', string, options.coef0);
    end
    if (~isempty(options.cost))
        string = sprintf('%s -c %d', string, options.cost);
    end
    if (~isempty(options.nu))
        string = sprintf('%s -n %d', string, options.nu);
    end
    if (~isempty(options.epsilon_loss))
        string = sprintf('%s -p %d', string, options.epsilon_loss);
    end
    if (~isempty(options.cachesize))
        string = sprintf('%s -m %d', string, options.cachesize);
    end
    if (~isempty(options.epsilon))
        string = sprintf('%s -e %d', string, options.epsilon);
    end
    if (~isempty(options.shrinking))
        string = sprintf('%s -h %d', string, options.shrinking);
    end
    if (~isempty(options.probability_estimates))
        string = sprintf('%s -b %d', string, options.probability_estimates);
    end
    if (~isempty(options.weight))
        string = sprintf('%s -w%d %d', string, options.weight(1), options.weight(2));
    end
    if (~isempty(options.quiet))
        string = sprintf('%s -q', string);
    end
end
    
function ParamSelection(svm, options)
    options.verbose = false;
    nLog2c  = length(options.log2cvector);
    nLog2g  = length(options.log2gvector);
    results = zeros(nLog2c, nLog2g);
    [trials nSamples] = GetFolds(size(svm.data, 1), options.k);
    
    iters = nLog2c*nLog2g;
    hwait = mrvWaitbar(0, 'Running parameter selection...');
    for ci = 1:nLog2c
        for gi = 1:nLog2g
            mrvWaitbar((nLog2g * (ci - 1) + gi)/iters, hwait);
            options.cost = 2^options.log2cvector(ci);
            options.gamma = 2^options.log2gvector(gi);
            [model meanAccuracy] = KFoldsCrossValidation(svm, options, nSamples, trials);
            results(ci, gi) = meanAccuracy;
        end
    end
    close(hwait);
    
    if (IsUniform(results))
        fprintf('Uniform accuracy of %g%%.\n', results(1));
        return;
    end
    
    h = figure;
    contourf(results);
    a = get(h, 'CurrentAxes');
    set(a, 'xTickLabel', options.log2gvector);
    xlabel('log2g');
    set(a, 'yTickLabel', options.log2cvector);
    ylabel('log2c');
    colorbar;
end

function bool = IsUniform(matrix)
    matrix = matrix./matrix(1);
    matrix(isnan(matrix)) = 1;
    bool = (sum(sum(matrix)) == numel(matrix));
end

function [shuffledTrials nSamplesPerFold] = GetFolds(nTrials, folds) 
    if (folds < 2 || folds > nTrials)
        shuffledTrials = 0; nSamplesPerFold = 0;
        warning('Invalid # of folds.  # Trials: %02d, # Folds: %02d', nTrials, folds);
        return;
    end
    
    shuffledTrials      = 1:nTrials;
    shuffledTrials      = Shuffle(shuffledTrials);
    
    nSamplesPerFold     = ones(1, folds) * floor(nTrials/folds);
    roundInds           = 1:rem(nTrials, folds);
    nSamplesPerFold(roundInds) = nSamplesPerFold(roundInds) + 1; % include comment to explain this...
end

function [model meanAccuracy] = KFoldsCrossValidation(svm, options, nSamples, trials)
% KFoldsCrossValidation
%	Iterates through all trials in the data set, first removing all groups of
%	that trial, training a model on the remaining data, and then testing the
%	model with the removed data.
%
    nTrials     = size(svm.data,1);
    if (notDefined('nSamples') || notDefined('trials'))
        [trials nSamples] = GetFolds(nTrials, options.k);
        if (trials == 0), model = []; meanAccuracy = []; return; end
    end
    
    optString = CreateOptionsString(options);
    
    accuratePredictions = zeros(nTrials, 1);
    tmpTrials = trials;
	for i = 1:options.k
        foldInds    = tmpTrials(1:nSamples(i));
        tmpTrials   = tmpTrials(nSamples(i)+1:end);
        
		% Get the data and labels corresponding to all trials NOT including the
		% one we're on in the iteration
        trainIndices    = setdiff(trials, foldInds);
        dataTrain       = svm.data(trainIndices, :);
        labelsTrain     = svm.group(trainIndices, :);
        
        % Get the data and labels corresponding ONLY to the trial we're on in the iteration
        dataTest        = svm.data(foldInds, :);
        labelsTest      = svm.group(foldInds, :);
        
        if strcmpi(svm.measure,'t-scores')
            % ****
            % Let's take the mean standard deviation across conditions (i.e. get
            % standard deviation for each condition separately, then get mean value).
            conds = unique(labelsTrain)';
            for c = conds
                inds = labelsTrain==c;
                stdTrain(c,:) = std(dataTrain(inds,:));
            end
            stdMean = mean(stdTrain);
            dataTrain = dataTrain./repmat(stdMean,size(dataTrain,1),1);
            dataTest = dataTest./repmat(stdMean,size(dataTest,1),1);

            %Subtract global mean for every voxel
            globalMean = mean(dataTrain);
            dataTrain = dataTrain-repmat(globalMean,size(dataTrain,1),1);
            dataTest = dataTest-repmat(globalMean,size(dataTest,1),1);
        end
        
        if ~options.subsample
            % Train the model using training set
            [output]        = libsvmtrain(labelsTrain, dataTrain, optString);

            % Predict test set
            [plabels acc decvals] = libsvmpredict(labelsTest, dataTest, output);

            if (options.verbose)
                fprintf('[Fold %02d/%02d, %02d Trial(s)] ', i, options.k, nSamples(i));
                fprintf('Accuracy = %g%% (%d/%d) (classification)\n', ...
                    acc(1), sum(labelsTest == plabels), length(plabels));
            end
        else  % this subsampling doesn't actually work yet
            for randIteration = 1:100
                % Create a random sampling of data
                dataInds = 1:size(dataTrain,2);
                dataInds = Shuffle(dataInds);
                subDataInds = sort(dataInds(1:numSamples));
                subDataTrain = dataTrain(:,subDataInds);
                subDataTest = dataTest(:,subDataInds);
                % Run the classifier on random sampling
                [output{randIteration}]        = libsvmtrain(labelsTrain, subDataTrain, optString);
                [plabels{randIteration} tmpacc decvals{randIteration}] = libsvmpredict(labelsTest, subDataTest, output{randIteration});
                acc(randIteration) = tmpacc(1);
            end
        end
        
		model(i).output				= output;
        model(i).queryLabels        = labelsTest;
		model(i).predictedLabels 	= plabels;
		model(i).accuracy			= acc;
		model(i).decisionValues 	= decvals;
        model(i).options            = options;
        
        accuratePredictions(foldInds) = (plabels == labelsTest);
    end
    meanAccuracy = sum(accuratePredictions)/nTrials * 100;
    
    if (options.verbose)
        fprintf('\nMean Accuracy:  %0.1f percent\n',meanAccuracy);
    end
end
