function [betas,  stdevs,  model] = mrComputeGLM(mr, stim, params);
% Compute a general linear model on 4D (time series) MR objects.
%
% Usage:
% [betas,  var,  model] = mrComputeGLM(mr, stim, [params]);
%
% mr: can be an mr object (see mrFormatDescription,  mrLoad),  a string
% specifying an mr object,  or a cell of such structs/strings. If many
% mr objects are specified,  will concatenate them together. 
%
% stim: can be a stim struct (see stimReadPar),  a string specifying the 
% path to a .par file,  or a cell specifying the path to many parfiles.
%
% params: event-related params (see eventParamsDefault). If omitted,  will
% use default values.
%
% Outputs:
% betas: 4-D mr object of beta weights.
%
% ras,  08/05.
if notDefined('params'),   params = eventParamsDefault; end

%%%%%initialize
% check that we have 4D data
if ndims(mr.data)<4,  error('Only works on 4-D (tSeries) data.'); end

% if parfiles specified,  load 'em into a stim struct
if ischar(stim) | iscell(stim),  stim = stimLoad(stim); end
    
% if mr path specified,  load it
if ischar(mr),  mr = mrLoad(mr); end

% if many mr objects specified,  concatenate them
if iscell(mr), 
    % first,  load any specified paths
    for i = 1:length(mr),  if ischar(mr{i}),  mr{i} = mrLoad(mr{i}); end; end
    
    % now,  concatenate the data
    tmp = mr{1};
    for i = 2:length(mr),  tmp.data = cat(4, tmp.data, mr{i}.data); end
    
    mr = tmp;
end

%%%%%preprocessing
% detrend if selected
if params.detrend==1,  mr = mrDetrend(mr); end

% format the data into 2D (frames x voxels) format
nFrames = mr.dims(4); nVoxels = prod(mr.dims(1:3));
Y = reshape(permute(mr.data, [4 1 2 3]), [nFrames nVoxels]);

%%%%%construct a design matrix
[X nh hrf] = designMatrix(stim, params, mr.data, 0)

%%%%%run the GLM
model = glm(Y, X, tr, nh, params.glmWhiten);

%%%%%grab the betas from the model and create an mr object:
% first,  grab every field except data (save memory)
fields = fieldnames(mr);
fields = setdiff(fields, 'data');
for f = fields(:)',  betas.(f{1}) = mr.(f{1}); end

% assign the data as a 4D volume of voxel dims x predictors
nPredictors = size(X, 2);
betas.data = model.betas; model.betas = []; % save mem
betas.data = permute(betas.data, [3 1 2]);
betas.data = reshape(betas.data, [mr.dims(1:3) nPredictors]);

% set beta-specific fields
betas.dims(4) = nPredictors; % only 3-D
betas.dataUnits = mr.dataUnits;
betas.dirLabels = {mr.dirLabels(1:3) 'Condition'};
betas.name = sprintf('GLM Betas for %s', mr.name);
betas.dataRange = [min(betas.data(:)) max(betas.data(:))];
betas.params = params;


%%%%%grab the stdevs from the model and create an mr object:
% first,  grab every field except data (save memory)
fields = fieldnames(mr);
fields = setdiff(fields, 'data');
for f = fields(:)',  stdevs.(f{1}) = mr.(f{1}); end

% assign the data as a 4D volume of voxel dims x predictors
nPredictors = size(X, 2);
stdevs.data = model.stdevs; model.stdevs = []; % save mem
stdevs.data = permute(stdevs.data, [3 1 2]);
stdevs.data = reshape(stdevs.data, [mr.dims(1:3) nPredictors]);

% set stdev-specific fields
stdevs.dims(4) = nPredictors; % only 3-D
stdevs.dataUnits = mr.dataUnits;
stdevs.dirLabels = {mr.dirLabels(1:3) 'Condition'};
stdevs.name = sprintf('GLM stdevs for %s', mr.name);
stdevs.dataRange = [min(stdevs.data(:)) max(stdevs.data(:))];
stdevs.params = params;

%%%%%finishing up
% format the tSeries back to 4D format
mr.data = reshape(mr.data', mr.dims);

return
