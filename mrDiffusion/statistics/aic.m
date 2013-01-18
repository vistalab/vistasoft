function AIC=aic(nParameters, nObservations, Residuals)
%Computes Akaike information criterion for a model
%
%
%
% Implements http://en.wikipedia.org/wiki/Akaike_information_criterion

% HISTORY: 
% ER wrote it 01/2010

AIC =2*(nParameters)+nObservations*(log(sum(Residuals.^2)/nObservations)); 