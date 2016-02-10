function rx = rxAlign(session,varargin)
%
% rxAlign([view or session dir]);
%
% Interface to use mrRx to perform alignments
% on mrVista sessions.
%
% The argument can either be the path to a mrVista
% session directory, or a view from an existing
% directory. If omitted, it assumes you're already
% in the session directory and starts up a hidden
% inplane view.
%
% To save the alignment, you'll want to use the
% following menu in the control figure:
%
% File | Save ... | mrVista alignment
%
% ras 03/05.
if ieNotDefined('session'), session = pwd;  end

mrGlobals;

if isstruct(session)
    % assume view; set globals
    inplane = session;
    clear session;
elseif ischar(session)
    HOMEDIR = session;
    loadSession;
    inplane = initHiddenInplane;
    clear session;
end

% get vAnatomy / xformed volume
vANATOMYPATH = getVAnatomyPath(mrSESSION.subject);
[vol, volVoxelSize] = readVolAnat(vANATOMYPATH);

% get anatomy / reference volume
if ~isfield(inplane,'anat') || isempty(inplane.anat)
    inplane = loadAnat(inplane);
end
anat = viewGet(inplane,'Anatomy Data');
ipVoxelSize = viewGet(inplane,'Voxel Size');

vol = double(vol);
anat = double(anat);

% call mrRx
rx = mrRx(vol, anat, 'volRes', volVoxelSize, 'refRes', ipVoxelSize);

% open a prescription figure
rx = rxOpenRxFig(rx);

% % check for a screen save file
% if exist('Raw/Anatomy/SS','dir')
% %     rxLoadScreenSave;
%     openSSWindow;
% end

% check for an existing params file
paramsFile = fullfile(HOMEDIR,'mrRxSettings.mat');
if exist(paramsFile,'file')
    rx = rxLoadSettings(rx,paramsFile);
    rxRefresh(rx);
else
	% add a few decent defaults
    hmsg = msgbox('Adding some preset Rxs ...');
    rx = rxMidSagRx(rx);
    rx = rxMidCorRx(rx);
    rx = rxObliqueRx(rx);
    close(hmsg);
end

% load any existing alignment
if isfield(mrSESSION,'alignment')
    rx = rxLoadMrVistaAlignment(rx,'mrSESSION.mat');
end


return
