function dataDir = mrtInstallSampleData(sourceFolder, projectName)
%MRTINSTALLSAMPLEDATA Install sample data set on local path.
%   dataDir = MRTINSTALLSAMPLEDATA(sourceFolder, projectName) 
%
%   The project will be installed in the vistasoft local directory:
%   fullfile(vistaRootPath, 'local')
%
%   Remote projects are assumed to be zip files, and located on a remote host
%   with a directory stucture:
%       repository/vistasoft/vistadata/<sourceFolder>/<projectName>
%
%    Inputs
%     sourceFolder: name of remote folder in which the project is stored
%                   Examples: 'functional' | 'anatomy' | 'diffusion'
%     projectName:  name of project to download
%                   Examples: 'mrBOLD_01' | 'prfInplane'
%
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

% This creates the object, using the configuration data in the file
% rdt/rdt-config-vistasoft.json
rd = RdtClient('vistasoft');

% Change remote path to requested folder
rd.crp(sprintf('/vistadata/%s/', sourceFolder));

% Download the zip file
dFolder = fullfile(vistaRootPath, 'local');
rd.readArtifact(projectName, 'type','zip', 'destinationFolder',dFolder);

% Unzip
zipfile = fullfile(dFolder, sprintf('%s.zip', projectName));
unzip(zipfile, dFolder);

% Return the directory containing the unzipped data
dataDir = fullfile(dFolder, projectName);

if ~exist(dataDir, 'dir')
    warning('Cannot locate unzipped data directory %s', dataDir)
end

return
