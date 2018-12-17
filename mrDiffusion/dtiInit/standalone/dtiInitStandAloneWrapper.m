function dtiInitStandAloneWrapper(json)
% 
% dtiInitStandAloneWrapper(json)
%
% Read a JSON object, a JSON file, or a directory containing a json file
% and run dtiInit inside of a docker container (vistalab/dtiinit). 
% 
% 
% INPUTS:
%       json - a JSON string, a JSON file, or a directory containing a json
%              file, in the following format (Note that 'input_dir' and
%              'output_dir' are the only REQUIRED inputs)
%
% OUTPUTS: 
%       A docker run produces a zip file containing all of the outputs
%       from the algorithm. The name of the output zip file is:
%           'dtiInit[date-time].zip'
%
%
% JSON SCHEMA:
%       Below is an example JSON file with the defaults show for 'params'.
%       See dtiInitParams.m for more info regarding params. Note that
%       "input_dir" and "output_dir" are required and must be in the
%       context of the container. 
% 
%             { 
%                 "input_dir": "/input",
%                 "output_dir": "/output",
%                 "dwi_file": "",
%                 "bvec_file": "",
%                 "bval_file": "",
%                 "t1_file": "",
%                 "params":  
%                     {
%                         "bvalue": "",
%                         "gradDirsCode": "",
%                         "clobber": 0,
%                         "dt6BaseName": "",
%                         "flipLrApFlag": 0,
%                         "numBootStrapSamples": 500,
%                         "fitMethod": "ls",
%                         "nStep": 50,
%                         "eddyCorrect": 0,
%                         "excludeVols": "",
%                         "bsplineInterpFlag": 0,
%                         "phaseEncodeDir": "",
%                         "dwOutMm": [2, 2, 2],
%                         "rotateBvecsWithRx": 0,
%                         "rotateBvecsWithCanXform": 0,
%                         "bvecsFile": "",
%                         "bvalsFile": "",
%                         "noiseCalcMethod": "b0",
%                         "outDir": "/output/"
%                     }
%             }
% 
% 
% REQUIRED INPUTS:
%       'input_dir' and 'output_dir' are the only required inputs.  
% 
% 
% HELP: 
%       If 'help', '-h', '--help', or nothing (nargin==0), is passed in
%       this help will be displayed.
% 
% 
% USAGE:
%       Pass in a JSON file, a JSON text string, or a path to a directory
%       containing a JSON file to the docker container to initiate a
%       dtiInit processing run (see INPUT section for JSON schema):
% 
%       % Using a JSON file
%        docker run --rm -ti -v `pwd`/input:/input -v `pwd`/output:/output vistalab/dtiinit /input/<JSON_filename>.json
% 
%       % Using a JSON string
%        docker run --rm -ti -v `pwd`/input:/input -v `pwd`/output:/output vistalab/dtiinit '{"input_dir":"/input", "output_dir": "/output"}'
% 
%       % Using a directory (in the container), containing a JSON (.json)
%        docker run --rm -ti -v `pwd`/input:/input -v `pwd`/output:/output vistalab/dtiinit /input/
% 
% 
% 
% (C) Vista Lab, Stanford University, 2015
% 

% TODO:
%   - Reproducibility
%   - Remote download of input files
%   - Json Structure validation
%   - Zip the results.

%% Initial checks

% If nothing was passed in, display help and return
if nargin == 0;
    help_file = '/opt/help.txt';
    if exist(help_file, 'file')
        system(['cat ', help_file]);
    else
        help(mfilename);
    end
    return
end

% Assume the user wanted to see the help, and show it
if ischar(json) 
    if strcmpi(json, 'help') || strcmpi(json, '-help') || strcmpi(json, '-h') || strcmpi(json, '--help')
        help(mfilename);
    end
end


%% Parse the JSON file or object

if exist(json, 'file') == 2
    J = loadjson(json);
elseif exist(json, 'dir') == 7
    jsonFile = dir(fullfile(json, '*.json'));
    jsonFile = fullfile(json, jsonFile.name);
    disp(jsonFile);
    if ~isempty(jsonFile)
        J = loadjson(jsonFile);
    else
        error('No JSON file could be found');
    end
elseif ~isempty(json) && ischar(json)
    try
        J = loadjson(json);
    catch ME
        disp(ME.message); 
        return
    end
else
    error('Could not find/parse the json file/structure');
end


%% Check the json ojbect for required fields

required = {'input_dir', 'output_dir'};
err = false;

for r = 1:numel(required)
    if ~isfield(J, required{r})
        err = true;
        fprintf('%s not found in JSON object!\n', required{r});
    elseif ~exist(J.(required{r}), 'dir')
        fprintf('%s Does not exist!\n', required{r});
        err = true;
    end
end

% If there was a problem, return
if err 
    error('Exiting! There was a problem with the inputs. Please check input_dir and output_dir!');
end

% Create an output subfolder for the outputs 
outputSubFolder = ['dtiInit_', strrep(strrep(datestr(now),' ', '_'),':','-')];
J.output_dir = fullfile(J.output_dir, outputSubFolder);
mkdir(J.output_dir);


%% Get a list of diffusion files from the input directory

dw = getDwiFilesStruct(J.input_dir);
dw = dw{1}; % For this case, limit to the first set found

if ~isfield(J, 'dwi_file') || ~exist(J.dwi_file, 'file')
    J.dwi_file = dw.nifti;
end
if ~isfield(J, 'bvec_file') || ~exist(J.bvec_file, 'file')
    J.bvec_file = dw.bvec;
end
if ~isfield(J, 'bval_file') || ~exist(J.bval_file, 'file')
    J.bval_file = dw.bval;
end


%% T1 File (Paths for templates are container specific)

if ~isfield(J, 't1_file') || ~exist(J.t1_file, 'file')
    template_t1 = '/templates/MNI_EPI.nii.gz'; 
    J.t1_file = template_t1;
end


%% Initialize diffusion parameters

dwParams            = dtiInitParams;
dwParams.outDir     = J.output_dir;
dwParams.bvecsFile  = J.bvec_file;
dwParams.bvalsFile  = J.bval_file;
dwParams.bvalue     = dw.bvalue;


%% Update the diffusion params from the JSON object

if isfield(J, 'params')
    param_names = fieldnames(J.params);
    for f = 1:numel(param_names)
        if isfield(dwParams,param_names{f}) && ~isempty(J.params.(param_names{f}))
            dwParams.(param_names{f}) = J.params.(param_names{f});
        end
    end
else
    disp('Using default dtiInit params')
end

disp(J);
disp(dwParams);


%% Validate the JSON structure against the JSON schema

% fprintf('Validating JSON input against schema... ');
% dtiInitStandAloneValidateJson(J);
% fprintf('Success.\n');


%% Run dtiInit

dtiInit(J.dwi_file, J.t1_file, dwParams);


%% Permissions

fileattrib(J.output_dir,'+w +x', 'o'); 


%% Compress the outputs

fprintf('Compressing output [%s]... ', J.output_dir);
cd(mrvDirup(J.output_dir));
zip([outputSubFolder, '.zip'], J.output_dir);
fprintf('Done.\n');


%% Remove uncompressed output files

rmdir(J.output_dir, 's');


%% TODO: REPRODUCIBILITY!


return 


% Use compile.sh for compiling
% Use this command to launch in matlab
%   dtiInitStandAloneWrapper('/data/localhome/glerma/soft/vistasoft/mrDiffusion/dtiInit/standalone/dtiInit.json')
% Use this command to run the docker in the directory
% 
