function data = rmPlotEccSigma(v, lr, fwhm, plot_pv, plotFlag)
% rmPlotEccSigma - plot sigma versus eccentricity in selected ROI
%
% data = rmPlotEccSigma(v, lr, [fwhm=0], [plot_position_variance], [plotFlag=1]);
%
%  INPUT
%   v: view
%   lr: left (1) or right (2) if FLAT view is used
%   fwhm: plot sigma (0) or fwhm (1)
%   plot_pv: plot 1D position variance (1), 2D position variance (2), sigma in mm (3) or not
%   (0)
%
% Uses data above view's co-threshold. It does makes sure that this
% threshold is above that used for the fine-search stage - so not to
% include blurred data. 
%
% 2007/08 SOD: ported from my scripts.
% 2008/11 KA: included the ability to plot position variance
% 2008/11 RAS: added a separate plot flag.
if ~exist('v','var') || isempty(v),
    v = getCurView;
end

if strcmp(v.viewType,'Flat')
    if notDefined('lr'), lr=1;  end
end

if notDefined('fwhm')
    fwhm=0;
end

if notDefined('plotFlag'),	plotFlag = 1;		end
if notDefined('plot_pv'),    plot_pv=0;			end

%% load stuff
% load retModel information
try
    rmFile   = viewGet(v,'rmFile');
    rmParams = viewGet(v,'rmParams');
catch %#ok<CTCH>
    error('Need retModel information (file)');
end
% load ROI information
try
    roi.coords = v.ROIs(viewGet(v,'currentROI')).coords;
    titleName  = v.ROIs(viewGet(v,'currentROI')).name;
catch %#ok<CTCH>
    error('Need ROI');
end

% load all coords
if strcmp(v.viewType,'Flat')
    if lr ==1
        allCrds  = viewGet(v,'coords','left');
    elseif lr==2
        allCrds  = viewGet(v,'coords','right');
    end
else
    allCrds  = viewGet(v,'coords');
end


% get data
rmData   = load(rmFile);
[tmp, roi.iCrds] = intersectCols(allCrds,roi.coords);
if plot_pv == 1 % 1D position variance plot
    getStuff = {'ecc','pol','sigma','varexp','pv'};
elseif plot_pv == 2 % 2D position variance plot
    getStuff = {'ecc','pol','sigma','varexp','pv2'};
elseif plot_pv == 3 % sigma in mm
    getStuff = {'ecc','pol','sigma','varexp','s_mm'};
else
    getStuff = {'ecc','pol','sigma','varexp'};
end
for m = 1:numel(getStuff),
    tmp = rmGet(rmData.model{1},getStuff{m});
    roi.(getStuff{m}) = tmp(roi.iCrds);
end;
if plot_pv == 2 % 2D position variance plot
    roi.pv=roi.pv2;
elseif plot_pv == 3 % plot sigma in mm
    roi.pv = roi.s_mm;
end
if fwhm ==1
    roi.sigma = sd2fwfm(roi.sigma);
end

% bin size (eccentricity range) of the data
if max([rmParams.stim(:).stimSize])>4,
    binsize = 1;
    %binsize = 1;
else
    %binsize = 0.25;
    binsize = 0.5;
end

%%--- thresholds
% take all data that would be processed in the 'search/fine' stage
% do not take data below this threshold because this is from the
% 'grid/coarse' stage and involves blurring.
thresh.varexp  = max(viewGet(v,'cothresh'), rmParams.analysis.fmins.vethresh);

% take all data within the stimulus range, and decrease it by a small 
% amount to be more conservative.
thresh.ecc = [0 max([rmParams.stim(:).stimSize])] + [.5 -2];% * binsize/2; 
thresh.ecc = viewGet(v, 'mapclip') + [0.5 -0.5];
% thresh.ecc = [0 max([rmParams.stim(:).stimSize])] + [0.5 -0.5];% * binsize/2; 

% thresh.ecc = [0 30];
% basically no sigma threshold
thresh.sig = [0.01 rmParams.analysis.sigmaRatioMaxVal-0.5]; 

%--- plotting parameters
xaxislim = [0 max([rmParams.stim(:).stimSize])];
MarkerSize = 8;

% find useful data given thresholds
ii = roi.varexp > thresh.varexp & ...
     roi.ecc > thresh.ecc(1) & roi.ecc < thresh.ecc(2) & ...
     roi.sigma > thresh.sig(1) & roi.sigma < thresh.sig(2);

% weighted linear regression:
roi.p = linreg(roi.ecc(ii),roi.sigma(ii),roi.varexp(ii));
roi.p = flipud(roi.p(:)); % switch to polyval format
xfit = thresh.ecc;
yfit = polyval(roi.p,xfit);

% bootstrap confidence intervals
if exist('bootstrp','file') 
    B = bootstrp(1000,@(x) localfit(x,roi.ecc(ii),roi.sigma(ii),roi.varexp(ii)),(1:numel(roi.ecc(ii))));
    B = B';
    pct1 = 100*0.05/2;
    pct2 = 100-pct1;
    b_lower = prctile(B',pct1);
    b_upper = prctile(B',pct2);
    keep1 = B(1,:)>b_lower(1) &  B(1,:)<b_upper(1);
    keep2 = B(2,:)>b_lower(2) &  B(2,:)<b_upper(2);
    keep = keep1 & keep2;
    b_xfit = linspace(min(xfit),max(xfit),100)';
    fits = [ones(100,1) b_xfit]*B(:,keep);
    b_upper = max(fits,[],2);
    b_lower = min(fits,[],2);
end

if plot_pv
    roi.p2 = linreg(roi.ecc(ii),roi.pv(ii),roi.varexp(ii));
    roi.p2 = flipud(roi.p2(:)); % switch to polyval format
    y2fit = polyval(roi.p2,xfit);
end

% output struct
data.xfit = xfit(:);
data.yfit = yfit(:);
data.x    = (thresh.ecc(1):binsize:thresh.ecc(2))';
data.y    = nan(size(data.x));
data.ysterr = nan(size(data.x));
data.roi = roi;

if plot_pv
    data.y2fit = y2fit(:);
    data.y2    = nan(size(data.x));
    data.y2sterr = nan(size(data.x));
end

% plot averaged data
for b=thresh.ecc(1):binsize:thresh.ecc(2),
    bii = roi.ecc >  b-binsize./2 & ...
          roi.ecc <= b+binsize./2 & ii;
    if any(bii),
        % weighted mean of sigma
        s = wstat(roi.sigma(bii),roi.varexp(bii));
        % store
        ii2 = find(data.x==b);
        data.y(ii2) = s.mean;
        data.ysterr(ii2) = s.sterr;
        
        if plot_pv
            % weighted mean of position variance
            s = wstat(roi.pv(bii),roi.varexp(bii));
            % store
            data.y2(ii2) = s.mean;
            data.y2sterr(ii2) = s.sterr;
        end
    else
       fprintf(1,'[%s]:Warning:No data in eccentricities %.1f to %.1f.\n',...
            mfilename,b-binsize./2,b+binsize./2);
    end;
end;

% plot if requested
if plotFlag==1,
    % plot first figure - all the individual voxels
    data.fig(1) = figure('Color', 'w');
    subplot(2,1,1); hold on;
    plot(roi.ecc(~ii),roi.sigma(~ii),'ko','markersize',2);
    plot(roi.ecc(ii), roi.sigma(ii), 'ro','markersize',2);
    ylabel('pRF size (sigma, deg)');xlabel('Eccentricity (deg)');
    h=axis;
    axis([xaxislim(1) xaxislim(2) 0 min(h(4),thresh.sig(2))]);
    title(titleName, 'Interpreter', 'none');

    subplot(2,1,2);hold on;
    plot(roi.ecc(~ii),roi.varexp(~ii),'ko','markersize',2);
    plot(roi.ecc(ii), roi.varexp(ii), 'ro','markersize',2);
	line(thresh.ecc, [thresh.varexp thresh.varexp], 'Color', [.3 .3 .3], ...
			'LineWidth', 1.5, 'LineStyle', '--'); % varexp cutoff	
    ylabel('variance explained (%)');xlabel('Eccentricity (deg)');
    axis([xaxislim(1) xaxislim(2) 0 1 ]);

    
	data.fig(2) = figure('Color', 'w'); hold on;
    
    % plot V2, V3 with certain style the rest the same
    if ~isempty(strfind(lower(titleName),'v2')),
        errorbar(data.x,data.y,data.ysterr,'ko');
        plot(data.x,data.y,'ko',...
            'MarkerFaceColor',[1 1 1],...
            'MarkerSize',MarkerSize);
        plot(data.x,data.y,'kx',...
            'MarkerSize',MarkerSize);
        plot(xfit,yfit','k','LineWidth',2);
        
    elseif ~isempty(strfind(lower(titleName),'v3'))
        errorbar(data.x,data.y,data.ysterr,'ko');
        plot(data.x,data.y,'ko',...
            'MarkerFaceColor',[1 1 1],...
            'MarkerSize',MarkerSize);
        plot(xfit,yfit','k','LineWidth',2);
    else
        errorbar(data.x,data.y,data.ysterr,'ko',...
            'MarkerFaceColor','k',...
            'MarkerSize',MarkerSize);
        if plot_pv
            errorbar(data.x,data.y2,data.y2sterr,'ko',...
                'MarkerFaceColor','b',...
                'MarkerSize',MarkerSize);
        end
        plot(xfit,yfit','k','LineWidth',2);
        if plot_pv
            plot(xfit,y2fit','b','LineWidth',2);
            legend('pRF size', 'position variance','Location','NorthWest')
            ttlText = sprintf([' %s pRF size (y=%.2fx+%.2f) and ' ...
                'position variance (y=%.2fx+%.2f)'], ...
                titleName, roi.p(1), roi.p(2), roi.p2(1), ...
                roi.p2(2));
            
        else
            ttlText = sprintf('%s: y=%.2fx+%.2f',titleName,roi.p(1),roi.p(2));
        end
        title(ttlText, 'Interpreter', 'none');
    end

	yfit = polyval(roi.p,xfit);
    h = plot(xfit,yfit','k');
    set(h,'LineWidth',2);
    title( sprintf('%s: y=%.2fx+%.2f', titleName, roi.p(1), roi.p(2)), ...
        'FontSize', 24, 'Interpreter', 'none' );
    if exist('bootstrp','file')
        plot(b_xfit,b_upper,'k--');
        plot(b_xfit,b_lower,'k--');
    end
    ylabel('pRF size (sigma, deg)');xlabel('Eccentricity (deg)');
    h=axis;
    axis([xaxislim(1) xaxislim(2) floor(h(3)) ceil(h(4))]);
	
    if plot_pv
        text(1,h(4)*0.8,sprintf('%s: y=%.2fx+%.2f',titleName,roi.p(1),roi.p(2)));
        text(1,h(4)*0.4,sprintf('%s: y=%.2fx+%.2f',titleName,roi.p2(1),roi.p2(2)));
    end
end

return;


function B=localfit(ii,x,y,ve)
B = linreg(x(ii),y(ii),ve(ii));
B(:);
return

