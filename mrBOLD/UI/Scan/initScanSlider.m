function vw=initScanSlider(vw,curScan)
%
%       vw=initScanSlider(vw,[curScan])
%
% Installs the slider and text box that control the current scan.
% The slider is placed on the top right, near the slice control slider.
%
% The first time through, the callback and related textbox are installed
%
% It is also called repeatedly as dataTypes are switched to re-display
%   the slider that represents scan information
%
% If you change this function make parallel changes in:
%    initSliceSlider
%
% bw,  01/16/01  Adjusted sliderstep
% bw,  12/25/00  Wrote it.

% The sliderHandle always exists because it is created in openXXWindow
% Set the step size for clicking on the arrows and the trough
sliderHandle = vw.ui.scan.sliderHandle;

nScans = viewGet(vw, 'numScans');

if nScans < 2
	% if there aren't 2 or more scans, we set the slider to a dormant state
	% (we could just hide it, but it's better to keep it visible)
    set(sliderHandle,'Enable','off', 'Min', 0, 'Max', 1, 'Value', .5);
else
    set(sliderHandle,'Enable','on');
	
	% By setting the max to a little more than nScans, we should
	% never quite reach it by clicking the arrow or the trough
	set(sliderHandle,'Min',1,'Max',nScans);
end
    

% Clicking an arrow moves by an amount (max - min)*sliderstep(1)
% Cllicking in the trough moves by an amount (max - min)*sliderstep(2)
% setSlider traps any values == to the max value and queries the user
%    this is a cheap way of setting a value by hand.
if nScans < 2
	sliderStep(1) = .01;
else
	sliderStep(1) = 1/(nScans - 1);
end
sliderStep(2) = 2*sliderStep(1);
set(sliderHandle, 'sliderStep', sliderStep);


% If we are first opening the window, create the text box.  
if ~isfield(vw.ui.scan, 'textHandle')
	cb = ['val = get(',vw.name,'.ui.scan.sliderHandle,''value''); '...
            'val = round(val); '...
            'setSlider(',vw.name,',',vw.name,'.ui.scan,val); '...
            vw.name '=setCurScan(',vw.name,',val); '...
            vw.name,'=refreshScreen(',vw.name,'); '];
	set(sliderHandle,'CallBack',cb);
    
   % Position the text box to the right of the slider
   pos = get(sliderHandle,'Position');
   l2 = pos(1) + pos(3) + .01;
   w2 = pos(3)/4; b = pos(2); h = pos(4);
   position = [l2 b w2 h];
   
   vw.ui.scan.textHandle = ...
      uicontrol('Style','text',...
      'Units','normalized',...
      'Position',position);
end

% This text tells the user how many scans there are
% in the current dataType.  Here, we set the value
%
str = sprintf('%.0f',round(nScans));
set(vw.ui.scan.textHandle,'String',str);

% Synchronize the curScan with the slider state
%
if ~exist('curScan','var')
   curScan = viewGet(vw, 'curScan');
end
if curScan > viewGet(vw, 'numScans')
    curScan = 1;
end
setSlider(vw,vw.ui.scan,curScan);
vw = setCurScan(vw,curScan);

% ras 08/05: make the scan slider update the curScan field as well:
cb = 'val=str2num(get(gcbo,''String'')); ';
cb = [cb sprintf('%s=setCurScan(%s,val); ',vw.name,vw.name)];
cb = [cb sprintf('%s=refreshScreen(%s);',vw.name,vw.name)];
set(vw.ui.scan.labelHandle,'Callback',cb);

return
