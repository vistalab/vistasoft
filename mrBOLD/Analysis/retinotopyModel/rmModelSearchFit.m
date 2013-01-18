function e = rmModelSearchFit(p,Y,trends,params,rawrss);
% rmModelSearchFit - actual fit function of rmSearchFit
%
% error = rmModelSearchFit(p,Y,trends,params);
%
% Basic fit with several hard limits on where the values can
% go. When encountering a set limit error will go to infinity. We
% may want to consider a more smooth limit.
%
% 2006/06 SOD: wrote it.

% sigma should be > 0 and < sigmaRatioInfVal
% This is a hard border beyond which the estimates cannot go.
if p(3)<=0 | p(3)>params.analysis.sigmaRatioInfVal, e = realmax; return; end;

% don't estimate too far away from the stimulus size, say 10x
if sqrt(p(1).^2+p(2).^2) > 10*max([params.stim(:).stimSize]), e = realmax; return; end;

% input check for 1 or 2 Gaussians
if numel(p) == 3,
  gaussianId = [p(3) p(3) 0 p(1) p(2)];
else,
  % also check that second Gaussian is at least twice as big as the
  % first one
  if p(4)< 2.*p(3) | p(4)>params.analysis.sigmaRatioInfVal, e = realmax; return; end;
  gaussianId = [p(3) p(3) 0 p(1) p(2);p(4) p(4) 0 p(1) p(2)];
end;

% make prediction
[pred, weight] = rfMakePrediction(params,gaussianId);

% Another hard border that depends on the relative overlap with
% stimulus window and penalizes pRFs too far away or too
% large. We'll do this only for the 1st pRF.
if weight(1)<0.01, e = realmax; return; end;

% fit
X = [pred trends];
b = pinv(X)*Y;

% Last sanity checks:
% The first pRF should be positive. 
if b(1)<0, e = realmax; return; end;
% For two Gaussians the center should always be positive.
if numel(p) == 4,
  if b(1)+b(2)<=0, e = realmax; return; end;
end;

% RSS weighted by amount within of RF in stimulus window
% e = sum((Y - X*b).^2) ./ weight;
e = norm(Y - X*b).^2;

% if rawrss is given scale rss relative to rawrss,
% otherwise report actuall rss.
if nargin > 4,
  e = e./rawrss.*100;
end;

return;
