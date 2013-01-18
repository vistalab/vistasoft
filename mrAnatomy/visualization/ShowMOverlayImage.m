function  ShowMOverlayImage(GrayIm,overIm,threshold,Incmap,clusterThresh)
% Take two images and display them as a base and overlay of
%
%   ShowMOverlayImage(GrayIm,overIm,threshold,Incmap,clusterThresh)
%
% GrayIm will be the gray scale image and one will overIm overlay the gray
% image.  Note that the image HAVE to be in the same size and
% transformation !!!
%
% Incmap is the color map that will be used for the overlay image. Incmap
%   is [26 3] matrix the default = autumn(256).
% threshold is the values from which the The overlay image will be shown
%   default = 0;
%
% The function also show a bar that is black up to the threshold value.
% clusterThresh is the number of voxels of the smallest cluster in the
% overlay image default = 0;
%
% Example:
%   threshold = 5;
%   GrayIm=rand([10,10,10]);
%   overIm=rand([10,10,10])*10;
%   Incmap=autumn(256);
%   clusterThresh=10;
%   ShowMOverlayImage(GrayIm,overIm,threshold,Incmap,clusterThresh )
%
% Bob (c) VISTASOFT Team, 2009


%% Argument checking
if (~exist('threshold','var')||isempty(threshold)), threshold=0; end;
if (~exist('Incmap','var')||isempty(Incmap)), Incmap=autumn(256); end;
if (~exist('GrayIm','var')||isempty(GrayIm)), error('no gray image'); end;
if (~exist('overIm','var')||isempty(overIm)), error('no Overlay image'); end;
if(~exist('clusterThresh','var')||isempty(clusterThresh)), clusterThresh = 0; end
clusterConnectivity = 18;

%% Make  a rgb for the gray iImage
rgb=repmat(GrayIm,[1 1 1 3]);

%make the mask for that overlay
%take only the above threshold
mask=(overIm>threshold);

%take only the cluster obove the clusterThresh
if(clusterThresh>0)
    mask = (bwareaopen(mask,clusterThresh,clusterConnectivity));
end

mask = repmat(mask,[1 1 1 3]);

% Scale overlay to 0-1, but remember the original range for making the colorbar
over_rng = [min(overIm(:)) max(overIm(:))];
overIm = (overIm-over_rng(1))./diff(over_rng);


%% black-out the thresholded part of the cmap:
threshold_index = round(threshold/diff(over_rng)*255)+1;

colorMP = Incmap(1:256-threshold_index,:);
cmap    = vertcat(zeros(threshold_index,3),colorMP);

over_rgb  = reshape(cmap(round(overIm*255+1),:), [size(overIm) 3]);
rgb(mask) = over_rgb(mask);
rgb       = uint8(rgb*255);
image(makeMontage3(rgb));

cbar_numbers = round(linspace(over_rng(1), over_rng(2), 5)*10)/10;
mrUtilMakeColorbar(cmap,cbar_numbers,'Data');

%% End