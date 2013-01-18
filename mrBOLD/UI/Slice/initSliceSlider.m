function vw=initSliceSlider(vw)
%
% vw=makeSliceButtons(vw)
%
% Installs push buttons that set curSlice.
% This is used for the inplane view only.
%
% If you change this function make parallel changes in:
%    initScanSlider
%
% djh, 1/97
% bw, 12.08.00.  For more than 12 planes, we put up a slider
% instead of the individual buttons
% ras, 2.21.07:  updated so that the vw is updated by the
% 'setCurSlice' part of the callback. This is now needed, since
% the cur slice is stored outside the slider field.
if ~strcmp(vw.viewType,'Inplane')
   error('initSliceSlider:  Only used for INPLANE window');
end

sliderHandle = vw.ui.slice.sliderHandle;

% Set the step size for clicking on the arrows and the trough
nSlices = viewGet(vw, 'numSlices');

if nSlices < 2
    nSlices=2;
    set(sliderHandle,'Enable','off');
else
    set(sliderHandle,'Enable','on');
end
    
% By setting the max to a little more than nSlices, we should
% never quite reach it by clicking the arrow or the trough
set(sliderHandle,'Min',1,'Max',nSlices);
sliderStep = [1/(nSlices - 1) , 2/(nSlices - 1)];
set(sliderHandle,'sliderStep',sliderStep);

% Update the slider callback to be an integer.
sliderCb = 'val=round(get(gcbo,''Value''));';
% sliderCb = sprintf('%s \n setSlider(%s, %s.ui.slice, val, 0);',...
%                sliderCb, vw.name, vw.name);
sliderCb = sprintf('%s \n %s = viewSet(%s, ''curSlice'', val);',...
               sliderCb, vw.name, vw.name);
sliderCb = sprintf('%s \n %s=refreshScreen(%s, 1, 1);',...
                sliderCb, vw.name, vw.name);
set(vw.ui.slice.sliderHandle,'CallBack',sliderCb);


% Update the edit callback to be an integer.
editCb = 'val=round(str2num(get(gcbo,''String'')));';
% editCb = sprintf('%s \n setSlider(%s,%s.ui.slice, val, 0);',...
%                editCb, vw.name, vw.name);
editCb = sprintf('%s \n %s = viewSet(%s, ''curSlice'', val);',...
               editCb, vw.name, vw.name);
editCb = sprintf('%s \n %s = refreshScreen(%s, 1, 0);',...
                editCb, vw.name, vw.name);
set(vw.ui.slice.labelHandle, 'CallBack', editCb);

% Set to a middle plane
r = get(vw.ui.slice.sliderHandle,'max');
vw = viewSet(vw, 'curslice', round(r/2));

% Add a text box above the slider so we know
% how many total planes there are
pos = get(vw.ui.slice.sliderHandle,'position');

% New left position
pos(1) = pos(1) + pos(3) + 0.01;
% New width
pos(3) = pos(3)/4;

str = sprintf('%.0f',nSlices);
vw.ui.slice.textHandle = ...
   uicontrol('Style','text',...
   'Units','normalized',...
   'Position',pos,...
   'String',str);

return;
