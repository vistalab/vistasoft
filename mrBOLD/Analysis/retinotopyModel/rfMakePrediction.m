function [prediction,  weight,  RF] = rfMakePrediction(params, id);
% rfMakePrediction - makes time-series based on rf-profile and image
% sequence.
%
% [prediction,  weight,  rf] = rfMakePrediction(params, id);
%
% input:
%  params  : parameter struct
%  id      : id for grid search [n] or rf-parameters
%            [sigmaMajor,  sigmaMinor,  sigmaTheta,  x0, 0]
%
%

% 2006/01 SOD: wrote it.
% 2006/03 SOD: vectorized.
% 2006/06 SOD: moved Hrf convolution out of this function to rmMakeStimulus.
% 2007/04 RAS: revert to version 1.15 in repository; this restores the
% making of the RF, based on the id params. It seems that removing that
% part made the function obsolete (it was just a multiplication), and also
% broke the RF visualization code, so for now I'm restoring it. 

% Programming note: This function is at the heart of the retinotopy
% model program and will be called lots. It is now vectorized so we
% can make all RFs in advance.

% Make (several) receptive field profiles. 
% Ugly input check allowing different kinds of inputs.
if numel(id)==1, 
    % if id == 0 then we make all the RFs
    if ~id, 
        RF =  rfGaussian2d(params.analysis.X, params.analysis.Y, ...
                            params.analysis.sigmaMajor, ...
                            params.analysis.sigmaMajor, ...
                            0, ...
                            params.analysis.x0,  ...
                            params.analysis.y0);
                        
    else,  % we make just a particular one
        RF =  rfGaussian2d(params.analysis.X, params.analysis.Y, ...
                            params.analysis.sigmaMajor(id), ...
                            params.analysis.sigmaMajor(id), ...
                            0, ...
                            params.analysis.x0(id),  ...
                            params.analysis.y0(id));
                        
    end;
    
elseif numel(id)==5, 
    RF =  rfGaussian2d(params.analysis.X, params.analysis.Y, ...
        id(1), id(2), id(3), id(4), id(5));
    
else,  % make lots
    RF =  rfGaussian2d(params.analysis.X, params.analysis.Y, ...
        id(:, 1), id(:, 2), id(:, 3), id(:, 4), id(:, 5));
end;

% Now we have to loop over each stimulus to convolve it with the RF. The
% stimulus is already convolved with the Hrf so we don't have to do that
% here,  also removing of initial time frames and time averaging is
% moved to the stimulus creation.
prediction = params.analysis.allstimimages * RF;

% compute the amount within the stimulus window to weight the
% fit
if nargout > 1, 
    weight = sum(RF);
end;

return;