function pathstr = putPathStrDialog(startPathStr,title,filterspec)
%
% fullPath = putPathStrDialog(startPathStr,title,[filterspec])
%
% Calls uiputfile to display a dialog box that allows the user to pick a file.
%
% startPathStr: starting point for the dialogbox
% title: window title of dialog box, passed on to uigetfile.
% filterspec: passed onto uigetfile. default: '*'
%
% returns full path string
%
% djh, 2/5/2001

if ~exist('filterspec','var')
    filterspec = '*';
end 
if ~exist(startPathStr,'dir')
    startPathStr = pwd;
end

% save current file position
cDir=pwd; 
% move to appropriate directory
chdir(startPathStr); 
% call uigetfile
[filename, pathStr]=uiputfile(filterspec,title);
% move back to original directory
chdir(cDir);
   
if (filename==0) % cancel pressed
    pathstr = [];
else       
    pathstr=fullfile(pathStr,filename);
end
