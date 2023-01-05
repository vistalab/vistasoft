function [err,testShift] = CMFfitOneMeridianFun( testShift, uDistTemplate, mnPhTemplate, uDist, mnPh)% % AUTHOR:  Wandell, Brewer% PURPOSE:% %   The CMF data have an observed relative uDist and complex phase (mnPh).
% The absolute value of the distance, however, is not meaningful.
% We can add or subtract a constant from each of the meridia because
% they don't start in exactly the same place.
%
%   This routine slides the distance of the data to be in
% register with a template function.  Usually one of the
% the data sets themselves is used as the template.
%
% We search for a distance shift (testShift) that 
% brings the data into register with the template data.
%
% DEBUG:
% template = meridia(1);
% testShift = 3; uDist = meridia(2).uDist; mnPh = meridia(2).mnPh;
% CMFfitOneMeridianFun( testShift, template, uDist,mnPh)
warning('Not used, we think.');

% Interpolate the test data set using the testShift parameter
% This uses the existing data to predict the values at the template
% The mnPh data are complex.
%
predicted = interp1(uDist + testShift, mnPh, uDistTemplate, 'linear');
% try adding 'extrap' option to interp1?

% A few of the data may be out of range.  These produce NaNs in the
% interpolation.  Count these;  if there are too many send a big error 
% back.  Otherwise, send back the norm difference, but accounting for
% the number of points used to do the fit.
% I wish I had a reason for using 0.65.
%
l = ~isnan(predicted);
if sum(l) > 0.65*length(uDistTemplate)
   err = norm(predicted(l) - mnPhTemplate(l))/sqrt(length(l));
else
   err = 1000;  % A large number
end

return;
