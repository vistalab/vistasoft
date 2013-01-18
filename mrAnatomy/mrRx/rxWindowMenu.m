function h = rxWindowMenu(parent);
%
% h = rxWindowMenu(parent);
%
% Make a menu for mrRx file commands,
% attached to parent object.
%
% ras 02/05.
if ieNotDefined('parent')
    parent = gcf;
end

h = uimenu(parent,'Label','Window');

% open rx fig:
% Callback format:
% cfig = findobj('Tag','rxControlFig');
% rx = get(cfig,'UserData');
% rx.ui.rxFig = rxOpenRxFig(rx);
% set(cfig,'UserData',rx);
cb = 'cfig = findobj(''Tag'',''rxControlFig'');';
cb = [cb ' rx = get(cfig,''UserData'');'];
cb = [cb ' rx = rxOpenRxFig(rx);'];
cb = [cb ' set(cfig,''UserData'',rx);'];
cb = [cb ' rxRefresh(rx);'];
uimenu(h,'Label','Open Rx Window','Separator','off',...
         'Accelerator','1','Callback',cb);

% open interp fig:
cb = 'cfig = findobj(''Tag'',''rxControlFig'');';
cb = [cb ' rx = get(cfig,''UserData'');'];
cb = [cb ' rx = rxOpenInterpFig(rx);'];
cb = [cb ' set(cfig,''UserData'',rx);'];
cb = [cb ' rxRefresh(rx);'];
uimenu(h,'Label','Open Prescribed Slice Window','Separator','off',...
         'Accelerator','2','Callback',cb);

% open rx fig:
cb = 'cfig = findobj(''Tag'',''rxControlFig'');';
cb = [cb ' rx = get(cfig,''UserData'');'];
cb = [cb ' rx = rxOpenRefFig(rx);'];
cb = [cb ' set(cfig,''UserData'',rx);'];
cb = [cb ' rxRefresh(rx);'];
uimenu(h,'Label','Open Reference Slice Window','Separator','off',...
         'Accelerator','3','Callback',cb);

% open comparison fig:
cb = 'cfig = findobj(''Tag'',''rxControlFig'');';
cb = [cb ' rx = get(cfig,''UserData'');'];
cb = [cb ' rx = rxOpenCompareFig(rx);'];
cb = [cb ' set(cfig,''UserData'',rx);'];
cb = [cb ' rxRefresh(rx);'];
uimenu(h,'Label','Open Rx/Ref Comparison Window','Separator','off',...
         'Accelerator','4','Callback',cb);
     

 % open ss fig:
cb = 'cfig = findobj(''Tag'',''rxControlFig'');';
cb = [cb ' rx = get(cfig,''UserData'');'];
cb = [cb ' rx.ui.ssFig = rxLoadScreenSave;'];
cb = [cb ' set(cfig,''UserData'',rx);'];
uimenu(h,'Label','Open Screen Save Window','Separator','on',...
         'Accelerator','5','Callback',cb);

 % open tSeries fig:
cb = 'cfig = findobj(''Tag'',''rxControlFig'');';
cb = [cb ' rx = get(cfig,''UserData'');'];
cb = [cb ' rx = rxOpenTSeriesFig(rx);'];
cb = [cb ' set(cfig,''UserData'',rx);'];
uimenu(h,'Label','Open tSeries Navigator Window','Separator','off',...
         'Accelerator','6','Callback',cb);
     
 % open interp 3-view fig:
cb = 'cfig = findobj(''Tag'',''rxControlFig'');';
cb = [cb ' rx = get(cfig,''UserData'');'];
cb = [cb ' rx = rxOpenInterp3ViewFig(rx);'];
cb = [cb ' set(cfig,''UserData'',rx);'];
uimenu(h,'Label','Open Interpolated 3-View Window','Separator','off',...
         'Accelerator','7','Callback',cb);
	 
     

return