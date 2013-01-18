function view = adjustCmap(view);
% view = adjustCmap(view);
%
% A button-down function for the colorbar
% on a view window. This is set to act when
% the user clicks on the colorbar, and does 
% different things depending upon which button
% was pressed. It does the following:
%
% Left click -> Change color map for this display mode
% Middle click -> (do nothing for now)
% Right click -> Set clip mode
% Double click -> load a new param map
%
% ras 11/04
fig = view.ui.windowHandle;

% figure out which button was pressed
button = get(fig, 'SelectionType');
if strcmp(button,'open')   % double click
   button = 4;
elseif strcmp(button,'normal')  % left 
   button = 1;
elseif strcmp(button,'extend')  % middle / shift-left
   button = 2;
elseif strcmp(button,'alt')     % right / ctrl-left
   button = 3;
else
    % weird selection -- just quit
    return
end

switch button
    case 1,
        % load a new parameter map
        view = loadParameterMap(view);
    case 2,
        % set color map
        dispMode = viewGet(view,'displayMode');
        cmapOpts = getCmapOpts(dispMode);
        [iCmap,ok] = listdlg('PromptString','Select Color Map',...
                            'ListSize',[400 600],...
                            'ListString',cmapOpts,...
                            'InitialValue',1,...
                            'SelectionMode','Single',...
                            'OKString','OK');
        if ~ok  return;  end
        modeStr = [dispMode 'Mode'];
        modeInfo = viewGet(view,modeStr);
        cName = cmapOpts{iCmap};
        numGrays = modeInfo.numGrays;
        numColors = modeInfo.numColors;
        cmap = eval(sprintf('%sCmap(%i,%i);',cName,numGrays,numColors));
        modeInfo.cmap = cmap;
        modeInfo.name = [cName 'Cmap'];
        view = viewSet(view,modeStr,modeInfo);
        if isequal(view.viewType,'Flat')
            view = thresholdAnatMap(view);
        end
    case 3,
        % set clip mode
        view = setClipMode(view);
    case 4,
        % set clip mode
        view = setClipMode(view);        
end

view = refreshScreen(view);

% reset the call to this functions
cbstr = sprintf('%s = adjustCmap(%s);',view.name,view.name);
set(view.ui.colorbarHandle,'ButtonDownFcn',cbstr);
tmp = get(view.ui.colorbarHandle,'Children');
set(tmp,'ButtonDownFcn',cbstr);

return
% /------------------------------------------------------------------/ %



% /------------------------------------------------------------------/ %
function cmapOpts = getCmapOpts(dispMode);
% A lookup for which color maps make sense based on the current
% display mode
if isequal(dispMode,'ph')'
    cmapOpts = {'hsv','rygb'};
else
    cmapOpts = {'hot','cool','redgreen','jet','gray','bicolor'};
end
return
    
