function GUI = sessionGUI_removeSession(session, nStudy);
% Remove a session from the current study in the mrViewer GUI.
% 
% GUI = sessionGUI_removeSession(<session=get from GUI>, <nStudy=get from GUI>);
%
%
%
%
% ras, 07/06.
mrGlobals2; 

if notDefined('nStudy'), nStudy = GUI.settings.study; end

% restriction: you can't remove the current session from the (Recent
% Sessions) study. I figure it's easier to remember the history; may
% introduce complications if you can remove all sessions. 
if nStudy==1
    myWarnDlg('Sorry, can''t remove a session from the Recent Sessions list.');
    return
end

if notDefined('session')           
    [p session] = fileparts(GUI.settings.session);
end

% get index into session, N:
for ii = 1:length(GUI.studies(nStudy).sessions)
	[p sessionNames{ii}] = fileparts(GUI.studies(nStudy).sessions{ii});
end
N = cellfind(sessionNames, session);

% take only remaining sessions
ok = setdiff(1:length(GUI.studies(nStudy).sessions), N);
GUI.studies(nStudy).sessions = GUI.studies(nStudy).sessions(ok);

studySave(GUI.studies);

sessionGUI_selectSession( max(1, N-1) ); 

return
