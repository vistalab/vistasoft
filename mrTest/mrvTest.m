function logfile = mrvTest(logfile, whichTests, extended)
% Run the vistasoft test-suite. This function wraps matlab_xunit's `runtest` 
%
% Inputs
% ---------
%   logfile:    Full path to logfile that will be produced by the test-suite. 
%               The file will be saved in the system tempdir, unless another
%               directory is specified in the file-name. Defaults to a
%               generic file-name with a time-stamp, generated in the pwd.
%
%   whichTests: string specifying which functions to test. Either 'bold',
%               'diffusion', 'anatomy' [default = 'bold']
%
%   extended:   boolean. If true, then run extended tests as well as core
%               tests. Extended tests take more time. [deault = false]
%
%
% Outputs
% -------
% logfile: string
% 
% Examples
%   mrvTest();
%   mrvTest([], 'bold');
%   mrvTest('~/myLogFile.m', 'bold', true);
%
% Dependency: Remote Data Toolbox 
%   https://github.com/isetbio/RemoteDataToolbox/
%
% Jon (c) Copyright Stanford team, mrVista, 2011 

%% Check inputs and paths
if notDefined('logfile')
    logfile = fullfile(tempdir, sprintf('mrvTestLog_%s.txt', ...
        datestr(now, 'yyyy_mm_dd_HH-MM-SS')));
end

if notDefined('whichTests'), whichTests = 'bold'; end
if notDefined('extended'), extended = false; end


%%
curdir = pwd;

%% Get information regarding the software environmnet
env  = mrvGetEvironment();

test_dir = fullfile(mrvTestRootPath, whichTests, 'core'); 

% if extended test requested, we will pass in two dirs in a cell array
if extended
    test_dir1 = test_dir;
    test_dir2 = fullfile(mrvTestRootPath, whichTests, 'extended'); 
    test_dir = {test_dir1, test_dir2};
end

%% Run the tests, return whether or not they passed: 
OK = runtests(test_dir, '-logfile',logfile, '-verbose');

fid = fopen(logfile,'a+');
fprintf(fid, '-----------------------------------------\n');
fprintf(fid, 'Environment information:\n');

f = fieldnames(env);

for ii=1:length(f)
    
    thisfield = env.(f{ii});
    
    % If this field is numeric, we need to convert to a string, or we get
    % a corrupted log file
    if isnumeric(env.(f{ii})), env.(f{ii}) = num2str(env.(f{ii})); end
    
    % If the field is itself a structured array, then we need to loop
    % through the array. For example, <env.matlabVer> is a struct, with one
    % entry for each toolbox on the matlab path.
    if isstruct(thisfield)
        for jj = 1:length(thisfield)
            fprintf(fid, '%s: %s\n', f{ii}, thisfield(jj).Name);
        end
    else
        % If the field is not a struct, write out its name and value.
        fprintf(fid, '%s: %s\n', f{ii}, env.(f{ii}));
    end
end

fclose(fid);

fprintf('Log file written: %s\n', logfile);

cd(curdir)

%%