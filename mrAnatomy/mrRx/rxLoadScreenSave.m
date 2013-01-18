function h = rxLoadScreenSave;
% 
% h = rxLoadScreenSave;
% 
% Check the Raw/Anatomy/SS directory for any
% screen-save I-files, and if they exist,
% display them for mrRx.
% 
% Returnx a handle to the displayVol GUI
% that is initialized.
% 
% ras 03/05.
ssDir = fullfile(pwd,'Raw/Anatomy/SS');

check = dir(fullfile(ssDir,'I*'));

if isempty(check)
    myWarnDlg(sprintf('No Anatomy Images found in %s.',ssDir));
    return
end

try
    ScreenSave = loadVolume(ssDir);
catch
    msg=sprintf('%s: Couldn''t load Screen Save.',mfilename);
    myWarnDlg(msg);
    return
end

h = displayVol(ScreenSave, 1, [], [.5 .1*max(ScreenSave(:))]);

% % for newer screen saves, there are 
% % some large negative values in the 
% % images -- clip at 0:
% vol = get(h,'UserData');
% dataRange = [min(vol.M(:)) max(vol.M(:))];
% vol.clipMin = dataRange(1) + 0.50*diff(dataRange);
% vol.clipMax = dataRange(1) + 0.52*diff(dataRange);
% vol.autoClip = 0;
% set(h,'UserData',vol);
% displayVol(h,[],[],0);

% check if a mrRx control is open,
% and if so, update the handles:
cfig = findobj('Tag','rxControlFig');
if ishandle(cfig)
    rx = get(cfig,'UserData');
    rx.ui.ssFig = h;
    set(cfig,'UserData',rx);
    
%     % also set a callback to clear this
%     % when the fig is closed:
%     cb = 'cfig=findobj(''Tag'',''rxControlFig''); ';
%     cb = [cb 'rx=get(cfig,''UserData''); '];
%     cb = [cb 'rx.ui.ssFig = []; '];
%     cb = [cb 'set(cfig,''UserData'',rx); '];
%     cb = [cb 'closereq;'];
%     set(h,'CloseRequestFcn',cb);
end
% openSSWindow;

return

    
