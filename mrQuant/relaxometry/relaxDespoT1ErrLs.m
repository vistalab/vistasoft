function [err,signal] = relaxDespoT1ErrLs(x, data, te, tr, ti, tiFa, alpha, tr_inv, k)

%x is of the form [t1, ro, k]

%load t1data.mat;

% t1 = x(1);
% ro = x(2);
% k = x(3);

%alpha_1 = 4*pi/180;
%alpha_2 = 18*pi/180;
%alpha_3 = 5*pi/180; %convert to radians

% *** Should te be used in here?


  if(exist('k','var'))
    % Allow the fit with a fixed k
    signal = x(2).*(1-exp(-tr./x(1))).*sin(k.*alpha)./(1-cos(k.*alpha).*exp(-tr./x(1)));
    signal(end+1) = x(2)*(1-(1-cos(k*pi))*exp(-ti/x(1))+exp(-tr_inv/x(1)))*sin(k*tiFa);
  else
    signal = x(2).*(1-exp(-tr./x(1))).*sin(x(3).*alpha)./(1-cos(x(3).*alpha).*exp(-tr./x(1)));
    signal(end+1) = x(2)*(1-(1-cos(x(3)*pi))*exp(-ti/x(1))+exp(-tr_inv/x(1)))*sin(x(3)*tiFa);
  end
  err = data - signal;
  % if(~all(isfinite(err))), keyboard; end

return;
