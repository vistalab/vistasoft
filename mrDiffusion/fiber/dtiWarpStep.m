function newSteps = dtiWarpStep(origSteps,param)
% Warp (shift and scale) the steps into a new coord system
% 
%    newSteps = dtiWarpStep(origSteps,param)
% 
%    Shifts and scales according to: f(x,p) = ( x+p(2) ) * p(1)
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
% 
% History:
%    2007/01/17 shc wrote it.
% 

if ieNotDefined('origSteps'), error('Require input data!');         end
if ieNotDefined('param'),     error('Require warping parameters!'); end

newSteps = (origSteps+param(2))*param(1);

return
