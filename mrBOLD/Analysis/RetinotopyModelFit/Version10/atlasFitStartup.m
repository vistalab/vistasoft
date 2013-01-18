% set path
addpath ./distance
addpath ./Interpolation
addpath ./kernel
addpath ./solvers
addpath ./GUI
% start GUI
% gui

% if you wish to call GUI directly with an images structure as a parameter
% be sure that the path is set correctly
% 
% you might have to change the initFromArgument function in GUI.m to suit
% your needs according to your images structure
% 
% the images structure should contain:
% angle data image
% angle atlas image
% angle coherence map (if only one is available, see
% initFromArgument in gui.m)
% eccentricity data image
% eccentricity atlas image
% eccentricity coherence map (if only one is available, see
% initFromArgument in gui.m)
% areas of interest image