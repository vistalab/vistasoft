function data = rmPlotTwoParams(v, p1, p2, binvector, lr, plotFlag)
% rmPlotTwoParams - plot param1 vs param2 in selected ROI
%
% data = rmPlotParams(v, [params1], [params2], [binvector], [lr], [plotFlag=1]);
%
%  INPUT
%   v: view
%   param1: parameter for x-axis
%   param2: parameter for y-axis
%   binvector: x values to use as bin centers
%   lr: left (1) or right (2) if FLAT view is used
%
% Uses data above view's co-threshold. It does makes sure that this
% threshold is above that used for the fine-search stage - so not to
% include blurred data. 
%
% 2009/03 SD & WZ: ported from rmPlotEccSigma made it more general input of
%                  x and y axis
% 2010/10 SD: added bootstrap 95% confidence intervals on binned data and fits


%% input handling
if ~exist('v','var') || isempty(v), error('Need view'); end
if ~exist('lr','var') || isempty(lr), lr=1;            end; 
if ~exist('plotFlag','var') || isempty(plotFlag), plotFlag = true;	end
if ~exist('binvector','var'), binvector = [];	end

if ~exist('p1','var') || isempty(p1) || ~exist('p2','var') || isempty(p2) 
    name = sprintf('Please enter the parameters:');   
    prompt = {'X-axis:','Y-axis:','X-axis bins'};
    defaultanswer = {'ecc','sigma',''};
    answer = inputdlg(prompt,name,1,defaultanswer);

    p1 = answer{1};
    p2 = answer{2};
    binvector = str2num(answer{3}); 
end


%% load retModel information from view struct
if isstruct(v)
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
    % also get variance explained except if already requested
    if strcmpi(p1,'varexp') || strcmpi(p2,'varexp')
        getStuff = {p1,p2};
    else
        getStuff = {p1,p2,'varexp'};
    end
    % store in roi struct
    for m = 1:numel(getStuff),
        tmp = rmGet(rmData.model{1},getStuff{m});
        roi.(getStuff{m}) = tmp(roi.iCrds);
    end
    
    
    %% thresholds
    % take all data that would be processed in the 'search/fine' stage
    % do not take data below this threshold because this is from the
    % 'grid/coarse' stage and involves blurring.
    thresh.varexp  = max(viewGet(v,'cothresh'), rmParams.analysis.fmins.vethresh);
    
    % find useful data given thresholds
    ii = roi.varexp > thresh.varexp;
    
    for m = 1:numel(getStuff),
        roi.(getStuff{m}) = roi.(getStuff{m})(ii);
    end
else
    roi.(p1) = v(:,1); % to be plotted on the x-axis (called 'p1' input) 
    roi.(p2) = v(:,2); % to be plotted on the y-axis (called 'p2' input)
    roi.varexp = v(:,3); % weighting function: higher is more weight
end


%% bin size and axis ranges
% make binvector, binsize and range vectors

if isempty(binvector)
    if strcmpi(p1,'ecc') || ...
            strcmpi(p1,'x') || strcmpi(p1,'x0') || ...
            strcmpi(p1,'y') || strcmpi(p1,'y0')
        if max([rmParams.stim(:).stimSize])>4,
            binsize = 0.5;
        else
            binsize = 0.25;
        end
    else
        binsize = max(roi.(p1))./20;
    end
    binvector = 0:binsize:max(roi.(p1));
else
    binsize = mean(diff(binvector));
end
range = [min(binvector) max(binvector) 0 max(roi.(p2))];


%% weighted linear regression:
roi.p = linreg(roi.(p1),roi.(p2),roi.varexp);
roi.p = flipud(roi.p(:)); % switch to polyval format
xfit = binvector;
yfit = polyval(roi.p,xfit);
xfit_bconf = linspace(min(binvector),max(binvector),100)'; 
indexBin = roi.(p1) >= min(binvector) & roi.(p1) <= max(binvector);
yfit_bconf = local_BootstrapLinReg(roi.(p1)(indexBin),roi.(p2)(indexBin),roi.varexp(indexBin),xfit_bconf);


%% output struct
data.xfit = xfit(:);
data.yfit = yfit(:);
data.xfit_bconf = xfit_bconf;
data.yfit_bconf = yfit_bconf;
data.x    = xfit';
data.y    = nan(size(data.x));
data.ysterr = nan(size(data.x));
data.y_bconf =  nan(numel(data.x),3);


%% compute averaged data inside bins
for b=binvector(:)'
    bii = roi.(p1) >  b-binsize./2 & ...
          roi.(p1) <= b+binsize./2;
    if any(bii),
        % weighted mean of y-value but don't weight variance explained
        if strcmpi(p2,'varexp')
            s = wstat(roi.(p2)(bii),roi.varexp(bii));
        else
            s = wstat(roi.(p2)(bii));
        end
        % store
        ii2 = find(data.x==b);
        data.y(ii2) = s.mean;
        data.ysterr(ii2) = s.sterr;
        if numel(roi.(p2)(bii))>1
            data.y_bconf(ii2,:) = local_BootstrapBin(roi.(p2)(bii),roi.varexp(bii));
        else
            data.y_bconf(ii2,:) = repmat(roi.(p2)(bii),[1 3]);
        end
    else
       fprintf(1,'[%s]:Warning:No data in %s %.1f to %.1f.\n',...
            mfilename,p1,b-binsize./2,b+binsize./2);
    end
end
if any(isnan(data.y_bconf))
    nanidx = any(isnan(data.y_bconf),2);
    data.y_bconf(nanidx,:) = [];
    data.x_bconf = data.x;
    data.x_bconf(nanidx,:) = [];
end


%% plot if requested
if plotFlag==1,
    %--- plotting parameters
    MarkerSize = 8;
    
    % plot first figure - all the individual voxels
    data.fig(1) = figure('Color', 'w');
    subplot(2,1,1); hold on;
    plot(roi.(p1),roi.(p2),'ko','markersize',2);
    ylabel(p2);xlabel(p1);
    axis(range);
    
    subplot(2,1,2);hold on;
    plot(roi.(p1),roi.varexp,'ko','markersize',2);
	ylabel('variance explained (%)');xlabel(p1);
    axis([range(1:2) 0 1 ]);

    
	data.fig(2) = figure('Color', 'w'); hold on;
    
    % bootstrp figure
    if exist('bootstrp','file') 
        
        e = diff(data.y_bconf,[],2);
        errorbar(data.x_bconf,data.y_bconf(:,2),e(:,1),e(:,2),'ko',...
            'MarkerFaceColor','k',...
            'MarkerSize',MarkerSize);
        plot(data.xfit_bconf,data.yfit_bconf(:,2),'k','LineWidth',2);
        plot(data.xfit_bconf,data.yfit_bconf(:,1),'k:','LineWidth',1);
        plot(data.xfit_bconf,data.yfit_bconf(:,3),'k:','LineWidth',1);
        ylabel(p2);xlabel(p1);
        h=axis;
        axis([range(1:2) floor(h(3)) ceil(h(4))]);
    else
        errorbar(data.x,data.y,data.ysterr,'ko',...
            'MarkerFaceColor','k',...
            'MarkerSize',MarkerSize);
        plot(xfit,yfit','k','LineWidth',2);
        ylabel(p2);xlabel(p1);
        h=axis;
        axis([range(1:2) floor(h(3)) ceil(h(4))]);
        
    end
    
end

return

%%%%%%%%%%%%%%%  local functions%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%--------------------------------------------------------------------------
% bootstrap confidence intervals
function output = local_BootstrapBin(y,w)
output = nan(1,3);
if exist('bootstrp','file') 
    B = bootstrp(1000,@(z) local_wmean(z,y,w),(1:numel(y)));
    output = prctile(B,[2.5 50 97.5]);
    output = output(:)';
end
return
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
function B=local_wmean(ii,y,ve)
B = wstat(y(ii),ve(ii),1,'mean');
return
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% bootstrap confidence intervals
function output = local_BootstrapLinReg(x,y,w,xi)
output = [];
if exist('bootstrp','file') 
    B = bootstrp(1000,@(z) local_linreg(z,x,y,w),(1:numel(x)));
    B = B';
    pct1 = 100*0.05/2;
    pct3 = 50;
    pct2 = 100-pct1;
    b_lower = prctile(B',pct1);
    b_upper = prctile(B',pct2);
    b_median = prctile(B',pct3);
    keep1 = B(1,:)>b_lower(1) &  B(1,:)<b_upper(1);
    keep2 = B(2,:)>b_lower(2) &  B(2,:)<b_upper(2);
    keep = keep1 & keep2;
    fits = [ones(numel(xi),1) xi(:)]*B(:,keep);
    b_upper = max(fits,[],2);
    b_lower = min(fits,[],2);
    median_fit = [ones(numel(xi),1) xi(:)]*b_median(:);
    output = [b_lower(:) median_fit(:) b_upper(:)];
end
return
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
function B=local_linreg(ii,x,y,ve)
B = linreg(x(ii),y(ii),ve(ii));
B(:);
return
%--------------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%