function mrManualCreate(manType, runDir, htmlDir)
% Call m2html to create html manual pages
%
%     mrManualCreate(manType, runDir, htmlDir)
%
% This code must execute from within the directory just above mrVista2.
% The output html pages will be written into htmlDir.  runDir is a full
% path.  htmlDir is a relative path to the runDir.
%
% The manual pages can be written either in frame or non-frame format.
% They are stored in the directory htmlDir, which by default is one level
% above the mrvRootPath.
%
% For people creating manuals, the m2html code must be located one
% directory level above the mrVista path.
%
% Example:
%    mrManualCreate('frame','C:\u\brian\Matlab','mrvManual');
%
% Copyright Stanford, mrVista team

if notDefined('manType'), manType = 'noframe'; end
if notDefined('srcDir'),  runDir = fileparts(mrvRootPath); end
if notDefined('htmlDir')  htmlDir = 'mrvManual'; end

curDir = pwd;
chdir(runDir);

str = which('m2html');
if isempty(str), addpath([mrvRootPath,filesep,'..',filesep,'m2html']); end

% Delete the old manual page
disp('Should delete the old directory')

switch lower(manType)
    case 'noframe'
        m2html('mfiles','mrVista2','htmldir',htmlDir,'recursive','on','source','off')
    case 'brain'
        m2html('mfiles','mrVista2','htmldir',htmlDir,'recursive','on','source','off','template','brain','index','menu')
    case 'frame'
        m2html('mfiles','mrVista2','htmldir',htmlDir,'recursive','on','source','off','template','frame','index','menu')
    case 'blue'
        m2html('mfiles','mrVista2','htmldir',htmlDir,'recursive','on','source','off','template','blue','index','menu')
   otherwise
        error('Unknown style.')
end

chdir(curDir);
% 
return;

