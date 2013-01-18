function G = gaborPyramid(s, theta, sz);
% Create a gabor wavelet pyramid.
%
% G = gaborPyramid(<s=0:2>, <theta=22.5:22.5:180>, <sz=[256 256]>);
%
% BACKGROUND: this function creates a wavelet pyramid analogous to that
% used by Kay et al (Nature 2000) to represent images for application to
% fMRI activity patterns. This pyramid contains a series of Gabor wavelets,
% each similar to the one described by Tai Sing Lee, "Image Representation 
% Using 2D Gabor Wavelets". 
% (IEEE Transactions 1996: online at www.cnbc.cmu.edu/~tai/papers/pami.pdf)
%
% "Gabor" wavelets (or "Weyl-Heisenberg groups" in physics) are a combined
% harmonic and Gaussian function which the physicist Dennis Gabor showed
% convey an optimal combination of spatial (or temporal) position localization 
% and frequency-domain localization. These functions serve as models of 
% receptive fields for early visual neurons, esp. simple cells. See the Lee 
% paper for more background. 
%
% "Pyramid" refers to the fact that, for different spatial frequencies,
% there will be a different number of channels, spanning the different
% positions that can be localized. This code follows the Kay et al
% convention of having spatial frequencies be powers of 2 in cycles per
% image: for 2 cycles per image, there will be 2^2=4 possible positions;
% for 4 cycles per image, there will be 4^2 possible positions.
%
%
% INPUTS:
% s: vector of spatial frequencies to use. s should be an integer, and specify 
% the log base 2 of the spatial frequency, in units of cycles / image. That is,
% 2^s is the number of cycles in the image for a given channel. 
% E.g.: s=0 indicates a single cycle per image; s=1 indicates two cycles 
% per image. A DC offset is automatically added to the list of channels as well, 
% which has undefined spatial frequency (2^s = 0).
%
% theta: vector of orientations to use, in degrees counterclockwise from
% the x0 axis. That is, 0=horizontal, 45 = increasing in x0/y0 direction, 90 =
% vertical, 135 = increasing in x0 while decreasing in y0 direction. Note
% that theta is cyclic with modulo 180 (theta=200 is the same as theta=20).
%
% sz: size [x y] of the resulting wavelets.
%
% OUTPUTS:
% Return results in a structure G, with the following fields:
%	odd: 3-D matrix of size [imgSize(1) imgSize(2) nChannels].
%		odd-symmetric (sine) component channels.
%		The # of channels depends on omega and theta (see above), and
%		represents the even channels only in the complex function.
%	even: same size as odd, containing even-symmetric (cosine) component
%	channels.
%	cyclesPerImage: vector of wavelengths corresponding to each channel.
%	orientation: vector of orientations corresponding to each channel.
%	x0: vector of x0 position centers for each channel
%	y0: vector of y0 position centers for each channel.
%
% REFERENCES: We implement a version of the wavelet decomposition used in
% Kay et al., Nature 2008. See also www.cnbc.cmu.edu/~tai/papers/pami.pdf.
%
% ras, 03/2008.
if notDefined('s'),			s = 0:2;					end
if notDefined('theta'),		theta = 22.5:22.5:180;		end
if notDefined('sz'),		sz = [128 128];				end

%%%%% params / setup
%% constants
kappa = 2.5; % pi;  % constrains the spat. freq. bandwith to be 1 octave

%% parse inputs
if length(sz)==1  % square image, only 1 size specified
	sz = [sz sz];
end

%% init empty struct
G.odd = [];
G.even = [];
G.layer = [];
G.cyclesPerImage = [];
G.orientation = [];
G.x0 = [];
G.y0 = [];


%%%%% (1) determine the number of channels
% first, convert the spatial frequency param s into units of cycles per
% image (cpi):
cpi = 2 .^ s;  

% we add one channel for the DC component:
cpi = [0 cpi];

% for each # of cycles/image, we have a square grid of positions for that
% frequency (see Kay et al, Sup Fig 2). 
tmp = sum( cpi .^ 2 ); % # of joint spatial-frequency/position combinations

% for each layer except the first one, we have one channel for each
% orientation. So, figure out the total # of channels:
nChannels = tmp * length(theta) + 1;
G.nChannels = nChannels;

%%%%% (2) determine parameters for each channel
% now, assign to each channel a unique combination of spatial frequency
% (cyclesPerImage), orientation, and position (x0 and y0). We'll call the 
% set of channels corresponding to this spat. freq a "layer" in the pyramid:
for layer = 1:length(cpi)
	% the 0 cycles/image layer is a special case: only 1 DC channel
	if cpi(layer)==0
		G.layer = 1;
		G.cyclesPerImage = 0;
		G.orientation = 0; % could be NaN; this will help w/ plotting
		G.x0 = 0;
		G.y0 = 0;
		
	else
		% # positions along x/y axis for this layer
		nGrid = cpi(layer); 
		
		% # channels in this layer
		n = length(theta) * nGrid ^ 2;

		% append cpi, orientation values
		G.layer = [G.layer repmat(layer, [1 n])];		
		G.cyclesPerImage = [ G.cyclesPerImage, repmat(cpi(layer), [1 n]) ];
		G.orientation = [ G.orientation, repmat(theta, [1 nGrid^2]) ];
		
		% get a grid of (x0, y0) centers for each position for this layer
		% these positions are in pixels from the uppper left-hand corner of
		% the image:
		yRange = linspace(0, sz(1), nGrid+2);  yRange = yRange(2:end-1);
		xRange = linspace(0, sz(2), nGrid+2);  xRange = xRange(2:end-1);
		[x0 y0] = meshgrid( xRange, yRange );
		
		% we tile the position space separately for each orientation
		x0 = repmat(x0(:)', [length(theta) 1]);
		y0 = repmat(y0(:)', [length(theta) 1]);
		G.x0 = [G.x0, x0(:)'];
		G.y0 = [G.y0, y0(:)'];
	end
end


%%%%% (3) create the channels
% initialize the empty channels
G.odd	= zeros(sz(1), sz(2), nChannels);
G.even	= zeros(sz(1), sz(2), nChannels);

% main loop
for n = 1:nChannels
	% get a map of (x,y) pixel positions relative to the center of the
	% Gabor function for this channel (x0, y0) across the image
	[x y] = meshgrid( [1:sz(2)] - G.x0(n), [1:sz(1)] - G.y0(n) );
	
	% express the orientation in radians
	theta = G.orientation(n) * pi/180;
	
	% convert spatial frequency from units of cycles per image to units of
	% radians per unit distance: we take as the image size the larger of
	% the two edge lengths for the image:
	omega = 2*pi * G.cyclesPerImage(n)*2 / max(sz);
	
	% compute the wavelet
	phi = gaborWavelet(x, y, theta, omega, kappa);

	% grab the odd and even components
	G.even(:,:,n)	= real(phi);
	G.odd(:,:,n)	= imag(phi);	
end

% to save memory, let's make everything single-precision
for f = fieldnames(G)'
	G.(f{1}) = single( G.(f{1}) );
end

return





