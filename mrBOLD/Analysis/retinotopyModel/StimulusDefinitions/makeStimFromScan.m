function params = makeStimFromScan(params,id)
% makeStimFromScan - Make stimulus from stored image matrix for solving
% retinotopic model or predicting BOLD response.
%
% params = makeStimFromScan(params,id);
%
% Notes: 
% 
%   This code was written with the intention of using files generated from
%   exptTools stimulus presentation code (such as 'ret'). If you run such
%   code and choose (1) save parameters, and (2) save image matrix, then
%   you will get two files in exactly the format required by this code.
%   Alternatively you can  generate the .mat files with the required
%   fields, as described below.
%
%   The two files the code will look for can be located anywhere with a
%   valid path. However, the GUI 'rmEditStimulusParameters' looks
%   specifically for files within a directory called '[My Project
%   directory]/Stimuli', and it looks for files that contain the string
%   'image' (for the image matrix) and 'param' (for the parameters file).
%
% Inputs:
%       id: scan number (integer)
%
%       params: a struct containing the following fields
%           (normally generated from GUI or stored in dataTYPES)
%
%          Required
%               params.stim(id).imFile*  (filename)
%               params.stim(id).paramsFile** (filename)
%               params.analysis.fieldSize (degrees, radius)
%               params.analysis.numberStimulusGridPoints (n points, radius)
%               params.analysis.sampleRate (degrees per point)
%
%          Optional
%               params.framePeriod (length of TR in s)
%               params.stim(id).nFrames (n TRs in scan)
%               params.prescanDuration (in TRs, not s)
%               params.stim(id).imFilter (default = 'binary');
%                   (see .../retinotopyModel/FilterDefinitions/ for 
%                       other filters)
%
%
%       *imFile:  imfile wil be loaded into struct 'I'
%           Required
%               I.images: an n x m x k matrix. n and m are the image size,
%                           k is the number of unique images.
%                TODO: allow RGB image matrices 
%
%       **paramsFile: paramsfile wil be loaded into struct 'P'.
%           Required
%               P.stimulus.seq: a vector indexing the image matrix I.images
%               P.stimulus.seqTiming: a vector of image onset times (in s)
%
%           Optional
%               P.params.display (screen calibration information)
%           Optional (but nec if not included in input params)
%               P.params.framePeriod (length of TR in s)
%               P.params.numImages (n TRs in scan)
%               P.params.prescanDuration (in s, not TRs)
%
%
% The basic steps are:
%   1. Load the parameter file and image matrix
%   2. Filter the images.
%       The images are saved as grayscale or RGB images, but as a predictor
%       for a BOLD response, we may want to binarize the images (i.e., draw
%       the stimulus aperture), or perform some other kind of filter such
%       as contrast energy. Default is binary.
%   3. Build a sampling grid.
%       (This will usually be coarser than the saved images.)
%   4. Downsample the images to the grid.
%   5. Average all the images within a TR.
%
%
%
% Warning:
% A source of potential confusion: There is an input argument 'params' and
% there is also a parameters file loaded into the structure P. These
% should not be confused. To make matters worse, the struct P has a
% subfield called params. Perhaps there is a better way to do this. But the
% reason for the current scheme is consistency with existing code: Similar
% functions like make8bars, makeWedges, etc, all input and output a struct
% called params. Hence it is useful to do so here. The parameters file that
% is loaded (and that also includes a subfield called 'params') is made by
% stimulus presentation code like 'ret'. Since those structures already
% exist, we use them without modification.
%
% 2008/09 JW: Wrote it.



if notDefined('params'),
    error('[%s]: Need params', mfilename);
end

if notDefined('id'),
    id = 1;
end

% Load the images and parameters from the scan
[P, I]          = subLoadImages(params, id);

% Spatially filter the images
[I, params]     = subFilterImages(I, P, params, id);

% Make a sampling grid
[x, y, params]  = subSamplingGrid (params);

% Spatially downsample the images to the X-Y grid
I               = subSpatialDownsample(I, params);

% Temporally downsample to 1 image per TR (by averaging filtered images)
[images, params]= subTemporalDownsample(I, P, params, id);

% Done. Save the images and return
params.stim(id).images = single(images);
fprintf(1,'[%s]: Done.\n', mfilename);

return;

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Subroutines %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%------------------------------------------------------------------
function [P, I] = subLoadImages(params, id)
%------------------------------------------------------------------
fprintf(1,'[%s]: Loading images: %s...\n', mfilename, params.stim(id).imFile);
fprintf(1,'[%s]: Loading images for scan %d...\n', mfilename, id);

% load the image matrix
if ~checkfields(params, 'stim', 'imFile'),
    error('Need the image matrix saved from scan');
end
imFile      =   params.stim(id).imFile;
if ~exist(imFile, 'file')
    [pth, fname ext] = fileparts(imFile);
    imFile = fullfile('Stimuli', [fname ext]);
end
I = load(imFile);
% TODO: make compatible with RGB images (now assumes grayscale)

% load the stored params (these are different from the input arg params)
if ~checkfields(params, 'stim', 'paramsFile'),
    error('Need the experiment params file from scan');
end
% TODO: absolute path is stored. Perhaps store path relative to data directory.
paramsFile  =    params.stim(id).paramsFile;
if ~exist(paramsFile, 'file')
    [pth, fname ext] = fileparts(paramsFile);
    paramsFile = fullfile('Stimuli', [fname ext]);
end
P = load(paramsFile);

end

%------------------------------------------------------------------
function [I, params] = subFilterImages(I, P, params, id)
%------------------------------------------------------------------
fprintf(1,'[%s]: Filtering images...\n', mfilename);

if ~checkfields(params, 'stim', 'imFilter'),
    params.stim(id).imFilter = 'binary';
end

% try to determine colormap parameters
try
    display = P.params.display;
catch 
    display = [];
    warning('[%s]: No calibration file found. This may affect image filtering.',...
        mfilename);
end

% new filters can be made with the name rmfilter_*
% they should be saved with the other filters in
%    '.../retinotopyModel/FilterDefinitions' 

switch params.stim(id).imFilter
    case 'none'
        I.images = rmfilter_none(I.images, display);
    case 'binary'
        I.images = rmfilter_binary(I.images, display);
    case 'energy'
        I.images = rmfilter_energy(I.images, display);
    case 'thresholdedBinary'
        I.images = rmfilter_thresholdedBinary(I.images, display);
    otherwise
        error('rmfilter_%s does not exist', params.stim(id).imFilter)
end



end

%------------------------------------------------------------------
function [x, y, params] = subSamplingGrid (params)
%------------------------------------------------------------------
% Note: Currently the grid is made from the input struct 'params'.
% It also would be possible to make it from params saved from
% the experiment. However the visual angle might not be right in the stored
% files. So safer to set it manually in the GUI.

nSamples = params.analysis.numberStimulusGridPoints;
mygrid = -params.analysis.fieldSize:params.analysis.sampleRate:params.analysis.fieldSize;

[x,y]=meshgrid(mygrid,mygrid);

% Update the sampling grid to reflect the sample points used.
params.analysis.X = x(:);
params.analysis.Y = y(:);

% Verify that the grid is the expected size.
if length(params.analysis.X) ~= (1+nSamples*2)^2,
    error('[%s]: error in grid creation', mfilename);
end

end

%------------------------------------------------------------------
function I = subSpatialDownsample(I, params)
%------------------------------------------------------------------

fprintf(1,'[%s]: Downsampling images to stimulus grid...\n', mfilename);

nImages = size(I.images, 3);

nSamples = params.analysis.numberStimulusGridPoints;

resampled = zeros(length(params.analysis.X), nImages);

for ii = 1:nImages
    tmp = imresize(I.images(:,:,ii), 1+2*[nSamples nSamples], 'nearest');
    resampled(:, ii) = tmp(:);
end

I.images = resampled;

end

%------------------------------------------------------------------
function [images, params] = subTemporalDownsample(I, P, params, id)
%------------------------------------------------------------------
fprintf(1,'[%s]: Averaging images within a TR...\n', mfilename);

% length of 1 TR
framePeriod = params.stim(id).framePeriod;

% Scan duration (in TRs)
nFrames = params.stim(id).nFrames;

% Prescan duration (in TRs)
if checkfields(P, 'params', 'prescanDuration')
    % Try to get this from the scan, and then set the value in params so
    % that it will be updated in the dataTYPES and GUI.
    % Note that exptTools stores this in s, but the GUI stores it in frames
    params.stim(id).prescanDuration = P.params.prescanDuration / framePeriod;
end
prescanDuration = params.stim(id).prescanDuration;

% Total scan duration (in TRs)
nFrames         = nFrames + prescanDuration;

% Image sequence
seq         = P.stimulus.seq;           %index to image number
seqTiming   = P.stimulus.seqtiming;     %time in s for each image onset

% Temporally downsample
images = zeros(length(params.analysis.X), nFrames);

% Specificy the onset time and offset time of each image frame
imOnset = seqTiming;
imOffset = shift(seqTiming, -1);
imOffset(end) = framePeriod * nFrames;

for f = 1:nFrames
    % specify the onset time and offset time of this TR
    frameOnset  = framePeriod * (f-1);
    frameOffset = framePeriod * f;
    
    % calculate the temporal overlap of each image frame with this TR
    imDur = min(imOffset, frameOffset) - max(imOnset, frameOnset);
    imDur = max(imDur, 0);
    imDur(imDur < .001) = 0;
    img = zeros(size(I.images(:,1)));
    % weighted average (only loop over seq we need)
    ii = find(imDur>0); ii = ii(:)';
    for im = ii
        img = img + imDur(im) * I.images(:, seq(im));
    end
    img = img / framePeriod;
    
    % if images need to be flipped
    if isfield(params.stim(id),'fliprotate'),
        if params.stim(id).fliprotate(1),
            img = fliplr(img);
        end;
        try % (use 'try' because fliprotate might be defined for just one dim) 
            if params.stim(id).fliprotate(2),
                img = flipud(img);
            end;
            if params.stim(id).fliprotate(3)~=0,
                img = rot90(img,params.stim(id).fliprotate(3));
            end;
        end
    end;
    
    images(:,f) = img;
end

end
