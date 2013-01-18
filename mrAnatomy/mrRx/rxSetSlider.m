function val = rxSetSlider(slider, val, sigFigs)
%
% val = rxSetSlider(slider, [val], [sigFigs])
%
% Sets the slider value and updates the text label.  If val is
% not provided, grabs it from the slider itself, i.e., doesn't
% change the value, but still updates the text label.  Prompts
% the user for a slider value if the slider is pegged at max.
%
% slider: slider structure that contains a slot for the slider
% handle itself, the slot for the name of the slider and a slot
% for the handle of the text label. Or, can be a handle
% to one of the controls in the slider.
%
% val: value to set the slider to.  Default is to grab that value
% from the sliderHandle.
% 
% sigFigs: # of significant figures (after decimal) to display for 
% the slider value text. Default is 3.
%
% ras 02/05.
if notDefined('sigFigs'),   sigFigs = 3;            end
if notDefined('flexFlag'),  flexFlag = 0;           end

if ~isstruct(slider)
    % assume it's a handle, get from UserData
    slider = get(slider,'UserData');
end

sliderHandle = slider.sliderHandle;

% If val not passed in, get it from the slider.  If pegged at
% max, prompt user for a new value.
minVal = get(sliderHandle, 'min');
maxVal = get(sliderHandle, 'max');
    
if notDefined('val')
   val = get(sliderHandle,'Value');
end

% If outside valid range, reset it if flexFlag = 0, otherwise expand it.
if ~isfield(slider,'flexFlag'); slider.flexFlag = 0; end; % default

% this may not be necessary, but is useful: a sanity check for min/max
if minVal > maxVal  % swap
    tmp = minVal; minVal = maxVal; maxVal = tmp;
    set(sliderHandle, 'Min', minVal, 'Max', maxVal);
elseif minVal==maxVal
    maxVal = abs(maxVal);
    minVal = -abs(maxVal);
    set(sliderHandle, 'Min', minVal, 'Max', maxVal);    
end

if (val < minVal) 
    if slider.flexFlag
        minVal = val; set(sliderHandle, 'min', val);
    else
        val = minVal;
    end
end 

if (val > maxVal)
    if slider.flexFlag
        maxVal = val; set(sliderHandle, 'max', val);
    else
        val = maxVal;
    end
end

% round if integer flag is set
if slider.intFlag==1
    val = round(val);
end

if mod(val,1)==0
    sigFigs = 0;
end

% Set slider value
set(sliderHandle, 'Value', val);

% Update slider edit field label
pattern = ['%2.' num2str(sigFigs) 'f'];
str = sprintf(pattern, val);
set(slider.editHandle, 'String', str);

return
