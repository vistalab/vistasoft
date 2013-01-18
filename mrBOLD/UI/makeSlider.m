function view = makeSlider(view,name,range,position)
% 
% view = makeSlider(view,name,range,position)
%
% Make a slider and attach its callback.  The slider is
% actually a structure that holds:
%  sliderHandle: handle to the slider itself
%  name: text string
%  label: handle to the label positioned below the slider.
%
% Inputs:
%   view: view (e.g., INPLANE)
%   name: name of slider (e.g., 'cothresh')
%   range: min and max values for slider (e.g., [0,1])
%   position: position of slider [left,bottom,width,height]
%
% To modify a slider's value, use functions like setCothresh and
% setPhWindow that call setSlider.  These functions call
% setSlider that updates the label appropriately.
%
% To get a slider's value, use functions like getCothresh and
% getPhWindow.
% 
% djh, 1/16/97
% bw   12/24/00:  Initialized slider val to min of the range
% ras, 04/24/04:  Changed the way the label is done, so now
%                 there's an edit field allowing you to jump
%                 to a particular value (made parallel changes
%                 in setSlider so that the whole prompt-on-max
%                 'feature' is gone). - Doesn't appear to be implemented
%                 (BW)
% Make callback string: 
%   setSlider(view,view.ui.name);
%   view=refreshScreen(view);
callbackStr = ...
    ['setSlider(',view.name,',',view.name,'.ui.',name,');',...
	view.name,'=refreshScreen(',view.name,');'];
if isempty(range), range = [1 2]; end
if range(2)<=range(1), range(2) = range(1)+1; end
color = get(gcf,'Color');

% Make slider
sliderHandle = ...
    uicontrol('Style','slider',...
    'Units','normalized',...
    'Position',position,...
    'min',range(1),...
    'max',range(2),...
    'val',range(1),...
    'Callback',callbackStr);

% Make label
labelOffset = [0,0.04,0,0];
pos = get(sliderHandle,'Position');
labelPos = pos - labelOffset;
labelPos(3) = labelPos(3) - 0.05; % leave space for edit field
labelPos(4) = labelOffset(2);     % don't encroach on the slider

% This creates some text below the slider to label
% the current position 
% ras, 04/04: while I'm at it, making separate axes
% seemed kind of ugly and unnecessary (okay, I'm  
% being anal :)
% labelAxis = subplot('position',labelPos);
% axis off;
% text(0,0,[name,': '],'FontSize',10);
% label = get(labelAxis,'Children');
txt = uicontrol('Style','text','Units','Normalized','Position',labelPos,...
         'FontSize',8,'FontWeight','normal',...
         'BackgroundColor',color,'HorizontalAlignment','left',...
         'String',[name ':']);
	 
% ----- ras 04/04: also make an edit field for jumping
% to a specific value: ----- %
% Edit field callback string: 
%   val = str2num(get(gcbo,'String'));
%   setSlider([view],[view].ui.[name],val);
%   [view]=refreshScreen([view]);
editCb = 'val=str2num(get(gcbo,''String''));';
editCb = sprintf('%s \n setSlider(%s,%s.ui.%s,val);',...
           editCb,view.name,view.name,name);
editCb = sprintf('%s \n %s=refreshScreen(%s);',...
            editCb,view.name,view.name);
% leave space for the label -- kind of ugly but should be ok
editPos = pos - labelOffset;
editPos(1) = editPos(1) + 0.10; 
editPos(3) = 0.05;
editPos(4) = labelOffset(2);    % don't encroach on the slider
editHandle = uicontrol('Style','edit','Units','normalized',...
                'Position',editPos,'String',num2str(range(1)),...
                'FontSize',8,'FontWeight','normal',...
                'HorizontalAlignment','left','BackgroundColor',color,...
                'Callback',editCb);
			
% just to be explicit: I'm setting the 'label' handle
% to point to the edit field, which is what gets updated
% when you move the slider, rather than the static text
% label which shouldn't change. 
% Doesn't appear to be used - BW
% (It is in the eval statements below: thought it may not matter much -RAS)
label =  editHandle;

% Return the current axes to the main image
% figure(view.ui.figNum);
set(gcf,'CurrentAxes',view.ui.mainAxisHandle);

% Set slots of slider structure
eval(['view.ui.',name,'.sliderHandle = sliderHandle;']);
eval(['view.ui.',name,'.name = name;']);
eval(['view.ui.',name,'.labelHandle = label;']);
eval(['view.ui.',name,'.nameHandle = txt;']);
return;
