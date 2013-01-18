function GUI = sessionGUI_addSession(session);
%
% Add a new session to the current mrVista study.
%
%  GUI = sessionGUI_addSession(<session=dialog>);
%
% ras, 07/2006.
mrGlobals2; 

if notDefined('session')            % dialog
    p = 'Select a first session to add to this study '; 
    session = sessionSelectDialog(1, p); 
end

% evaluate relative to the current study's parent dir, if specified
n = GUI.settings.study;
if ~isempty(GUI.studies(n).studyDir)
    session = fullfile(eval(GUI.studies(n).studyDir), session);
else
    session = fullpath(session);
end

%%%%% add to sepcified study list:
otherSessions = GUI.studies(n).sessions;
if ~isempty(cellfind(otherSessions, session))
	ok = setdiff(1:length(otherSessions), cellfind(otherSessions,session));
	otherSessions = otherSessions(ok);
end
GUI.studies(n).sessions = [session otherSessions];

if n ~= 1
    %%%%% also add to recent sessions list:
    % first, if this session was already there, remove it:
    GUI.studies(1).sessions = setdiff(GUI.studies(1).sessions, session);

    % now, add to top of the list:
	otherSessions = GUI.studies(1).sessions;
	if ~isempty(cellfind(otherSessions, session))
		ok = setdiff(1:length(otherSessions), cellfind(otherSessions,session));
		otherSessions = otherSessions(ok);
	end

    GUI.studies(1).sessions = [session otherSessions];
end

% restrict to a max # of recent sessions
maxRecentSessions = 50;
if length(GUI.studies(1).sessions) > maxRecentSessions
    GUI.studies(1).sessions = GUI.studies(1).sessions(1:maxRecentSessions); 
end

studySave(GUI.studies);

% select the new session
GUI = sessionGUI_selectSession(session);

return

