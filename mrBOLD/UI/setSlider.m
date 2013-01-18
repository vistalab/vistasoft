function vw = setSlider(vw,slider,val,sigFigs)
%
% vw = setSlider(vw,slider,[val],[sigFigs])
%
% Sets the slider value and updates the text label.  If val is
% not provided, grabs it from the slider itself, i.e., doesn't
% change the value, but still updates the text label.  Prompts
% the user for a slider value if the slider is pegged at max.
%
% slider: slider structure that contains a slot for the slider
% handle itself, the slot for the name of the slider and a slot
% for the handle of the text label.
%
% val: value to set the slider to.  Default is to grab that value
% from the sliderHandle.
% 
% sigFigs: # of significant figures (after decimal) to display for 
% the slider value text. Default is 2.
%
% djh, 1/16/97
% rmk, 1/25/99 added 'hit enter for max value'
% djh, 4/99 catch out of range value and reset it to min/max
% bw,  01/17/01 leave the max value at max for slice and scan sliders
% ras, 04/24/04 decided a more sensible way to handle the whole 
%               'how-do-I-manually-enter-a-slider-value' issue would
%               be better dealt with by having the label contain an edit 
%               field for this purpose, and disabling the  
%               feature that causes the max value to give a command prompt.
if ieNotDefined('sigFigs')
    sigFigs = 2;
end

sliderHandle=slider.sliderHandle;

% If val not passed in, get it from the slider.  If pegged at
% max, prompt user for a new value.
minVal = get(sliderHandle,'min');
maxVal = get(sliderHandle,'max');

if ~exist('val','var')
   val = get(sliderHandle,'Value');

end

% If outside valid range, reset it
if (val < minVal) 
   val = minVal;
end 
if (val > maxVal)
   val = maxVal;
end

% Set slider value
set(sliderHandle,'Value',val);

% Update slider edit field label
pattern = ['%2.' num2str(sigFigs) 'f'];
str = sprintf(pattern,val);
set(slider.labelHandle,'String',str);

% Return the current axes to the main image.  BW 07/28/99
% I added the figure call.  There were occasions where this
% was called and a different window was active, so that caused
% me problems.  I made the VOLUME window come forward.
%
% figure(vw.ui.windowHandle);
set(vw.ui.windowHandle,'CurrentAxes',vw.ui.mainAxisHandle);

return;

