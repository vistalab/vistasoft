function dataDir = mrtInstallSampleData(sourceFolder, projectName, dFolder, forceOverwrite)
%MRTINSTALLSAMPLEDATA Install sample data set on local path.
%   dataDir = MRTINSTALLSAMPLEDATA(sourceFolder, projectName, ...
%      [dFolder], [forceOverwrite]) 
%
%   The project will be installed in the vistasoft local directory:
%   fullfile(vistaRootPath, 'local')
%
%   Remote projects are assumed to be zip files, and located on a remote host
%   with a directory stucture:
%       repository/vistasoft/vistadata/<sourceFolder>/<projectName>
%
%    Inputs
%     sourceFolder:     Name of remote folder where project is stored
%                         Examples: 'functional' | 'anatomy' | 'diffusion'
%     projectName:      Name of project to download
%                         Examples: 'mrBOLD_01' | 'prfInplane'
%     dFolder:          Destination folder 
%                         [default = fullfile(vistaRootPath, 'local')]
%     forceOverwrite:   If true, unzip the project even if project folder
%                           is found. If false, do not unzip if project
%                           folder is found. 
%                          [default = true]
%    Outputs
%      datadir:  full path to installed project folder
%
%   Example:
%      dataDir = mrtInstallSampleData('functional', 'mrBOLD_01');
%
%    Code dependency: Remote Data Toolbox
%                  https://github.com/isetbio/RemoteDataToolbox
%
%    See also: MRVTEST

% Check inputs
if notDefined('forceOverwrite'), forceOverwrite = true; end
if notDefined('dFolder'), dFolder = fullfile(vistaRootPath, 'local'); end

% This creates the object, using the configuration data in the file
% rdt/rdt-config-vistasoft.json
rd = RdtClient('vistasoft');

% Change remote path to requested folder
rd.crp(sprintf('/vistadata/%s/', sourceFolder));

% Download the zip file
rd.readArtifact(projectName, 'type','zip', 'destinationFolder',dFolder);

% Return the directory containing the unzipped data
dataDir = fullfile(dFolder, projectName);

% Unzip 
if exist(dataDir, 'dir') && ~forceOverwrite
    % If the project directory already exists and user has requested NOT to
    % force overwrite, then we do not unzip
    fprintf('Data directory %s already exists. Skipping unzip.\n', dataDir);
else
    zipfile = fullfile(dFolder, sprintf('%s.zip', projectName));
    unzip(zipfile, dFolder);
end

if ~exist(dataDir, 'dir')
    warning('Cannot locate unzipped data directory %s', dataDir)
end

return
