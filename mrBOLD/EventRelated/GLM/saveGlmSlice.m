function saveGlmSlice(vw,model,dtName,scan,varargin)
% Save the results of a GLM applied to one slice of data
%
%  saveGlmSlice(vw,model,dtName,scan);
%
% The format of the saved file may vary depending on how we decide to
% minimize the footprint of each analysis (omitting some fields of the
% analysis which can be easily recomputed on the fly, and maybe changing
% data types), but in general they'll be saved in the following place:
%
% [sessionDir]/[viewType]/[dtName]/Scan[#]/glmSlice[#].mat
%
% E.g.:
% 020405ras/Inplane/GLMs/Scan1/glmSlice1.mat
%
% ras 06/06.

mrGlobals;

if nargin<4, help(mfilename); return; end

% ensure the target data type exists
% tgtDt = existDataType(dtName);
% if tgtDt==0
%     mrGlobals;
%     tgtDt = length(dataTYPES)+1;
% end

% the slice should be specified in the model struct
% (from applyGlmSlice): if not, error:
if ~isfield(model,'roiName')
    error('Need to specify slice # in roiName field. See applyGlmSlice.')
end
slice = str2num(model.roiName(7:end));
if isempty(slice)
    error('Need to specify slice # in roiName field. See applyGlmSlice.')
end

%% Get path for saved data

savePath = fullfile(viewDir(vw),dtName,['Scan' num2str(scan)]);
ensureDirExists(savePath);

% Loop over slices, saving one file per slice
for ii = 1:length(slice)
    
    thisSlice = slice(ii);
    fname =  ['glmSlice' num2str(thisSlice) '.mat'];
    
    
    %% Save the model
    % (we used to save as rescaled int16's to make the footprint smaller,
    % but there are roundoff issues with this methods, so instead we save as
    % singles. However, we don't save the SEMs, since they can be
    % quickly recomputed from the stdevs and trial count):
    thismodel = model;
    
    thismodel.sems          = [];
    thismodel.betas         = single(model.betas(:,:,:,ii));
    thismodel.residual      = single(model.residual(:,:,ii));
    thismodel.stdevs        = single(model.stdevs(:,:,:,ii));
    thismodel.C             = single(model.C);
    thismodel.designMatrix  = single(model.designMatrix);
    
    % % Older code (keep in case saving as singles is too inefficient)
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % % Save model, making adjustments to make footprint small %
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % model.sems = []; % can be computed quickly
    % [model.betas rng.betas] = intRescale(model.betas);
    % [model.residual rng.residual] = intRescale(model.residual);
    % [model.stdevs rng.stdevs] = intRescale(model.stdevs);
    % [model.C rng.C] = intRescale(model.C);
    % [model.designMatrix rng.designMatrix] = intRescale(model.designMatrix);
    % model.rng = rng;
    
    save(fullfile(savePath, fname), '-struct', 'thismodel');
    
end

return





