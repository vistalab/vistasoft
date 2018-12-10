function dataDir = mrtInstallSampleData(sourceFolder, projectName, ...
    dFolder, forceOverwrite, varargin)
%MRTINSTALLSAMPLEDATA Install sample data set on local path.
%
% Syntax:
%   dataDir = MRTINSTALLSAMPLEDATA(sourceFolder, projectName, ...
%      [dFolder], [forceOverwrite], varargin) 
%
%   Code dependency: Remote Data Toolbox
%      https://github.com/isetbio/RemoteDataToolbox
%
% Description:
%   A data set stored on the remote data client in the vista repository
%   is downloaded to the local computer.
%
%   The data set will be installed in the vistasoft local directory:
%   fullfile(vistaRootPath, 'local')
%
%   Remote projects are assumed to be zip files, and located on a remote host
%   with a directory stucture:
%       repository/vistasoft/vistadata/<sourceFolder>/<projectName>
%
% Inputs
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
%     varargin:         Pairs of parameters, values
%                           'filetype', {'zip' 'dat' 'mat' etc}    
% Outputs
%      datadir:  full path to installed project folder
%
% Example:
%    dataDir = mrtInstallSampleData('functional', 'mrBOLD_01');
%
% See also:
%   MRVTEST

% Examples:
%{
  srcFolder = 'anatomy';
  project = 'anatomyNIFTI';
  dFolder = fullfile(vistaRootPath,'local');
  mrtInstallSampleData('anatomy','anatomyNIFTI',dFolder);

%}
% Check inputs
if notDefined('forceOverwrite'), forceOverwrite = true; end
if notDefined('dFolder'), dFolder = fullfile(vistaRootPath, 'local'); end
if exist('varargin', 'var')
    for ii = 1:2:length(varargin)
        switch varargin{ii}
            case 'filetype', filetype = varargin{ii+1};
            otherwise, error('%s parameter unrecognized.', varargin{ii});
        end
    end
end

% By default, assyme we are downloading a zip file
if notDefined('filetype'), filetype = 'zip'; end

% Make sure there is a decent error message if RdtClient is not found
if exist('RdtClient', 'file')  % ok
else
    error(['The RdtClient function is not on your Matlab path; make' ...
           ' sure that you''ve installed the RemoteDataToolbox:' ...
           ' https://github.com/isetbio/RemoteDataToolbox'])
end

% This creates the object, using the configuration data in the file
% rdt/rdt-config-vistasoft.json
rd = RdtClient('vistasoft');

% Change remote path to requested folder
rd.crp(sprintf('/vistadata/%s', sourceFolder));

% Download the zip file
rd.readArtifact(projectName, 'type',filetype, 'destinationFolder',dFolder);

% Return the directory containing the unzipped data
dataDir = fullfile(dFolder, projectName);

% If the filetype was not a zip file, we are done. Otherwise unzip.
if ~strcmpi(filetype, 'zip'), return; end

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
