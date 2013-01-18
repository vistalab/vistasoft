function rx = rxLoadMrVistaAlignment(rx,mrSessPath)
%
% rx = rxLoadMrVistaAlignment([rx],[mrSessPath])
%
% Load a mrVista alignment from a mrSESSION.mat file
% into mrRx.
%
% ras 03/05.
if notDefined('rx')
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end

if notDefined('mrSessPath')
    mrSessPath = fullfile(pwd,'mrSESSION.mat');
end

if ~exist(mrSessPath,'file')
    msg = sprintf('%s not found.',mrSessPath);
    myErrorDlg(msg);
end

h = msgbox('Loading mrVista Alignment...');

load(mrSessPath);

newXform = mrSESSION.alignment;

% flip to (x,y,z) instead of (y,x,z):
newXform(:,[1 2]) = newXform(:,[2 1]);
newXform([1 2],:) = newXform([2 1],:);

rx = rxSetXform(rx,newXform,0);

rxStore(rx,'mrVista Alignment');

close(h);

return

