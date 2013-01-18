function mrCreateReadme 
% function mrCreateReadme  
%  
% Creates a Readme.txt text file that describes a scanning session.  
% Uses the .reconParams field and several other fields of mrSESSION  
% for default values.  If mrSESSION does not exist it must first 
% be created using mrInitRet. 
% 
% TO DO: 
%   - Option to add the scan to list for heeger's accounting (get 
%        name of account used during scan) 
%   - Collect protocol name 
% 
% djh, 9/4/01 
% based on Ben Backus' version for mrLoadRet 2.*
% ras, 04/05: reads info from existing readme, applies
% update of relevant fields back to mrSESSION.mat

global mrSESSION dataTYPES 
 
% Check if a Readme file already exists 
if exist(fullfile(pwd,'Readme.txt'),'file')
    resp = questdlg('Readme.txt exists. Update?','Warning','Yes','No','Yes');
    if ~isequal(resp,'Yes')
        return
    end
    info = readReadme;
else   
    info = [];
end
 
loadSession 
 
% Session identifiers
createReadmeSession(info); 
 
% Scan-by-scan info 
createReadmeParams; 
 
% allow for text to be appended
if ~isempty(info)
    appendTextToReadme(info.comments);
else
    appendTextToReadme;
end

% now append this info to mrSESSION --
% it doesn't make sense to have this in one but not the
% other
info = readReadme;
fields = fieldnames(info);
for i = 1:length(fields)
    mrSESSION.(fields{i}) = info.(fields{i});
end
saveSession;

return
