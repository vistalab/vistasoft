function view = roiSplitToBins(view,nBins);
% roiSplitToBins - split roi into seperate ones based on distance
% from a starting node. (after ROIBuildBins)
% 
% view = roiSplitToBins(view, nBins);
%
% So far only tested on Gray view using a line ROI.

if ~exist('view','var') | isempty(view),
  error('Need view struct.');
end;
if ~exist('nBins','var') | isempty(nBins);
  prompt={'Number of bins:'}; def={'7'};lineNo=1;
  dlgTitle = 'Number of bins?';
  answer=inputdlg(prompt,dlgTitle,lineNo,def);
  if isempty(answer),  myErrorDlg('Cancelling.');return;
  else                 nBins = str2num(answer{1});
  end
end;


% store selected roi:
roi = view.ROIs(view.selectedROI)

% get corresponding roi nodes
if ~isfield(roi,'nodeIndices') | isempty(roi.nodeIndices);
  roi.nodeIndices = roiGetNodes(roi, view);
  view.ROIs(view.selectedROI).nodeIndices = roi.nodeIndices;
end;

% first sort according to distance
nodes = view.nodes;
edges = view.edges;
nodeIndices = roi.nodeIndices;

% compute distances
dist = mrManDist(nodes, edges, nodeIndices(1));
dist = dist(nodeIndices);

% give some info regarding the distance and bins
disp(sprintf('[%s]:Distance (min-max) = %.1f - %.1f',mfilename,min(dist),max(dist)));
disp(sprintf('[%s]:Bin distance = %.1f (%dbins).',mfilename,max(dist)./nBins,nBins));

% distances between bins
binDistances = linspace(min(dist),max(dist),nBins+1);
% maybe these should be reset every time?

% get number of existing ROIs so we can append our bin-rois
nROIs = numel(view.ROIs);

% fill bins into new roi-struct
for n=1:numel(binDistances)-1,
  % new roi number
  nn = nROIs + n;
  % copy roi
  view.ROIs(nn) = roi;
  % different colors
  if n/2==round(n/2),
    view.ROIs(nn).color = 'r';
  else,
    view.ROIs(nn).color = 'b';
  end;
  % rename to bin number
  view.ROIs(nn).name = sprintf('bin%d',n);
  % find bin id
  ii = dist>=binDistances(n) & dist< binDistances(n+1);
  % copy only nodes and coords in bin id
  view.ROIs(nn).nodeIndices = roi.nodeIndices(ii);
  view.ROIs(nn).coords = roi.coords(:,ii);
end;


return;
