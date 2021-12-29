
function params = rmDefineParameters(vw, varargin)
% rmDefineParameters - define parameters for retinotopic model fit
%
% params = rmDefineParameters([vw], [varargin]);  
%
% inputs:
%  vw :       mrVista struct
%  varargin   : other inputs
%
% 2005/12 SOD: wrote it.
% 2007/08 SOD: large reorganization and more explanations.
% The hrfID had to go.  We tried to catch all instances and replace it with
% a switch statement that sets the hrfParams{} for each scan
% 2009/02 SOD: incorporated another stage that estimates the HRF while
% keeping the pRF parameters constant.

% The program is organized as follows:
%  general params   : defaults, (user) defined, derived
%  1st stage params : defaults, (user) defined, derived
%  2nd stage params : defaults, (user) defined, derived
%  3rd stage params : defaults, (user) defined, derived
% Some subfunctions.

% The defaults should not be modified. If another value is requested this
% should be given as an additional input and placed into the parameter
% structure by the subfunction: rmProcessVarargin

if ~exist('vw','var') || isempty(vw),
    error('Need view struct');
end

if nargin > 1,
    addArg = varargin;
    if numel(addArg) == 1,
        addArg=addArg{1};
    end;
else
    addArg = [];
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% General
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%--------------------------------------------------------------------------
%--- default params
%--------------------------------------------------------------------------
% Which pRF model do we want to use? Options are:
%'one gaussian', 'two gaussians DoG','two gaussians','one gaussianunsigned', 
% and 'one oval gaussian'.
% We can do several (or all) they will be done in the order they are given
% in this cell structure. So far only the first one (one Gaussian) is
% tested thoroughly.
params.analysis.pRFmodel = {'one gaussian'};


% Stimulus reconstruction grid. Larger = greater final accuracy, but
% overall slower. The total number of grid point will be
% 2*numberStimulusGridPoints+1, that is this parameter defines the number
% of grid point from the center to the edge of the stimulus. Therefore the
% default matrix size will be 101x101, regardless of the stimulus size (in
% degrees).
params.analysis.numberStimulusGridPoints = 50;

% Convert data to percent BOLD signal:
params.analysis.calcPC   = true;

% RAS 07/05/07: having the 'nSlices' field be definable as a stimulus
% argument creates bugs: for instance, if you edit the stim params in
% the Gray/Volume view, then for Inplane it also sets it to only have
% one slice. This crashes rmSave, but also doesn't make much sense (how
% is it a stimulus parameter?) -- so, I make a separate, analysis parameter
% here. This may not be a complete solution, but seems like the most
% appropriate fix; this function should be run within rmMain for each view:
params.analysis.nSlices = viewGet(vw, 'numSlices');

% RAS 02/2009: let's also keep track of some other meta-information, such
% as the scanning session and data type of the data used. This will be
% useful for finding data, in those functions where the view structure is
% not passed as an argument.
try
    mrGlobals;
    params.analysis.session     = mrSESSION.sessionCode;
    params.analysis.dataType    = viewGet(vw, 'dataTypeName');
    params.analysis.scans       = (1:viewGet(vw, 'numScans'));
    params.analysis.viewType    = vw.viewType;
catch %#ok<CTCH>
    fprintf('[%s]: Couldn''t record meta-data about RM params.\n', mfilename);
end

% We can either estimate the DC component during the fit or derive it from
% the data (e.g. a certain time during the stimulus)
params.analysis.dc.datadriven = false; % false = old behaviour 
% other associated parameters
% only use mean-lumince block data after the BOLD response has finished.
% This next parameter estimates how long the BOLD response takes and all
% mean-lumince data after that is used to estimate the DC-component.
% After 22 seconds the default two-gamma HRF's amplitude is less than 1% of the
% maximum response amplitude.
params.analysis.dc.hrfTime = 22; % sec

params.analysis.betaRatioAlpha = 1;
params.analysis.sigmaRatioFixedValue = [1 1 1];



%--------------------------------------------------------------------------
%--- user defined params
%--------------------------------------------------------------------------

% get stimulus defined parameters (+ some analysis ones)
params = rmGetStimType(vw, params);

% parse command line inputs:
params = rmProcessVarargin(params,addArg);

% GLU 2021-10-14: for css cases, add the option to use a fixed exponent
% By default, if the fixcssexp is 0, and the css model is selected,
% everything will be as it was

%--------------------------------------------------------------------------
%--- derived params
%--------------------------------------------------------------------------

% if ROI is selected process only ROI
if vw.selectedROI == 0,
    params.wData = 'all';
else
    params.wData = 'roi';
end;

% set output file name base
if ~exist('matFileName','var') || isempty(matFileName),
    if strcmp(params.analysis.pRFmodel,'one oval gaussian')
        params.matFileName{1} = ['retModel-',datestr(now,'yyyymmdd-HHMMSS'),'-oval'];
    elseif strcmp(params.analysis.pRFmodel,'one oval gaussian without theta')
        params.matFileName{1} = ['retModel-',datestr(now,'yyyymmdd-HHMMSS'),'-oval-notheta'];
    elseif strcmp(params.analysis.pRFmodel,'difference of gaussians')
        params.matFileName{1} = ['retModel-',datestr(now,'yyyymmdd-HHMMSS'),'-dog'];
    else
        params.matFileName{1} = ['retModel-',datestr(now,'yyyymmdd-HHMMSS')];
    end
else
    if ~iscell(matFileName),
        params.matFileName{1} = matFileName;
    else
        params.matFileName = matFileName;
    end
end;

% store minimal and maximal stimulus size
params.analysis.minFieldSize = 0;
if ~isfield(params.analysis,'fieldSize')
    params.analysis.fieldSize   = max([params.stim(:).stimSize]);
end
fprintf(1,'[%s]:Stimulus size: %.2fdeg.\n',...
    mfilename,params.analysis.fieldSize);

% Store separate HRFs for each stimulus, this will allow different
% scans with different TRs to be combined.
hrfParams = hrfGet(params,'hrfparams');

% we need to compute the HRF for each scan because they might have
% different TRs. All other hrf parameters are independent of the TR.
params = hrfSet(params,'hrf');


% report the HRF used for every stimulus:
for n=1:numel(params.stim),
    fprintf(1, '[%s]:Scan %d:HRF type: [%s]; parameters: [',...
        mfilename,n,lower(params.stim(n).hrfType));
    for ii=1:numel(hrfParams{n}),
        fprintf(1,' %.2f',hrfParams{n}(ii));
    end;
    fprintf(']. (%s)\n', datestr(now)); drawnow;
end

% Two Gaussian model: extra parameters:
% The next two parameters reflect the size of more diffuse (larger) and the
% weight of pRF: relative to the center rf (ratio). Empty for no two-gaussian
% model.
%params.analysis.sigmaRatioFixedValue       = [];

% if the model has a nonlinearity, then store this explicitly
switch lower(params.analysis.pRFmodel{1})
    case {'onegaussiannonlinear' 'css' 'onegaussiannonlinearboxcar' 'cssboxcar'}
        params.analysis.nonlinear = true;
        params.analysis.fixcssexp = 0;
end
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 1st stage ("coarse" grid fit)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%--------------------------------------------------------------------------
%--- default params
%--------------------------------------------------------------------------

% We have the option to smooth the data for the grid fit. This will
% make the grid fit more robust. The smoothing will not be done for
% the follow search fit: i.e. do we run a "true" coarse-to-fine approach:
params.analysis.coarseToFine = true;

% We can also sparse sample the data and interpolate the
% rest for speed reasons (and since neighboring points will be
% similar by definition if the data is smoothed).
% False (0) means no coarse sampling but non-zero positive numbers indicate
% how how coarsely we sample the data. Here we choose this parameter based
% (1) params.analysis.coarseToFine (2) on the voxel resolution.
if params.analysis.coarseToFine,
    if prod(viewGet(vw,'mmPerVox')) >= 1,
        params.analysis.coarseSample = 1;
    else
        % Increase here if you want high-resolution data to be sampled
        % coarser. Better yet, do it on a commandline call. This file
        % should be altered only sparsly because it affects all users.
        params.analysis.coarseSample = 1;
    end
else
    params.analysis.coarseSample = false;
end

% If we smooth the data: this parameter defines the smoothing amount,
% i.e. iterations and neighborhood weight for the discrete heat kernel
% smoothing: 
% [16 1] ~ 7mm fwhm
% [11 0.7] | [10 0.75] | [7 1.6] ~ 5mm fwhm
% [9 0.6] | [7 0.7] | [5 1.1] ~ 4mm fwhm
% [9 0.5] | [5 0.6] | [4 0.75] ~ 3mm fwhm
% assuming a 1mm cubic resolution
params.analysis.coarseBlurParams = [10 0.75];

% We can link neighboring estimates. In this case we smooth the rss, thus
% the goodness-of-fit is determined by the fit of the voxel *and* the
% neighbors. This shifts the optimal individual voxel fit to fits that are
% similar in the neighborhood. Because this is done after *every* fit,
% iterations should be kept small. This parameters define the iterations and
% neighborhood weight for the discrete heat kernel smoothing (see previous
% param):
params.analysis.linkBlurParams = [5 1.1]; % ~4mm fwhm

% Next we allow temporal smoothing. Temporal smoothing is achieved by
% decimation, allowing both SNR improvement due to low-pass filtering and
% speed up due to less sample points.
% [0]: no decimate.
% [2]: decimate by factor 2.
params.analysis.coarseDecimate = 2;

% pRF grid: how many pRF sizes to test (# sigmas).
% Larger = greater grid-search accuracy, less likely to get stuck
% in local minima but slower grid search. On the other hand it will
% mean faster unconstrained search. Final accuracy may not be
% affected if the search space is relatively smooth.
% The spacing of these sigmas is determined by spaceSigmas.
if strcmp(params.analysis.pRFmodel{1}, 'one oval gaussian') || ...
    strcmp(params.analysis.pRFmodel{1}, 'one oval gaussian without theta')
    params.analysis.numberSigmas     = 10;
else
    params.analysis.numberSigmas     = 24;
end
% The minumum pRF size:
params.analysis.minRF            = 0.2; % degrees, sigma
% The maximum pRF size will be determined by the maximum stimulus size
% in the derived params below.

% The number of the ratio between sigma_major and sigma_minor
params.analysis.numberSigmaRatios= 5;
% params.analysis.numberSigmaRatios= 1;
% The number of the angle of sigma_major (theta)
params.analysis.numberThetas= 4;
% params.analysis.numberThetas= 1;

% The next parameter defines how the sigma values are distributed
% between minRF and maxRF. So far we have three methods:
% 'lin','log','linlog'. See spaceSigmas below for details.
params.analysis.spaceSigmas      = 'linlog';

% if we use linlog (default) we can specify where the cutoff lies. This
% cutoff is defined as a percentage of total sigmas, i.e. a value of 0.7
% gives 70% of sigmas linearly spaced and 30% logarithmically spaced. See
% spaceSigmas below for details
params.analysis.linlogcutoff    = 0.7; % 0.7 = old default

% Once we have defined the number of sigmas, we need to determine the x,y
% positions of the pRFs to be able to make all pRF combinations we are
% going to test. The pRF positions are determined by the step-size
% (distance between pRFs). This stepsize could be fixed or could covary
% with the sigma so it estimates smaller steps at smaller sigmas
% (step==sigma*alpha).
% This switch that determines whether to scale (covary) the pRF position
% grid steps with sigmas (true) or go to minimum (fixed) scaling (false).
% The latter (false) seems more robust but more computationally expensive.
% I care more about robustness than time, so:
params.analysis.scaleWithSigmas  = false; % not currently used.

% If we do need scale the step size with the sigma size, we can here
% specify an upper limit. Without this limit large pRF sizes will be
% tested at very (too) few positions. The minimum grid positions to
% test (radius, actual positions will be x*2+1) Set the lower limit
% enough position to roughly tile the visual space, only matters if
% params.analysis.scaleWithSigmas  = true;
% It is not in a if statement because we might reset scaleWithSigmas in the
% commandline (see user defined params)
params.analysis.minimumGridSampling = 7;  % nsteps

% Whether we change the step size with the sigma-size or not. The step size
% is relative to the (minimum or individual) pRF size. This parameter
% defines how the step size relates to the pRF size. This parameter is
% defined as a fraction of the (minimum or individual) pRF sigma size. For
% example if we place the pRFs at a stepsize equal to their fwhm, this
% parameter should be (2*sqrt(2*log(2))). Suspicion that this step may be
% too big, for further optimization and since rmGridFit is faster we may
% put more weight on it. Revert back to one standard deviation (1);
params.analysis.relativeGridStep = (2*sqrt(2*log(2))); % *sigma

% The pRFs are estimated outside the stimulus size. The estimation power
% obviously goes down as you move further outside the stimulus, in other
% words the overlap between the pRF and the stimulus decreases. This
% parameter defines how far away we estimate the pRF centers. This
% parameter is defined in multiples of each pRFs sigma.
params.analysis.outerlimit       = 2; % 2 sigmas outside

% for Difference of Gaussians model: ratio of the second Gaussian relative
% to the first. These ratios will be evaluated sigma^2/sigma2^2, we place
% them therefor semi-linearly in this space.
params.analysis.sigmaRatio       = [sqrt(1./(1:-0.1:0.1)) 5 10];
%[1 1.054 1.118  1.1952  1.291  1.414  1.581 1.826 2.236 3.162 5 10];
% minimal sigma ratio
params.analysis.minSigmaRatio    = 1;

% By default the grid is a triangular grid. Here you can specify a
% different grid:
params.analysis.grid.type        = 'triangular';
params.analysis.grid.params      = [];
% other option
% params.analysis.grid.type      = 'polar'
% params.analysis.grid.params    = [20 16]; %[nrings nspokes]


%--------------------------------------------------------------------------
%--- user defined params
%--------------------------------------------------------------------------

% parse command line inputs:
params = rmProcessVarargin(params,addArg);

%--------------------------------------------------------------------------
%--- derived params
%--------------------------------------------------------------------------

% pRF model sanity check:
stable_models = {'onegaussian','one gaussian','default','standard'};
for n=1:numel(params.analysis.pRFmodel),
    switch lower(params.analysis.pRFmodel{n}),
        case stable_models
            % do nothing: these are all supported
            
        otherwise
            % provide warning: these are models that are under development
            fprintf(1,'[%s]: **********************************************************************\n',mfilename);
            fprintf(1,'[%s]: * WARNING: You are using pRF models (%s) that are under development!\n',mfilename,params.analysis.pRFmodel{n});
            fprintf(1,'[%s]: *          These pRF models may have known issues.\n',mfilename);
            fprintf(1,'[%s]: **********************************************************************\n',mfilename);
            
            % one warning is enough.
            break;
            
    end
end

% Coarse-to-fine approach is only incorporated in the "Gray" view. So check
% if we have a "gray" view and if not abandone coarse to fine approach:
if ~strcmpi(vw.viewType,'gray'),
    fprintf(1,['[%s]:Not a Gray view (%s): ABANDONING ' ...
        'coarse-to-fine approach (that means no initial smoothing of the data).\n'],...
        mfilename,vw.viewType);
    params.analysis.coarseToFine = false;
    params.analysis.coarseSample = false;
end;

% Maximum pRF size (sigma) is equal to the stimulus size (degrees):
if ~isfield(params.analysis,'maxRF'),
    params.analysis.maxRF = params.analysis.fieldSize;
end

% Maximum pRF center position (degrees):
params.analysis.maxXY = params.analysis.fieldSize + params.analysis.maxRF;

% Set upper pRF sampling limit roughly equal to stimulus sampling points (no point
% going much higher). This parameter might reset the
% params.analysis.relativeGridStep above. See sigma2searchgrid for details.
params.analysis.maximumGridSampling = params.analysis.numberStimulusGridPoints./2;

% Now make actual sampling grids:
% Space number of sigmas nonlinearly between minimum and maximum value.
initSigmas = rmSpaceSigmas(params);
fprintf(1,'[%s]:PRF size spacing: from %.2f to %.2f deg (%d).\n',mfilename,...
    min(initSigmas),max(initSigmas),numel(initSigmas));
if ~isfield(params.analysis,'sampleRate')
    params.analysis.sampleRate      = params.analysis.fieldSize./...
        params.analysis.numberStimulusGridPoints;
end
fprintf(1,'[%s]:Stimulus sample size: %.2f deg.\n',mfilename,...
    params.analysis.sampleRate);

% Position of every pRF in the visual field.
% Now make all possible combinations for pRF positions (x,y center position
% degrees)  and pRF size (z = sigma degrees)
[x, y, z]  = sigma2searchgrid(initSigmas, params);

% xlim parameter can impose limits on the search space in x-dimension. Thus
% estimate pRFs in the left or right visual field only. 
% The sign indicates wich part of the visual field (left or right).
% The amplitude indicates different procedures to remove part of the search
% space.
%   1 = remove other visual field
%   2 = remove all pRFs with outerlimit overlap with other visual field
%   Other values will not remove values but can have effects down the line.
%   For now this is only occurs with rmGridFit_twoGaussiansPosOnly where
%   the search space is dynamically changed.
% Default is zero (0). No limits.
if isfield(params.analysis,'xlim'),
    if params.analysis.xlim == -1, % left visual field
        ii=x<0;
        x=x(ii);y=y(ii);z=z(ii);
    elseif params.analysis.xlim == 1, % right visual field
        ii=x>0;
        x=x(ii);y=y(ii);z=z(ii);
        
    elseif params.analysis.xlim == -2, % left visual field > 1sd
        ii=(x+params.analysis.outerlimit.*z)<0;
        x=x(ii);y=y(ii);z=z(ii);
    elseif params.analysis.xlim == 2, % right visual field > 1sd
        ii=(x-params.analysis.outerlimit.*z)>0;
        x=x(ii);y=y(ii);z=z(ii);
        
    else
        % do nothing (should be the default)
    end
end
        
% Now we limit all possible combinations, with certain rules:
%  (a) pRF center should be maxRF away from center, this makes our search
%   field circular like our stimulus
%  (b) xy-sigma should fall in fieldSize preventing estimation of 'too'
%   small pRF centers 'too' far out our field of view. See
%   params.analysis.outerlimit
% Somewhat arbitrary rules but will limit the search to pRFs that are most
% plausible and speed it up.
% Keep those that fit our rules:
dist = sqrt(x.^2+y.^2);
keep = find(dist<=params.analysis.maxXY & ...
    (dist-params.analysis.outerlimit.*z)<=params.analysis.fieldSize);
% put in params structure

switch params.analysis.pRFmodel{1}
    case 'one oval gaussian'
        numSigmaRatiosThetas = params.analysis.numberSigmaRatios*params.analysis.numberThetas;
        params.analysis.x0 = repmat(flipud(x(keep)),numSigmaRatiosThetas,1);
        params.analysis.y0 = repmat(flipud(y(keep)),numSigmaRatiosThetas,1);
        params.analysis.sigmaMajor = repmat(flipud(z(keep)),numSigmaRatiosThetas,1);
        tmp = sort(repmat((1/params.analysis.numberSigmaRatios:1/params.analysis.numberSigmaRatios:1)',size(flipud(x(keep)))));
        tmp2= repmat(tmp,params.analysis.numberThetas,1);
        params.analysis.sigmaMinor = params.analysis.sigmaMajor.*tmp2;
        tmp = sort(repmat((pi/params.analysis.numberThetas:pi/params.analysis.numberThetas:pi)',size(flipud(x(keep)),1)*params.analysis.numberSigmaRatios,1));
        params.analysis.theta = tmp;
        params.analysis.exponent = ones(size(params.analysis.x0));
        clear tmp*
        % params.analysis.theta = -atan(params.analysis.y0./params.analysis.x0);
    case 'one oval gaussian without theta'
        params.analysis.x0 = repmat(flipud(x(keep)),(params.analysis.numberSigmas+1),1);
        params.analysis.y0 = repmat(flipud(y(keep)),(params.analysis.numberSigmas+1),1);
        params.analysis.sigmaMajor = repmat(flipud(z(keep)),(params.analysis.numberSigmas+1),1);
        params.analysis.sigmaMinor = sort(repmat(unique(params.analysis.sigmaMajor),size(x(keep))));
        params.analysis.theta = -atan(params.analysis.y0./params.analysis.x0);
        params.analysis.theta(isnan(params.analysis.theta))=0;
        params.analysis.exponent = ones(size(params.analysis.x0));
        
    case {'css' 'onegaussiannonlinear', 'onegaussianexponent'}
        % The number of exponents for nonlinear model (pred = (stim*prf)^exponent)
        % GLU 2021-10-14: if we are here and the new variable fixcssexp~=0,
        %                 then we want just one exponent set up to that value
        
        numberOfGridPoints          = length(keep);
        
        if params.analysis.fixcssexp==0
            params.analysis.numberExponents = 4 ;
            exponentValues              = (params.analysis.numberExponents:-1:1)/params.analysis.numberExponents;
            params.analysis.exponent    = repmat(exponentValues, numberOfGridPoints, 1);
            params.analysis.exponent    = params.analysis.exponent(:);
        else
            params.analysis.numberExponents = 1 ;  
            params.analysis.exponent    = repmat(params.analysis.fixcssexp, numberOfGridPoints, 1);
            params.analysis.exponent    = params.analysis.exponent(:);
        end
        
        

        params.analysis.x0          = repmat(flipud(x(keep)),(params.analysis.numberExponents),1);
        params.analysis.y0          = repmat(flipud(y(keep)),(params.analysis.numberExponents),1);

        params.analysis.sigmaMajor  = repmat(flipud(z(keep)),(params.analysis.numberExponents),1);
        params.analysis.sigmaMajor  = params.analysis.sigmaMajor .* sqrt(params.analysis.exponent);
        params.analysis.sigmaMinor  = params.analysis.sigmaMajor;
        params.analysis.theta       = params.analysis.sigmaMajor * 0;

    otherwise
        params.analysis.x0 = flipud(x(keep));
        params.analysis.y0 = flipud(y(keep));
        params.analysis.sigmaMajor = flipud(z(keep));
        params.analysis.sigmaMinor = params.analysis.sigmaMajor;
        params.analysis.theta = params.analysis.sigmaMajor * 0;
        params.analysis.exponent = ones(size(params.analysis.x0));
end

fprintf(1,'[%s]:Number of [x,y,s] models for grid search: %d.\n',...
    mfilename,numel(params.analysis.x0));

% Position of every sample point in the visual field.
mygridx = (-params.analysis.fieldSize:...
    params.analysis.sampleRate:...
    params.analysis.fieldSize);
[params.analysis.X, params.analysis.Y] = meshgrid(mygridx,mygridx);
% We want the stimulus grid to have postive values for the upper part of
% the image, which requires a flip. 
%   For example, prior to flip, this produces negative values in the upper 
%   portion of the image: figure; imagesc(params.analysis.Y); colorbar;
%   After the flip, this produces positive values in the upper portion of 
%   the image: figure; imagesc(params.analysis.Y); colorbar;
params.analysis.Y = flipud(params.analysis.Y);

% rmMakeStimulus by default limits the sample points to those where a
% stimulus was actually presented. This remains the default. 
if ~isfield(params.analysis,'keepAllPoints')
    params.analysis.keepAllPoints = false;
end

% Correct for off-center (real or simulated) fixation. This is not necesary
% for 1 Gaussian models (easier to do afterwards), but is required for more
% complex models that are mirrored around central axes. This should not be
% done here but after the stimulus is made! Potential later errors are when
% we recreate X and Y instead of loading it!
% if isfield(params.analysis,'fixationCorrection')
%     fprintf('[%s]:Shifting X (+%.2f) and Y (+%.2f) axis!\n',mfilename,...
%         params.analysis.fixationCorrection(1),...
%         params.analysis.fixationCorrection(2));
%     params.analysis.X = params.analysis.X + params.analysis.fixationCorrection(1);
%     params.analysis.Y = params.analysis.Y + params.analysis.fixationCorrection(2);
% end


% Two Gaussian model: extra parameters:
% Maximum of second Gaussian and "full field second Gaussian
% = inf" definitions relative to fieldsize (degrees).
params.analysis.sigmaRatioMaxVal = 8*params.analysis.fieldSize;
params.analysis.sigmaRatioInfVal = 8*params.analysis.fieldSize;
% Make sure that the smallest size of the second Gaussian is at
% least minSigmaRatio the size of the first one.
if ~isempty(params.analysis.sigmaRatio)
    params.analysis.sigmaRatio = ...
        params.analysis.sigmaRatio(params.analysis.sigmaRatio>=params.analysis.minSigmaRatio);
    params.analysis.sigmaRatio = params.analysis.sigmaRatio(:);
end;

% Shifted Gaussian model. Define Gaussian shift.
params.analysis.pRFshift = 0.5; % deg, default
					  
% Make 1D Gaussian grid and reset certain defaults
switch lower(params.analysis.pRFmodel{1}),  
    case {'1d gaussian','1dgaussian','1d',...
          '1d dog','1ddog'}
        % make 1d grid
        params = rmMake1Dgrid(params);
        % reset certain other parameters
        %params.analysis.keepAllPoints = true;
        
    otherwise
        % do nothing
end
					  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 2nd stage ("fine" search fit)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%--------------------------------------------------------------------------
%--- default params
%--------------------------------------------------------------------------
% optimization parameters
params.analysis.fmins.options = optimset('fmincon');

% Display iterations?
params.analysis.fmins.options = optimset(params.analysis.fmins.options,'Display','none'); %'none','iter','final'

% Maximum iterations. If set to zero it does not refine the parameters but
% simply refits. This is useful to remove 'coarse-blurred' estimates below
% a certain threshold.
% GLU params.analysis.fmins.options = optimset(params.analysis.fmins.options,'MaxIter',25); % #
params.analysis.fmins.options = optimset(params.analysis.fmins.options,'MaxIter',500); % #

% Precision of output (degrees). That is, stop if the estimate is
% within TolX degrees:
% GLU params.analysis.fmins.options = optimset(params.analysis.fmins.options,'TolX',1e-2); % degrees
params.analysis.fmins.options = optimset(params.analysis.fmins.options,'TolX',1e-8); % degrees



% Precision of evaluation function. We define RMS improvement
% relative to the initial raw 'no-fit' data RMS. So, 1 means
% stop if there is less than 1% improvement on the fit:
% GLU params.analysis.fmins.options = optimset(params.analysis.fmins.options,'TolFun',1e-2); % degrees
params.analysis.fmins.options = optimset(params.analysis.fmins.options,'TolFun',1e-8); % degrees

% Variance-explained threshold above which to do search.
% This limits the search algorithms to voxels that will have 'good' data.
params.analysis.fmins.vethresh = 0.1;

% Maximum range x,y,sigma in which to search. This parameter is
% defined in an expansion of original grid steps.
params.analysis.fmins.expandRange = 5;

% Specific search options to only refine certain parameters.
params.analysis.fmins.refine = 'all';

%--------------------------------------------------------------------------
%--- user defined params
%--------------------------------------------------------------------------

% parse command line inputs:
params = rmProcessVarargin(params,addArg);

%--------------------------------------------------------------------------
%--- derived params
%--------------------------------------------------------------------------

% NONE

%% convert large data fields to single precision (ras, 01/09)
for f = {'x0' 'y0' 'sigmaMajor' 'sigmaMinor' 'theta' 'X' 'Y'}
	params.analysis.(f{1}) = single( params.analysis.(f{1}) );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 3nd stage ("fine" search fit for HRF) 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This search is conceptually similar to the pRF 2nd stage search fit. In
% this search we optimize the HRF, while holding all other parameters
% constant. This will furhter improve the fit. We are searching for all
% voxels (within ROI if specified) at once. 

% We suspect that a HRF with a full-field on-off might not reflect the HRF
% for the pRF mapping. It is important that the stimulus is balanced,
% otherwise pRF position might be confounded with HRF delay, and pRF size
% with HRF width. To minimize these effects, pRF parameters are fixed when
% estimating the HRF and vice versa. 

% We limit the search to all good voxels. We estimate one (1) HRF for all
% these voxels at the same time by minimizing the RSS. The search is
% relatively fast so we are generous on the minimization stopping
% criteria. Like the pRF search we employ a coarse-to-fine optimization
% implemented in a grid and search fit stage.

% TO DO: fit only works for the first scan; only works for twogamma HRF 
% (but if 5th argument approaches zero, the two gamma function becomes
% a one gamma function). 

%--------------------------------------------------------------------------
%--- default params
%--------------------------------------------------------------------------

% We employ various thresholds to select 'good' voxels. We select on
% goodness of fit parameters (variance explained) as well as pRF
% parameters. This selects 'good' voxels with reasonable pRFs. We have most
% confidence in voxels with high variance explained and whose pRF locations
% lies within the stimulus aperture. Historically, pRFs around the foveal
% confluence are also more unreliable so we might be careful to include
% them as well.

% Variance-explained threshold above which to do search.
params.analysis.hrfmins.thresh.ve = 0.1;

% Eccentricity thresholds - default within stimulus range
params.analysis.hrfmins.thresh.ecc = [0 params.analysis.fieldSize];

% Sigma thresholds - all within range
params.analysis.hrfmins.thresh.sigma = [params.analysis.minRF params.analysis.maxRF];

% Range in which to optimize the HRF parameters. This is defined relative
% to the default parameters - used to derive the pRF fit. HRF parameters
% will be varied between HRFparams/range and HRFparams*range
params.analysis.hrfmins.range = 2;

% Number of steps between to sample the grid search within the range
params.analysis.hrfmins.gridsample = 11; % oneven so it always samples the default one

% Maximum time before HRF has to go back to zero (within certain accuracy)
params.analysis.hrfmins.maxHrfDuration = 30; % seconds


% Minimization parameters. Because the fit is relatively fast we can be
% generous.
params.analysis.hrfmins.opt = optimset('fmincon');
% Display iterations?
params.analysis.hrfmins.opt = optimset(params.analysis.hrfmins.opt,'Display','none');%'none','iter','final'

% Maximum iterations:
params.analysis.hrfmins.opt = optimset(params.analysis.hrfmins.opt,'MaxIter',200); % go wild

% Precision of output (degrees). That is, stop if the estimate is
% within TolX degrees:
params.analysis.hrfmins.opt = optimset(params.analysis.hrfmins.opt,'TolX',1e-6); % sec, overkill with little consequence.

% Precision of evaluation function. We define RMS improvement
% relative to the initial raw 'no-fit' data RMS of the 'whole' dataset. 
params.analysis.hrfmins.opt = optimset(params.analysis.hrfmins.opt,'TolFun',1e-6); % percent 

% plot the new HRF for visualization
params.analysis.hrfmins.plot = false;


%--------------------------------------------------------------------------
%--- user defined params
%--------------------------------------------------------------------------

% parse command line inputs:
params = rmProcessVarargin(params,addArg);

%--------------------------------------------------------------------------
%--- derived params
%--------------------------------------------------------------------------
% NONE

return
%--------------------------------------------------------------------------



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Some sub-functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%------------------------------------------------------
% Load subject defined stimulus parameters (under the
% 'retinotopyModelParams' field). If this does not exist it prompts the
% user, and saves them in the aforementioned field.
%------------------------------------------------------
function params = rmGetStimType(vw, params)
mrGlobals;

sParams = viewGet(vw,'rmStimParams');
if isempty(sParams)
    % See if you can find it in the dataTYPES
    dt = viewGet(vw, 'curDataType');
    if checkfields(dataTYPES(dt),'retinotopyModelParams')
        params.stim = dataTYPES(dt).retinotopyModelParams;
    else
       error('Please define stimulus parameters (Analysis | Retinotopy Model | Set Stimulus Parameters).');
    end
else
    params.stim = sParams;
    return;
end

return
%------------------------------------------------------

%------------------------------------------------------
% This function creates grid for a grid search, where the steps in x, y
% are scaled with sigma. That is step==sigma*alpha. Make sure we go through
% zero and we do at least a minimum of 7 steps from left to right. Uses a
% triangular grid (optimal stacking of circles).
%------------------------------------------------------
function [x,y,z]=sigma2searchgrid(sigma,params)
x = []; y = []; z = []; 
alpha = params.analysis.relativeGridStep;
sigma = sigma(:);
maxXY = params.analysis.maxXY;

% minimum step based on alpha and sigma:
step = min(sigma).*alpha;

% minimum step based on the stimulus sampling and stimulus size.
step = max(step, params.analysis.maxXY./2./params.analysis.maximumGridSampling);

% report result
fprintf(1,'[%s]:Minimimal pRF position spacing in triangular grid: %.2f deg.\n',...
    mfilename, step);


for n=1:numel(sigma),
    if params.analysis.scaleWithSigmas,
        % make sure we go through 0
        step = sigma(n).*alpha;

        % certain maximum of steps (minimum sampling)
        maxstepindeg = maxXY./2./params.analysis.minimumGridSampling;
        step=min(step,maxstepindeg);

        % certain max of steps too (minimumSampling)
        minstepindeg = maxXY./2./params.analysis.maximumGridSampling;
        step=max(step,minstepindeg);
    end;
    
    % make grid
    switch lower(params.analysis.grid.type)
        case 'triangular'           % find triangular grid positions
            [tx,ty]=triangleGrid([-maxXY maxXY],step);
        case 'polar'                % find polar grid positions
            [tx,ty]=polarGrid([-maxXY maxXY],...
                params.analysis.grid.params(1),...
                params.analysis.grid.params(2));
        otherwise
            error('[%s]:Unknown grid type: %s',mfilename,...
                params.analysis.grid.type);
    end

    % grow grid
    x=[x;tx(:)]; %#ok<AGROW>
    y=[y;ty(:)]; %#ok<AGROW>
    z=[z;ones(size(ty(:))).*sigma(n)]; %#ok<AGROW>
end;
return;
%------------------------------------------------------

%------------------------------------------------------
% parse varargin commandline input arguments into params struct
%------------------------------------------------------
function params = rmProcessVarargin(params,vararg)
if ~exist('vararg','var') || isempty(vararg), return; end
fprintf(1,'[%s]:Resetting parameter:',mfilename);
for n=1:2:numel(vararg),
    data = vararg{n+1};
    fprintf(1,' %s,',vararg{n});
    switch lower(vararg{n}),
        case {'calcpc'}
            params.analysis.calcPC = logical(data);

        case {'keepallpoints','keep all points'}
            params.analysis.keepAllPoints = logical(data);
            
        case {'samplerate','sample rate'}
            params.analysis.sampleRate = data;
            
            
        case {'prfmodel','prf model','model'}
            params.analysis.pRFmodel = data;
        
        case {'vethresh','tthresh','variance explained threshold'}
            params.analysis.fmins.vethresh = data;

        case {'maxiter','maximum iterations'}
            params.analysis.fmins.MaxIter = data;

        case {'expandrange','expand range'}
            params.analysis.fmins.expandRange = data;

        case {'gridpoints','grid points','numberstimulusgridpoints'}
            params.analysis.numberStimulusGridPoints = data;

        case {'outerlimit','sigma outerlimit'}
            params.analysis.outerlimit       = data;

        case {'relativegridstep','relative grid step'}
            params.analysis.relativeGridStep = data;

        case {'numbersigmas','numberofsigmas','number of sigmas'}
            params.analysis.numberSigmas     = data;

        case {'spacesigmas','space sigmas'}
            params.analysis.spaceSigmas     = data;

        case {'linlogcutoff'}
            params.analysis.linlogcutoff    = data;

        case {'scalewithsigmas','scale with sigmas'}
            params.analysis.scaleWithSigmas  = logical(data);
            
        case {'minfieldsize','minx','min field size','min x'}
            params.analysis.minFieldSize     = data;
            
        case {'maxfieldsize','maxx','max field size','max x','fieldsize'}
            params.analysis.fieldSize     = data;

        case {'minrf','minprf','min rf','min prf','min prf size'}
            params.analysis.minRF            = data;

        case {'maxrf','maxprf','max rf','max prf','max prf size'}
            params.analysis.maxRF            = data;

        case {'coarsetofine','coarse to fine'}
            params.analysis.coarseToFine = logical(data);

        case {'coarsesample','coarse sample'}
            params.analysis.coarseSample = data;

        case {'coarseblurparams','coarse blur params'}
            params.analysis.coarseBlurParams = data;

        case {'coarsetblurparams','coarse temporal blur params','decimate','coarsedecimate'}
            params.analysis.coarseDecimate = data;

        case {'linkblurparams','link blur params'}
            params.analysis.linkBlurParams = data;

        case {'gridtype','grid type'}
            params.analysis.grid.type = data;

        case {'matfilename'}
            if ~iscell(data),
                params.matFileName{1} = data;
            else
                params.matFileName = data;
            end

        case {'sigmaratio','sigma ratio'}
            params.analysis.sigmaRatio = data(:);

        case {'betaratio','beta ratio'}
            params.analysis.betaRatio = data(:);

        case {'stimstart'}
            for ii=1:numel(params.stim)
                params.stim(ii).stimStart = data;
            end
            
        case {'ndct','number of discrete cosine functions'}
            for ii=1:numel(params.stim)
                params.stim(ii).nDCT = data;
            end
            
        case {'hrf','hdrf','hemodynamic response function'}
            params = hrfSet(params,'hrfType',data{1});
            params = hrfSet(params,'hrfparams',data{2});
            
        case {'xlim'}
            params.analysis.xlim = data;
            
        case {'mirror'}
            params.analysis.mirror = sign(data);
            if any(sign(data)==0), disp(sign(data)); error('Zero values in mirror'); end;
            
		case {'prfshift'}
			params.analysis.pRFshift = data;
					  
        case {'fixation correction','fixationcorrection'}
            params.analysis.fixationCorrection = data;
            
        case {'datadrivendc','dc','data driven dc'}
            params.analysis.dc.datadriven = logical(data);
            
        case {'hrftime'}
            params.analysis.dc.hrfTime = data;

        case {'betaratioalpha','alpha'}
            params.analysis.betaRatioAlpha = data;
            
        case{'sigmaratiofixedvalue', 'sigma2fixedvalue','srf'}    
            params.analysis.sigmaRatioFixedValue = data(:);  % 3 values: 1st = sigma-sigma2 ratio 
                                                             % 2nd = ecc -sigma2 ratio
                                                             % 3rd = beta

        case {'refine','search fit refine parameter'}
            params.analysis.fmins.refine = data;
            
        case {'fixcssexp'}
            params.analysis.fixcssexp = data;    
            
        otherwise,
            fprintf(1,'[%s]:IGNORING unknown parameter: %s\n',...
                mfilename,vararg{n});
    end;
end;
fprintf(1,'.\n');
return
%------------------------------------------------------

