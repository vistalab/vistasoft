function [model, params, ind] = rmMakeCompositeModel(rmFiles, compositeModelFileName, method)
% Combine two or more stored retinotopic models
%  
%  [model, params, ind] = rmMakeCompositeModel(rmFiles, [compositeModelFileName], [method])
%
% Purpose:
%   Take two or more retinotopic models and combine them by using the model
%   parameters from the model with the highest variance explained for each
%   voxel.
%   
%   rmFiles:                paths to retinotopic models (cell array)
%   compositeModelFileName: path to new composite model (string)
%   method:                 'max' or 'mean' [default = 'max']     
%       max:  use solution from the model with highest variance explained 
%       mean: average the models weighted by variance  explained
%
% Notes: 
%   The composite model will inherit information about the analysis
%   (params.analysis) from the first input model. If, for example, you
%   build a composite model from a 3 deg scan and a 14 deg scan, you might
%   want to make the 14 deg scan  the first input. This way, if you
%   subsequently use the composite model as inputs for, say, plotting
%   pRF-centers, the stimulus extent will be defined by the larger scan.
%
%   All the input models must contain the same number of voxels. To
%   ensure that this is the case, you can import all the models to the same
%   mrVista session using the function 'importRetModelFit'  
%
%   output arg 'ind' is the length of the number of voxels, and indexes
%   which input model 'won' each voxel 
%
% Example: 
%   Take one model solved with a 14 deg stimulus, and one model solved with
%   a 3 deg stimulus and make a new composite model. The 3 deg scan should
%   give better fits for the fovea, and the 14 deg scan should give better
%   fits for the periphery. 
% 
%       % Navigate to a vista project directory
%       cd /biac1/wandell/data/Retinotopy/Winawer/20080602-wedgesAndBars3Deg
%       % Open a vista gray view
%       mrVista 3;
%       % Specify the rm files
%       rmFiles{1}  = 'Gray/Averages/imported-retModel-14Deg-jw080713.mat';
%       rmFiles{2}  = 'Gray/Averages/retModel-20080616-180403-sFit.mat';
%       % Give the composite model a name
%       compositeModelFileName = 'Gray/Averages/pRFcompositeModel-max.mat';
%       % Build it
%       model = rmMakeCompositeModel(rmFiles, compositeModelFileName, 'max');

% 1/2009: JW

%---------------------------------
% Var check
%---------------------------------
if notDefined('rmFiles'), error('[%s]: Need rmFiles', mfilename); end
if notDefined('compositeModelFileName'), compositeModelFileName = []; end
if notDefined('method'), method = 'max'; end
vw = getCurView;

%---------------------------------
% Load the input models
%---------------------------------
nModels = length(rmFiles);

for ii = 1:nModels;
    foo = load(rmFiles{ii});
    model{ii}   = foo.model{1}; %#ok<AGROW>
    p{ii}       = foo.params; %#ok<AGROW>
end

%---------------------------------
% Compare them
%---------------------------------

% count the number of voxels
nVoxels = length(model{1}.x0);
var = zeros(nModels, nVoxels);

% get the variance explained for each model
for ii = 1:nModels;
    var(ii, :)  = rmGet(model{ii}, 'varexplained');
end

% sort voxels by var explained in each model
[B, ind] = sort(var);

% the last row of 'ind' tells us which model has most var explained
ind = ind(end,:);

%---------------------------------
% Define the composite model params
%---------------------------------
params.stim = [];
for ii = 1:nModels;
    % make sure that the stimulus fields of each model are the same
    stim = rmCreateStim(vw,p{ii}.stim);
    
    % then concatenate them for the combined model
    params.stim = [params.stim stim];
    
end

% by default take analysis parameters & wData from the first input model
params.analysis =   p{1}.analysis; 
params.wData =      p{1}.wData;      


if notDefined('compositeModelFileName'),
    params.matFileName{1} = [pwd filesep 'retModelComposite.mat'];
    params.matFileName{2} = 'retModelComposite.mat';
else
    params.matFileName{1} = compositeModelFileName;
    [d n e] = fileparts(compositeModelFileName);
    params.matFileName{2} = [n e];
end


%---------------------------------
% Assign values to composite value
%---------------------------------

% give it a description and store the paths that contributed to the model
M.description = 'composite model made from ';
for ii = 1:nModels;
    M.description = [M.description model{ii}.description];
    M.subModels{ii} = rmFiles{ii};
end

% preallocate all fields for the new composite model
M.x0          = zeros(1, nVoxels);
M.y0          = zeros(1, nVoxels);
M.sigma.major = zeros(1, nVoxels);
M.sigma.minor = zeros(1, nVoxels);
M.sigma.theta = zeros(1, nVoxels);
M.rawrss      = zeros(1, nVoxels);
M.rss         = zeros(1, nVoxels);
M.beta        = zeros(1, nVoxels);

% save the indices telling us which model contributed to each voxel
M.compositeIndices = ind; 

% Assign model values from the model with the most variance explained 
switch lower(method)

    case 'max'
        
        for ii = 1:nModels
            v = ind == ii;
            
            M.x0(v)          = model{ii}.x0(v);
            M.y0(v)          = model{ii}.y0(v);
            M.sigma.major(v) = model{ii}.sigma.major(v);
            M.sigma.minor(v) = model{ii}.sigma.minor(v);
            M.sigma.theta(v) = model{ii}.sigma.theta(v);
            M.rawrss(v)      = model{ii}.rawrss(v);
            M.rss(v)         = model{ii}.rss(v);
            M.beta(v)        = model{ii}.beta(v);            
        end
        
    case {'mean', 'average'}
        
        varn = var ./ (ones(size(var, 1), 1) * sum(var));
        
        for ii = 1:nModels
            M.x0          = M.x0           + model{ii}.x0          .* varn(ii, :);
            M.y0          = M.y0           + model{ii}.y0          .* varn(ii, :);
            M.sigma.major = M.sigma.major  + model{ii}.sigma.major .* varn(ii, :);
            M.sigma.minor = M.sigma.minor  + model{ii}.sigma.minor .* varn(ii, :);
            M.sigma.theta = M.sigma.theta  + model{ii}.sigma.theta .* varn(ii, :);
            M.rawrss      = M.rawrss       + model{ii}.rawrss      .* varn(ii, :);
            M.rss         = M.rss          + model{ii}.rss         .* varn(ii, :);
            M.beta        = M.beta         + model{ii}.beta(:,:,1) .* varn(ii, :);
        end

end

clear model;
model{1} = M;
save(params.matFileName{1}, 'model', 'params');

return



% -----------------------------------------------------------------------
% Test: the composite model should have more variance explained than any of
% the input models
% ------------------------------------------------------------------------
varianceExplained = rmGet(M, 'varexplained');

for ii = 1:nModels;
    figure; hist(var(ii,:));
    title(sprintf('var explained for model %d, median = %d', ii, median(var(ii,:)))); 
end
figure
hist(varianceExplained);
title(sprintf('var explained for composite model, median = %d', median(varianceExplained)));
