function [stat, ces, vSig, units] = glm_contrast(model,active,control,varargin)
% [stat, ces, vSig, units] = glm_contrast(model,active,control,[options]):
%
% For GLM toolbox, perform a statistical test (default t-test)
% between two sets of conditions, and return a set of significance
% statistics as well as contrast effect sizes.
%
% model is a struct produced by the glm m-file. See the discussion in the
% header of glm.m for an explanation of the fields in model. N.B. The model
% structure includes flags that can matter to the calculation.  For
% example, if 'selective averaging' is set, then the computation takes a
% different route.  The options for type also include 'applied HRF'.
%
% active:  a vector specifying positive conditions for the contrast.
% control: a vector specifying negative conditions for the contrast.
% So, if active were [1 3] and control were [2 5], the contrast
% would be [1 3] > [2 5], ignoring condition 4 as well as any other
% conditions.
%
% stat:   a matrix of statistical values [default significance level, or
% -log10(p) of t test], one for each voxel the model was applied to. 
%
% ces:  estimates the contrast effect size for each voxel. The CES is the
%  simple difference between the model weights as specified by the
%  contrast. For example, if you have three weights, b1, b2, b3, and your
%  are computing the contrast (1,-1,0), then the CES is b1 - b2.
%
% Options include:
%   'size',[val]:   specify a size to reshape the significance
%                   and ces slices (e.g., for an inplane slice).
%   'test',[char]:  specify the test type to use. Default is 'tm',
%                   for a t test.
%   
%   'weights',[val]: specify points in the time course of a deconvolved
%                    time series to use for the contrast.
%
%   'p':            return stat in units of p, rather than -log10(p).
%   'ln':           return stat in units of -ln(p), rather than -log10(p).
%
%   'T':            return the T values as the first argument (T test)
%   'F':            return the F valuse as the first argument (F test)
%
%	'FDR':			report the result as a false discovery rate 
%					(see  Benjamini & Hochberg, 1995;  Benjamini &
%					Yekutieli 2001.) (*** still in progress ***)
%   
% outputs
%  stat           significance value of statistical test (default -log(p))
%  ces            contrast effect size (difference between beta values)
%  vSig           statistical values (t or F values, depending on the test)
%  units          units in which stat is represebted (default -log(p))
% 
% Examples:
%   % Get the t-values
%   [statT, ces, vSig, units] = glm_contrast(model,active,control,'t');
%   % Get -log10(p)
%   [stat, ces, vSig, units] = glm_contrast(model,active,control);
%
% 02/05 ras.

% allow an empty model to be entered, returning an empty result
if isempty('model') | isempty(model.betas)
	stat = []; 
	return
end

% params/defaults
test = 'tm';
units = 'log10p';              % what units will stat be returned in?
resz = [];                     % optional size to reshape stat for each condition
dof = model.dof;               % degrees of freedom
Ch = model.voxIndepNoise;      % noise covariance matrix
nh = model.nh;
nPredictors = size(model.betas,2);
nVoxels = size(model.betas,3);
tcWeights = 1:nh; % for deconvolved tcs only

% parse the options
varargin = unNestCell(varargin);
for i = 1:length(varargin)
    if ischar(varargin{i})
        switch lower(varargin{i})
            case {'size','resize','resz','sz'},
                resz = varargin{i+1};
            case {'test','testtype'},
                test = varargin{i+1};
            case {'tcweights','weights'},
                tcWeights = varargin{i+1};
            case {'units'},
                units = varargin{i+1};
            case {'log','log10','log10p'},
                units = 'log10p';
            case {'ln','lnp','naturallog'},
                units = 'lnp';
            case {'p','pval'},
                units = 'pval';
            case {'t', 'tval'}  % force stat to be the vSig (T) map
                units = 't';
            case {'f', 'fval'}  % force stat to be the vSig (F) map
                units = 'f';
            case {'ces'}        % force stat to be the contrast effect size
                units = 'ces';
        end
    end
end

betas = model.betas;

% the betas variable needs to be of size nVoxelRows x nVoxelCols x
% nNonNullConditions for going into stxgrinder: the first two dimensions
% can be any format (but the product of their size must equal the # of
% voxels). We'll use 1D vectors for each cond, 1 x nVoxels, then reshape
% the results later if preferred:
betas = permute(betas, [3 1 2]);
betas = reshape(betas, [1 nVoxels nh*nPredictors]);

if checkfields(model, 'dc_betas')
	% append these at the end
	betas = cat(3, betas, permute(model.dc_betas, [3 2 1]));
end

% estimated residual variance:
resVar = sum(model.residual.^2) / model.dof; 

% ras 05/09/05:
% remove null condition
if ismember(active, 0),    active = setdiff(active, 0);   end
if ismember(control, 0),   control = setdiff(control, 0); end

% now get restriction matrix:
if isequal(model.type, 'selective averaging')
    RM = glm_restrictionMatrix(test, nh, nPredictors, active, control, ...
                               tcWeights);  
						   
	% deal with DC predictors: these are reflected in Ch but will be missing 
	% from the restriction matrix
	if size(RM, 2) < size(Ch, 1)
		RM(end,size(Ch,1)) = 0;  % these won't be part of the contrast
	elseif size(RM, 2) > size(Ch, 1)
		error('Restriction matrix has too many entries! This is weird.')
	end
	
	%% if there's a bug, this is where it's likely to be:
	% the FS-FAST-based restriction matrix returns a matrix of size
	% [nh x nPredictors]. If you view this, you see a bunch of diagonals
	% (e.g. a Toeplitz matrix). We want to do this like in brain voyager:
	% have a list of all predictors, set some positive, some negative, but
	% leave it a single, 1-D vector:
	RM = sum(RM, 1);	
else
    RM = glm_restrictionMatrix(test, nh, nPredictors, active, control);
end

%% apply the contrast:
% first, make everything double-precision
betas = double(betas);
resVar = double(resVar);
Ch = double(Ch);

% use the selected test to look up a 
[vSig pSig ces] = er_stxgrinder(test, betas, resVar, Ch, dof, RM);

if ~isempty(resz) && prod(resz)== numel(vSig)
    vSig = reshape(vSig,resz);
    pSig = reshape(pSig,resz);
    ces = reshape(ces,resz);
end

% correct for sign of effect for t tests
if isequal(test,'t') || isequal(test,'tm')
    signMask = ((vSig>=0) - (vSig<0));
    pSig = pSig .* signMask;
end

% Don't let pSig = zero (messes up log10)
iz = find(abs(pSig) < 10^-50);
pSig(iz) = sign(pSig(iz)) * 10^-50;
pSig(pSig == 0) = 10^-50; % Have to do this because sign(0) = 0


% convert to appropriate units
if ~isempty(units)
    switch units
        case 'log10p',
            stat = -log10(abs(pSig)) .*sign(pSig);
        case 'lnp',
            stat = -log(abs(pSig))  .*sign(pSig);
        case 'pval',
            stat = pSig;
        case {'t' 'f'}
            if units ~= test(1)
                error('Specified units are incompatible w/ test.');
            end
            stat = vSig;  % redundant outputs, but useful for some purposes
        case {'ces'}
            stat = ces;  % redundant outputs, but useful for some purposes             
    end
end


return
