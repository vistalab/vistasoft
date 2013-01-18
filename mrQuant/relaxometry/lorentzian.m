function g = lorentzian(delta,t2);

%T2B = 11e-6;
dtheta = 1/1000;

%d_delta = [0; delta];
[theta, Delta] = meshgrid([1:1/dtheta]*dtheta*pi/2, delta.');

tmp = t2./abs(3*cos(theta).^2-1);

tmp2 = tmp.*exp(-2*(2*pi*Delta.*tmp).^2).*sin(theta);
% g = sqrt(2/pi)*trapz(tmp2,2)*dtheta;

g = sqrt(2/pi)*trapz(tmp2,2)*dtheta;