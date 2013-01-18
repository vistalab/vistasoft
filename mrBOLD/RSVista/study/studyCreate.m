function study = studyCreate(name);
% Create a new mrVista 2 study with the specified name.
%
% study = studyCreate(name);
%
%
% ras, 07/03/06.
if notDefined('name')
    name = inputdlg({'Name of the new study'}, mfilename); 
    if isempy(name), study = []; return; end
    name = name{1};
end

study.name = name;
study.sessions = {};
study.studyDir = '';
study.params = struct;
study.comments = '';

return
