function view=initLevelSlider(view,curLevel)
%
%       view=initLevelSlider(view,[curLevel])
%
% Installs the slider and text box that control the gray level.
% The slider is placed on the top right, near the slice control slider.
%
% The first time through, the callback and related textbox are installed
%
% It is also called repeatedly as dataTypes are switched to re-display
%   the slider that represents level information
%
% If you change this function make parallel changes in:
%    initSliceSlider
%
% bw,  01/16/01  Adjusted sliderstep
% bw,  12/25/00  Wrote it.
% ras, 09/30/04  adapted to initLevelSlider
if ieNotDefined('curLevel')
    curLevel = 1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add an edit field for the # of gray levels to show %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
color = get(gcf,'Color');

% text label
htmp = uicontrol('Style','text',...
                 'Units','Normalized',...
                 'Position',[0 0.75 0.12 0.03],...
                 'BackgroundColor',color,...
                 'HorizontalAlignment','left',...
                 'String','And next:');
view.ui.level.numLevelLabel = htmp;

% edit field
callBackStr = sprintf('%s = refreshScreen(%s);',view.name,view.name);
htmp = uicontrol('Style','edit',...
                 'Units','Normalized',...
                 'Position',[0.10 0.75 0.03 0.03],...
                 'BackgroundColor',color,...
                 'Callback',callBackStr,...
                 'String','0');
view.ui.level.numLevelEdit = htmp;

% also need to get text label for level slider
% (to turn off if looking across levels)
htmp = findobj('Parent',gcf,'Style','text','String','level:');
view.ui.level.levelLabel = htmp;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize slider stuff                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% The sliderHandle always exists because it is created in openXXWindow
% Set the step size for clicking on the arrows and the trough
sliderHandle = view.ui.level.sliderHandle;

nScans=numScans(view);
if nScans < 2
    %   Can't have a slider value of 1.  Sorry.
    nScans=2;
    set(sliderHandle,'Enable','off');
else
    set(sliderHandle,'Enable','on');
end

hemi = findSelectedButton(view.ui.sliceButtons); 
nLevels = view.numLevels(hemi); % update for diff. # levels

% By setting the max to a little more than nScans, we should
% never quite reach it by clicking the arrow or the trough
set(sliderHandle,'Min',1,'Max',nLevels);

% Clicking an arrow moves by an amount (max - min)*sliderstep(1)
% Cllicking in the trough moves by an amount (max - min)*sliderstep(2)
% setSlider traps any values == to the max value and queries the user
%    this is a cheap way of setting a value by hand.
sliderStep(1) = 1/(nLevels - 1);
sliderStep(2) = 2*sliderStep(1);
set(sliderHandle,'sliderStep',sliderStep);

% update the callback
callBackStr = ...
    ['val = get(',view.name,'.ui.level.sliderHandle,''value'');'...
        'val = round(val);'...
        'setSlider(',view.name,',',view.name,'.ui.level,val);'...
        view.name,'=refreshScreen(',view.name,');'];
set(sliderHandle,'CallBack',callBackStr);

% If we are first opening the window, create the text box.  
if ~isfield(view.ui.level,'textHandle')
   
   % Position the text box to the right of the slider
   pos = get(sliderHandle,'Position');
   l2 = pos(1) + pos(3) + .01;
   w2 = pos(3)/4; b = pos(2); h = pos(4);
   position = [l2 b w2 h];
   
   view.ui.level.textHandle = ...
      uicontrol('Style','text',...
      'Units','normalized',...
      'Position',position);
end

% This text tells the user how many levels there are
% for the given gray mesh. 
%
str = sprintf('%.0f',nLevels); 
set(view.ui.level.textHandle,'String',str);

setSlider(view,view.ui.level,curLevel);


return
