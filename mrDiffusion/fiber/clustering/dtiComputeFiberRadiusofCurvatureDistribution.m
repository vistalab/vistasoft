function [Cnorm, Curv, Mu, Sigma] = dtiComputeFiberRadiusofCurvatureDistribution(fg,displayDist)

% Calculate the mean curvature of individual fiber first, and then make a
% summary across fibers.
%
% [Cnorm, Curv, Mu, Sigma]= dtiComputeFiberRadiusofCurvatureDistribution(fg,displayDist)
%
% INPUTS:
% fibers   = A fiber group.
% displayDist = 1: Display the distribution plot. 0: Not display.
%
% Outputs:
% Cnorm    = Normalized radius of curvature of each fiber, in units of z-score.
% Curvature      = The mean radius of curvature of each fiber.
%
% Written by Hiromasa Takemura (c) Stanford University 2014

if notDefined('fg'), error('Fiber group required'); end

% Compute the curvature of fibers in individual nodes.
[fibercurvature] = dtiComputeFiberCurvature(fg);

% Calculate the mean of curvature in individual fibers.

for i = 1:length(fibercurvature)
   Curv(i) = 1./mean(fibercurvature{i}); 
    
end

% Z-score the curvature
% Here we take the log first so that the distribution of Curv is 'more'
% gaussian and because it it not clipped at 0.
[Cnorm, Mu, Sigma] = zscore(log10(Curv));

% Show a histagram
if displayDist==1
    mrvNewGraphWin('Distibutions of fiber lengths');
    hold on;
    [y, x] = hist(Curv,round(length(fg.fibers)*0.1));
    bar(x,y,'FaceColor','k','EdgeColor','k');
    axis([min(x) max(x) 0 max(y)]);
    xlabel('Curvature');
    plot(10.^[Mu Mu],[0 max(y)],'r','linewidth',2);
    plot(10.^[Mu-Sigma   Mu-Sigma],[0 max(y)],'--r');
    plot(10.^[Mu+Sigma   Mu+Sigma],[0 max(y)],'--r');
    plot(10.^[Mu-2*Sigma Mu-2*Sigma],[0 max(y)],'--r');
    plot(10.^[Mu+2*Sigma Mu+2*Sigma],[0 max(y)],'--r');
end

return
