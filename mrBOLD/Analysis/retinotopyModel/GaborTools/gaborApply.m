function [ce, filt_even, filt_odd, img] = gaborApply(img, G);
% Apply a Gabor Wavelet Pyramid to an image, returning the estimated
% contrast energy for each channel.
%
%  ce = gaborApply(<img=dialog for image file>, <G=default Gabor pyramid>);
%
% INPUTS:
%	img: 2D grayscale image matrix, a path to an image file, a cell array
%	of many images, or a 3D matrix of many images. Images should all be the
%	same size. For multiple images, the code will apply the Gabor pyramid
%	to each separately.
%
%	G: Gabor pyramid. If omitted, creates a default pyramid the same size
%	as the image using gaborPyramid.
%
% OUTPUTS:
%	ce: nChannels x nImages matrix of contrast energy for each image,
%	across each channel. The contrast energy is the square root of the sum
%	of energy across even/odd quadrature wavelet pairs. For the DC
%	(luminance-only) channel, the contrast energy is the square root of 
%	the sum-square of the image.
%
%	filt_even: convolution of each of the even channels onto each image. A
%	4-D matrix of size rows x cols x channels x images.
%
%	filt_odd: same as filt_even, except for the odd-symmetric channels.
%
%	img: parsed-out 3-D matrix of grayscale images (after loading,
%	normalizing, etc).
%
% ras, 04/01/08 (for real).
if notDefined('img')
	f = {'*.jpg' 'JPEG files'; '*.png' 'Portable Network Grahpics'; ...
		 '*.tiff' 'TIFF files'; '*.*' 'All Files'};
	[f p] = uigetfile(f, 'Select an image file');
	img = fullfile(p, f);
end

% parse out how the image(s) were provided
if ischar(img)
	% load an image file
	img = imread(img);
elseif isnumeric(img)
	% enforce double-precision, grayscale 2-D image for now
	img = single( img(:,:,1) );	
elseif iscell(img)
	% convert cell array of (img paths, images) to a 3D matrix
	tmp = img; img = [];
	for ii = 1:length(tmp)
		if ischar(tmp{ii})
			subImg = imread(tmp{ii});
			img(:,:,ii) = single( subImg(:,:,1) );
		else
			img(:,:,ii) = single( tmp{ii}(:,:,1) );
		end
	end
end

% normalize
img = normalize(img, 0, 1);

nImages = size(img, 3);

% get default Gabor pyramid if none is provided
if notDefined('G'), 
	hbutton = buttondlg('Creating Gabor Wavelet Pyramid');
	G = gaborPyramid([], [], size(img));
	close(hbutton);
end

% init output matrices
ce = single( zeros(nImages, G.nChannels) );
if nargout > 1
	nRows = size(img, 1);  nCols = size(img, 2);
	filt_even = single( zeros(nRows, nCols, nImages, G.nChannels) );
	filt_odd = single( zeros(nRows, nCols, nImages, G.nChannels) );
end

%% main loop: filter each channel, get contrast energy
hwait = mrvWaitbar(0, 'Applying wavelet pyramid');
for n = 1:G.nChannels
	if G.cyclesPerImage(n)==0
		% Luminance-only (DC) channel: no quadrature pair
		filtA = img;
		filtB = img;
	else
		filtA = img .* repmat( G.even(:,:,n), [1 1 nImages] ); 
		filtB = img .* repmat( G.odd(:,:,n),  [1 1 nImages] ); 
	end
	
	for m = 1:nImages
		projA = sum(sum( filtA(:,:,m) )) .^ 2;
		projB = sum(sum( filtB(:,:,m) )) .^ 2 ;
		ce(n,m) = sqrt( projA + projB );
	end

	if nargout > 1
		filt_even(:,:,:,n) = filtA;
		filt_odd(:,:,:,n)  = filtB;
	end
	
	mrvWaitbar(n/length(G.cyclesPerImage), hwait);
end
close(hwait);

if nargout > 1
	% permute the filtered images to be rows x cols x channels x images
	filt_even = single( permute(filt_even, [1 2 4 3]) );
	filt_odd  = single( permute(filt_odd, [1 2 4 3]) );
end


return
