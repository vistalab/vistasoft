function slider = rxMakeSlider(name,range,pos,intFlag,val,flexFlag);
% slider = rxMakeSlider(name,range,pos,[intFlag],val,[flexFlag]);
%
% A knockoff of the mrVista function 'makeSlider',
% but for mrRx. Make a slider, label, and edit field
% with the specified name, min/max values, and
% position, and return a struct with the handles
% to these things.
%
% Unlike the position specification for makeSlider,
% pos here should specify a box containing all
% controls -- slider, label, and edit. Same format
% though: [xLeft yLower xSize ySize], Normalized units.
%
% intFlag is an optional flag if the specified 
% slider allows only integer values.
%
% val: specify initial value for slider. If omitted,
% defaults to min of range.
%
% flexFlag: allows the slider to expand when values are out of 
% range. Applicable to the translations sliders only.
%
% ras 02/05.
if ieNotDefined('intFlag')
    intFlag = 0;
end

if ieNotDefined('val')
    val = range(1);
end

if ieNotDefined('flexFlag')
    flexFlag = 0;
end

if isempty(range)
    range = [1 2];
end

if range(2)<=range(1)
    range(2) = range(1)+1;
end

if flexFlag % overrides input ranges if flexFlag
    range(1) = min([range(1),val]);
    range(2) = max([range(2),val]);
end

color = get(gcf,'Color');

% Slider callback string: 
cbstr = 'slider = get(gcbo,''UserData'');';
cbstr = sprintf('%s \n rxSetSlider(slider);',cbstr);
cbstr = sprintf('%s \n rxRefresh;',cbstr);

% slider position within box
sliderPos = pos;
sliderPos(2) = pos(2) + 0.5*pos(4);
sliderPos(4) = 0.5*pos(4);

% Make slider
sliderHandle = uicontrol('Style','slider',...
                        'Units','Normalized',...
                        'Position',sliderPos,...
                        'ForegroundColor',get(gcf,'Color'),...
                        'BackgroundColor',[1 1 1],...
                        'min',range(1),...
                        'max',range(2),...
                        'val',val,...
                        'Callback',cbstr);
                    
if intFlag==1
    % make slider step across integer values
    nVals = floor(diff(range));
    sliderStep = [1/(nVals+1) 3/(nVals+1)];
    set(sliderHandle,'SliderStep',sliderStep);
end

% label pos within box
labelPos = pos;
labelPos(3) = 0.7*pos(3);
labelPos(4) = 0.5*pos(4);

% Create a text label w/ the slider name
labelHandle = uicontrol('Style','text',...
                          'Units','Normalized',...
                          'Position',labelPos,...
                          'BackgroundColor',color,...
                          'String',[name ':']);

% Edit field callback string: 
cbstr = 'val = str2num(get(gcbo,''String''));';
cbstr = sprintf('%s \n slider = get(gcbo,''UserData'');',cbstr);
cbstr = sprintf('%s \n rxSetSlider(slider,val);',cbstr);
cbstr = sprintf('%s \n rxRefresh;',cbstr);


% edit pos within box
editPos = pos;
editPos(1) = pos(1) + 0.7*pos(3);
editPos(3) = 0.3*pos(3);
editPos(4) = 0.5*pos(4);

% make edit control
editHandle = uicontrol('Style','edit',...
                        'Units','Normalized',...
                        'Position',editPos,...
                        'String',num2str(val),...
                        'BackgroundColor',color,...
                        'Callback',cbstr);


% add handles to struct
slider.sliderHandle = sliderHandle;
slider.editHandle = editHandle;
slider.labelHandle = labelHandle;
slider.range = range;
slider.intFlag = intFlag;
slider.flexFlag = flexFlag;

% set as user data to controls
set(editHandle,'UserData',slider);
set(sliderHandle,'UserData',slider);

return
