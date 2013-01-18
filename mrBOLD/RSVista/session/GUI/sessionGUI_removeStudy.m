function GUI = sessionGUI_removeStudy(study, forceRemove);
% Remove a study from the mrVista GUI.
% 
% <GUI> = sessionGUI_removeStudy(<study=current>, <forceRemove=0>);
%
% This function will update or create the saved studies file 
% (saved in the mrVista 2 repository: mrVista2/study/studies.mat).
%
% If the forceRemove flag is set to 1, will remove without prompting.
% Otherwise, asks the user to confirm first.
%
% ras, 07/06. 
mrGlobals2;

if notDefined('study'),    study = GUI.settings.study;      end
if notDefined('forceRemove'), forceRemove = 0;              end

% N will index the index for this study
if isnumeric(study)
    N = study;
    study = GUI.studies(N).name;
    
elseif ischar(study)
    N = cellfind({GUI.studies.name}, study);
    
else
    error('Invalid study specification.')
    
end

% can't remove the first study (recent sessions); check that we're not
% trying:
if N==1
    myWarnDlg('Sorry, you can not remove the Recent Sessions study.');
    return
end

% Ask the user if he/she is sure, if not forcing the removal:
if ~forceRemove
    q = sprintf('Permanently delete study %s? ', study);
    resp = questdlg(q, mfilename);
    if ~isequal(resp, 'Yes'), return; end
end

% remove the study
ok = setdiff(1:length(GUI.studies), N);
GUI.studies = GUI.studies(ok);


% save the updated studies file
studyPath = studySave(GUI.studies);
fprintf('Studies file %s updated.\n', studyPath);

% select the previous study in the study list
GUI = sessionGUI_selectStudy(N-1);

return


