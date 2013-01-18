function fiber_curvature_vals=dtiFiberCurvature(fiber)

%For 3xn fiber computes curvature at each point as defined here
%http://en.wikipedia.org/wiki/Curvature (I know it is a shame to use Wiki
%for research -- but oh well
%
%ER 12/2007
xprime=gradient(fiber(1, :)); 
yprime=gradient(fiber(2, :)); 
zprime=gradient(fiber(3, :)); 

fiber_curvature_vals=sqrt((gradient(zprime).*yprime-gradient(yprime).*zprime).^2+(gradient(xprime).*zprime-gradient(zprime).*xprime).^2+(gradient(yprime).*xprime-gradient(xprime).*yprime).^2)./((xprime.^2 + yprime.^2 + zprime.^2).^(3/2));
%fiber_curvature_vals=fiber_curvature_vals./max(fiber_curvature_vals(:));

% These values are sometimes huge. what is the distribution? The original
% data are not unitless. 
