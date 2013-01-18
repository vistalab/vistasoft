function slider = mrvSlider(pos, name, varargin);
%
% slider = mrvSlider([pos], [name], [properties]);
%
% Create a slider with an attached edit field,  both of which
% specify the same value,  and a text label describing the 
% parameter being set. Often used in mrVista UIs.
%
% pos: position [lrhc_x lrhc_y x_size y_size] of box containing
%      slider,  edit field,  and labels.
% name: name of slider (will be default text in the label).
% 
% properties: specify in pairs,  the name of the property and
% its value. Here are the properties an mrvSlider can have:
%    'parent': parent figure or uipanel for slider. Default gcf.
%    'range': [min max] values for the slider. Default [0 1].
%    'val': initial value for the slider. Default is [min] value.
%
%    'callback': callback function for the object. When the edit field
%          or sliders are modified by the user,  the control will
%          first set the other control to agree with the value that
%          was set. (E.g., if you type a value, it will first set the
%          slider to match that value.)
%		   Then it will evaluate the cb string entered here.
%          Default cb is empty.
%          For the callback, the current value of the slider will be 
%          evaluated to the temporary variable 'val', so no get functions
%          need to be added. For example:
%          'callback', 'colormap( gray( val ))' will cause the slider
%          to set the figure's colormap to the [val] number of grays after
%          a value is selected.
%
%    'units': units for slider objects. Default 'normalized',  relative
%          to parent object.
%    'intFlag': flag for whether slider value should be constrained
%          to be an integer or not. Default 0.
%    'flexFlag': flag for whether slider should be flexible for
%          values entered outside the specified range. If 0,  when
%          a value is entered into the edit field outside the min
%          and max values set by the slider,  the value is automatically
%          reset to be within the bounds. If 1,  will allow the higher
%          value,  and expand the slider's range accordingly. Default 
%          is 0,  reset out-of-bound values.
%    'sigFigs': # of significant figures to show in the edit field.
%           Default is 2. If intFlag is 1,  this is overridden and 0
%           sig figs are always shown. 
%    'maxLabelFlag': flag to put a small label to the side of the
%           slider indicating the maximum value. Default is 0, 
%           don't add this.
%    'color': background color of the object. Default is the
%           same value as the parent object.
%    'fontSize': size of fonts for the edit / text controls.
%           Default is 12 point.
%
% Returns a slider struct with handles to the slider,  edit,  and
% label(s),  the callback strings for the slider and edit controls, 
% and the values of the properties above.
%
% Properties of the mrvSlider can be set later on using 
% mrvSliderSet.m.
%
% ras,  07/05/05.
% ras,  09/06 -- imported into VISTASOFT repository from mrVista 2 tools.
if nargin<2,  help(mfilename); error('Not enough args.');            end

%%%%% Default properties
parent = gcf;
range = [0 1];
cb = ''; 
units = 'normalized'; 
intFlag = 0;
flexFlag = 0;
sigFigs = 2;
maxLabelFlag = 0; 
fontName = 'Helvetica';
fontSize = 12;
sliderStep = [.03 .15];
visible = 'on';

%%%%% parse the property flags
for i = 1:2:length(varargin)
    prop = lower(varargin{i});
    switch prop
        case 'parent',  parent = varargin{i+1};
        case 'range',  range = varargin{i+1};
        case {'val', 'value'},  val = varargin{i+1};
        case {'cb', 'callback'},  cb = varargin{i+1};
        case 'units',  units = varargin{i+1};
        case 'intflag',  intFlag = varargin{i+1};
        case 'flexflag',  flexFlag = varargin{i+1};
        case 'sigfigs',  sigFigs = varargin{i+1};
        case 'maxlabelflag',  maxLabelFlag = varargin{i+1};
        case 'color',  color = varargin{i+1}; 
		case 'fontname',  fontName = varargin{i+1}; 
		case 'fontsize',  fontSize = varargin{i+1}; 
		case 'sliderstep', sliderStep = varargin{i+1};
        case 'visible',  visible = varargin{i+1};
        otherwise,  fprintf('mrvSlider: %s unrecognized property.\n', prop);
    end
end

% default initial val
if ~exist('val', 'var') | isempty(val),  val = range(1);   end

% default initial val
if ~exist('color', 'var')|isempty(color),  
    if isequal(get(parent, 'Type'), 'figure')
        color = get(parent, 'Color'); 
    else
        color = get(parent, 'BackgroundColor');
    end
end
      
% range check
if range(2)<=range(1),     range(2) = range(1)+eps;         end

if flexFlag % overrides input ranges if flexFlag
    range(1) = min([range(1), val]);
    range(2) = max([range(2), val]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make slider
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Slider callback string :
sliderCb = 'val = get(gcbo, ''Value'');';
if intFlag==1
	sliderCb = [sliderCb ' val = round(val); '];
end
sliderCb = sprintf('%s \n slider = get(gcbo, ''UserData'');', sliderCb);
sliderCb = sprintf('%s \n mrvSliderSet(slider, ''Val'', val);', sliderCb);
if ~isempty(cb)
    sliderCb = sprintf('%s \n %s;', sliderCb, cb);
end
sliderCb = sprintf('%s \n clear val slider; ', sliderCb);

% slider position within box
sliderPos = pos;
sliderPos(2) = pos(2) + 0.5*pos(4);
sliderPos(4) = 0.5*pos(4);

% create slider control
sliderHandle = uicontrol('Style', 'slider', ...
                        'Parent', parent, ...
                        'Units', units, ...
                        'Position', sliderPos, ...
                        'fontName', fontName, ...
						'FontSize', fontSize, ...
                        'ForegroundColor', color, ...
                        'BackgroundColor', [1 1 1], ...
                        'Min', range(1), ...
                        'Max', range(2), ...
                        'Val', val, ...
                        'SliderStep', sliderStep, ...
						'Visible', visible, ...
                        'Callback', sliderCb);                    
if intFlag==1 
    %% make slider step across integer values
	sigFigs = 0;
	sliderStep = [.03 .15];
	
    if diff(range)>=1
		denom = max(1, abs(diff(range)));
        sliderStep(1) = 1/ denom; % should always page 1
	end
	
    set(sliderHandle, 'SliderStep', sliderStep);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if selected,  add a little label for the max slider val   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if maxLabelFlag==1
    sliderPos(3) = sliderPos(3) * 0.8;
    set(sliderHandle, 'Position', sliderPos);
    maxLabelPos = sliderPos;
    maxLabelPos(1) = sliderPos(1) + sliderPos(3);
    maxLabelPos(3) = sliderPos(3) * 0.2/0.8;
	maxTxt = sprintf( sprintf('%%.%if', sigFigs), range(2) );
    maxLabelHandle = uicontrol('Style', 'text', ...
                        'Parent', parent, ...
                        'fontName', fontName, ...						
                        'FontSize', fontSize-2, ...
                        'Units', units, ...
                        'Position', maxLabelPos, ...
                        'BackgroundColor', 'w', ...
                        'Visible', visible, ...
                        'HorizontalAlignment', 'left', ...
                        'String', maxTxt);
else
    maxLabelHandle = [];
end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create text label
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% label pos within box
labelPos = pos;
labelPos(3) = 0.7*pos(3);
labelPos(4) = 0.5*pos(4);

% Create a text label w/ the slider name
labelHandle = uicontrol('Style', 'text', ...
                        'Parent', parent, ...
                        'fontName', fontName, ...						
                        'FontSize', fontSize, ...
                        'Units', units, ...
                        'Position', labelPos, ...
                        'BackgroundColor', color, ...
                        'Visible', visible, ...
                        'HorizontalAlignment', 'left', ...
                        'String', [name ':']);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create edit field
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
% edit pos within box
editPos = pos;
editPos(1) = pos(1) + 0.5*pos(3);
editPos(3) = 0.5*pos(3);
editPos(4) = 0.5*pos(4);

% Edit field callback string: 
editCb = 'val = str2num(get(gcbo, ''String''));';
if intFlag==1
	editCb = [editCb ' val = round(val); '];
end
editCb = sprintf('%s \n slider = get(gcbo, ''UserData'');', editCb);
editCb = sprintf('%s \n mrvSliderSet(slider, ''Val'', val);', editCb);
if ~isempty(cb)
    editCb = sprintf('%s \n %s;', editCb, cb);
end
editCb = sprintf('%s \n clear val slider;', editCb);


% make edit control
editHandle = uicontrol('Style', 'edit', ...
                        'Parent', parent, ...
                        'Units', units, ...
                        'fontName', fontName, ...						
                        'FontSize', fontSize, ...
                        'Position', editPos, ...
                        'String', num2str(val), ...
                        'Visible', visible, ...
                        'BackgroundColor', color, ...
                        'Callback', editCb);

% add handles to struct
slider.name = name;
slider.sliderHandle = sliderHandle;
slider.editHandle = editHandle;
slider.labelHandle = labelHandle;
slider.maxLabelHandle = maxLabelHandle;
slider.range = range;
slider.intFlag = intFlag;
slider.flexFlag = flexFlag;
slider.sigFigs = sigFigs;
slider.maxLabelFlag = maxLabelFlag;
slider.sliderCb = sliderCb;
slider.editCb = editCb;

% set as user data to controls
set(editHandle, 'UserData', slider);
set(sliderHandle, 'UserData', slider);

return
