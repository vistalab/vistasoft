function val = rmGetVoxelData(param, vw, roi, varargin)
% rmGetVoxelData - Get Retinotopy Model data for a selected set of voxels.
%
% val = rmGetVoxelData(param, [view or RM model], [voxels=cur ROI], [options]);
%
%
% INPUTS:
%   param: name of the parameter to get for each voxel. Possible values:
%       'prf', 'rf': constructed 2D population receptive fields for each voxel.
%       If several voxels are specified, returns a 3D matrix in which the
%       slices correspond to the pRF for each voxel.
%
%		'prfvector', 'rfvector': same as 'prf', but each voxel's RF is
%		provided in a single vector format. The resulting matrix is size
%		pixels (in visual space) x voxels.
%
%       'x', 'x0': X position center of the pRF for the voxel.
%
%       'y', 'y0': Y position center of the pRF for the voxel.
%
%		'ecc', eccentricity of pRF center.
%
%		'pol', polar angle of pRF center.
%
%       'sigma', 'sigmamajor': pRF size of the first/only Gaussian.
%
%       'sigmaminor': pRF size of the second Gaussian, if it exists.
%
%       'theta': relative rotation of the major/minor axes.
%
%       'sig', 'log10p': significance level (-log10(p)) for the model for
%        each voxel.
%
%       'beta': scaling coefficient ("beta value") for the Gaussian pRF for
%       each voxel.
%
%		'amp': amplitude of the response. This is the scale factor
%		necessary to take a predicted response for each voxel, and fit it
%		to the time series. (This is the "beta value" for a GLM, constructed
%		from a pRF-derived esign matrix).
%
%
%   model: can either be a retinotopy model struct, or a mrVista view.
%   If the latter, grabs the first model loaded into the view (prompting
%   the user to select and RM file if none are loaded). Can also be
%   a number, indexing into loaded model structs. [Default: cur view
%   model]
%
%   voxels: ROI specification. Can be a numeric index into the view's ROIs
%   field, the ROI struct itself, a 3xN set of coordinates relative to the
%   view, or the ROI name of a loaded ROI. (Uses tc_roiStruct to
%   disambiguate these possibilities.) [Default: cur ROI of cur view]
%
% options include:
%   'rot', [value]: rotate RF params clockwise by [value] degrees. Ths will
%                   happen if the stimulus specification doesn't quite
%                   match the actual presentation regime. (Shouldn't
%                   happen, I know, but it seems to for some data sets, to
%                   a small degree.)
%   'xRange', [value]: range of X values for estimating the pRF. Defaults
%                   to -14:.2:14.
%   'yRange', [value]: same as for xRange, but along the Y axis.
%
%
% ras, 10/2006.
if notDefined('param'),     error('Need to specify param name.');	end
if notDefined('vw'),        vw = getCurView;						end
if notDefined('roi'),       roi = viewGet(vw, 'curROI');            end

% params/defaults
rot = 0;

% parse options
varargin = unNestCell(varargin); % allow recursive passing of options
for i = 1:length(varargin)
    if ischar(varargin{i})
        switch lower(varargin{i})
            case 'rot', rot = varargin{i+1};
            case 'x', X = varargin{i+1};
            case 'y', Y = varargin{i+1};
            case 'rmparams', rmParams = varargin{i+1};
        end
    end
end

% test for a view struct being passed in
if ~isfield(vw, 'x0') && isfield(vw, 'viewType')
    if ~checkfields(vw, 'rm', 'retinotopyModels')
        vw = rmSelect(vw, 1);
    end
    rmParams = vw.rm.retinotopyParams;
    model = vw.rm.retinotopyModels{1};
else
    % this is messy, need to reorganize...
    model = vw;
    vw = getCurView;
end

% disambiguate ROI sepecification
if ~isstruct(roi), roi = tc_roiStruct(vw, roi); end

% get indices of coords which correspond to selected voxels
if ismember(roi.viewType, {'Volume' 'Gray'})
    % get the indices corresponding to the ROI, preserving the voxel order
    % (this may take some time and memory for large ROIs)
    I = roiIndices(vw, roi.coords, 1);
    
    ok = find( ~isnan(I) );
    
else
    % not yet implemented for other view types
    error('Sorry, Not Yet Implemented.')
end

% plural/singular flexibility: ignore any 's' at the end of the param name
if lower(param(end))=='s'
    param = param(1:end-1);
end

% get the relevant value for the specified parameter
val = NaN(1, length(I));
switch lower(param)
    case {'amp' 'voxelamplitude' 'voxamp' 'glmbeta'}
        % compute the scale factor which maps from a normalized (-1 - 1
        % range) prediction to the fitted data. This runs a GLM for each
        % voxel in the ROI.
        %
        % I'm going to go ahead and assume vw is a view structure; it's too
        % hard to do this otherwise.
        [tSeries coords] = voxelTSeries(vw, roi.coords, [], 0, 0);
        
        pred = rmGetVoxelData('predictedtseries', vw, roi, varargin);
        
        % we called voxelTSeries with the preserveCoords flag set to zero.
        % This means the tSeries will have some voxels discarded (if
        % there's no data), and the coord order shuffled. Make sure the
        % order of predictions matches this order.
        [coords ok map2roi] = intersectCols(roi.coords, coords); %#ok<*ASGLU>
        pred = pred(:,ok);
        
        % take the prediction and make a design matrix (add trends terms)
        trends = rmMakeTrends(rmParams, prefsVerboseCheck);
        
        % initialize an empty output value
        val = NaN(1, length(I));
        
        % run a GLM for each non-NaN voxel, returning the scale factor
        for v = 1:length(ok)
            p = pred(:,v);
            if all(p==0) || all( isnan(p) )
                continue
            end
            p = p ./ abs(max(p));
            X = [p trends];
            [t df RSS B] = rmGLM(tSeries(:,v), X);
            
            % because of the sorting we introduced in voxelTSeries, the
            % order of tSeries may not match the order of our output amps
            % value. Map this back to the original order of the ROI coords.
            whichVoxel = map2roi(v);
            val(whichVoxel) = B(1);
        end
        
        
    case {'pred' 'prediction' 'predictedtserie'}
        % predicted time series of response based on the pRF for each voxel
        % and the stimulus.
        
        % we need pRF params for each voxel
        X = rmParams.analysis.X;
        Y = rmParams.analysis.Y;
        x0 = zeros(1, length(I));
        y0 = x0;
        sigma = x0;
        beta = x0;
        x0(ok) = model.x0(I(ok));
        y0(ok) = model.y0(I(ok));
        sigma(ok) = model.sigma.major(I(ok));
        beta(ok) = model.beta(1,I(ok),1);
        
        % rotation compensation if selected
        if rot ~= 0
            R = sqrt(x0.^2 + y0.^2);
            theta = atan2(y0, x0);
            theta = theta - deg2rad(rot);
            theta = mod(theta, 2*pi);
            x0 = R .* cos(theta);
            y0 = R .* sin(theta);
        end
        
        % initalize an empty output matrix
        nFrames = size(rmParams.analysis.allstimimages, 1);
        val = NaN(nFrames, length(I));
        
        for v = ok
            pRF = rfGaussian2D(X, Y, sigma(v), sigma(v), 0, x0(v), y0(v));
            val(:,v) = rmParams.analysis.allstimimages * pRF;
        end
        
    case {'prf' 'rf' 'prfs' 'rfs'}
        % we need to find a sampling grid for the pRF.
        if notDefined('X') || notDefined('Y')
            [X Y] = prfSamplingGrid(rmParams);
        end
        
        x0 = zeros(1, length(I));
        y0 = x0;
        sigma = x0;
        beta = x0;
        x0(ok) = model.x0(I(ok));
        y0(ok) = model.y0(I(ok));
        sigma(ok) = model.sigma.major(I(ok));
        beta(ok) = model.beta(1,I(ok),1);
        
        % rotation compensation if selected
        if rot ~= 0
            R = sqrt(x0.^2 + y0.^2);
            theta = atan2(y0, x0);
            theta = theta - deg2rad(rot);
            theta = mod(theta, 2*pi);
            x0 = R .* cos(theta);
            y0 = R .* sin(theta);
        end
        
        % re-initialize the return value as a matrix of NaNs
        val = NaN(size(X, 1), size(X, 2), length(I));
        
        for v = ok
            pRF = rfGaussian2D(X, Y, sigma(v), sigma(v), 0, x0(v), y0(v));
            val(:,:,v) = pRF;
        end
        
    case {'prfvector' 'rfvector' 'prfsvector' 'rfsvector' 'prfvectors' 'rfvectors'}
        % we need to find a sampling grid for the pRF.
        if notDefined('X') || notDefined('Y')
            [X Y] = prfSamplingGrid(rmParams);
        end
        
        x0 = zeros(1, length(I));
        y0 = x0;
        sigma = x0;
        beta = x0;
        x0(ok) = model.x0(I(ok));
        y0(ok) = model.y0(I(ok));
        sigma(ok) = model.sigma.major(I(ok));
        beta(ok) = model.beta(1,I(ok),1);
        
        % rotation compensation if selected
        if rot ~= 0
            R = sqrt(x0.^2 + y0.^2);
            theta = atan2(y0, x0);
            theta = theta - deg2rad(rot);
            theta = mod(theta, 2*pi);
            x0 = R .* cos(theta);
            y0 = R .* sin(theta);
        end
        
        % re-initialize the return value as a matrix of NaNs
        val = NaN(numel(X), length(I));
        
        for v = ok
            pRF = rfGaussian2D(X(:), Y(:), sigma(v), sigma(v), 0, x0(v), y0(v));
            val(:,v) = pRF;
        end
        
        
    case {'x' 'x0'}, val(ok) = model.x0(I(ok));
        
    case {'y' 'y0'}, val(ok) = model.y0(I(ok));
        
    case {'sigma' 'sigmamajor'}, val(ok) = model.sigma.major(I(ok));
        
    case {'sigmaminor'}, val(ok) = model.sigma.minor(I(ok));
        
    case {'theta'}, val(ok) = model.sigma.theta(I(ok));
        
    case {'beta'}, val(ok) = model.beta(1,I(ok),1);
        
    case {'sig' 'log10p' 'logp'}
        allsig = rmGet(model, 'log10p');
        val(ok) = allsig(I(ok));
        
        
    otherwise,
        try
            allvals = rmGet(model, param);
            val(ok) = allvals(I(ok));
        catch %#ok<*CTCH>
            fprintf('[%s] Unknown parameter name %s \n', mfilename, param);
        end
        
end

return

