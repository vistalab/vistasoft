function mrvEdit
%Initialize a new vista function
%
%  mrvEdit
%
% Example:
%   mrvEdit;
%
% Copyright Stanford team, mrVista, 2011


% Select the new file name
[FileName,PathName] = uiputfile('*.m','Function name');
if isequal(FileName,0)
    disp('User canceled'); 
    return;
else
    % Copy the template there
    % In the future stick in more stuff, like the function name into the header
    % Do this by writing the m-file as a function (fprintf)
    template = fullfile(vistaRootPath,'mrvUtilities','vistaFunctionTemplate.m');
    fullFileName = fullfile(PathName,FileName);
    copyfile(template,fullFileName);
    
    % Edit it
    edit(fullFileName)
end

return

