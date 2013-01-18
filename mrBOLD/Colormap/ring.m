function [ringImg, cMap] = ring(background,linearizeFlag,dutyCycle,numImages,hemoDelay,cycleDuration);
%
% [ringImg, cMap] = ring([background],[linearizeFlag],[dutyCycle],[numImages],[hemoDelay],[cycleDuration])
%
% Author:  Press, Wandell, Brrewer
% Purpose:
%   Ring creates and displays an expanding ring phase map.
%   Calls the function ringMap.
%   This function produces the image itself.  The data are assigned to
%   userdata in the image window, as well as returned.
%
% Background -    0: black
%			default: 1: white
%
% LinearizeFlag - 0: non linealized colormap (default)
%                 1: linearized colormaps
% dutyCycle - default pi/4 duty cycle
% numImages - default 18 images shown per cycle
% hemoDelay - default 3 second hemodynamic delay
% cycleDuration - deault 36 seconds\
%
% This routine should be integrated with mrLoadRet to produce the color map
% associated with the current window/callback-window
%
% Examples:
%    ring(0);
%    bkg = 1; linearize = 0; dutyCycle = []; numImages = 18; hemoDelay = 7; cycleDuration = 36; 
%    ring(bkg,linearize,dutyCycle,numImages,hemoDelay,cycleDuration);

if ~exist('background','var')    | isempty(background),    background = 1; end
if ~exist('linearizeFlag','var') | isempty(linearizeFlag), linearizeFlag = 0; end
if ~exist('dutyCycle','var')     | isempty(dutyCycle),     dutyCycle = pi/4; end
if ~exist('numImages','var')     | isempty(numImages),     numImages = 18; end
if ~exist('hemoDelay','var')     | isempty(hemoDelay),     hemoDelay = 3; end
if ~exist('cycleDuration','var') | isempty(cycleDuration), cycleDuration = 36; end

phaseOffset = 3*pi/2 - dutyCycle/2 + 2*pi/numImages + 2*pi*hemoDelay/cycleDuration;

if linearizeFlag
   gammaLeft = 2;
   gammaRight = 1.3;
else
   gammaLeft = 1;
   gammaRight = 1;
end

background = background*ones(1,3);

hsvMap = hsv(128);
indicesLeft = 1:64;
indicesRight = 65:128;
hsvMap(indicesLeft,:) = hsvMap(indicesLeft,:) .^ (1/gammaLeft);
hsvMap(indicesRight,:) = hsvMap(indicesRight,:) .^ (1/gammaRight);

% make ring map
po = round(phaseOffset/(2*pi)*size(hsvMap,1))+1;
ring = [hsvMap(po:128,:); hsvMap(1:po-1,:); background];
[ringImg, cMap] = ringMap(ring);

figure;
image(ringImg);  colormap(cMap);
truesize; axis off;
data.ringImg = ringImg;  
data.ringMap = cMap;
set(gca,'userdata',data);

return;
