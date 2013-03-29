function anatIm = recomputeAnatImage(vw,displayMode,slice)
% anatIm = recomputeAnatImage(vw,[displayMode],[slice]);
%
% Return the anat image, clipped and or scaled
% according to the (non-hidden) vw's ui settings,
% for the specified display mode. displayMode
% defaults to the currently-selected mode (e.g.,
% 'anat' 'amp' 'map' etc). slice defaults to the 
% current slice.
%
% 
%
% ras 01/05. Added b/c I want to migrate to using
% brightness/contrast/possibly gamma, but also 
% want back compatibility.
if isequal(viewGet(vw, 'Name'),'hidden')
    % hidden views: just return the anat
    % image w/o contrast adjustment
    %TODO: put slice error handling here
    anatIm = viewGet(view, 'anatomycurrentslice', slice);
    return
end

ui = viewGet(vw,'ui');

if ieNotDefined('slice')
	% Get curSlice from ui
	slice = viewGet(vw, 'curSlice');
end

if ieNotDefined('displayMode')
    displayMode = ui.displayMode;
end

modeStr = sprintf('%sMode',displayMode);
numGrays = ui.(modeStr).numGrays;

% Get anatomy image from vw (non-scaled)
anatIm = cropCurAnatSlice(vw,slice);	

if isfield(ui,'brightness')
    % adjust img brightness/contrast
    brightness = get(ui.brightness.sliderHandle,'Value');
    contrast = get(ui.contrast.sliderHandle,'Value');
    
    % unlike the normal way contrast/brightness work,
    % I've found it's better to have 'contrast'
    % just change the upper bound of the anatClip,
    % and 'brightness' just shift the median value
    % up and down a bit:
    minVal = double(min(anatIm(:)));
	maxVal = (1-contrast)*double(max(anatIm(:)));
    % removed lines that turned off/on warnings...
	anatIm = (rescale2(double(anatIm),[minVal maxVal],[1 numGrays])); 
    
    % brighten
    brightDelta = brightness - 0.5;
    if brightDelta ~= 0 % slowwww....
        anatIm = brighten(anatIm,brightDelta);
        anatIm = rescale2(anatIm,[],[1 numGrays]);
    end
else
    % do it the old way, using the 
    % anat clip slider values

	% Get anatClip from sliders
	anatClip = getAnatClip(vw);
		
	% Rescale anatIm to [1:numGrays], anatClip determines the range
	% of anatomy values that gets mapped to the available grayscales.
	% If anatClip=[0,1] then there is no clipping and the entire
	% range of anatomy values is scaled to the range of available gray
	% scales.
    minVal = double(min(anatIm(:)));
	maxVal = double(max(anatIm(:)));
	anatClipMin = min(anatClip)*(maxVal-minVal) + minVal;
	anatClipMax = max(anatClip)*(maxVal-minVal) + minVal;
	warning off;
	anatIm = (rescale2(double(anatIm),[anatClipMin,anatClipMax],[1,numGrays]));
	warning backtrace;
end

return




% This way seemed sensible, but
% the images didn't look as great as
% I'd hoped:
%     % Will rescale the values in anatIm to be
%     % distributed with a median determined by
%     % the brightness param, and a range of values
%     % determined by contrast -- but it will all
%     % fit in the range 1:numGrays:
%     mu = round(brightness*numGrays);
%     sigma = (1-contrast) * (numGrays/2-1) + 1;
%     anatIm = rescale2(anatIm,[],[-sigma sigma]) + mu;    
%     
%     % need a 2nd clip step -- could set this in the 
%     % rescale2 step, but it's the same # of cycles to 
%     % do it this way, I think, and more legible:
%     anatIm(anatIm <= 1) = 1;
%     anatIm(anatIm >= numGrays) = numGrays;
