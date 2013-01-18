classdef SVMModel < handle
    properties
        model
        dataObject
        parameters
        predicted_label
        accuracy
        prob_estimates
        isTraining
        isSelected
        % The following are related to PCA - reducing the dimensionality of
        % the data set we're workign with.  I don't know if I should
        % offload them to another object (I feel I should) but I'm going to
        % test their functionality within the model for now.
        pcaCoefs
        pcaVariances
        pcaPercentExplained
        pcaTransform
        pcaTransformParam
    end
    
    properties (Constant)
        UNSELECT = -1;
    end
    
    methods (Access = public)
        %%
        function obj = SVMModel(dataObject)
        % SVMModel(data)
        %   Constructor for SVM Model object.  Takes data object.
        %
        % @param TimeSeriesData data
        % @return SVMModel obj
        %
            if (isa(dataObject,'SVMData'))
                nRows = size(dataObject.data,1);
                obj.dataObject = dataObject;
                obj.isSelected = zeros(nRows,1);
                obj.isTraining = zeros(nRows,1);
            else
                tellUser('Unrecognized data format.');
            end
        end
        
        %%
        function run(obj)
        % run()
        %   Runs SVM Model, creating model parameters and displaying
        %   results of testing.
        %
        % @return void
        %
            labels = obj.dataObject.conditions;
            groupedIndices = (obj.dataObject.groups ~= 0);
            labels(groupedIndices) = ...
                obj.dataObject.groups(groupedIndices);
           
            trainingData = obj.dataObject.data(obj.isTraining == 1 & obj.isSelected == 1, :);
            trainingLabels  = labels(obj.isTraining == 1 & obj.isSelected == 1);
            
            testingData = obj.dataObject.data(obj.isTraining == 0 & obj.isSelected == 1, :);
            testingLabels   = labels(obj.isTraining == 0 & obj.isSelected == 1);
            
            if (~isempty(obj.pcaTransform))
                trainingData = trainingData*obj.pcaTransform;
                testingData = testingData*obj.pcaTransform;
            end
            
            obj.model = libsvm_svmtrain(trainingLabels, trainingData, ...
                obj.getParameters());
            
            [obj.predicted_label, obj.accuracy, obj.prob_estimates] = ...
                svmpredict(testingLabels, testingData, obj.model);
            
            obj.printResults(testingLabels, obj.predicted_label);
        end
        
        %%
        function printResults(obj, actual, predicted)
        % printResults(actual, predicted)
        %   Takes a vector of actual and predicted labels for the SVM
        %   instances, printing out the actual vs the predicted labels into
        %   two columns.
        %
        % @param vector<int> actual
        % @param vector<int> predicted
        % @return void
        %
            labels = [actual'; predicted'];
            fprintf(1, '%10s\t%10s\n', '[ACTUAL]', '[PREDICTED]');
            fprintf(1, '%10s\t%10s\n', obj.dataObject.labels{labels});
        end
        
        %%
        function string = getParameters(obj)
        % string = getParameters()
        %   Returns a string for use as the option argument in the svm
        %   training routine.
        %
        % @return string string
        %
            if (isempty(obj.parameters))
                string = '';
            else
                string = sprintf('%s ', obj.parameters{:});
            end
        end
        
        %%
        function pcaInitialize(obj)
        % pcaInitialize()
        %   [???] Runs the PCA analysis on the selected training set.
        %
        % @return void
        %
            % Get training data and run it through PCA
            [obj.pcaCoefs, scores, obj.pcaVariances] = princomp(obj.dataObject.data(obj.isSelected == 1 & obj.isTraining == 1, :));
            
            % Compute percent explained
            obj.pcaPercentExplained = 100*obj.pcaVariances/sum(obj.pcaVariances);
           
            % Setting an arbitrary default for the number of dimensions
            obj.pcaSetDimensions(5);
        end
        
        function pcaSetDimensions(obj, nDims)
        % pcaSetDimensions(nDims)
        %   [???] Sets number of desired dimensions to reduce to.
        %
        % @param int nDims
        % @return void
        %
            if (nDims >= length(obj.pcaPercentExplained))
                tellUser('You''ve selected as many or more dimensions than you have.');
                return;
            end
            
            explained = sum(obj.pcaPercentExplained(1:nDims));
            
             % Print the result of the cutoff and store the transform
            fprintf(1, '\n %d component(s) selected. %4.2f%% total variance explained.', ...
                nDims, explained);
            obj.pcaTransformParam = {'fixed dimensions', nDims};
            obj.pcaTransform = obj.pcaCoefs(:, 1:nDims);
        end
        
        function pcaSetPercentExplained(obj, cutOff)
        % pcaSetPercentExplained(cutOff)
        %   [???] Sets minimum percent explained tolerable for a component.
        %
        % @param double cutOff
        % @return void
        %
            if (isempty(obj.pcaCoefs))
                tellUser('No PCA has been run.');
                return;
            end

            % Compute number of components
            nComponents = length(obj.pcaPercentExplained);
            
            % Find the index of the last value satisfying cutoff
            lastIndex = [];
            for i = 1:nComponents
                if (obj.pcaPercentExplained(i) < cutOff), lastIndex = i - 1; break; end;
            end
            
            % If it's empty, finished loop without discovering it
            if (isempty(lastIndex))
                tellUser('Cutoff too low.  Nothing falls below this value.');
                return;
            elseif (lastIndex == 0) % If it's 0, didn't get past the first value
                tellUser('Cutoff too high.  Everything falls below this value');
                return;
            end
            
            % Compute the total variance explained
            explained = sum(obj.pcaPercentExplained(1:lastIndex));
            
            % Print the result of the cutoff and store the transform
            fprintf(1, '\n %d component(s) selected. %4.2f%% total variance explained.', ...
                lastIndex, explained);
            obj.pcaTransformParam = {'percent explained cutoff', cutOff};
            obj.pcaTransform = obj.pcaCoefs(:, 1:lastIndex);
        end
        
        function pcaClear(obj)
        % pcaClear()
        %   [???] Clear PCA related parameters.
        %
        % @return void
        %
            % Just a hack of a way to do it for now...
            obj.pcaCoefs = [];
            obj.pcaVariances = [];
            obj.pcaPercentExplained = [];
            obj.pcaTransform = [];
            obj.pcaTransformParam = [];
        end
        
        %%
        function reset(obj, varargin)
        % reset(varargin)
        %   Reset given parameters to defaults.  All inputs are strings
        %   specifying the parameters.  If it's empty, reset all
        %   parameters.
        %
        % @param varargin
        % @return void
        %
            if (isempty(varargin))
            	obj.parameters = [];
            end
            
            for i = 1:length(varargin)
                param = varargin{i};
                opt = obj.inputToOption(param);
                
                if (isempty(opt))
                    continue;
                end
                
                ind = cellfind(strfind(obj.parameters,opt),1);
                if (isempty(ind))
                    tellUser(['Parameter ''' opt ''' already set to default.']); 
                    continue;
                end
                
                obj.parameters(ind) = [];
                obj.parameters = obj.parameters(cellfind(obj.parameters));
            end

        end
        
        %%
        function set(obj, varargin)
        % set(varargin)
        %   Allows setting of model parameters - odd inputs are strings
        %   specifying the parameter while even inputs are ints/doubles
        %   representing the value.
        %
        % @param varargin
        % @return void
        %
            if (isempty(varargin))
                obj.parameterHelp();
            end
            
            for i = 1:2:length(varargin)
                param = varargin{i};
                value = varargin{i + 1};
                opt = obj.inputToOption(param);
                
                if (isempty(opt))
                    continue;
                elseif (sum(ismember(opt,['s' 't'])) ~= 0)
                    if (value < 0 || value > 4)
                        tellUser(['Invalid value for parameter ''' opt '''.']);
                        continue;
                    end
                end

                ind = cellfind(strfind(obj.parameters,opt),1);
                command = {[opt ' ' num2str(value)]};
                if (isempty(ind))
                    obj.parameters = [obj.parameters; command];
                else
                    obj.parameters(ind) = command;
                end
            end
        end
        
        %%
        function select(obj, dataType, condition, trial)
        % select(dataType, condition, trial)
        %   Adds conditions and trials to training or testing matrices.
        %
        % @param string dataType
        % @param vector<int> condition
        % @param vector<int> trial
        % @return void
        %
            isTraining = 1;
            
            if (~exist('dataType','var'))
                isTraining = obj.promptUser('Select data for training (1), testing (0)? ', [1 0]); 
            else
                if (strcmpi(dataType,'testing'))
                    isTraining = 0;
                elseif (~strcmpi(dataType,'training'))
                    tellUser(['Unrecognized data type: ' dataType]);
                    isTraining = obj.promptUser('Use data for training (1) or testing (0)? ', [1 0]);
                end
            end
                
            if (~exist('condition','var') || (~exist('condition','var')))
                if (~exist('condition','var') || isempty(condition))
                    condition = obj.promptUser('Enter condition(s): ', {1:length(obj.dataObject.labels)});
                end

                if (~exist('trial','var') || isempty(trial))
                    trial = obj.promptUser('Enter trial(s): ', {1:max(obj.dataObject.nTrials)});
                end
            end
            
            obj.addInstance(condition, trial, isTraining);
        end
        
        %%
        function remove(obj, condition, trial)
        % remove(condition, trial)
        %   Removes a set of conditions or trials from the testing and
        %   training sets (puts it back into the unselected pool).
        %
        %   Has some repeated code, which I don't much care for.  Might try
        %   to fix this up later (repeats what selectSVM does).
        %
        % @param vector<int> condition
        % @param vector<int> trial
        % @return void
        %
            if (~exist('condition','var') || (~exist('condition','var')))
                if (~exist('condition','var') || isempty(condition))
                    condition = obj.promptUser('Enter condition(s): ', {1:length(obj.dataObject.condLabels)});
                end

                if (~exist('trial','var') || isempty(trial))
                    trial = obj.promptUser('Enter trial(s): ', {1:max(obj.dataObject.nTrials)});
                end
            end
            
            % Perhaps a poor stylistic choice given the name of the
            % function, but it does indeed get the job done.
            obj.addInstance(condition, trial, obj.UNSELECT);
        end
        
        %%
        function list(obj)
        % list()
        %   Lists the training, test, and unselected conditions.
        %
        %   Contains blasphemous repeated code, so I do intend (hope) to
        %   fix this up later.
        %
        % @param string dataType
        % @return void
        %
            conditions = unique(obj.dataObject.conditions(obj.isTraining == 1 & obj.isSelected == 1));
            if (~isempty(conditions))
                fprintf(1,'\n[TRAINING]\n');
                for condition = conditions'
                    fprintf(1,'\t%10s\t][ ', obj.dataObject.labels{condition});
                    fprintf(1,'%d ', obj.dataObject.trials(obj.dataObject.conditions == condition ...
                        & obj.isTraining == 1 & obj.isSelected == 1));
                    fprintf(1,'\n');
                end
            end
            
            conditions = unique(obj.dataObject.conditions(obj.isTraining == 0 & obj.isSelected == 1));
            if (~isempty(conditions))
                fprintf(1,'\n[TESTING]\n');
                for condition = conditions'
                    fprintf(1,'\t%10s\t][ ', obj.dataObject.labels{condition});
                    fprintf(1,'%d ', obj.dataObject.trials(obj.dataObject.conditions == condition ...
                        & obj.isTraining == 0 & obj.isSelected == 1));
                    fprintf(1,'\n');
                end
            end
            
            conditions = unique(obj.dataObject.conditions(obj.isSelected == 0));
            if (~isempty(conditions))
                fprintf(1,'\n[UNSELECTED]\n');
                for condition = conditions'
                    fprintf(1,'\t%10s\t][ ', obj.dataObject.labels{condition});
                    fprintf(1,'%d ', obj.dataObject.trials(obj.dataObject.conditions == condition ...
                        & obj.isSelected == 0));
                    fprintf(1,'\n');
                end
            end
        end
        
    end
    
    methods (Access = private)
        %%
        function addInstance(obj, condition, trial, training)
        % addInstance(condition, trial, training)
        %   Retrieve a set of trials/conditions from the main data store
        %   and place them in a training or testing store.
        %
        % @param vector<int> condition
        % @param vector<int> trial
        % @param bool training
        % @return void
        %
            selectedIndices = ismember(obj.dataObject.trials, trial) ...
                & ismember(obj.dataObject.conditions,condition);
            
            if (training == obj.UNSELECT)
                obj.isSelected(selectedIndices) = 0;
            else
                obj.isTraining(selectedIndices) = training;
                obj.isSelected(selectedIndices) = 1;
            end
        end
        
    end

    methods (Static)
         %%
        function parameterHelp()
            info = {'svm_type',     's',    'Type of SVM.', '0', '\t\t0 (C-SVC)\n\t\t1 (nu-SVC)\n\t\t2 (one-class SVM)\n\t\t3 (epsilon-SVR)\n\t\t4 (nu-SVR)\n'; ...
                    'kernel_type',  't',    'Type of kernel function.', '2', ''; ...
                    'degree',       'd',    'Degree of kernel function.', '3', ''; ...
                    'gamma',        'g',    'Gamma in kernel function.', '1/num_features', ''; ...
                    'coef0',        'r',    'Coef0 in kernel function.', '0', ''; ...
                    'cost',         'c',    'Parameter of C of C-SVC, epsilon-SVR, and nu-SVR.', '1', ''; ...
                    'nu',           'n',    'Parameter nu of nu-SVC, one-class SVM, and nu-SVR.', '.5', ''; ...
                    'epsilon',      'p',    'Epsilon in loss function of epsilon-SVR.', '.1', ''; ...
                    'cachesize',    'm',    'Cache memory size in MB.', '100', ''; ...
                    'tolerance',    'e',    'Tolerance of termination criterion.', '.001', ''; ...
                    'shrinking',    'h',    'Whether to use the shrinking heuristics.', '1', '\t\t0 (False)\n\t\t1 (True)';...
                    'probability',  'b',    'Whether to train a SVC or SVR model for probability estimates.', '0', '\t\t0 (False)\n\t\t1 (True)\n'; ...
                    'weight',       'wi',   'Parameter C of class i to weight*C, for C-SVC.', '1', ''; ...
                    'n-folds',      'v',    'N-fold cross validation mode.', 'N/A', ''; ...
                    };
            fprintf(1, '[LIB-SVM PAREMETERS]\n');
            for i = 1:size(info,1)
                fprintf(1, ['\t%s (%s) %s [Default: %s]\n' info{i,5} '\n'],info{i,1},info{i,2},info{i,3},info{i,4});
            end
        end
        
        %%
        function userResponse = promptUser(userMessage, acceptableInput)
        % userResponse = promptUser(userMessage, acceptableInput)
        %   Prompt user with message and limit acceptable responses.
        %
        %   Usage:
        %       resp = promptUser('Give me 1, 2, or 3: ', [1 2 3]);
        %       resp = promptUser('What is your name? ', 'string');
        %       resp = promptUser('How about a vector?', {1:8});
        %
        % @param string userMessage
        % @param string|vector<int>|cellarray acceptableInput
        % @return string|int|vector<int> userResponse
        %
            while (true)
                try
                    userResponse = input(userMessage);
                catch %#ok<*CTCH>
                    tellUser('Erroneous input: Could not process input.');
                    continue;
                end
                
                if (isa(acceptableInput, 'char'))
                    if (isa(userResponse, 'char'))
                        break;
                    else
                        tellUser('Erroneous input: Please enter a string.');
                    end
                elseif (isa(acceptableInput,'cell'))
                    if (~isa(userResponse, 'char')) && ...
                            (length(intersect(acceptableInput{1}, userResponse)) ...
                            == length(userResponse))
                        break;
                    else
                        tellUser(['Erroneous input: One or more of the ' ...
                            'integers entered was not valid.']);
                    end      
                else
                    if (~isa(userResponse, 'char') && ...
                            (~sum(acceptableInput==userResponse)==0))
                        break;
                    else
                        tellUser('Erroneous input: Please enter a valid integer.');
                    end
                end
            end
        end
        
        %%
        function opt = inputToOption(input)
        % inputToOption(input)
        %   Converts a generic string to a specifically formatted string
        %   for use in setting model parameters.  Returns empty and
        %   displays a message should an invalid input be given.
        %
        % @param string input
        % @return string opt
        %
            switch (lower(input))
                case {'svm_type', 's'}
                    opt = '-s';
                case {'kernel_type', 't'}
                    opt = '-t';
                case {'degree', 'd'}
                    opt = '-d';
                case {'gamma', 'g'}
                    opt = '-g';
                case {'coef0', 'r'}
                    opt = '-r';
                case {'cost', 'c'}
                    opt = '-c';
                case {'nu', 'n'}
                    opt = '-n';
                case {'epsilon', 'p'}
                    opt = '-p';
                case {'cachesize', 'm'}
                    opt = '-m';
                case {'tolerance', 'e'}
                    opt = '-e';
                case {'shrinking', 'h'}
                    opt = '-h';
                case {'probability_estimates', 'probability', 'b'}
                    opt = '-b';
                case {'weight', 'wi'}
                    opt = '-wi';
                case {'n-folds', 'n-fold', 'v'}
                    opt = '-v';
                otherwise
                    opt = [];
                    tellUser(['Cannot set parameter.  No ''' input ''' option.']);
            end
        end
 
    end
end

%%
function tellUser(message)
% tellUser(message)
%   Shorthand to print a message to the user with some convenient
%   line breaks.
%
% @param string message
% @return void
%
    fprintf(1,['\n' message '\n']);
end
