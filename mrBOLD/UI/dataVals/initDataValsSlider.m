function view=initDataValsSlider(view,curDVIndex)
%
%       view=initDataValsSlider(view,[curDVIndex])
%
% Installs the slider and text box that control the current datavals .
% The slider is placed on the mid-left, under the datavals control slider.
%
% The first time through, the callback and related textbox are installed
%
% It is also called repeatedly as dataTypes or FFTCheckBox are switched to re-display
%   the slider that represents datavals information
%
% ARW Wrote it 030606:
% Based on BW's initScanSlider

% The sliderHandle always exists because it is created in openXXWindow
% Set the step size for clicking on the arrows and the trough
sliderHandle = view.ui.datavals.sliderHandle;

nDataVals=numDataVals(view); % This looks at dataTYPES and also FFTCheckBox to see if we're currently displaying FFT or Time-domain data
if nDataVals < 2
    %   Can't have a slider value of 1.  Sorry.
    nDataVals=2;
    set(sliderHandle,'Enable','off');
else
    set(sliderHandle,'Enable','on');
end
    
% By setting the max to a little more than nDataValss, we should
% never quite reach it by clicking the arrow or the trough
set(sliderHandle,'Min',1,'Max',nDataVals);

% Clicking an arrow moves by an amount (max - min)*sliderstep(1)
% Cllicking in the trough moves by an amount (max - min)*sliderstep(2)
% setSlider traps any values == to the max value and queries the user
%    this is a cheap way of setting a value by hand.
sliderStep(1) = 1/(nDataVals - 1);
sliderStep(2) = 2*sliderStep(1);
set(sliderHandle,'sliderStep',sliderStep);


% If we are first opening the window, create the text box.  
if ~isfield(view.ui.datavals,'textHandle')
    % Can this be inside the if below so that it only happens 
	% when the window is first opened?
	% djh, 9/5/01
	callBackStr = ...
        ['val = get(',view.name,'.ui.datavals.sliderHandle,''value'');'...
            'val = round(val);'...
            'setSlider(',view.name,',',view.name,'.ui.datavals,val);'...
            view.name '=setCurDataValIndex(',view.name,',val);'...
            view.name,'=refreshScreen(',view.name,');'];
	set(sliderHandle,'CallBack',callBackStr);
    
   % Position the text box to the right of the slider
   pos = get(sliderHandle,'Position');
   l2 = pos(1) + pos(3) + .01;
   w2 = pos(3)/4; b = pos(2); h = pos(4);
   position = [l2 b w2 h];
   
   view.ui.datavals.textHandle = ...
      uicontrol('Style','text',...
      'Units','normalized',...
      'Position',position);
end

% This text tells the user how many datavals indices there are
% in the current dataType and domain.  Here, we set the value
%
str = sprintf('%.0f',nDataVals);
set(view.ui.datavals.textHandle,'String',str);

% Synchronize the curScan with the slider state
%

if (~isfield(view,'dataValIndex'))
    view = setCurDataValIndex(view,1);
end

if ~exist('curDataValIndex','var')
   curDataValIndex = getCurDataValIndex(view);
end

if curDataValIndex > numDataVals(view)
    curDataValIndex = 1;
end
setSlider(view,view.ui.datavals,curDataValIndex);
view = setCurDataValIndex(view,curDataValIndex);

% ras 08/05: make the scan slider update the curScan field as well:
cb = 'val=str2num(get(gcbo,''String'')); ';
cb = [cb sprintf('%s=setCurDataValIndex(%s,val); ',view.name,view.name)];
cb = [cb sprintf('%s=refreshScreen(%s);',view.name,view.name)];
set(view.ui.datavals.labelHandle,'Callback',cb);

return
