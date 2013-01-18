function phi = gaborWavelet(x, y, theta, omega, kappa, anisotropy);
% Main function to produce a single gabor wavelet. 
%
% phi = gaborWavelet(x, y, theta, omega, kappa, [anisotropy]);
%
% The equation is:
%
% phi = [omega / sqrt(2*pi*kappa)] * f * g,
%
% Where
%	f = exp[ -(omega^2 / 8*kappa) * a + b ],
%	a = 2 * (x * cos(theta) + y * sin(theta) )^2,
%	b = 2 * (-x * sin(theta) + y*cos(theta))^2, and
%	g = exp(i * (omega*x*cos(theta) + omega*y*sin(theta)) - exp(-kappa^2 / 2)
%
% f contributes the oriented 2D Gaussian envelope to the wavelet, while g
% contributes a harmonic function. 
%
% x, y: sample points (in an image).
% theta: orientation (degrees CCW from horizontal).
% omega: spatial frequency of harmonic; radians per unit distance (in x,y).
% kappa: constant which determines the bandwidth
% anisotropy: optional [2 x 1] vector which makes the Gaussian window
% anisotropic with respect to theta. The first element gives a weight to
% the Gaussian along the parallel direction, and the second along the
% perpendicular direction. (Verify that this is the right order.) [Default:
% [1 1], istropic Gaussian.]
%
% This is similar to equation (3) in Tai Sing Lee, 1996, IEEE Transactions:
% http://www.cnbc.cmu.edu/~tai/papers/pami.pdf. 
% However, I've adjusted the functions a and b to have coefficients 2 and
% 2, rather than 4 and 1 (which was the version in the Lee paper, and which
% made the Gaussian envolope anisotropic). This matches Sup. Fig. 2 in Kay
% et al 2008.
% For more information, see the help section for gaborPyramid.
%
% ras, 03/2008, with some help from priyanka singh.
if nargin < 6  
	% only call notDefined if some params are omitted -- calling takes time,
	% and this is a low-level function
	if notDefined('x') | notDefined('y')
		[x y] = meshgrid(-63:63, -63:63);
	end
	
	if notDefined('theta'),	theta = 0;	end
	if notDefined('omega'), omega = 1;  end
	if notDefined('kappa'), kappa = pi; end
	if notDefined('anisotropy'), anisotropy = [1 1];	end
end

coeff1 = omega ./ ( sqrt(2*pi) * kappa ); 
coeff2 = -omega.^2 ./ (8 * kappa^2);

weight1 = anisotropy(1);
weight2 = anisotropy(2);

a = 2 * [x.*cos(theta) + y.*sin(theta)].^2;
b = 2 * [-x.*sin(theta) + y.*cos(theta)].^2;
gaussian = exp(coeff2 * (weight1*a + weight2*b));

exponent = omega * x * cos(theta)  +  omega * y * sin(theta); 
harmonic = exp( j * exponent ) - exp( - kappa^2 / 2 );

phi = coeff1 * gaussian .* harmonic;

% normalize:
dc =  max(abs(phi(:))); 
dc(dc<=0) = eps;  % nominally small, so we don't divide by zero
phi = phi ./ dc;

% per Kay et al 2008, we restrict the spatial extent of each wavelet by
% zeroing out values less than 1% of the maximum:
phi( abs(phi) < .01 * max(abs(phi(:))) ) = 0;

return
