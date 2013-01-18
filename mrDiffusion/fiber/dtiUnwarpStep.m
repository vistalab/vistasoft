function newSteps = dtiUnwarpStep(origSteps,param)
% Unwarp (shift and scale) the steps into a new coord system
% 
%    newSteps = dtiUnwarpStep(origSteps,param)
% 
%    Shifts and scales according to: f(x,p) = ( x/p(1) ) - p(2)
% 
%    origSteps - nx1 vector
%    param     - 2x1 vector [scale shift]
% 
%    newSteps  - nx1 vector
% 
% Example:
%    % original x's
%    x = 1:10;
%    % stretch by 2 times after shifting 5 units to the right
%    nx = dtiWarpStep(x,[2 5]);
%    % go back to the original
%    ox = dtiUnwarpStep(nx,[2 5]);
% 
% See also: dtiWarpStep
% 
% History:
%    2007/01/17 shc wrote it.
% 

if ieNotDefined('origSteps'), error('Require input data!');         end
if ieNotDefined('param'),     error('Require warping parameters!'); end

newSteps = (origSteps/param(1))-param(2);

return
