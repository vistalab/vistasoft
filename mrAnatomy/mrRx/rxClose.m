function rxClose(rx)
%
% rxClose(rx);
%
% Close mrRx interface; clear memory if any 
% variables are hanging around.
%
%
% ras 02/05
if ieNotDefined('rx')
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end

if ishandle(rx.ui.interpFig)
	delete(rx.ui.interpFig);
end

if ishandle(rx.ui.rxFig)
	delete(rx.ui.rxFig);
end

if ishandle(rx.ui.refFig)
	delete(rx.ui.refFig);
end

if ishandle(rx.ui.compareFig)
	delete(rx.ui.compareFig);
end

if ishandle(rx.ui.controlFig)
	delete(rx.ui.controlFig);
end

if ishandle(rx.ui.ssFig)
	delete(rx.ui.ssFig);
end

if checkfields(rx, 'ui', 'interp3ViewFig') && ishandle(rx.ui.interp3ViewFig)
	delete(rx.ui.interp3ViewFig);
end


if isfield(rx.ui,'tSeriesFig') && ishandle(rx.ui.tSeriesFig)
	delete(rx.ui.tSeriesFig);
end

evalin('base', 'clear rx ans');

return