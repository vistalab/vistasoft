function dtiInitStandAloneWrapper(json)
% 
%   dtiInitStandAloneWrapper(json)
%
% From a json file (or object) construct a run of dtiInit inside of a docker
% container (e.g., vistalab/dtiinit).
% 
% INPUTS:
%       json - JSON object, file or directory containing a json file in the following format:
%             { 
%                 "input_dir": "/input",
%                 "output_dir": "/output",
%                 "dti_file": "",
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
% USAGE:
%       Note that 'input_dir' and 'output_dir' are required inputs.       
%       Pass a json object, file, or directory with jsonFile to docker,
%       like so:
% 
%       docker run --rm -ti -v `pwd`/input:/input -v `pwd`/output:/output vistalab/dtiinit {"input_dir":"/input", "output_dir": "/output"}
% 
% 
% (C) Vista Lab, Stanford University, 2015 [lmperry]
% 


%% Initial checks

if nargin == 0;
    error('Must supply path to json file or a json struct');
end


%% Parse the JSON file or object

if exist(json,'file')
    J = loadjson(json);
elseif exist ('json','dir')
    jsonFile = mrvFindFile('*.json', json);
    if ~isempty(jsonFile)
        J = loadjson(jsonFile);
    else
        error('No JSON file could be found');
    end
elseif exist('json','var') && ~isempty(json) && ischar(json)
    J = loadjson(json);
else
    error('Could not find nor parse the json file/structure');
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
if err 
    error('One or more required fields were not found or their target does not exist.');
end


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
    disp('Using MNI template for DWI alignment...');
end


%% Initialize diffusion parameters

dwParams            = dtiInitParams;
dwParams.outDir     = J.output_dir;
dwParams.bvecsFile  = J.dwi_file;
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

disp(dwParams);


%% Run dtiInit

dtiInit(J.dwi_file, J.t1_file, dwParams);


%% TODO: REPRODUCIBILITY!


return 