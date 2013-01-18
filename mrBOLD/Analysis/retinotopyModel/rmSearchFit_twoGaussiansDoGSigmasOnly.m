function model = rmSearchFit_twoGaussiansDoGSigmasOnly(model,data,params,wProcess,t)
% rmSearchFit_twoGaussiansDoG - wrapper for 'fine' two DoG Gaussian fit
%
% model = rmSearchFit_twoGaussiansDoG(model,prediction,data,params);
%
% Second gaussian negative only. 
%
% 2008/01 SOD: split of from rmSearchFit.

% add upper and lower limit:
expandRange    = params.analysis.fmins.expandRange;

% fminsearch options
searchOptions = params.analysis.fmins.options;
vethresh      = params.analysis.fmins.vethresh;

% convert to double just in case
params.analysis.X = double(params.analysis.X);
params.analysis.Y = double(params.analysis.Y);
params.analysis.allstimimages = double(params.analysis.allstimimages);

% amount of negative fits
nNegFit  = 0;
trends   = t.trends;
t_id     = t.dcid+2;

% get starting upper and lower range and reset TolFun 
% (raw rss computation (similar to norm) and TolFun adjustments)
[range TolFun] = rmSearchFit_range(params,model,data);

% initialize
if ~isfield(model,'rss2')
    model.rss2 = zeros(size(model.rss));
end

if ~isfield(model,'rssPos')
    model.rsspos = zeros(size(model.rss));
end

if ~isfield(model,'rssNeg')
    model.rssneg = zeros(size(model.rss));
end

%-----------------------------------
% Go for each voxel
%-----------------------------------
progress = 0;tic;
for ii = 1:numel(wProcess),

    % progress monitor (10 dots)
    if floor(ii./numel(wProcess)*10)>progress,
        % print out estimated time left
        if progress==0,
            esttime = toc.*10;
            if floor(esttime./3600)>0,
                fprintf(1,'[%s]:Estimated processing time: %d voxels: %d hours.\n',...
                    mfilename,numel(wProcess),ceil(esttime./3600));
            else
                fprintf(1,'[%s]:Estimated processing time: %d voxels: %d minutes.\n',...
                    mfilename,numel(wProcess),ceil(esttime./60));
            end;
            fprintf(1,'[%s]:Nonlinear optimization (x,y,sigma):',mfilename);
        end;
        fprintf(1,'.');drawnow;
        progress = progress + 1;
    end;

    % volume index
    vi = wProcess(ii);
    vData = double(data(:,ii));
    
    % reset tolFun: Precision of evaluation function. 
    % We define RMS improvement relative to the initial raw 'no-fit' data
    % RMS. So, 1 means stop if there is less than 1% improvement on the fit:
    searchOptions.TolFun = TolFun(ii);
    
    % compute part of the pRF computations related to position (x,y) here
    % for speed reasons
    Xv = params.analysis.X-range.start(1);
    Yv = params.analysis.Y-range.start(2);
    XvYv = (Yv.*Yv + Xv.*Xv);
    
    % actual fitting routine
    if searchOptions.MaxIter>0
        outParams = ...
            fmincon(@(x) rmModelSearchFit_twoGaussiansDoGSigmasOnly(x,vData,...
            XvYv,...
            params.analysis.allstimimages,trends),...
            range.start(3:4,vi),[],[],[],[],range.lower(3:4,vi),range.upper(3:4,vi),...
            @(x) distanceCon(x,params.analysis.minSigmaRatio),searchOptions);
    else
        outParams = range.start(3:4);
    end
    
    % make predictions
    rf(:,1) = exp( (XvYv) ./ (-2.*(outParams(1).^2)) );
    rf(:,2) = exp( (XvYv) ./ (-2.*(outParams(2).^2)) );
    
    % test 1 gaussian alone (must be done prior to with second gaussian)
    if searchOptions.MaxIter==0
        % without second gaussian
        X = [params.analysis.allstimimages*rf(:,1) trends];
        b = pinv(X)*vData;
        % force positive fit (is a constraint in the rmModelSearchFit_twoGaussian, so it should return here to get the right values)    
        b(1) = abs(b(1));
        rss2  = norm(vData-X*b).^2;
        % make only the positive and the negative rf
        % find out where the rf is positive and where it is negative
        % for the positive rf put all the negative rf-values to zero, for
        % the negative rf put all the positive rf-values to zero.
        X = [params.analysis.allstimimages*rf trends];
        b    = pinv(X)*vData;
        
        % force positive fit
        b(1) = abs(b(1));
        %force negative b2 fit
        b(2) = -(abs(b(2)));
        
        rfBeta = b(1).*rf(:,1) + b(2).*rf(:,2);
        posInd = rfBeta > 0;
        negInd = rfBeta < 0;
        rfPos = rf;
        rfNeg = rf;
        rfPos(negInd,1) = 0;
        rfPos(negInd,2) = 0;
        rfNeg(posInd,1) = 0;
        rfNeg(posInd,2) = 0;
        XPos = [params.analysis.allstimimages*rfPos trends];
        XNeg = [params.analysis.allstimimages*rfNeg trends];
        rssPos = norm(vData-XPos*b).^2;
        rssNeg = norm(vData-XNeg*b).^2;
        
        %rfBeta = rf*b(1:2);
        %rssPos = norm(vData-max(rfBeta,0)).^2;
        %rssNeg = norm(vData-min(rfBeta,0)).^2;
        
%         if length(rssPos)==0 
%             disp('rssPos is empty!');
%             rssPos = 1;
%         end
    end
    
    % with second gaussian
    X = [params.analysis.allstimimages*rf trends];
    b    = pinv(X)*vData;
    % force positive fit
    b(1) = abs(b(1));
    %force negative b2 fit
    b(2) = -(abs(b(2)));
    rss  = norm(vData-X*b).^2;
    
    % store results only if the first beta is positive, somehow fmincon
    % outputs negative fits. If the fit is negative keep old (grid) fit.
    if b(1)>0 && b(1)>-b(2) && b(2) <=0,
        model.s(vi)    = outParams(1);
        model.s_major(vi)    = outParams(1);
        model.s_minor(vi)    = outParams(1);
        model.s_theta(vi)    = 0;
        model.s2(vi)   = outParams(2);
        model.rss(vi)  = rss;
        model.b([1 2 t_id],vi) = b;
        if searchOptions.MaxIter==0
            model.rss2(vi) = rss2;
            model.rsspos(vi) = rssPos;
            model.rssneg(vi) = rssNeg;
        end
    else
        % change the percent variance explained to be just under the
        % current vethresh. So it counts as a 'coarse'-fit but can still be
        % included in later 'fine'-fits
        model.rss(vi)  = (1-max((vethresh-0.01),0)).*model.rawrss(vi);
        nNegFit = nNegFit + 1;
        if searchOptions.MaxIter==0
            model.rss2(vi)  = (1-max((vethresh-0.01),0)).*model.rawrss(vi);
            model.rsspos(vi)  = (1-max((vethresh-0.01),0)).*model.rawrss(vi);
            model.rssneg(vi)  = (1-max((vethresh-0.01),0)).*model.rawrss(vi);
        end
    end;
end;

% end time monitor
et  = toc;
if floor(et/3600)>0,
    fprintf(1,'Done [%d hours].\n',ceil(et/3600));
else
    fprintf(1,'Done [%d minutes].\n',ceil(et/60));
end;
fprintf(1,'[%s]:Removed negative fits: %d (%.1f%%).\n',...
    mfilename,nNegFit,nNegFit./numel(wProcess).*100);

return;

%-----------------------------------
% make sure that the pRF can only be moved "step" away from original
% poisiton "startParams"
% For the two Gaussian model we add the additional constraint that the
% second Gaussian is at least twice as large as the first.
function [C, Ceq]=distanceCon(x,minRatio)
Ceq = [];
C   = minRatio - 0.001 - x(2)./x(1);
return;
%-----------------------------------

