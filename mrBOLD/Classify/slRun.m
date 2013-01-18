function slRun(searchlight, varargin)
% slRun(searchlight, varargin)
% SEARCHLIGHT - RUN
% ---------------------------------------------------------
% Use to run a searchlight, either as one or several processes.
%
% After a searchlight is completed, several files are often generated that
% require reassembly.  See slComplete for reassembly and parameter map
% generation.
%
% INPUTS
%   searchlight - Structure initialized in SLINIT.
% 	OPTIONS
%       'SpawnWith' - How to run the individual partitions.
%           'Manual' - Print commands to execute.
%           'Grid' - Spawn processes onto SGE.
%       'SLFile' - Path to file containing searchlight structure.
%       'ExportCmds' - When in manual mode, exports text file to subject
%           directory with commands to run.
%
% OUTPUTS
%   N/A
%
% USAGE
%   Setting up a searchlight to be run on a properly configured SGE.
%       searchlight = slInit(...);
%       slRun(searchlight, 'SpawnWith', 'Grid');
%   
%   Try saving the searchlight variable, assuming you've loaded it but want
%   to run it later.
%       save('searchlight.mat', searchlight);
%
%   Use slRun to load it up and print the commands to run portions of the
%   job on your own machine.
%       slRun([], 'SLFile', 'searchlight.mat', 'SpawnWith', 'Manual');
%   
% See also SLINIT, SLCOMPLETE, SLSPAWN, SVMINIT.
%
% renobowen@gmail.com [2010]
%

	spawnWith = 'manual'; % alternatives: 'grid' or 'manual'
    exportCmds = false;
    
    %%
    i = 1;
    while (i <= length(varargin))
        if (isempty(varargin{i})), break; end
        switch (lower(varargin{i}))
            case {'spawnwith'}
                spawnWith = varargin{i + 1};
            case {'slfile'}
                load(varargin{i + 1});
            case {'exportcmds'}
                exportCmds = true;
                i = i - 1;
            otherwise
                fprintf(1, 'Unrecognized option: ''%s''\n', varargin{i});
                return;
        end
        i = i + 2;
    end
    
    if (notDefined('searchlight')), fprintf('No searchlight struct found.\n'); return; end
    
	filename = fullfile(searchlight.path, searchlight.tmpDir);
    save(fullfile(filename, 'struct.mat'), 'searchlight');
    switch (lower(spawnWith))
        case {'grid'}
            [tmp subjName] = fileparts(searchlight.path);
            subjName(subjName == '-') = '_'; % hyphens break sge file loading
            jobName = [searchlight.tmpDir '_' subjName];
            sgerun('slSpawn(searchlight, jobindex, searchlight.processes, searchlight.partitions);', jobName, 1, 1:searchlight.processes);
            
        case {'manual'}
            if (searchlight.processes == 1) % if we only have 1 process, just run it
                slSpawn(searchlight, 1, searchlight.processes, searchlight.partitions);
                return;
            end
            
            % otherwise we write out the commands for the user to run
            fid = 1;

            if (exportCmds)
                fid = fopen([filename '.txt'], 'w');
            end
            
            fprintf(fid, sprintf('load(''%s'');\n', fullfile(filename, 'struct.mat')));
            for i = 1:searchlight.processes
                fprintf(fid, sprintf('slSpawn(searchlight, %d, %d, %d);\n', i, searchlight.processes, searchlight.partitions));
            end
            
            if (exportCmds), fclose(fid); end
               
        otherwise
            fprintf(1, 'Unrecognized spawn method: ''%s''\n', spawnWith);
            return;
    end

end

    
