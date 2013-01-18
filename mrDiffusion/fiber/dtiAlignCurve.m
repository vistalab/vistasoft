function p = dtiAlignCurve(origCurve,targetCurve)
% Compute the scale and shift factors for x and y to best align the curves
% 
%     p = dtiAlignCurve(origCurve,targetCurve)
% 
%     origCurve   - n1x2 matrix [origX origY]
%     targetCurve - n2x2 matrix [targetX targetY]
% 
%     p - 2x1 vector [scaleX shiftX scaleY shiftY]
% 
% History;
%    2007/01/17 shc wrote it.
%  

if ieNotDefined('origCurve'),   error('Require original curve data!'); end
if ieNotDefined('targetCurve'), error('Require target curve data!');   end

sz = size(origCurve);
if any(sz==1)
    origCurve = [(1:length(origCurve))' origCurve(:)];
elseif any(sz==2)
    if sz(1)==2 && sz(2)~=2
        origCurve = origCurve';
    end
else
    error('Unknown data format for the original: %d x %d!',sz(1),sz(2));
end

sz = size(targetCurve);
if any(sz==1)
    targetCurve = [(1:length(targetCurve))' targetCurve(:)];
elseif any(sz==2)
    if sz(1)==2 && sz(2)~=2
        targetCurve = targetCurve';
    end
else
    error('Unknown data format for the target: %d x %d!',sz(1),sz(2));
end

optimOpt = optimset('LargeScale','off','Display','notify',...
    'MaxFunEvals',5000,'MaxIter',5000);

xLB = -mean(targetCurve(:,1)-min(targetCurve(:,1)));
xUB = mean(targetCurve(:,1)-min(targetCurve(:,1)));

yLB = -nanmean(targetCurve(:,2)-min(targetCurve(:,2)))*10;
yUB = nanmean(targetCurve(:,2)-min(targetCurve(:,2)))*10;

% try fitting using fmincon
try
    f = @(x) (dtiComputeCurveDiff(x,origCurve,targetCurve));
    p = fmincon(f,[1 0 1 0],[],[],[],[],...
        [0.75 xLB 0.25 yLB],[1.25 xUB 1.75 yUB],...
        [],optimOpt);
catch
    fprintf('[%s]: fminsearch failed!\n',mfilename);
    rethrow(lasterror);
end

p = p(:);

return
