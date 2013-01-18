function errSS = dtiComputeCurveDiff(param,origCurve,targetCurve)
% Compute error sum of squares between 2 curves given the warping params
% 
%    errSS = dtiComputeCurveDiff(param,origCurve,targetCurve)
% 
%    param       - 4x1 vector [xScale xShift yScale yShift]
%    origCurve   - n1x2 matrix [origX origY]
%    targetCurve - n2x2 matrix [targetX targetY]
% 
%    errSS - sum of squares of differences between the 2 curves
% 
% History:
%    2007/01/17 shc wrote it.
% 

if ieNotDefined('param'),       error('Require warping parameters!');  end
if ieNotDefined('origCurve'),   error('Require original curve data!'); end
if ieNotDefined('targetCurve'), error('Require target curve data!');   end

x1 = origCurve(:,1);
x2 = targetCurve(:,1);

startPt = max([min(x1) dtiUnwarpStep(min(x2),param(1:2))]);
endPt   = min([max(x1) dtiUnwarpStep(max(x2),param(1:2))]);

xs = linspace(startPt,endPt,5000);

y1Hat = (spline(origCurve(:,1),origCurve(:,2),xs) + param(4)) * param(3);
y2Hat = spline(targetCurve(:,1),targetCurve(:,2),dtiWarpStep(xs,param));

errSS = sum((y1Hat - y2Hat) .^ 2) / (endPt - startPt);

return
