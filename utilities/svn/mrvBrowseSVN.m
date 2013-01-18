function mrvBrowseSVN(funcName)
% Bring up the SVN trac browser for the named function
%
%     mrvBrowseSVN(funcName)
%
% Example:
%  funcName = 'dtiRawPreprocess';
%  mrvBrowseSVN(funcName)
% 
% Copyright Stanford team, mrVista, 2011

str = 'http://white.stanford.edu/trac/vistasoft/browser/trunk/';

% Make the name to be used for the browser
fName = which(funcName);
p = strfind(fileparts(fName),'trunk') + 6;
fName = fName(p:end);
tracName = fullfile(str,fName);

% Browse using the user's default browser
web(tracName,'-browser');

return