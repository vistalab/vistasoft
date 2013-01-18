function rx = rxReset(rx,selected);
%
% rx = rxReset([rx],[selected]): 
% reset settings on rx control fig to 
% selected xform.
%
% ras 02/05.
if ieNotDefined('rx')
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end

if ieNotDefined('selected')
    selected = get(rx.ui.storedList,'Value');
end

if selected==1
    % defaults
	rxSetSlider(rx.ui.axiRot,0);
	rxSetSlider(rx.ui.corRot,0);
	rxSetSlider(rx.ui.sagRot,0);
	rxSetSlider(rx.ui.axiTrans,0);
	rxSetSlider(rx.ui.corTrans,0);
	rxSetSlider(rx.ui.sagTrans,0);
	
	set(rx.ui.axiFlip,'Value',0);
	set(rx.ui.corFlip,'Value',0);
	set(rx.ui.sagFlip,'Value',0);
else
    % restore saved settings
    s = rx.settings(selected-1);
    rx.xform = s.xform;
    
    % set ui controls
    rxSetSlider(rx.ui.axiRot,s.axiRot);
    rxSetSlider(rx.ui.corRot,s.corRot);
    rxSetSlider(rx.ui.sagRot,s.sagRot);
    rxSetSlider(rx.ui.axiTrans,s.axiTrans);
    rxSetSlider(rx.ui.corTrans,s.corTrans);
    rxSetSlider(rx.ui.sagTrans,s.sagTrans);
	set(rx.ui.axiFlip,'Value',s.axiFlip);
	set(rx.ui.corFlip,'Value',s.corFlip);
	set(rx.ui.sagFlip,'Value',s.sagFlip);
    
    % set view prefs, for convenience
	rxSetSlider(rx.ui.nudge,s.nudge);
	if ishandle(rx.ui.interpAxes) & ~isempty(s.interpBright)
        rxSetSlider(rx.ui.interpBright,s.interpBright);
        rxSetSlider(rx.ui.interpContrast,s.interpContrast);
	end
	if ishandle(rx.ui.rxAxes) & ~isempty(s.volBright)
        rxSetSlider(rx.ui.volBright,s.volBright);
        rxSetSlider(rx.ui.volContrast,s.volContrast);
        rxSetSlider(rx.ui.volSlice,s.volSlice);
        selectButton(rx.ui.volOri,s.volOri);
	end
	if ishandle(rx.ui.refAxes) & ~isempty(s.refBright)
        rxSetSlider(rx.ui.refBright,s.refBright);
        rxSetSlider(rx.ui.refContrast,s.refContrast);
	end

end

rx = rxRefresh(rx);

return
