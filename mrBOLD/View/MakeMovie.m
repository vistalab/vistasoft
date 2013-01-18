function M = MakeMovie(scanNum, sliceNum, useCurrentFigure)

% function M = MakeMovie(scanNum, sliceNum, useCurrentFigure);
%
% Makes a movie matrix M for the designated scan and
% slice. Assumes that pwd is a valid session directory. If the
% useCurrentFigure flag is set, then that figure is used to make the movie;
% otherwise a default figure window is opened.
%
% DBR, 3/99

global mrSESSION
load mrSESSION;

if ~exist('useCurrentFigure', 'var'), useCurrentFigure = 0; end

% Load the time series:
disp('Loading time series...');
view = initHiddenInplane;
tSeries = loadtSeries(view, scanNum, sliceNum);

% Determine movie dimensions:
fDims = mrSESSION.functionals(scanNum).cropSize;
nFrames = size(tSeries, 1);

% Set up the image display:
if useCurrentFigure, h = figure(gcf); else h = figure; end
imagesc(reshape(tSeries(1, :), fDims));
axis equal
axis image
axis off
axis manual
colormap(gray)

% Make the movie:
disp('Making the movie...');
M = moviein(nFrames);
for iFrame=1:nFrames
  imagesc(reshape(tSeries(iFrame, :), fDims));
%  axis equal;
  axis image
  axis off
  h = text(5, 5, ['Frame: ', int2str(iFrame)]);
  set(h, 'Color', [1, 1, 0]);
  M(:, iFrame) = getframe;
end
