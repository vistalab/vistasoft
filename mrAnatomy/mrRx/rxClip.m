function img = rxClip(img, clip, brightness, contrast, auto);
%  img = rxClip(img, [clip, brightness, contrast, auto]);
%
% Clip / Brightness-adjust / Contrast-adjust an image
% for mrRx. Takes in a 2D matrix and returns a 3D 
% true color image.
%
% clip is a 2D vector of [min max], normalized from
% 0 - 1. Will rescale this to the image's min and
% max values. If omitted, defaults to [0 1].
%
% brightness and contrast can either be
% values ranging from 0 to 1, or else mrRx 
% slider structs (or slider handles), in which
% case it'll read the values off the slider.
% 
% auto is an optional flag/handle to a checkbox: it determines
% whether or not to use auto-clipping for contrast instead of the 
% contrast slider. It can be logical (0 or 1), in which case 1 means
% use the histoThresh criterion, or it can be a handle to a 
% uicontrol, in which case, it determines whether to threshold based
% on the value of the control (if it's nonzero, e.g., checkbox checked).
% [default 0, don't auto-threshold]
%
% ras 02/05.
if notDefined('clip'),          clip = [0 1];           end
if notDefined('brightness'),    brightness = 0.5;       end
if notDefined('contrast'),      contrast = 0.6;         end
if notDefined('auto'),      	auto = 1;               end

% check if a handle is passed in for the auto arg
if not(ismember(auto, [0 1])) & ishandle(auto)
    auto = get(auto, 'Value');
end

% read bright/contrast off ui controls if passed
if isstruct(brightness) & ishandle(brightness.sliderHandle)
    brightness = get(brightness.sliderHandle,'Value');
elseif ishandle(brightness)
    brightness = get(brightness,'Value');
end

if isstruct(contrast)
    contrast = get(contrast.sliderHandle,'Value');
elseif ishandle(brightness)
    contrast = get(contrast,'Value');
end

if auto==1
    % use histogram to get contrast tresholds
    img = histoThresh(img);
else
    % set contrast manually
    rng = double(mrvMinmax(img));
    clip = clip .* rng;
    if contrast ~= 0.5
        clip(2) = clip(1) + (max(img(:))-clip(1))*(1-contrast);
    end

    % clip
    img(img < clip(1)) = clip(1);
    img(img > clip(2)) = clip(2);
    img = normalize(double(img),0,255);
    img = uint8(img);
end

% set brightness
cmap = gray(256);
delta = 2*brightness - 1;
if delta ~= 0
    cmap = brighten(cmap,delta);
end

% convert to RGB image
img = ind2rgb(img,cmap);


return
