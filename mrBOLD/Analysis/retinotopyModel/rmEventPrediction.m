function [voxAmps, tS] = rmEventPrediction(mv, rmParams, anal, voxels, roi);
% rmEventPrediction - compute a set of predicted voxel amplitudes 
% and time series for a  set of voxels, given their retinotopy parameters.
%
%  [voxAmps tS] = rmEventPrediction(mv, rmParams, anal, [voxels=all], [roi=1]);
%
% The 'mv' struct is a multivoxel struct, created by mv_init or
% multiVoxelUI.
%
% The anal struct is the output from rmVisualizeRFs. The voxels flag
% specifies the voxels for which to make predictions (defaulting to all
% voxels in the current ROI), and the roi flag specifies which ROI to make
% predictions for in the anal struct (default is the first one). 
%
% ras, 09/2006.
if nargin<3, error('Not enough input args.');               end
if notDefined('roi'),    roi = 1;                           end
if notDefined('voxels'), voxels = 1:length(anal.x0{roi});   end

nConds = sum(mv.trials.condNums>0);
nVoxels = length(voxels);

% % to properly normalize the voxel amplitudes, we need
% % to divide by a measure of the number of samples per square degree:
% % the idea is that the density per deg^2 is constant over time, but
% % sampling may change.
% dX = unique(diff(anal.X(:))); dY = unique(diff(anal.Y(:)));
% dX = dX(2); dY = dY(2); % should be at least 2 unique vals, 0 and step size
% samplesPerDeg2 = ceil( [1/dX] * [1/dY] );

% get image masks
xRange = unique(anal.X); yRange = unique(anal.Y);
[rmParams images] = rmStimulusMatrix(rmParams, xRange, yRange, 0);

%%%%% compute voxAmps
fprintf('[%s] Computing predicted voxel amplitudes ', mfilename);
for c = 1:nConds
    mask = logical( round(images(:,:,c)) );

    for v = 1:nVoxels    
        ii = voxels(v);
        sigma = anal.sigma{roi}(ii);
        x0 = anal.x0{roi}(ii);
        y0 = -anal.y0{roi}(ii);
        beta = anal.beta{roi}(ii);
        RF = rfGaussian2D(anal.X, anal.Y, sigma, sigma, 0, x0, y0);
		
        % multiply by the two stimulus representations
        voxAmps(v,c) = sum( RF(mask) ); % / [sum(mask(:))/samplesPerDeg2];
    end
    
    fprintf('.');
end
fprintf(' done.\n');

%%%%% using voxAmps as scaling betas, compute predicted tSeries
erParams = mv.params; erParams.glmHRF = -1; % delta function only
X = glm_createDesMtx(mv.trials, erParams);
X = X(:,2:end); % remove null condition onsets
nFrames = size(X, 1);
betas = ones(1, size(X,2)); % note this is beta for the prediction, not the 
                            % retinotopy model
							
% if multiple trials are specified for each event (block-design),
% replicate the non-null trials the appropriate # of times
if erParams.eventsPerBlock>1
    % first, figure out how many times to replicate each onset:
    % For now, let's assume 'eventsPerBlock' directly specifies 
    % this number:
    nRep = erParams.eventsPerBlock;
    
    for i = 1:nConds
        for j = find(X(:,i))' % for each onset in this column
            rng = j:j+nRep-1;
            rng = rng(rng>1 & rng<size(X,1));
            X(rng,i) = 1;
        end                        
    end
end
							
for v = 1:nVoxels
    betas(1:nConds) = voxAmps(voxels(v),:);
%     timeSeries = conv2(X * betas', rmParams.analysis.Hrf{1}, 'full'); 
    timeSeries = filter(rmParams.analysis.Hrf{1}, 1, X * betas');
    tS(:,v) = timeSeries(1:nFrames);
end

% remove NaNs
voxAmps( isnan(voxAmps) ) = 0;
tS( isnan(tS) ) = 0;

return





% %% alternate method to above: simply get the two main inputs:
% % pRFs: matrix of size [voxels] x [visual pixels]
% % images: matrix of size [visual pixels] x [conditions]
% % and multiply them. Should be the same as the above loop (w/o betas).
% 
% % get pRFs, vectorize
% sigma = anal.sigma{roi}(voxels);
% x0 = anal.x0{roi}(voxels);
% y0 = anal.y0{roi}(voxels);
% beta = anal.beta{roi}(voxels);
% for v = 1:nVoxels
% 	pRF = rfGaussian2D(anal.X, anal.Y, sigma(v), sigma(v), 0, x0(v), y0(v));
% 	pRFs(v,:) = beta(v) * pRF(:);
% end
% 
% % vectorize masks
% masks = reshape(images(:), [size(pRFs, 2) nConds]);
% 
% % multiply
% voxAmps = pRFs * masks;
% 



