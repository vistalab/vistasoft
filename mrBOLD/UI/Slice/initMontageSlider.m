function vw = initMontageSlider(vw)
%
% vw = initMontageSlider(vw)
%
% initializes the slider that sets the size of
% an inplane montage.
% 
% ras 09/04, off initSliceSlider
if ~strcmp(vw.viewType,'Inplane')
   error('initMontageSlider: Only used for INPLANE window');
end

ui = viewGet(vw,'ui');
sliderHandle = ui.montageSize.sliderHandle;

% Set the step size for clicking on the arrows and the trough
nSlices = viewGet(vw, 'numSlices');

% if there's only one slice, this slider should be turned off
if nSlices < 2
    nSlices=2;
    set(sliderHandle,'Enable','off');
else
    set(sliderHandle,'Enable','on');
end
    
% set the range and step size of the slider
set(sliderHandle,'Min',1,'Max',nSlices);
sliderStep = [1/(nSlices-1) , 3/(nSlices-1)];
set(sliderHandle,'sliderStep',sliderStep);

% Update the slider callback to be an integer.
sliderCb = 'val=round(get(gcbo,''Value''));';
sliderCb = sprintf('%s \n setSlider(%s,%s.ui.montageSize,val,0);',...
               sliderCb,vw.name,vw.name);
sliderCb = sprintf('%s \n %s=refreshScreen(%s);',...
                sliderCb,vw.name,vw.name);
set(vw.ui.montageSize.sliderHandle,'CallBack',sliderCb);

% Update the edit callback to be an integer.
editCb = 'val=round(str2num(get(gcbo,''String'')));';
editCb = sprintf('%s \n setSlider(%s,%s.ui.montageSize,val,0);',...
               editCb,vw.name,vw.name);
editCb = sprintf('%s \n %s=refreshScreen(%s);',...
                editCb,vw.name,vw.name);
set(vw.ui.montageSize.labelHandle,'CallBack',editCb);

% If we are first opening the window, create the text box.  
if ~isfield(vw.ui.montageSize,'textHandle')
   
   % Position the text box to the right of the slider
   pos = get(sliderHandle,'Position');
   l2 = pos(1) + pos(3) + .01;
   w2 = pos(3)/4; b = pos(2); h = pos(4);
   position = [l2 b w2 h];
   
   vw.ui.montageSize.textHandle = ...
      uicontrol('Style','text',...
      'Units','normalized',...
      'Position',position);
end

% This text tells the user the max number of slices being
% shown in the montage (starting with the selected slice)
str = sprintf('%.0f',nSlices);
set(vw.ui.montageSize.textHandle, 'String', str);

vw = setSlider(vw, vw.ui.montageSize, 1, 0);

return

