function GUI = sessionGUI_selectStudy(study);
% Select a mrVista study, updating relevant GUI controls and global
% variables.
%
% GUI = sessionGUI_selectStudy(<study name or uicontrol handle>);
%
% If the name of a study is provided, will check if the session is in the
% current study list. If so, will select it, and if not, will create a new 
% empty session with that name. 
%
% If the handle to a study control (listbox) is provided, will select the
% session based on the currently-selected value of the uicontrol.
%
% If no argument is provided, will get from the GUI.controls.study
% listbox.
%
% The GUI input/output args do not generally need to be called, as this
% function will update the global variable GUI, as well as the mrGlobals
% variables. However, it will formally allow keeping this information in 
% other, independent, structures.
%
% ras, 07/03/06.
mrGlobals2;

if notDefined('study'), study = GUI.controls.study; end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% depending on the way in which the study is specified, get the numeric
% index into the current list of loaded studies 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isnumeric(study) & mod(study, 1)==0
    nStudy = study;
    
elseif ischar(study)
    nStudy = cellfind({GUI.studies.name}, study);
    if isempty(nStudy)
        q = sprintf('Study %s not found. Create it?', study);
        resp = questdlg(q, mfilename);
        if ~isequal(resp, 'Yes')
            return % exit unless 'Yes' option selected
        end
        GUI.studies(end+1) = studyCreate(study);
        nStudy = length(GUI.studies);
    end
    
elseif ishandle(study)
    nStudy = get(study, 'Value');
    
else
    error('Invalid study selection.')
end


% select study in the GUI variable
GUI.settings.study = nStudy;

% update the GUI control
set(GUI.controls.study, 'Value', nStudy, 'String', {GUI.studies.name});

% select the first session in that study
if ~isempty(GUI.studies(nStudy).sessions)
    sessionGUI_selectSession(GUI.studies(nStudy).sessions{1});
end

    


return
    