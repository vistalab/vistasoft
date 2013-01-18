function pth = parfilesDir(vw)
% Returns the directory containing .par files 
%
%  pth = parfilesDir(vw)
%
% The .par files specify trial/event onsets
% for a view. This routine creates the directories if they don't exist. 
%
% ras, 05/05
global HOMEDIR;

if ~exist('vw','var') || isempty(vw), vw = getSelectedInplane; end

if isempty(HOMEDIR), HOMEDIR = pwd; end % let's hope that's right...

% to be consistent w/ other naming conventions, I'm renaming
% my 'stim' dirs as 'Stimuli', but be back-compatible
if exist(fullfile(HOMEDIR,'stim'),'dir')
    stimDir = 'stim';
else
    stimDir = 'Stimuli'; % this will be the new default
end
   
% same for parfiles directory
if exist(fullfile(HOMEDIR,stimDir,'parfiles'),'dir')
    parDir = 'parfiles';
else
    parDir = 'Parfiles'; % this will be the new default
end

pth = fullfile(HOMEDIR,stimDir,parDir); 

% make sure it exists
ensureDirExists(pth);

return

