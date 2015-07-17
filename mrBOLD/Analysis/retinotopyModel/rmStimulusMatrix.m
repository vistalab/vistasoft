function [params, M] = rmStimulusMatrix(params, xRange, yRange, playMovie, useFinalImages, scans)
% rmStimulusMatrix - create  a 3-D matrix M depicting the stimulus
%
% [params, M] = rmStimulusMatrix([params], [xRange], [yRange],...
%                               [playMovie=2], [useFinalImages=false], [scan]);
%
% Given a set of retinotopy model parameters, produce
% a 3-D matrix M depicting the stimulus at each time frame.
%
% The size of M is szX by szY by nImages, where szX and szY are the
% size of xRange and yRange, respectively. If either
% xRange or yRange is omitted, the code will guess based on the 
% analysis params.
%
% If playMovie is 1, plays the movie using the mplay tool.
% If 2, displays it using displayVol.
% 
% If useFinalImages is true, displays the processed images, not the original.  
% This includes eye-movement jitter and HRF. If false, displays the
% original (unprocessed) images.
%
% If params are omitted, gets from current view. Returns a modified set of
% parameters, in which the params.stim(s).images3D field for each entry s in
% stim contains a 3D matrix for those images. Optionally returns the matrix
% M, containing the images concatenated across all scans.
%
% Examples:
%   rmStimulusMatrix(viewGet(VOLUME{1}, 'rmparams'), [], [], 2);
%   rmStimulusMatrix(viewGet(VOLUME{1}, 'rmparams'), [], [], 2, true);
%
% ras, 08/2006.
if nargin<1, help(mfilename); error('Not enough input args.'); end

if notDefined('playMovie'), playMovie = 2; end

if notDefined('useFinalImages'), useFinalImages = false; end

if notDefined('xRange') || notDefined('yRange')
    % get from analysis params
    xRange = unique(params.analysis.X);
    yRange = unique(params.analysis.Y);
end

if notDefined('scans'), scans = 1:length(params.stim); end

M = [];

[X Y] = meshgrid(xRange, yRange);

% compute the indices I which correspond to the sampling locations
% in params.stim(:).images_org ...
modelCoords = [params.analysis.Y(:) params.analysis.X(:)];
imageCoords = [Y(:) X(:)];
[commonCoords Ia Ib] = intersectCols(imageCoords', modelCoords');


for ii = 1:length(scans)    
    s = scans(ii);
    nFrames = size(params.stim(s).images, 2);
    
    if ~useFinalImages
        % SOD: To get the raw stimulus that was actually used:
        % params.stim(s).images: used for model fit but are already
        %  convolved with hemodynamic response function. Not what we want.
        % params.stim(s).images_org: original (unconvolved images). This is
        % what we want to show. But they are not clipped to the actual
        % recording range and averaged so we'll do that first.
        rng = params.stim(s).prescanDuration+1:size(params.stim(s).images_org,2);
        presentedImages  = params.stim(s).images_org(:,rng);
    else
        % We show the filtered (processed) images, not the original
        % Good for viewing jittered or effects of HRF.
        presentedImages  = params.stim(s).images;
        presentedImages = repmat(presentedImages,1, params.stim(s).nUniqueRep);
    end

    % average
    presentedImages  = rmAverageTime(presentedImages', params.stim(s).nUniqueRep)';
    
    for f = 1:nFrames
        img = zeros(size(X));
        img(Ia) = presentedImages(Ib,f);
        M = cat(3, M, single(img));
    end

    % add the frames for the most recent scan to the params struct
    if nargout >= 1
        params.stim(s).images3D = M(:,:,end-nFrames+1:end);
    end
end


if     playMovie==1, implay(M .* 255);
elseif playMovie==2, displayVol(M);
end



return


% ALTERNATE CODE:
% This interpolates the values, which is more formally proper
% (esp. if the sampling grid provided doesn't sync up w/ the
% sampling grid used by the analysis), but a lot slower and more
% memory-hungry...
% method = 'nearest';
% 
% %% step 1: get images at the locations specified by the analysis params
% [modelX modelY] = meshgrid(params.analysis.X, params.analysis.Y);
% win = params.stim(1).instimwindow;
% for s = 1:length(params.stim)    
%     modelM{s} = []; % for each stimulus, the images at the model sampling rate
%     nFrames = size(params.stim(s).images, 2);
%     for f = 1:nFrames
%         img = zeros(size(modelX));
%         img(win) = params.stim(s).images_org(:,f);
%         modelM{s} = cat(3, modelM{s}, logical(round(img)));
%     end
% end
% 
% 
% %% step 2: resample at the specified X, Y locations
% % get a grid of sampling points for each slice
% [X Y Z] = meshgrid(xRange, yRange, f);
% 
% % interpolate at each point
% for s = 1:length(params.stim)    
%     nFrames = size(params.stim(s).images, 2);
%     for f = 1:nFrames
%         img = interp3(modelM{s}(:,:,f), X, Y, Z, method);
%         M = cat(3, M, logical(round(img)));
%     end
% 
%     % add the frames for the most recent scan to the params struct
%     if nargout >= 1
%         params.stim(s).images3D = M(:,:,end-nFrames+1:end);
%     end
% end


% OLD CODE:
% [X Y] = meshgrid(xRange, yRange);
% 
% % compute the indices I which correspond to the sampling locations
% % in params.stim(:).images_org ...
% modelCoords = [params.analysis.Y params.analysis.X];
% imageCoords = [Y(:) X(:)];
% [commonCoords Ia Ib] = intersectCols(imageCoords', modelCoords');
% 
% for s = 1:length(params.stim)    
%     nFrames = size(params.stim(s).images, 2);
%     for f = 1:nFrames
%         img = zeros(size(X));
%         img(Ia) = params.stim(s).images_org(Ib,f);
%         M = cat(3, M, logical(round(img)));
%     end
% 
%     % add the frames for the most recent scan to the params struct
%     if nargout >= 1
%         params.stim(s).images3D = M(:,:,end-nFrames+1:end);
%     end
% end
% 
% 
% if playMovie==1
%     mplay(M .* 255);
% elseif playMovie==2
%     displayVol(M);
% end

    


