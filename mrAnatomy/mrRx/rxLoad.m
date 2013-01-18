function rx = rxLoad(loadPath);
% rx = rxLoad([loadPath]);
%
% Load a matlab file containing a mrRx 
% rx struct, which contains information
% on a transformation being applied to
% a volume. Returns the struct; and, if
% a mrRx GUI is open, attach the struct
% to the GUI so that future operations
% work on that alignment/xform.
%
%
% ras 02/05.
if ieNotDefined('loadPath')
    [fname parent] = uigetfile('*.mat','Select rx file...');
    loadPath = fullfile(parent,fname);
end

if ~exist(loadPath,'file')
    myErrorDlg(sprintf('File %s not found!',loadPath));
end

load(loadPath);

if ~exist('rx','var')
    myErrorDlg(sprintf('%s does not contain an ''rx'' variable.',loadPath));
end

% check if a GUI is open, and if so,
% attach loaded rx struct:
cfig = findobj('Tag','rxControlFig');
if ishandle(cfig)
    % first we need to grab the
    % valid handles from the existing 
    % struct (the saved handles are defunct):
    oldrx = get(cfig,'UserData');
    ui = oldrx.ui;
    
    % now swap in the new handles and set the rx:
    rx.ui = ui;
    set(cfig,'UserData',rx);

    % set saved ui settings
    if isfield(rx,'settings')
        names = {rx.settings.name};
        names = {'(Default)' names{:}};
        set(rx.ui.storedList,'String',names,'Value',length(names));
        rxReset(rx);
    end

    rxRefresh(rx);
end

return
