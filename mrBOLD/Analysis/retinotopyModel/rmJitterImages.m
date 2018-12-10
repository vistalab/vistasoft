function stim = rmJitterImages(stim, params)
% Offset a retinotopic mapping stimulus to compensate for eye position. 
%
%   stim = rmJitterImages(stim, params)
% 
% The eye movements are read from a file in stim.jitterFile. This file
% contains two variables, x and y, that indicate the x and y positions of
% the jitter across temporal samples. The number of time samples in the eye
% position must much the number of volume acquisitions (TRs), which are
% ordinarily matched to the number of stimulus frames. 
% 
% Eye movement position is encoded in visual angle, with one (x, y)
% coordinate pair per stimulus frame (or TR). 
%
% 12/2008: JW
%
% When describing the stimulus in the vista UI (Analsysis || Retinotopic
% Model || Set Parameters), any matlab file located in the directory
% 'Stimuli' and containing the string 'jitter' in the name will be
% available in the drop down menu for image jitter.
%
% An example of building a jitter file:
%   A scan had 96 frames + 5 pre-scan (removed) frames.
%   The subject fixated 3 deg to the right and above fixation for the
%   entire scan.
%
%   nFrames = 101;
%   deg = 3;
%   x = ones(1, nFrames) * deg;
%   y = ones(1, nFrames) * deg;
%   save Stimuli/jitter3deg101frames x y;
%
% Example to simulate random eye movements with a standard deviation of 1
% deg:
%
%


%% If no eye movement data, return without doing anything
if ~checkfields(stim, 'jitterFile'), return; end
[p, n, e] = fileparts(stim.jitterFile);
if strcmpi(n,'none'), return; end  % A filename of None returns

%% Build jittered images

% Parse eye eyePosition data
[x, y] = parseEyePositionData(stim);

% Get stimulus mesh grid in visual angle
[m n step] = prfSamplingGrid(params);
nrows = size(m,1); ncols = size(m, 2);

% Convert eye positions from degrees to pixels 
%   Note that x must be negated, since a positive shift in x means a
%   rightward eye position (and hence a leftward shift in the image),
%   and leftward image shifts are represented by negative numbers. But
%   y is not negated, since a positive shift in y means an upward eye
%   movement (and hence a downward shift in the image), and downward
%   image shifts are represented by positive numbers.
x = -round(x / step);
y = round(y / step);

% Initialize an image of the correct 2D dimenstions
im = zeros(size(m));
inStimWindow = params.stim(1).instimwindow;

% Jitter stimulus frame-by-frame to compensate for eye position
for f = 1:stim.nFrames
    % Reshape image from 1D to 2D
    im(inStimWindow) = stim.images(:, f);
    
    % Jitter in opp direction to eye movement

    imShifted = zeros(size(im));
    
    % We can shift in 4 possible ways:
    if x(f) >= 0 
        xShifted = 1:ncols-x(f); xUnshifted =  x(f)+1:ncols;
    else
        xShifted = -x(f)+1:ncols; xUnshifted =  1:ncols+x(f);
    end
    
    if y(f) >= 0 
        yShifted = 1:nrows-y(f); yUnshifted =  y(f)+1:nrows;
    else
        yShifted = -y(f)+1:nrows; yUnshifted =  1:nrows+y(f);
    end
    
    imShifted(yShifted, xShifted) = im(yUnshifted, xUnshifted);
    
    % Reshape from 2D to 1D
    stim.images(:, f) = imShifted(inStimWindow);
end

% --------------------------------------------------------------
%% test (un-comment to view jittered images as they are created)
% im = zeros(size(m));
% range = mrvMinmax(stim.images(:));
% for f = 1:stim.nFrames
%     % reshape image from 1D to 2D
%     im(inStimWindow) = stim.images(:, f);
%     figure(99);
%     imagesc(im, range);
%     axis image off;
%     pause(0.05)
% end
%---------------------------------------------------------------

return


function [x, y] = parseEyePositionData(stim)
% Read the stimulated eye positions

if ischar(stim.jitterFile)
    tmp = load(stim.jitterFile);
    x = tmp.x; y = tmp.y;
end

if length(x) ~= length(y), error('x/y eye positions not matched'); end

nFrames = size(stim.images,2);
if length(x) < nFrames
    error('Eye movement length (%d) less than nFrames (%d)\n',length(x),nFrames);
elseif length(x) > nFrames
    fprintf('Eye movement length (%d) too long. Truncating to (%d).\n',length(x),nFrames);
    x = x(1:nFrames);
    y = y(1:nFrames);
end

return;



