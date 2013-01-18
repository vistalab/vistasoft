function loadSession(baseDir)
% Loads the mrSESSION and SCANS structures from mrSESSION.mat.
%
%  loadSession([baseDir])
%
% baseDir: directory containing the mrSESSION.mat file
%             defaults to current directory (pwd)
%
% djh, 2/17/2001
% 7/16/02 djh, update mrSESSION to version3.01
% - inhomoCorrect can now be 0, 1, or 2
%   previous default of 0 is now option 1 (divide by mean)
%   0 now means do nothing
% - eliminate mrSESSION.vAnatomyPath
%   replace with global vANATOMYPATH
%
% ras, 04/05 -- got rid of all references to versions earlier
% than 3.0, on the grounds that none of those sessions would
% work anyomre anyway, and times have changed...

mrGlobals

if ~exist('HOMEDIR', 'var') || isempty(HOMEDIR), HOMEDIR = pwd; end
if ~exist('baseDir', 'var') || isempty(baseDir), baseDir = HOMEDIR; end

mrSessPath = fullfile(baseDir, 'mrSESSION.mat');

% Load mrSESSION & dataTYPES
if exist(mrSessPath,'file'), load(mrSessPath)
else  myErrorDlg(sprintf('No mrSESSION.mat file in %s \n', baseDir))
end

% Old mrSESSIONs don't seem to have this field.  Can we do better than
% setting it empty?  Maybe we should write and call a mrSESSION update
% routine that queries the user? -- BW
if(~isfield(mrSESSION,'sessionCode')), mrSESSION.sessionCode = 'sCode'; end
if(~isfield(mrSESSION,'description')), mrSESSION.description = 'sDesc'; end

return
