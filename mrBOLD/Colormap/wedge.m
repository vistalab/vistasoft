function [wedgeImg, cMap ] = wedge(orientation,background,linearizeFlag,dutyCycle,numImages,hemoDelay,cycleDuration)
% 
%  [wedgeImg, cMap ] = wedge([orientation],[background],[linearizeFlag],[dutyCycle],[numImages],[hemoDelay],[cycleDuration])
%
% Author: Press, Wandell, Brewer
% Purpose:
%     Creates and displays a rotating wedge phase map.
%
% Orientation -   0: start in upper-left visual field, rotate CW   (binoculars)
%                 1: start in upper-right visual field, rotate CCW (projector) (default)
% Background -    0: black
%		          1: white (default)
% LinearizeFlag - 0: non linealized colormap (default)
%                 1: linearized colormaps  
% dutyCycle - default pi/2 duty cycle
% numImages - default 18 images shown per cycle
% hemoDelay - default 3 second hemodynamic delay
% cycleDuration - deault 36 seconds
%
% Examples
%    wedge;
%    ori = 1; bkg = 1; lin = 1;
%    wedge(ori,bkg,lin,[],[],4,[]);
%
% TODO:
%  3.26.00 (BW) Bug concerning po computation below.  See comment
%

if ~exist('orientation','var') || isempty(orientation),     orientation = 1; end
if ~exist('background','var')  || isempty(background),      background = 1;  end
if ~exist('linearizeFlag','var') || isempty(linearizeFlag), linearizeFlag = 0; end
if ~exist('dutyCycle','var') || isempty(dutyCycle),         dutyCycle = pi/2;  end
if ~exist('numImages','var') || isempty(numImages),         numImages = 18; end
if ~exist('hemoDelay','var') || isempty(hemoDelay),         hemoDelay = 3; end
if ~exist('cycleDuration','var') || isempty(cycleDuration), cycleDuration = 36; end

phaseOffset = - dutyCycle/2 + 2*pi/numImages + 2*pi*hemoDelay/cycleDuration;
% Add 3*pi/4 to get horizontal meridian phase offset (as the first
% image is just leaving the horizontal meridian).  Without 3*pi/4,
% we have the vertical meridian offset phase, which is what we
% want here.
% There are cases where the hemodelay is zero (because we average two
% directions of the wedge).  In that case, this value can be
% negative, and everything below breaks.  We need to fix it.

if linearizeFlag
   gammaLeft = 2;
   gammaRight = 1.3;
else
   gammaLeft = 1;
   gammaRight = 1;
end

background = background*ones(1,3);

hsvMap = hsv(128);
hsvMap(1:64,:) = hsvMap(1:64,:) .^ (1/gammaLeft);
hsvMap(65:128,:) = hsvMap(65:128,:) .^ (1/gammaRight);

% make left and right wedge maps

% These indices can turn out negative.  We should check
% this here. For example, I have a case where po = -8.
% This causes a crash.  BW.
%
po = round(phaseOffset/(2*pi)*size(hsvMap,1))+1;
if po < 1, error('Phase offset calculation error.  Hacker should fix'); end

indicesLeft = po:(po+63);
indicesRight = [(po+64):128 1:(po-1)];

rotatedHsvMap = hsvMap;
rotatedHsvMap(1:64,:) = hsvMap(indicesLeft,:);
rotatedHsvMap(65:128,:) = hsvMap(indicesRight,:);

l = [rotatedHsvMap(1:64,:); background];
r = [rotatedHsvMap(65:128,:); background];
b = [rotatedHsvMap; background];
[limg, lmap] = wedgeMap(l,128,180);
[rimg, rmap] = wedgeMap(r,128,180);
[wedgeImg, cMap] = wedgeMap(b,128,360);

limg = fliplr(limg);
limg = flipud(limg);
wedgeImg = flipud(wedgeImg);
wedgeImg = fliplr(wedgeImg);

if orientation
   tmap = lmap;
   lmap = rmap;
   rmap = tmap;
   limg = flipud(limg);
   rimg = flipud(rimg);
   wedgeImg = fliplr(wedgeImg);
end

%figure;image(limg);colormap(lmap);truesize;axis off;
%figure;image(rimg);colormap(rmap);truesize;axis off;
figure; 
image(wedgeImg);
colormap(cMap);
truesize;axis off;

data.wedgeImg = wedgeImg;
data.cMap = cMap;

set(gca,'userdata',data);
return;
