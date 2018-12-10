% t_templateTutorial
%
% A brief synopsis of what the tutorial does. 1-2 lines of text.
% 
%
% Dependencies: 
%   Any toolbox or code repoistories other than vistasoft
%
% ** ONLY RELEVANT IF THE TUTORIAL IS PART OF A SEQUENCE **
% This tutorial is part of a sequence. Run 
%   t_initAnatomyFromFreesurfer
% prior to running this tutorial. 
% ***
%
% Summary (ONE DESCRIPTOR PER CELL)
%
% - Do actiom A
% - Do action B
% - Visualize
% - Clean up
%
% Tested MM/DD/YYYY - MATLAB r2015a (REPLACE WITH VERSION), Mac OS 10.11.6
% (REPLACE WITH YOUR OS)
%
%  See also: t_XXX (IF THERE IS A CLOSELY RELATED TUTORIAL)
%
% YOUR LAB OR NAME


%% Action A (DOWNLOADS A SAMPLE DATASET)

% (OPTIONAL) Clean start in case we have a vista session open
mrvCleanWorkspace();

% (OPTIONAL) Remember where we are
curdir = pwd();

% (OPTIONAL) If we find the directory, do not bother unzipping again
forceOverwrite = false; 

% (OPTIONAL)  Get it
erniePRFOrig = mrtInstallSampleData('functional', 'erniePRF', [], forceOverwrite);


%% Action B (DO SOMETHING WITH THE DATASET)




%% Visualize (OPTIONAL)
if prefsVerboseCheck
    % something to visualize the restuls
end
    
%% Clean up (OPTIONAL)
mrvCleanWorkspace
cd(curdir)