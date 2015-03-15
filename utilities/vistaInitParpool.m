function vistaInitParpool(cpus)
%
% vistaInitParpool(cpus)
%
%   Initialize a parallel pool using parpool with a given number of cpus
%   [cpus] or use a given mode.
%
%
% BACKGROUND:
%   When parpool is called by itself the default number of workers are
%   chosen from the local profile, however, that has little to do with the
%   power of your machine.
%
%   NOTE: Matlab versions prior to R2014a (8.3) have a limit of 12 workers.
%   For these versions, if you request more than 12 we set it max of 12.
%
%   With this function you can chose a POSITIVE NUMBER (eg. 8 - to include
%   8 cores) of threads or a MODE (eg. performance) or a PERCENTAGE (eg.
%   .25, to use 25% of the cores) or even a NEGATIVE NUMBER of cores (eg.
%   -2, to leave 2 cores out of the pool). This function will query your
%   system to check the number of CPUS and set the value based on that.
%
%   By DEFAULT 'performance' mode is chosen - which uses 80% of resources.
%
%
% INPUT:
%   cpus - The number of CPUS or the MODE you want to run in the pool.
%          
%           [cpus] can be an +/-INT, a DECIMAL, or a STRING:
%           POSITIVE INT - start a parpool with this many cores (eg. 8)
%                          [cpus=0 will use *all* cores]
%           NEGATIVE INT - start a pool with *all but* these cores (eg. -2)
%           DECIMAL - start a parpool with this *percentage* of cores
%           STRING - use this *mode* when starting the pool. 
%             Mode options are:
%             - 'performance' - use 80% of the cores
%             - 'maxperformance' - use all but 2 cores
%             - 'half' - use 50% of all cores
%             - 'all' [or 0]  - use all of the cores (use at your own risk)
%             - 'some' - use 25% of all cores
%
%
% WEB RESOURCES:
%       vistaBrowseGit('vistaInitParpool');
%
%
% EXAMPLE USAGE:
%
%       vistaInitParpool(4);     % Use 4 cores/threads
%
%       vistaInitParpool(-2)     % Use all but 2 cores
%
%       vistaInitParpool(.20)    % Use 20 percent of all cores
%
%       vistaInitParpool('all'); % Use all the cores
%
%       vistaInitParpool(0);     % Use all the cores
%
% SEE ALSO:
%       vistaGetNumCores.m, parpool.m, parcluster.m
%
% (C) Stanford University, VISTA Lab - 2015
%


%% Check for parcluster file

if (exist('parcluster','file') == 2)
    vistapool = parcluster;
else
    fprintf('No cluster environment can be found.')
    return
end


%% Inputs

if nargin == 0 || ~exist('cpus','var') || isempty(cpus)
    disp('Setting mode to ''performance'': 80% of cores will be used.');
    cpus='performance';
end


%% Get number of total CPUS on this machine

total_cpus = vistaGetNumCores;

if isnumeric(cpus) && cpus ~=0

    % Deal with a negative input
    if cpus < 0
        cpus = total_cpus-abs(cpus);
    end
    % Deal with decimal input
    if mod(cpus,1) ~= 0
        cpus = round(cpus*total_cpus);
    end
    % Check that cpus desired is reasonable
    if cpus <= total_cpus
        numcpus = cpus;
    else
        disp('Total number of requested CPUS is more than MAX. Setting to MAX.');
        numcpus = total_cpus;
    end
elseif cpus == 0
    % Set to max
    numcpus = total_cpus;
end

if ischar(cpus)
    switch cpus
        case 'performance'
            numcpus = floor(total_cpus*.8);
        case 'maxperformance'
            numcpus = total_cpus-2;
        case 'half'
            numcpus = total_cpus/2;
        case {'all','rage'}
            numcpus = total_cpus;
        case {'some','nice'}
            numcpus = round(total_cpus*.25);
    end
end


% Check matlab version and warn if numcpus is > allowed by Matlab version
v = version; v = str2double(v(1:3));
if v < 8.3 && numcpus > 12
    warning('You have requested %s workers, however your version of Matlab (%s) has a limit of 12 workers. \n Requesting the limit of 12...',num2str(numcpus),version);
    numcpus = 12;
end


%% Check for a running pool

pool = gcp('nocreate');
startpool = true;

if ~isempty(pool)
    % There is a pool - check workers against numcpus
    if isprop(pool,'NumWorkers') && pool.NumWorkers == numcpus
        disp('A pool has been found with required cpus. Not starting.');
        startpool = false;
    else
        delete(gcp);
        startpool = true;
    end
end


%% Open the pool with the numcpus

vistapool.NumWorkers = numcpus;

if startpool
    try
    parpool(vistapool,vistapool.NumWorkers);
    catch
        fprintf('Could not start pool with %s workers! \n Trying defaults...\n', num2str(numcpus));
        try
            parpool;
            pool = gcp;
            fprintf('Parpool started. \n You asked for %s workers and got %s',num2str(numcpus),num2str(pool.NumWorkers));
        catch
            fprintf('Could not start parpool!');
        end
    end
end

return




