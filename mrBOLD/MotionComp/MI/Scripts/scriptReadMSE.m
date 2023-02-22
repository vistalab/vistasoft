%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%    gb 05/05/05
%
% This script has to be executed directly in the command line
% It plots the MSE graphs for all the sujects that are in the repository
% folder : /Snarp/u1/data/reading_longitude/fmri
%
% After a graph is displayed, type Enter to plot the next one.
%
% Type Ctrl + c in the command line to terminate the program
%
% Just make sure the VISTASOFT directory is in the path and type :
% scriptReadMSE
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all
clear all

if isunix
    networkPath = '/snarp1/u1';
else
    networkPath = '\\snarp\u1\';
end

rootDir = fullfile(networkPath,'data','reading_longitude','fmri');

cd(rootDir);
[fileNum dirName] = countDirs(pwd);

for count = 3:fileNum
    try
        currentDir = dirName{count};
    
        cd(fullfile(rootDir,currentDir));
        motionCompPlotMSE(currentDir);
        pause;
          
    end
        
    close all;
    
end    