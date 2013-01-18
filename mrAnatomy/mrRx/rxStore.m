function rx = rxStore(rx,newName);
% 
% rx = rxStore(rx,[newName]);
%
% Store an xform matrix in an rx struct
% for later retrieval (not saved to disk
% yet though).
%
%
% ras 02/05.
if ieNotDefined('rx')
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end

list = get(rx.ui.storedList,'String');

n = length(list); % new entry #

if ieNotDefined('newName')
    newName = sprintf('Setting %i',n);
end

list{n+1} = newName;

set(rx.ui.storedList,'String',list);

% start a struct with cur settings
s.name = newName;

% get the xform
s.xform = rx.xform;

% get the ui settings
s.axiRot = get(rx.ui.axiRot.sliderHandle,'Value');
s.corRot = get(rx.ui.corRot.sliderHandle,'Value');
s.sagRot = get(rx.ui.sagRot.sliderHandle,'Value');
s.axiTrans = get(rx.ui.axiTrans.sliderHandle,'Value');
s.corTrans = get(rx.ui.corTrans.sliderHandle,'Value');
s.sagTrans = get(rx.ui.sagTrans.sliderHandle,'Value');
s.axiFlip = get(rx.ui.axiFlip,'Value');
s.corFlip = get(rx.ui.corFlip,'Value');
s.sagFlip = get(rx.ui.sagFlip,'Value');

% get other settings, for convenience
s.nudge = get(rx.ui.nudge.sliderHandle,'Value');
if ishandle(rx.ui.interpFig)
    s.interpBright = get(rx.ui.interpBright.sliderHandle,'Value');
    s.interpContrast = get(rx.ui.interpContrast.sliderHandle,'Value');
else
    s.interpBright = [];
    s.interpContrast = [];
end
if ishandle(rx.ui.rxFig)
    s.volBright = get(rx.ui.volBright.sliderHandle,'Value');
    s.volContrast = get(rx.ui.volContrast.sliderHandle,'Value');
    s.volSlice = get(rx.ui.volSlice.sliderHandle,'Value');
    s.volOri = findSelectedButton(rx.ui.volOri);
else
    s.volBright = [];
    s.volContrast = [];
    s.volSlice = [];
    s.volOri = [];
end
if ishandle(rx.ui.refFig)
    s.refBright = get(rx.ui.refBright.sliderHandle,'Value');
    s.refContrast = get(rx.ui.refContrast.sliderHandle,'Value');
else
    s.refBright = [];
    s.refContrast = [];
end


% initialize settings field if it doesn't
% exist:
if ~isfield(rx,'settings')
    rx.settings = s;
else
    rx.settings(n) = s;
end

rxRefresh(rx);

return
