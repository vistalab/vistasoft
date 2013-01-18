function options = svmRunOptions(varargin)
% options = svmRunOptions(varargin)
% SUPPORT VECTOR MACHINE - RUN OPTIONS
% ---------------------------------------------------------
% Produces structure with parameters describing how to perform a
% classification.
%
% INPUTS
%	OPTIONS
%       'Procedure' - 
%           'KFolds' - Split trials into k approximately equal folds,
%               removing each fold one by one, training on the remainder,
%               and testing on the withheld fold.
%           'ScanFolds' - KFolds where the folds are scans/runs.
%           'LeaveOneOut' - KFolds where the folds are individual trials.
%       'Verbose' - Whether or not to print MATLAB generated output.
%           DEFAULT: false
%       'Options' - Pre-existing options structure.
%       'OptionsFile' - Path to file containing pre-existing options
%           structure.
%       'k' - K parameter for KFolds. DEFAULT: 10
%       's' | 'SVM_Type' - See libSVM help.
%       't' | 'Kernel_Type' - See libSVM help.
%       'd' | 'Degree' - See libSVM help.
%       'g' | 'Gamma' - See libSVM help.
%       'r' | 'Coef0' - See libSVM help.
%       'c' | 'Cost' - See libSVM help.
%       'n' | 'Nu' - See libSVM help.
%       'p' | 'Epsilon_Loss' - See libSVM help.
%       'm' | 'CacheSize' - See libSVM help.
%       'e' | 'Epsilon' - See libSVM help.
%       'h' | 'Shrinking' - See libSVM help.
%       'b' | 'Probability_Estimates' - See libSVM help.
%       'w' | 'Weight' - See libSVM help.
%       'q' | 'Quiet' - See libSVM help.
%
% OUTPUTS
%   options - Structure containing all parameters to be used in svmRun, or
%       elsewhere.
%
% USAGE
%   Setting up the parameters to run a classification with KFolds, k = 20.
%   This options structure is then passed to svmRun.
%       options = svmRunOptions('Procedure', 'KFolds', 'k', 20);
%
%   Often, this function is called from within another function, such as
%   svmRun, which will accept the same inputs.
%       svmRun(..., 'Procedure', 'KFolds', 'k', 20);
%
% See also SVMINIT, SVMRUN, SVMEXPORTMAP, SVMBOOTSTRAP, SVMRELABEL,
% SVMREMOVE, SLINIT.
%
% renobowen@gmail.com [2010]
%

    % Lib SVM options
    options.svm_type = [];
    options.kernel_type = 0;
    options.degree = [];
    options.gamma = [];
    options.coef0 = [];
    options.cost = [];
    options.nu = [];
    options.epsilon_loss = [];
    options.cachesize = [];
    options.epsilon = [];
    options.shrinking = [];
    options.probability_estimates = [];
    options.weight = [];
    options.quiet = 1;
    options.subsample = false;
    
    % MATLAB side options
    options.procedure = 'scanfolds';
    options.verbose = false;
    options.k = 10;
    
    i = 1;
    while (i <= length(varargin))
        if (isempty(varargin{i})), break; end
        switch (lower(varargin{i}))
            case {'options'} % careful with this one and the next - we assume you know what you're doing with the options struct
                options = varargin{i + 1};
            case {'optionsfile'}
                load(varargin{i + 1});
            case {'procedure'}
                options.procedure = varargin{i + 1};
            case {'k'}
                options.k = varargin{i + 1};
            case {'log2cvector'}
                options.log2cvector = varargin{i + 1};
            case {'log2gvector'}
                options.log2gvector = varargin{i + 1};
            case {'svm_type' 's'}
                options.svm_type = varargin{i + 1};
            case {'kernel_type' 't'}
                options.kernel_type = varargin{i + 1};
            case {'degree' 'd'}
                options.degree = varargin{i + 1};
            case {'gamma' 'g'}
                options.gamma = varargin{i + 1};
            case {'coef0' 'r'}
                options.coef0 = varargin{i + 1};
            case {'cost' 'c'}
                options.coef = varargin{i + 1};
            case {'nu' 'n'}
                options.nu = varargin{i + 1};
            case {'epsilon_loss' 'p'}
                options.epsilon_loss = varargin{i + 1};
            case {'cachesize' 'm'}
                options.cachesize = varargin{i + 1};
            case {'epsilon' 'e'}
                options.epsilon = varargin{i + 1};
            case {'shrinking' 'h'}
                options.shrinking = varargin{i + 1};
            case {'probability_estimates', 'b'}
                options.probability_estimates = varargin{i + 1};
            case {'weight' 'w'}
                options.weight = [varargin{i + 1} varargin{i + 2}];
                i = i + 1;
            case {'quiet' 'q'} % Silence LIBSVM side outputs
                options.quiet = 1;
                i = i - 1;
            case {'verbose'}
                options.verbose = true;
                i = i - 1;
            case {'silent'} % Silence MATLAB side outputs
                options.verbose = false;
                i = i - 1;
            case {'subsample'}
                subsample = varargin{i+1};
            otherwise
                fprintf(1, 'Unrecognized option: ''%s''\n', varargin{i});
                return;
        end
        i = i + 2;
    end
    
end