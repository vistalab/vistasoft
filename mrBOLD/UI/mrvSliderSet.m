function val = mrvSliderSet(slider, varargin);
%
% val = mrvSliderSet(slider, [property], [val], ...)
%
% Set properties of an mrvSlider,  a slider+edit field. See
% help mrvSlider or doc mrvSlider for more info.
%
% Properties list:
%    'val': value for the slider.
%    'range': [min max] values for the slider.
%    'labe': text label for the slider.
%    'cb': callback function for the object. When the edit field
%          or sliders are modified by the user,  the control will
%          first set the other control to agree with the value that
%          was set,  then will evaluate the cb string entered here.
%    'units': units for slider objects.
%    'intFlag': flag for whether slider value should be constrained
%          to be an integer or not.
%    'flexFlag': flag for whether slider should be flexible for
%          values entered outside the specified range. If 0,  when
%          a value is entered into the edit field outsside the min
%          and max values set by the slider,  the value is automatically
%          reset to be within the bounds. If 1,  will allow the higher
%          value,  and expand the slider's range accordingly.
%    'sigFigs': # of significant figures to show in the edit field.
%           If intFlag is 1,  this is overridden and 0 sig figs are
%           always shown.
%    'maxLabelFlag': flag to put a small label to the side of the
%           slider indicating the maximum value.
%    'color': background color of the object.
%    'fontSize': size of fonts for the edit / text controls.
%    'visible': set visibility of all uicontrols related to the slider.
%
% ras 07/05.
if nargin==0,  help(mfilename); error('Not enough args.'); end

if ~isstruct(slider)
    % assume it's a handle,  get from UserData
    slider = get(slider, 'UserData');
end

%%%%% parse the property flags
for i = 1:2:length(varargin)
    prop = lower(varargin{i});
    switch prop
        case 'range', 
            range = double(varargin{i+1});
            
            % check if current val is out of bounds
            val = get(slider.sliderHandle, 'Value');
            if (val<range(1)) | (val>range(2))
                val = range(1);
            end
                       
            % figure out a step size that will move at least one slice
            stepSize = [.03 .15];
            if diff(range)>1
                stepSize(1) = 1/(abs(diff(range))+1); % should always page 1
                stepSize(1) = min(0.1, stepSize(1));
            end

            set(slider.sliderHandle, 'Min', range(1), 'Max', range(2), ...
                'SliderStep', stepSize, 'Value', val);
            pattern = ['%2.' num2str(slider.sigFigs) 'f'];
            str = sprintf(pattern, val);
            set(slider.editHandle, 'String', str);
            if slider.maxLabelFlag==1
                str = sprintf(pattern, range(2));
                set(slider.maxLabelHandle, 'String', str);
            end
            
        case 'label',
            label = varargin{i+1};
            set(slider.labelHandle, 'String', label);

        case {'val', 'value'}, 
            mrvSliderSetVal(slider, varargin{i+1});

        case {'cb', 'callback'}, 
            cb = varargin{i+1};
            % Slider callback string :
            sliderCb = 'val = str2num(get(gcbo, ''Value''));';
            sliderCb = 'slider = get(gcbo, ''UserData'');';
            sliderCb = sprintf('%s \n mrvSliderSet(slider, ''Val'', val);', sliderCb);
            sliderCb = sprintf('%s \n %s;', sliderCb, cb);
            sliderCb = sprintf('%s \n clear val slider; ', sliderCb);

            % Edit field callback string:
            editCb = 'val = str2num(get(gcbo, ''String''));';
            editCb = sprintf('%s \n slider = get(gcbo, ''UserData'');', editCb);
            editCb = sprintf('%s \n mrvSliderSet(slider, ''Val'', val);', editCb);
            sliderCb = sprintf('%s \n %s;', editCb, cb);
            editCb = sprintf('%s \n clear val slider; ', editCb);

            slider.sliderCb = sliderCb; slider.editCb = editCb;
            set(slider.sliderHandle, 'Callback', sliderCb);
            set(slider.editHandle, 'Callback', editCb);

        case 'units', 
            units = varargin{i+1};
            set(slider.sliderHandle, 'Units', units);
            set(slider.editHandle, 'Units', units);
            set(slider.labelHandle, 'Units', units);
            if slider.maxLabelFlag==1
                set(slider.maxLabelHandle, 'Units', units);
            end

        case 'intflag', 
            slider.intFlag = varargin{i+1};

        case 'flexflag', 
            slider.flexFlag = varargin{i+1};

        case 'sigfigs', 
            slider.sigFigs = varargin{i+1};

        case 'maxlabelflag', 
            slider.maxLabelFlag = varargin{i+1};
            if ishandle(slider.maxLabelHandle)
                if slider.maxLabelFlag==0
                    set(slider.maxLabelHandle, 'Visible', 'off')
                else
                    set(slider.maxLabelHandle, 'Visible', 'on')
                end
            end
            
        case 'fontsize', 
            fontSize = varargin{i+1};
            set(slider.sliderHandle, 'FontSize', fontSize);
            set(slider.labelHandle, 'FontSize', fontSize);
            set(slider.editHandle, 'FontSize', fontSize);
            if slider.maxLabelFlag==1
                set(slider.maxLabelHandle, 'FontSize', fontSize);
            end
            
        case 'color', 
            color = varargin{i+1};
            set(slider.sliderHandle, 'ForegroundColor', color);
            set(slider.labelHandle, 'BackgroundColor', color);
            set(slider.editHandle, 'BackgroundColor', color);

        case {'visible', 'visibility'}, 
            set(slider.sliderHandle, 'Visible', varargin{i+1});
            set(slider.labelHandle, 'Visible', varargin{i+1});
            set(slider.editHandle, 'Visible', varargin{i+1});
            if slider.maxLabelFlag==1
                set(slider.maxLabelHandle, 'Visible', varargin{i+1});
            end
            
        case 'tag',
            set(slider.sliderHandle, 'Tag', varargin{i+1});
            set(slider.editHandle, 'Tag', varargin{i+1});
            
        otherwise, 
            fprintf('mrvSliderSet: Unrecognized property %s .\n', prop);
    end
end

set(slider.sliderHandle, 'UserData', slider);
set(slider.editHandle, 'UserData', slider);


return
% /--------------------------------------------------------------/ %




% /--------------------------------------------------------------/ %
function mrvSliderSetVal(slider, val);
% Set the slider / edit field values.
%
% ras,  07/05.
sliderHandle = slider.sliderHandle;
sigFigs = slider.sigFigs;

% If outside valid range,  reset it if flexFlag = 0,  otherwise expand it.
minVal = get(sliderHandle, 'Min');
maxVal = get(sliderHandle, 'Max');
if (val < minVal)
    if slider.flexFlag
        minVal = val; set(sliderHandle, 'min', minVal);
    else
        val = minVal;
    end
end
if (val > maxVal)
    if slider.flexFlag
        maxVal = val; set(sliderHandle, 'max', maxVal);
    else
        val = maxVal;
    end
end

% round if integer flag is set
if slider.intFlag==1,     val = int16(round(val));   end

if mod(val, 1)==0,        sigFigs = 0;                end

% Set slider value
set(sliderHandle, 'Value', val);

% Update slider edit field label
pattern = ['%2.' num2str(sigFigs) 'f'];
str = sprintf(pattern, val);
set(slider.editHandle, 'String', str);

return
