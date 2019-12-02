function pth = mrtInstallSampleData(sourceFolder, projectName, ...
    dFolder, forceOverwrite, varargin)
%MRTINSTALLSAMPLEDATA Install sample data set on local path.
%
% Syntax:
%   pth = MRTINSTALLSAMPLEDATA(sourceFolder, projectName, ...
%      [dFolder], [forceOverwrite], varargin) 
%
% Description:
%   A data set stored on the OSF website (https://osf.io/xes6n/) and
%   is downloaded to the local computer.
%
%   The data set will be installed in the vistasoft local directory:
%   fullfile(vistaRootPath, 'local')
%
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
%      pth:             Full path to installed project folder or file
%
% Example:
%    pth = mrtInstallSampleData('functional', 'mrBOLD_01');
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

% By default, assume we are downloading a zip file
if notDefined('filetype'), filetype = 'zip'; end

% Find the zip file
pth = fullfile(vistaRootPath, 'local', 'testData', sourceFolder); 
d = dir (fullfile(pth, sprintf('%s*.%s', projectName, filetype)));

% Return the directory containing the unzipped data
pth = fullfile(dFolder, projectName);

% If the filetype was not a zip file, we are done. Otherwise unzip.
if ~strcmpi(filetype, 'zip')
    pth = fullfile(d.folder, d.name);
    return; 
end

% Unzip
if exist(pth, 'dir') && ~forceOverwrite
    % If the project directory already exists and user has requested NOT to
    % force overwrite, then we do not unzip
    fprintf('Data directory %s already exists. Skipping unzip.\n', pth);
else
    zipfile = fullfile(d.folder, d.name);
    unzip(zipfile, dFolder);
end

if ~exist(pth, 'dir')
    warning('Cannot locate unzipped data directory %s', pth)
end

return
