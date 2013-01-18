function [X, nh] = eventDeconvolutionMatrix(S,frameWindow)
%
% [X, nh] = eventDeconvolutionMatrix(S,frameWindow)
%
% Create a stimulus matrix to use for applying 
% a GLM in which estimated trial time courses
% are produced, using the 'selective averaging'
% technique of Buckner et al (1998).
%
% S: binary matrix specifying event onsets, of size
% nFrames by nConditions. Each column represents the
% onsets for one condition: 1 during the frame an
% event started, 0 otherwise.
%
% frameWindow: time window around which to estimate the
% mean response, expressed in frames. E.g. if you want
% to estimate the response from 4 seconds before the
% start of each event to 20 seconds afterward, and your
% TR is 2 secs/frame, frameWindow is -2:10.
%
% gb, 11/04; text by ras, 04/05

% initialize X
X = zeros(size(S));

nFrames = size(S,1);
nConds = size(S,2);
nScans = size(S,3);

frameWindow = unique(round(frameWindow)); % make integers

% nh is the total # of predictors for each condition
nh = length(frameWindow);

% prestim is the # of frames before each event onset for
% which to estimate response:
prestim = sum(frameWindow<0);

X = zeros(nFrames,nConds*nh);
for i = 1:nScans
    for j = 1:nConds
        X(:,(j-1)*nh+1:j*nh,i) = col2Toeplitz(S(:,j,i),nh,prestim);
    end
end

% append an extra predictor of ones for each scan,
% to estimate DC shifts in baseline from different
% runs (total of nScans extra predictors made):
dcEst = repmat(eye(nScans),[1 1 nFrames]);  
dcEst = permute(dcEst,[3 1 2]);  

% The dims of dcEst are nFrames by nh*nConds(extra predictors);
% add as extra columns
X = cat(2,X,dcEst);     

return
% /---------------------------------------------------------/ %




% /---------------------------------------------------------/ %
function T = col2Toeplitz(vec,nh,prestim);
% For an nFrames x 1 column vector of 0'S and 1'S, specifying
% event onsets for a condition, return a Toeplitz matrix T of
% onsets for use in selective averaging of that condition. 
% T is size nFrames by nh.
nFrames = size(vec,1);
T = zeros(nFrames,nh);
onsets = find(vec==1);
[cols rows] = meshgrid(1:nh,onsets-prestim);
rows = rows+cols-1; % each element is the row of that predictor/trial
ok = find(ismember(rows,1:nFrames)); 
rows = rows(ok); % remove out-of-range
cols = cols(ok); % remove out-of-range
if ~isempty(rows)
	ind = sub2ind([nFrames nh],rows,cols);
	T(ind) = 1;
end
return

