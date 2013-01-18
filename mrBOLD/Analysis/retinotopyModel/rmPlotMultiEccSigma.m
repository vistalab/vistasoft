function data = rmPlotMultiEccSigma(vw, ROIlist)
% rmPlotMultiEccSigma(vw, [ROIlist])
%
% Wrapper to plot pRF sigma vs eccentricity for multiple ROIs
%
%   vw: mrVista view struct
%   ROIlist: list of ROIs (if blank, call menu; if 0, plot all ROIs)
%
%   note: need to have an rm model and at least one ROI loaded into the 
%           view.
%
% 2/2009: JW

%--------------------------
% VARIABLE CHECKS
%--------------------------
% check view struct
if notDefined('vw'), vw = getCurView; end

% check model
model = viewGet(vw, 'rmModel'); %#ok<NASGU>
if isempty('model'), vw = rmSelect(vw); end

% check ROIs
if (notDefined('ROIlist'))
    roiList=viewGet(vw, 'roinames');
    selectedROIs = find(buttondlg('ROIs to Plot',roiList));
elseif ROIlist == 0,
    selectedROIs = 1:length(viewGet(vw, 'ROIs'));
else
    selectedROIs=ROIlist;
end

nROIs=length(selectedROIs);
if (nROIs==0), error('No ROIs selected'); end

%--------------------------
% PLOT
%--------------------------

% set up plot
graphwin = selectGraphWin;  
figure(graphwin); hold on;
set(graphwin, 'Color', 'w')
c = jet(nROIs);

% initialize a legend
legendtxt = cell(1,nROIs);

% initialize data struct
data = cell(1, nROIs); 

% suppress individual plots from calls to rmPlotEccSigma
plotFlag = false; 

% loop thru ROIs
for ii = 1:nROIs
    vw = viewSet(vw, 'curroi', selectedROIs(ii));
    data{ii} = rmPlotEccSigma(vw, [], [], [], plotFlag);
    data{ii}.roi = viewGet(vw, 'roiname');
    legendtxt{ii} = data{ii}.roi;
    figure(graphwin);
    % plot the fit lines for each ROI (so we have one series per ROI to
    % make the legend nicer)
    plot(data{ii}.xfit, data{ii}.yfit, '-', 'color', c(ii,:), 'LineWidth', 2)
end

legend(legendtxt);

% add the data points for each plot
for ii = 1:nROIs   
    errorbar(data{ii}.x,data{ii}.y,data{ii}.ysterr, 'x', 'color', c(ii,:));    
end

ylabel('pRF size (sigma, deg)');
xlabel('Eccentricity (deg)');

data = cell2mat(data);

return
