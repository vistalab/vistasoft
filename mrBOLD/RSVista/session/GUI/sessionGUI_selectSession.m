function GUI = sessionGUI_selectSession(session, GUI)
% Select a mrVista sesssion, updating relevant GUI controls and global
% variables.
%
% GUI = sessionGUI_selectSession(<session path or uicontrol handle>, <GUI>);
%
% If the path to a session is provided, will check if the session is in the
% current study / session list, and if not, will load it. 
%
% If the handle to a session control (listbox) is provided, will select the
% session based on the currently-selected value of the uicontrol.
%
% If no argument is provided, will get from the GUI.controls.session
% listbox.
%
% The GUI input/output args do not generally need to be called, as this
% function will update the global variable GUI, as well as the mrGlobals
% variables. However, it will formally allow keeping this information in 
% other, independent, structures.
%
% ras, 07/03/06.

mrGlobals2;
global GUI

hmsg = msgbox('Loading Session...');

if notDefined('session'), session = GUI.controls.session; end

nSession = GUI.settings.session;

if ishandle(session)
    nSession = get(session, 'Value');
    
    % see if session is specified relative to a parent directory
    if ~isempty(GUI.studies(GUI.settings.study).studyDir)
        % relative path, w/ parent dir
        parent = eval(GUI.studies(nStudy).studyDir); % allows dynamic parent dirs
        session = fullfile(parent, GUI.studies(nStudy).sessions{nSession});
    else
        % absolute path
        session = GUI.studies(GUI.settings.study).sessions{nSession};
    end
    
elseif ischar(session)
%     [par sessName ext] = fileparts(session);
    sessList = [GUI.studies(GUI.settings.study).sessions];
    for i = 1:length(sessList)
        [p sessCodes{i}] = fileparts(sessList{i});
    end
    nSession = cellfind(sessCodes, session);
    if isempty(nSession), nSession = 1; else, nSession = nSession(1); end
    session = sessList{nSession(1)};  % in case it appears multiple times
end

% at this point, session should be a string pointing to the session
% and nSession should be an index into the current study for this session.

% update session list in GUI
sessionPaths = GUI.studies(GUI.settings.study).sessions;
for i=1:length(sessionPaths), 
	[p sessions{i}] = fileparts(sessionPaths{i}); 
	
	% try loading a mrSESSION.mat file to get a description from the
	% mrSESSION.sessionCode variable
	try
		mrSessPath = fullfile(sessionPaths{i}, 'mrSESSION.mat');
		M = load(mrSessPath);
		descriptions{i} = M.mrSESSION.sessionCode;
	catch
		descriptions{i} = sessions{i};
	end
end
set(GUI.controls.session, 'String', descriptions, 'Value', nSession);

% set the current session: provides the setting independent of the
% control which may be a good thing (though it risks disagreement)
GUI.settings.session = session;

% load the session into the global variables
mrSessPath = fullfile(session, 'mrSESSION.mat');
if ~exist(mrSessPath, 'file')
    error(sprintf('No mrSESSION.mat file found in %s.', session))
end

load(mrSessPath, 'mrSESSION', 'dataTYPES');
HOMEDIR = session;
assignin('base', 'HOMEDIR', session);
vANATOMYPATH = getVAnatomyPath;

% cd to the homedir if the preference 'GUI_change_directory' is 1
if ~ispref('VISTA', 'GUI_change_directory')
    cdFlag = 1;
    setpref('VISTA', 'GUI_change_directory', cdFlag);
else
    cdFlag = getpref('VISTA', 'GUI_change_directory');
end

if cdFlag==1, cd(HOMEDIR); end


% load the inplane anatomies as well: it doesn't take much time/space,
% and facilitates several imported options
INPLANE{1} = initHiddenInplane;
INPLANE{1} = loadAnat(INPLANE{1});
INPLANE{1}.name = 'INPLANE{1}';  % 'hidden' name is problematic for some things

if isempty(VOLUME)
    if exist(fullfile(HOMEDIR, 'Gray', 'coords.mat'), 'file')
        VOLUME{1} = initHiddenGray;
        
    elseif exist(fullfile(HOMEDIR, 'Volume', 'coords.mat'), 'file')
        VOLUME{1} = initHiddenVolume;
        
    end
end
VOLUME{1}.name = 'VOLUME{1}';
    



% update status text with a session description
txt = sprintf('%s: %s', mrSESSION.sessionCode, mrSESSION.description);
set(GUI.controls.feedback, 'String', txt);

% check for saved user preferences for this session:
% look for inplane prefs, and if a file is found, use them:
prefsPath = fullfile(session, 'Inplane', 'userPrefs.mat');
if exist(prefsPath)
    load(prefsPath, 'dataTypeName', 'curScan')
    curDataType = cellfind({dataTYPES.name}, dataTypeName);
else
    curDataType = 1;
    curScan = 1;
end

sessionGUI_selectDataType(curDataType);
sessionGUI_selectScans(curScan);

sessionGUI_selectROIType(GUI.settings.roiType);

close(hmsg);

return
    