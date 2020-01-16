function [vw, figHandle] = plotEccVsPhase(vw, newfig, colored, drawROI, varargin)
%
% [vw figHandle] = plotEccVsPhase(vw, newfig, co)
%
% Plot of eccentricity versus phase for the current scan, for all
% pixels (in all slices) in the current ROI. You can use this function
% to plot visual field coverage.
%
% This function is kind of a hack, in that it expects that the pRF data are
% loaded as per rmLoadDefault: variance explained in the 'co' slot, polar
% angle in the 'ph' slot, and eccentricity (or log10(eccentricity)) in the
% 'map' slot. However, you can overload this by specifying alternate sets
% of co, eccentricity, or phase data by passing them in as parameter/value
% pairs (see OPTIONS below).
%
% the line ROI should be transformed from the cortical surface mesh
% _without_ fill layers.
%
% INPUTS
%  vw: mrVista view struct
%  newfig: whether you open a new figure or not
%  colored: whether you change the color of dots depending on the coherence
%  data.
%
% OPTIONS:
%	'cothresh', [cothresh]: specify the minimum coherence value to include
%	in the plot.
%
%	'eccthresh', [eccthresh]: specify the maximum eccentricity to include
%	in the plot.
%
%	'co', [co data]: overload the view's coherence data with your own set of
%	coherence values. Should match the size of the data in view.co.
%
%	'ecc', [ecc data]: overload the view's eccentricity data with your own set of
%	eccentricity values. Should match the size of the data in view.map.
%
%	'ph', [ph data]: overload the view's phase data with your own set of
%	polar angle values. Should match the size of the data in view.ph.
%
%  SEE ALSO: retinoPlot, rmPlotCoverage. 
%
%  08/06 KA made several changes
%  aug 2008: JW added ROI title to the plot
%  sep 2008: JW added option to draw visually-referred polygon ROI
%  jan 2009: JW: removed subroutine 'ROIcaptureSelectedPoints' and put it
%                in an independent function, so that it can be called from
%                other plotting functions
%  apr 2009: RAS: clarified what needs to be set up; allows you to overload
%  new ph, ecc, and co values.

if notDefined('vw'), error('View must be defined.'); end
if notDefined('newfig'), newfig = 1; end
if notDefined('colored'), colored = 0; end

if notDefined('drawROI'), drawROI = 0; end


if isempty(viewGet(vw, 'ROIs')) || viewGet(vw, 'selected ROI') < 1
	error('No Selected ROI!');
end
	

% Get selpts from current ROI
ROIcoords = viewGet(vw, 'ROI coords');

% Get co and ph (vectors) for the current scan, within the
% current ROI.
I = viewGet(vw, 'ROI indices');
model = viewGet(vw, 'rmmodel');
model = model{1};
co = rmGet(model, 'varexp');
co = co(I);
ph = rmGet(model, 'pol');
ph = ph(I);
ecc = rmGet(model, 'ecc');
ecc = ecc(I);

% Remove NaNs from subCo and subAmp that may be there if ROI
% includes volume voxels where there is no data.
NaNs = find(isnan(co), 1);
if ~isempty(NaNs)
%   myWarnDlg('ROI includes voxels that have no data.  These voxels are being ignored.');
  notNaNs = find(~isnan(co));
  co = co(notNaNs);
  ph = ph(notNaNs);
  ecc = ecc(notNaNs);
end

cothresh = viewGet(vw, 'co thresh');
eccthresh = max(viewGet(vw, 'mapclipmode')); 

%% parse options
for ii = 1:2:length(varargin)
	switch lower(varargin{ii})
		case 'cothresh', cothresh = varargin{ii+1};
		case 'eccthresh', eccthresh = varargin{ii+1};
		case 'ecc', ecc = varargin{ii+1};
		case 'ph',  ph = varargin{ii+1};
		case 'co', co = varargin{ii+1};
	end
end

% Find voxels which satisfy cothresh and eccthresh.
coIndices = find(co>cothresh & ecc<=eccthresh);

% Pull out co and ph for desired pixels
subCo =   co(coIndices);
subPh =   ph(coIndices);
subEcc = ecc(coIndices);
if newfig
    figHandle = figure;
else
	%figHandle = selectGraphWin;
end

% selectGraphWin;
% Window header
% headerStr = ['Eccentricity vs. phase, ROI ',ROIname,', scan ',num2str(curScan)];
% set(gcf,'Name',headerStr);
% Plot it
fontSize = 14;
symbolSize = 4;

% polar plot
subX = subEcc.*cos(subPh);
subY = subEcc.*sin(subPh);

% polar plot params
params.grid = 'on';
params.line = 'off';
params.gridColor = [0.6,0.6,0.6];
params.fontSize = fontSize;
params.symbol = 'o';
params.size = symbolSize;
params.color = 'w';
params.fillColor = 'w';
params.maxAmp = eccthresh;
% if eccthresh > 10, params.ringTicks = [0:5:eccthresh];
% else
	params.ringTicks = round( linspace(0, eccthresh, 4) );
% end


% Use 'polarPlot' to set up grid'
% clf
polarPlot(0,params);

% finish plotting it
for i=1:size(subX,2)
    if colored
        h=plot(subX(i),subY(i),'o','MarkerSize',symbolSize,'Color',[1-subCo(i) 1-subCo(i) 1-subCo(i)]);
        set(h,'MarkerFaceColor',[1-subCo(i) 1-subCo(i) 1-subCo(i)])
    else
        h=plot(subX(i),subY(i),'o','MarkerSize',symbolSize,'Color',[0 0 0]);
        set(h,'MarkerFaceColor',[0.5 0.5 0.5])
    end
end

title(vw.ROIs(vw.selectedROI).name, 'FontSize', 24, 'Interpreter', 'none');
hold off

if drawROI, 
    vw = roiCapturePointsFromPlot(vw, subX, subY, coIndices, ROIcoords);
end

% Save the data in gca('UserData')
data.co = co;
data.ph = ph;
data.subCo = subCo;
data.subPh = subPh;
set(gca,'UserData',data);

return;

end
