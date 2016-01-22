function hrfParams = hrfModelSearchFit(data,prediction,hrfParams,params)
% hrfModelSearchFit - find optimal HRF parameters for entire dataset
%
% hrfParams = hrfModelSearchFit(view,hrfParams);
% 
% 2009/02 SOD: wrote it.

%warning off MATLAB:divideByZero;

%-----------------------------------
% input handling
%-----------------------------------
if ~exist('data','var') || isempty(data), error('Need data'); end
if ~exist('hrfParams','var') || isempty(hrfParams), error('Need hrfParams'); end
if ~exist('prediction','var') || isempty(prediction), error('Need prediction'); end
if ~exist('params','var') || isempty(params), error('Need params'); end

% do we need to adjust for a variable dc component?
if params.analysis.dc.datadriven
    estimate_dc = false;
else
    estimate_dc = true;
end

% Fitting params
startParams = hrfParams.hrfStart(:);
bndParams = startParams*[1/hrfParams.range hrfParams.range];
bndParams = max(bndParams,0); % no negative values
bndParams(5,1) = 0; % always allow the option to become a one gamma function

% compute rawrss for each voxel
rawrss = sum(data.^2);

% time to make HRF and HRF should be zero near the end
FIR_frames    = ceil(hrfParams.maxHrfDuration/hrfParams.tr);
FIR_time      = (0:FIR_frames)*hrfParams.tr;



% actual fitting routine
fprintf(1,'[%s]:Estimating HRF\n',mfilename);drawnow;
fprintf(1,'\tTwo gamma function:\t[peak1 width1 peak2 width2 -weight2]\n');
fprintf(1,'\tInput (Default):\t[%.4f %.4f %.4f %.4f %.4f]\n',startParams);
fprintf(1,'\tSearch range (min):\t[%.4f %.4f %.4f %.4f %.4f]\n',bndParams(:,1));
fprintf(1,'\tSearch range (max):\t[%.4f %.4f %.4f %.4f %.4f]\n',bndParams(:,2));

% grid fit
gridsample = hrfParams.gridsample;
gridParams = single(startParams);

% default rss 
tic;
% for speed reasons convert to single precision
sdata = single(data);
spred=cell(numel(prediction),1);
for n=1:numel(prediction), spred{n} = single(prediction{n}); end
srawrss = single(sum(data.^2));
stime = single(FIR_time);
eDefault=hrfFit(single(startParams),sdata,spred,srawrss,stime,estimate_dc);
for i1=linspace(bndParams(1,1),bndParams(1,2),gridsample)
    for i2=linspace(bndParams(2,1),bndParams(2,2),gridsample)
        for i5=linspace(bndParams(5,1),bndParams(5,2),gridsample)
            % only go into the other loops if 2nd gamma weight is not zero
            if i5~=0
                for i3=linspace(bndParams(3,1),bndParams(3,2),gridsample)
                    % rule: 2nd gamma peaks after first one
                    if i3>i1+1
                        for i4=linspace(bndParams(4,1),bndParams(4,2),gridsample)
                            % rule: 2nd gamma is at least as wide as 1st
                            if i4>=i2
                                h = single([i1 i2 i3 i4 i5]);
                                e=hrfFit(h,sdata,spred,srawrss,stime,estimate_dc);
                                if e<eDefault
                                    gridParams=h;
                                    eDefault = e;
                                end
                            end
                        end
                    end
                end
            else
                h = single([i1 i2 i1+2 i2+2 i5]);
                e=hrfFit(h,sdata,spred,srawrss,stime,estimate_dc);
                if e<eDefault
                    gridParams=h;
                    eDefault = e;
                end
            end
        end
    end
end
gridParams = double(gridParams);
fprintf(1,'\tGrid stage output:\t[%.4f %.4f %.4f %.4f %.4f] (%d min)\n',gridParams,round(toc./60));

% search fit
tic;
try
    hrfParams = ...
    fmincon(@(x) hrfFit(x,data,prediction,rawrss,FIR_time,estimate_dc),...
    gridParams,[],[],[],[],bndParams(:,1),bndParams(:,2),[],hrfParams.searchOptions);

catch ME
    warning(ME.identifier, ME.message)
    fprintf('[%s]: HRF search failed due to error shown above. Using HRF grid solution\n', mfilename)
    hrfParams = gridParams;
end

fprintf(1,'\tSearch stage output:\t[%.4f %.4f %.4f %.4f %.4f] (%d min)\n',hrfParams,round(toc./60));
fprintf(1,'[%s]:Estimating HRF...Done. (%s)\n',mfilename,datestr(now));drawnow;

return;





%-----------------------------------------
function e=hrfFit(params,data,stim,rawrss,t,estimate_dc)
% accuracy of penalizing factors
acc = 0.005;

% assign maximal rss
e = 1e6;

%--- parameter sanity checks
% no negative params (but params(3:5) can be zero)
if any(params(1:2)<=0) || any(params(3:5)<0), return; end; 
if params(5)~=0
    % positive peak first for two gammas
    if params(3)<=(params(1)+1), return; end;
    % first gamma must be equal in width to the second one
    if params(4)<params(2), return; end
end

%--- make hrf
hrf = twogammas(t,params);

% under some rare cercumstances the hrf contains NaNs
if sum(~isfinite(hrf(:)))
    return
end

%--- hrf sanity checks
% finish HRF at the end close to the start
if any(abs(hrf(end-2:end))>acc), return; end;
% must have some positive peak
if max(hrf)<=0, return; end
% response must be net positive
if sum(hrf)<=0, return; end
% penalize a second peak
% (a) get diff (approximate derivative)
d = diff(hrf);  
% (b) are there two rising slopes
if any(diff(find(d>acc))-1)
    % two gamma function should end with a rising slope
    % (ie no two positive peaks), because we are looking at the slope
    % we increase the accuracy
    if (find(d>acc/20,1,'last') < find(d<-acc/20,1,'last')),
        return;
    end
end

%--- make prediction
for n=1:numel(stim)
    tmp(n).ind = filter(hrf,1,stim{n})';
end
pred = [tmp(:).ind]';

%--- fit prediction (simple regression much faster in this case then GLM)
pred = lin_reg_matrix(pred,data,estimate_dc);

%--- compute reverse of variance explained
% rss for each voxel
rss = sum((data-pred).^2);
%--- compute reverse of variance explained
% error in percent
e = double(mean(rss./rawrss).*1e6);

return;
%-----------------------------------------



%-------------------------------------------------------------
function [h]=twogammas(t,params)
% from rfConvolveTC

% params
peak1 = params(1);
fwhm1 = params(2);
peak2 = params(3);
fwhm2 = params(4);
dip   = params(5);

% Taylor:
alpha1=peak1^2/fwhm1^2*8*log(2);
beta1=fwhm1^2/peak1/8/log(2);
gamma1=(t/peak1).^alpha1.*exp(-(t-peak1)./beta1);

if peak2>0 && fwhm2>0
    alpha2=peak2^2/fwhm2^2*8*log(2);
    beta2=fwhm2^2/peak2/8/log(2);
    gamma2=(t/peak2).^alpha2.*exp(-(t-peak2)./beta2);
else
    gamma2=min(abs(t-peak2))==abs(t-peak2);
end
h = gamma1-dip*gamma2;

return;
%-------------------------------------------------------------

%-------------------------------------------------------------
function y0 = lin_reg_matrix(x,y,estimate_dc)
x = single(x);
y = single(y);

% number of points
n = single(size(x,1));
ii = ones(n,1,'single');

% Accumulate intermediate sums
sx = sum(x);
sy = sum(y);
sxx = sum(x.^2);
%m = sum(y.^2);
sxy = sum(x.*y);

if estimate_dc
    % Compute curve coefficients
    b = (n.*sxy - sy.*sx)./(n.*sxx - sx.^2);
    b(isnan(b)) = 0;
    a = (sy - b.*sx)./n;
    b=abs(b);
    
    % Interpolation value
    y0 = (ii*b).*x;
    y0 = y0 + ii*a;
else
    % Compute curve coefficients
    b = (n.*sxy)./(n.*sxx);
    b(isnan(b)) = 0;
    b=abs(b);
    
    % Interpolation value
    y0 = (ii*b).*x;
end
return
%-------------------------------------------------------------
