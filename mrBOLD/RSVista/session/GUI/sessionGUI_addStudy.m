function GUI = sessionGUI_addStudy(study, session, studyDir);
% Add a study to the mrVista GUI, selecting it in the process, and
% initializing with one session.
% 
% <GUI> = sessionGUI_addStudy(<study=dialog>, <session=dialog>, <studyDir=''>);
%
% This function will update or create the saved studies file 
% (saved in the mrVista 2 repository: mrVista2/study/studies.mat)
% with the new session, as well as adding it to the GUI.
%
%
% ras, 07/06. 
mrGlobals2;

if notDefined('studyDir'), studyDir = ''; end

if notDefined('study')              % dialog
    study = inputdlg({'Name of the new study'}, mfilename); 
    if isempty(study), return; end
    study = study{1};
end

if notDefined('session')            % dialog
    p = 'Select a first session to add to this study '; 
    session = sessionSelectDialog(1, p); 
end

% create the new study
n = length(GUI.studies) + 1; % index into new study
GUI.studies(n) = studyCreate(study);
GUI.studies(n).studyDir = studyDir;

% select the study
GUI = sessionGUI_selectStudy(study);

% add the first session to it
GUI = sessionGUI_addSession(session);

% save the updated studies file
studyPath = studySave(GUI.studies);
fprintf('Studies file %s updated.\n', studyPath);


return
