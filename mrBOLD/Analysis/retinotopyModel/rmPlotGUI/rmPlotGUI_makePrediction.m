function [prediction, RFs, rfParams, varexp blanks] = rmPlotGUI_makePrediction(M, coords, voxel)
% Create predicted time series and pRFs for a voxel in the rmPlotGUI. 
%   [prediction, RFs, rfParams, varexp] = rmPlotGUI_makePrediction(M, voxel);
%
%
% 11/2008 RAS: broken off rmPlotGUI function.
% 10/2009 RAS: doesn't require the UI structure anymore
if notDefined('voxel')
    voxel     = get(M.ui.voxel.sliderHandle, 'Value');
end
    
% Get model and info
model     = M.model{M.modelNum};
modelName = rmGet(model, 'desc');
coords	  = M.coords(:,voxel);

% get variance explained
varexp = rmCoordsGet(M.viewType, model, 'varexp', coords);

% check the GUI settings to see if we want to recompute the prediction's
% fit
if checkfields(M, 'ui', 'recompFit')
    recompFit = isequal( get(M.ui.recompFit, 'Checked'), 'on' );
else
    recompFit = 1;
end

% varexp of zero indicates that there is no pRF: all the params are 0. If
% we go through the code below, it will error (NaNs get introduced). Don't
% bother -- we know the return values are empty:
if varexp==0
	nTimePoints = size(M.params.analysis.allstimimages, 1);
	prediction  = zeros(nTimePoints, 1);
	gridSize    = size(M.params.analysis.X(:), 1);
	RFs         = zeros(gridSize, 1);
	rfParams    = zeros(1, 6);
    blanks      = [];
	return
end

%% get RF parameters from the model
rfParams = rmPlotGUI_getRFParams(model, modelName, M.viewType, coords, M.params);

%% adjust parameters if requested
if checkfields(M, 'ui', 'movePRF')
    rfParams = movePRF(M, rfParams, voxel);
end

%% make RFs
RFs = rmPlotGUI_makeRFs(modelName, rfParams, M.params.analysis.X, M.params.analysis.Y);
        
%% make predictions for each RF
pred = M.params.analysis.allstimimages * RFs;

% Determine which frames have no stimulus. We may want to use this
% information to highlight the blanks in the time series plots. We need to
% determine blanks from the original images, not the images that have been
% convolved with the hRF.
stim = [];
for ii = 1:length(M.params.stim)
   endframe = size(M.params.stim(ii).images_org, 2);
   frames =  endframe - M.params.stim(ii).nFrames+1:endframe;
    stim = [stim M.params.stim(ii).images_org(:, frames)];
end
blanks = sum(stim, 1) < .001;

%% get/make trends
[trends, ntrends, dcid] = rmMakeTrends(M.params, 0);
if isfield(M.params.analysis,'allnuisance')
    trends = [trends M.params.analysis.allnuisance];
end

%% Compute final predicted time series (and get beta values)
% we also add this to the rfParams, to report later
switch modelName,
    case {'2D pRF fit (x,y,sigma, positive only)',...
          '2D RF (x,y,sigma) fit (positive only)',...
          '1D pRF fit (x,sigma, positive only)'};
        if recompFit==0,
            beta = rmCoordsGet(M.viewType, model, 'b', coords);
            beta = beta([1 dcid+1])';
            
        else
            beta = pinv([pred trends(:,dcid)])*M.tSeries(:,voxel);
            beta(1) = max(beta(1),0);
            
        end

        RFs        = RFs .* (beta(1) .* M.params.analysis.HrfMaxResponse);

        rfParams(4) = beta(1);


    case {'2D pRF fit (x,y,sigma_major,sigma_minor)' ...
			'oval 2D pRF fit (x,y,sigma_major,sigma_minor,theta)'};
        if recompFit==0,
            beta = rmCoordsGet(M.viewType, model, 'b', coords);
            beta = beta([1 dcid+1]);
        else
            beta = pinv([pred trends(:,dcid)])*M.tSeries(:,voxel);
            beta(1) = max(beta(1),0);
            
        end

        RFs        = RFs .* (beta(1) .* M.params.analysis.HrfMaxResponse);

        rfParams(4) = beta(1);

    case 'unsigned 2D pRF fit (x,y,sigma)';
        if recompFit==0,
            beta = rmCoordsGet(M.viewType, model, 'b', coords);
            beta = beta([1 dcid+1]);
        else
            beta = pinv([pred trends(:,dcid)])*M.tSeries(:,voxel);
        end

        RFs        = RFs .* (beta(1) .* M.params.analysis.HrfMaxResponse);
        
        rfParams(4) = beta(1);

   case {'Double 2D pRF fit (x,y,sigma,sigma2, center=positive)',...
         'Difference 2D pRF fit (x,y,sigma,sigma2, center=positive)',...
         'Difference 1D pRF fit (x,sigma, sigma2, center=positive)'},
        if recompFit==0,
            beta = rmCoordsGet(M.viewType, model, 'b', coords);
            beta = beta([1 2 dcid+2]);
            beta = beta';
        else
            beta = pinv([pred trends(:,dcid)])*M.tSeries(:,voxel);
            beta(1) = max(beta(1),0);
            beta(2) = max(beta(2),-abs(beta(1)));
         end

        RFs        = RFs * (beta(1:2).*M.params.analysis.HrfMaxResponse);

        rfParams(:,4) = beta(1);
		
    case {'Two independent 2D pRF fit (2*(x,y,sigma, positive only))'},
        if recompFit==0,
            beta = rmCoordsGet(M.viewType, model, 'b', coords);
            beta = beta([1 2 dcid+2]);
        else
            beta = pinv([pred trends(:,dcid)])*M.tSeries(:,voxel);
            beta(1:2) = max(beta(1:2),0);
        end

        RFs        = RFs * (beta(1:2) .* M.params.analysis.HrfMaxResponse);

        rfParams(:,4) = beta(1:2);
        rfParams = rfParams(1,:);
		
   case {'Mirrored 2D pRF fit (2*(x,y,sigma, positive only))'},
        if recompFit==0,
            beta = rmCoordsGet(M.viewType, model, 'b', coords);
            beta = beta([1 dcid+1]);
        else
            beta = pinv([pred trends(:,dcid)])*M.tSeries(:,voxel);
            beta(1) = max(beta(1),0);
        end

        RFs        = RFs * (beta(1) .* M.params.analysis.HrfMaxResponse);

        rfParams(:,4) = beta(1);
        rfParams = rfParams(1,:);
		
  case {'Sequential 2D pRF fit (2*(x,y,sigma, positive only))'},
        if recompFit==0,
            beta = rmCoordsGet(M.viewType, model, 'b', coords);
            beta = beta([1 2 dcid+2]);
        else
            beta = pinv([pred trends(:,dcid)])*M.tSeries(:,voxel);
            beta(1:2) = max(beta(1:2),0);
       end

        RFs        = RFs * (beta(1:2) .* M.params.analysis.HrfMaxResponse);

        rfParams(:,4) = beta(1:2);
        rfParams = rfParams(1,:);
    case {'fitprf'}
        % this is how we calculate the time-series
        %   y = gain * (prf (dot) stimulus) ^ (exponent)
        % get some parameters from the model for this voxel:
        gain     = rfParams(8); % this was defined in rmPlotGUI_getRFParams
        exponent = rfParams(7); % this was defined in rmPlotGUI_getRFParams        
        hrf      = M.model{1}.hrf(:, coords);

        if length(hrf) ==1, hrf = 1; end
        
        % start a counter so we can loop across the scans
        firstframe = 1;
        
        % this is the stimulus across all scans, without hrf convolution
        stim = M.params.analysis.allstimimages;
        
        % loop across scans
        for scan = 1:length(M.params.analysis.scans)
            % get the frames for this scan
            nframes = M.params.stim(scan).nFrames;
            theseframes = firstframe:firstframe + nframes -1; 
            firstframe  = max(theseframes) + 1;
            
            % calculate the time series
            p{scan} = gain * (stim(theseframes,:) * RFs) .^ exponent;
            
            % convolve with hRF
            p{scan} = conv(p{scan}, hrf, 'full');
            p{scan} = p{scan}(1:nframes);
            
            % number of polynomial trends
            npoly = M.params.stim(scan).nDCT - 1;
            
            % project out polynomial trends
            if npoly > 0  % if we have npoly == 0, we probaly do not want to detrend at all

                p{scan} = projectionmatrix( ...
                    constructpolynomialmatrix(nframes,0:npoly))*p{scan};            
            end

        end
        
        pred = catcell(1, p);
        
        % beta will be requested outside the switch/case, in a
        % model-general part of the code. in standard prf models the first
        % beta value is the gain, but in fitprf models the gain is stored
        % separately, and is already in the equation above. so we make the
        % first beta value one. the beta struct will need another scalar
        % for each scan, and we make these all zeros. these beta values are
        % for the DC term, but we do not need it; we will plot the
        % detrended prediction and the detrended time series. 
        % baseline of zero.
        beta = [1 zeros(size(dcid))]';
        
        
        
   otherwise,
        error('Unknown modelName: %s', modelName);
end;

% Calculate the prediction
prediction = [pred trends(:,dcid)] * beta;

% Convert to percent signal specified in the model, and we do not recompute
% fit (if we recompute fit, the prediction will already be in % signal)
if M.params.analysis.calcPC && ~recompFit
    % Only do this if the prediction is not already in % signal. We check
    % whether the signal is in % signal. If it is the mean should be
    % near-zero. So: 
    if abs(mean(prediction))>0.1 % random picked number (0.001 is too low)
        fprintf('[%s]:WARNING:converting prediction to %% signal even though recompFit=false.\n',mfilename);
        prediction  = raw2pc(prediction);
    end
end


% recompute variance explained (do we need to do this?)
if recompFit==1
	rss = sum((M.tSeries(:,voxel)-prediction).^2);
	rawrss = sum(M.tSeries(:,voxel).^2);
else
	rss = rmCoordsGet(M.viewType, model, 'rss', coords);
	rawrss = rmCoordsGet(M.viewType, model, 'rawrss', coords);
end

% sometimes rawss > rss. This can happen when the pRF is empty, and the
% prediction is just the trend: the trend doesn't actually help always.
% in this case, the varexp is zero, not negative:
varexp = max(1 - rss./rawrss, 0);
% varexp = 1 - rss ./ rawrss;

return
% ---------------------------------------------------------------



% ---------------------------------------------------------------
function rfParams = movePRF(M, rfParams, voxel)
% Subroutine to manually alter the pRF center for visualizing other fits.
% The stored model is not altered. 
%
% This is constrained right now to the circular Gaussian case. This is
% mainly because of simple contraints of space in the GUI window for adding
% more sliders. I think a better long-term solution is to break off a
% separate subfunction, expressly designed for editing a single pRF, which
% would lack the voxel slider, and a number of other options, but would
% have sliders for sigma major/minor, theta (angle b/w axes), etc. (ras)

%% has the selected voxel changed?
if voxel ~= M.prevVoxel 
	% let's update the 'pRF adjust params' sliders to match the new voxel.
	% (we'll wait until the user adjusts one of the sliders to modify
	% rfParams.)
	mrvSliderSet(M.ui.moveX, 'Value', rfParams(1));
	mrvSliderSet(M.ui.moveY, 'Value', rfParams(2));
	mrvSliderSet(M.ui.moveSigma, 'Value', rfParams(3));
	return;  
end

%% if we got here, we haven't changed the voxel: 
% we can adjust the rfParams, *if* the option is selected...

% test whether the 'adjust PRF' option is selected
if isequal( get(M.ui.movePRF, 'Checked'), 'on' )
	% either manually move the pRF according to slider values...
	mrvSliderSet(M.ui.moveX, 'Visible', 'on');
    mrvSliderSet(M.ui.moveY, 'Visible', 'on');
	mrvSliderSet(M.ui.moveSigma, 'Visible', 'on');
    rfParams(1) = get(M.ui.moveX.sliderHandle, 'Value');
    rfParams(2) = get(M.ui.moveY.sliderHandle, 'Value');
	rfParams(3) = get(M.ui.moveSigma.sliderHandle, 'Value');
	rfParams(5) = rfParams(3);   % circular case
	
else
	% ... or use stored values  (and keep the sliders hidden)
    mrvSliderSet(M.ui.moveX, 'Visible', 'off');
    mrvSliderSet(M.ui.moveY, 'Visible', 'off');
    mrvSliderSet(M.ui.moveSigma, 'Visible', 'off');

end

return



%---------------------------------
function data=raw2pc(data)
dc   = ones(size(data,1),1)*mean(data);
data = ((data./dc) - 1) .*100;
return;
%---------------------------------

