function data = rmPlotAngleSigmaratio(v, lr, fwhm)
% rmPlotEccSigmaratio - plot sigma versus eccentricity in selected ROI
%
% data = rmPlotEccSigma(view);
%
% Uses data above view's co-threshold. It does makes sure that this
% threshold is above that used for the fine-search stage - so not to
% include blurred data. 
%
% 2007/08 SOD: ported from my scripts.

if ~exist('v','var') || isempty(v),
    error('Need view struct');
end

if v.viewType == 'Flat'
    ieNotDefined('lr')==1, lr=1;
end

if ieNotDefined('fwhm')
    fwhm=0;
end

% load stuff
% load retModel information
try
    rmFile   = viewGet(v,'rmFile');
    rmParams = viewGet(v,'rmParams');
catch
    error('Need retModel information (file)');
end
% load ROI information
try
    roi.coords = v.ROIs(viewGet(v,'currentROI')).coords;
    titleName  = v.ROIs(viewGet(v,'currentROI')).name;
catch
    error('Need ROI');
end
% load all coords
if v.viewType == 'Flat'
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
getStuff = {'ecc','pol','sigma','varexp','sigmaratiooval'};
for m = 1:numel(getStuff),
    tmp = rmGet(rmData.model{1},getStuff{m});
    roi.(getStuff{m}) = tmp(roi.iCrds);
end;

if fwhm ==1
    roi.sigma = sd2fwfm(roi.sigma);
end

% bin size (eccentricity range) of the data
if max([rmParams.stim(:).stimSize])>4,
    binsize = 1;
else
    binsize = 0.25;
end

%--- thresholds
% take all data that would be processed in the 'search/fine' stage
% do not take data below this threshold because this is from the
% 'grid/coarse' stage and involves blurring.
thresh.varexp  = max(viewGet(v,'cothresh'),rmParams.analysis.fmins.vethresh);
% take all data within the stimulus range, and decrease it by a small 
% amount to be more conservative.
thresh.ecc = [0 max([rmParams.stim(:).stimSize])] + [1 -1]; 
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
roi.p = linreg(roi.ecc(ii),roi.sigmaratiooval(ii),roi.varexp(ii));
roi.p = flipud(roi.p(:)); % switch to polyval format
xfit = thresh.ecc;
yfit = polyval(roi.p,xfit);

% output struct
data.xfit = xfit(:);
data.yfit = yfit(:);
data.x    = (thresh.ecc(1):binsize:thresh.ecc(2))';
data.y    = nan(size(data.x));
data.ysterr = nan(size(data.x));

% plot averaged data
for b=thresh.ecc(1):binsize:thresh.ecc(2),
    bii = roi.ecc >  b-binsize./2 & ...
          roi.ecc <= b+binsize./2 & ii;
    % weighted mean
    if any(bii),
        s = wstat(roi.sigmaratiooval(bii),roi.varexp(bii));
        
        % store
        ii2 = find(data.x==b);
        data.y(ii2) = s.mean;
        data.ysterr(ii2) = s.sterr;
        
    else
       fprintf(1,'[%s]:Warning:No data in eccentricities %.1f to %.1f.\n',...
            mfilename,b-binsize./2,b+binsize./2);
    end;
end;

% plot if no output is requested
if ~nargout,
    % plot first figure - all the individual voxels
%     figure;
%     subplot(2,1,1);hold on;
%     plot(roi.ecc(~ii),roi.sigma(~ii),'k.','markersize',1);
%     plot(roi.ecc(ii), roi.sigma(ii), 'r.','markersize',1);
%     ylabel('pRF size (sigma, deg)');xlabel('Eccentricity (deg)');
%     h=axis;
%     axis([xaxislim(1) xaxislim(2) 0 min(h(4),thresh.sig(2))]);
%     title(titleName);
% 
%     subplot(2,1,2);hold on;
%     plot(roi.ecc(~ii),roi.varexp(~ii),'k.','markersize',1);
%     plot(roi.ecc(ii), roi.varexp(ii), 'r.','markersize',1);
%     ylabel('variance explained (%)');xlabel('Eccentricity (deg)');
%     axis([xaxislim(1) xaxislim(2) 0 1 ]);
    
    figure; hold on;
    
    % plot V2, V3 with certain style the rest the same
    errorbar(data.x,data.y,data.ysterr,'ko',...
        'MarkerFaceColor','k',...
        'MarkerSize',MarkerSize);

    yfit = polyval(roi.p,xfit);
    h = plot(xfit,yfit','k');
    set(h,'LineWidth',2);
    title(sprintf('%s: y=%.2fx+%.2f',titleName,roi.p(1),roi.p(2)));
    ylabel('log of pRF size ratio (angle/ecc)');xlabel('Eccentricity (deg)');
    h=axis;
    axis([xaxislim(1) xaxislim(2) floor(h(3)) ceil(h(4))]);
%     set(gca,'YTick',-1:0.5:1);
%     set(gca,'YTickLabel',{'10^-1','10^-0.5','1','10^0.5','10^1'})
end

return;


