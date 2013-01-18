function params = rmMakeStimulus(params, keepAllPoints)
% rmMakeStimulus - make stimulus sequence
%
% params = rmMakeStimulus(params, [keepAllPoints=0]);
%
% This program makes the stimulus sequence for each stimulus.
% This will be used to predict the response profiles of certain
% receptive fields: response = pRF.*stim (rmMakePrediction)
%
% keepAllPoints is an optional flag specifying whether or not to restrict
% the stimulus representations to the set of pixels for which a stimulus
% was shown. This step is important for solving the pRF model: the logic is
% that if no stimulus was ever shown at a particular pixel, there can be no
% way the data can distinguish whether the pRF should cover that position.
% Removing the un-stimulated pixels when vectorizing the stimulus fields
% makes the process much more efficient.
%
% However, the RM params and stimulus representations are now used for
% other purposes than solving the model. For these purposes, restricting
% the stimulus can create difficulties. (One example: when titrating the
% width of stimuli, such as bars, some widths will cause more or fewer
% pixels to be sampled. For the sparser sampling, reconstructing the
% stimulus on the sampling grid is no longer possible, because so many
% sampled points are lost.)
%
% 12/2005 SOD: wrote it.
if notDefined('keepAllPoints'),	
    if isfield(params.analysis,'keepAllPoints')
        keepAllPoints = params.analysis.keepAllPoints;
    else
        keepAllPoints = false;
    end
end

% TODO:
% Would be kind of cool to use the actual stimulus program when possible.

%-------------------
% Allow different stimuli. Stimulus parameters are defined as
% params{stim}.m and the programs to make them are saved as
% make{stim}.m thus to make them simply do:
% eval(['make' params.stim(n).stimType '(params,',num2str(n),');']);
%
% In order to speed things up we need to limit the representation of the
% stimulus (square matrix) to those points that fall within the stimulus
% window (non square - mostly circular). For a circle stimulus this will be
% about 25%. This will be done for (a) the stimulus, (b) the grid used to
% make the pRFs.
% A further speed improvement can be achieved by convolving with the Hrf
% now time since we do it once for the stimulus rather than for *every*
% prediction. The end result it the same because it is linear: we can do
% images*Hrf*(pRF loop) instead of the conceptual order of images*(pRF
% loop)*Hrf.
%-------------------

% calculate wich points are in the stimulus window (of any of the stimulus
% sequences)
for n=1:numel(params.stim),
    params = eval(['make' params.stim(n).stimType '(params,',num2str(n),');']);
    if n==1,
        params.stim(1).stimwindow = nansum(params.stim(n).images,2);
    else
        params.stim(1).stimwindow =  params.stim(1).stimwindow + ...
            nansum(params.stim(n).images,2);
    end
end;

if keepAllPoints
	% mark all pixels as pixels to keep
	params.stim(1).stimwindow(:) = 1;
    params.stim(1).instimwindow = find(params.stim(1).stimwindow==1);
else
	params.stim(1).stimwindow = params.stim(1).stimwindow > 0;
	params.stim(1).stimwindow = params.stim(1).stimwindow(:);
	params.stim(1).instimwindow = find(params.stim(1).stimwindow==1);
end

%-------------------
% Now only keep points within stimulus window and convolve with the Hrf.
% Convolving with the Hrf now saves time since we do it once for the
% stimulus rather than for *every* prediction. The end result it the same
% because it is linear: we can do images*Hrf*pRF instead of the conceptual
% order of images*pRF*Hrf.
% Because we convolve with the Hrf we don't need the initial
% time-frames any more and we can time average too.
% lastly we create one all-stimulus set of images.
%
% Now if we want to the output amplitude (beta) to be in
% %BOLD/degree2. Then a convenient place to do that is here. We
% need to take into account the sampling of the stimulus. Thus, if
% we want 1degree2 of stimulus to yield 1 %BOLD signal change
% (volume - not amplitude) we need to scale the original binary
% stimulus sequence by the sample rate: images*samplerate
%-------------------
keep = params.stim(1).instimwindow;
for n=1:length(params.stim),
    % keep image points within stimulus window
    params.stim(n).images   = params.stim(n).images(keep,:);
    
    % keep original image sequence, just in case we want to view it later
    params.stim(n).images_org = params.stim(n).images;
    
    % now scale amplitude according to the sample rate:
    params.stim(n).images = params.stim(n).images.*(params.analysis.sampleRate.^2);
    
    % jitter images to account for eye movement if offset data exists
    params.stim(n) = rmJitterImages(params.stim(n), params);
    
    % now convolve with Hrf
    params.stim(n).images = filter(params.analysis.Hrf{n}, 1, params.stim(n).images');
    
    % limit to actual MR recording.
    params.stim(n).images = params.stim(n).images(params.stim(n).prescanDuration+1:end,:);
    
    % and time averaging
    params.stim(n).images = rmAverageTime(params.stim(n).images, ...
                                          params.stim(n).nUniqueRep);
    
    % rotate so we can easily create an average stimulus image matrix
    params.stim(n).images = params.stim(n).images';
end;

% matrix with all the different stimulus images.
params.analysis.allstimimages = [params.stim(:).images]';

% the stimulus generation file can specify nuisance factors (e.g. large
% fixation changes) that should be removed from the data.
if isfield(params.stim,'nuisance'),
    params.analysis.allnuisance = [params.stim(:).nuisance]';
end

% we don't really need to keep the individual stimuli, we should
% really incorporate that in the previous loop but let's just see
% if our assumption is true (2006/07). Well it is true, but we
% still might want to keep this so we can later visualize what the
% stimulus was and how it was defined.
%for n=1:length(params.stim),
%    params.stim(n).images = [];
%end;

% We limit the x,y coordinates to the stimulus window too: 
% This has several advantages: 
% 1) It will allow to remove points that are not used, e.g. due to a
% circular window (see rmMakeStimulus).
% 2) It creates a 1D pRF matrix and making the prediction is reduced to a
% matrix multiplication.
% We do that here and not in rmDefineParameters so any make'stimulus'
% program that will be called earlier in rmMakeStimulus (above)program
% deals with an intuitive 2D matrix.
params.analysis.X = params.analysis.X(keep);
params.analysis.Y = params.analysis.Y(keep);


% Correct for off-center (real or simulated) fixation. This is not necesary
% for 1 Gaussian models (easier and more flexible to do afterwards), but is
% required for more complex models that are mirrored around central axes.
% Potential later errors are when we recreate X and Y instead of loading
% it!
if isfield(params.analysis,'fixationCorrection')
    fprintf('[%s]:Shifting X (+%.2f) and Y (+%.2f) axis!\n',mfilename,...
        params.analysis.fixationCorrection(1),...
        params.analysis.fixationCorrection(2));
    params.analysis.X = params.analysis.X + params.analysis.fixationCorrection(1);
    params.analysis.Y = params.analysis.Y + params.analysis.fixationCorrection(2);
end

return;

