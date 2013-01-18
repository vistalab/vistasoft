function mergeSessions(sessionDirs,newSession)
%
% function mergeSessions(sessionDirs,[newSession])
%
% sessionDirs: cell array of pathStrings
% newSession: path for the new session. default: pwd
%
% Makes a new scanning session by combining the gray coords of the from sessionDirs.
% The new session has no Inplane or Volume views, only Gray and Flat views.
% This function coupled with copyScan allows you to bring data from different 
% sessions together into one.
%
% djh, 3/2001
%
% 7/16/02 djh, removed mrSESSION.vAnatomyPath

global mrLoadRetVERSION

if isempty(mrLoadRetVERSION)
    mrLoadRetVERSION = 3;
end

if ~exist('newSession','var')
    newSession = pwd;
end

% Load info from the first sessionDir:
% mrSESSION: 
%   subject
% Gray/coords: 
%   coords,nodes,edges,...
%   allLeftNodes,allLeftEdges,allRightNodes,allRightEdges,...
%   leftPath,rightPath  
sessionDir = sessionDirs{1};
tmp = load(fullfile(sessionDir,'mrSESSION'));
subject = tmp.mrSESSION.subject;
load(fullfile(sessionDir,'Gray','coords.mat'));
coordsTranspose = coords';

% Construct mrSESSION and dataTYPES structures
mrSESSION.mrLoadRetVersion = mrLoadRetVERSION;
mrSESSION.title = '';
mrSESSION.subject = subject;
mrSESSION.examNumber = [];
mrSESSION.inplanes.cropSize = [1 1];
mrSESSION.inplanes.nSlices = 0;
mrSESSION.functionals = [];
mrSESSION.screenSaveSize = [];
mrSESSION.alignment = [];
dataTYPES(1).name = 'Original';
dataTYPES(1).scanParams(1).annotation = '';
dataTYPES(1).scanParams(1).nFrames = 0;
dataTYPES(1).scanParams(1).slices = [];
dataTYPES(1).scanParams(1).cropSize = [0 0];
save(fullfile(newSession,'mrSESSION.mat'),'mrSESSION','dataTYPES');

% Loop through sessions
% - check consistency of subject, leftPath, rightPath
% - compute union of coords
for s = 1:length(sessionDirs)
    sessionDir = sessionDirs{1};
    tmp = load(fullfile(sessionDir,'mrSESSION'));
    if ~strcmp(tmp.mrSESSION.subject,subject)
        warning(['Different subjects: ',subject,' and ',tmp.mrSESSION.subject]);
    end
    tmp = load(fullfile(sessionDir,'Gray','coords.mat'));
    if ~strcmp(tmp.leftPath,leftPath)
        warning(['Different segmentations: ',leftPath,' and ',tmp.leftPath]);
    end
    if ~strcmp(tmp.rightPath,rightPath)
        warning(['Different segmentations: ',rightPath,' and ',tmp.rightPath]);
    end
    coordsTranspose = union(coordsTranspose,tmp.coords','rows');
end

% Final coords
coords = coordsTranspose';

% Keep nodes that intersect with the coords
[leftCoords,leftIndices,keepLeft] = intersectCols(coords,allLeftNodes([2 1 3],:));
[leftNodes,leftEdges,nLeftNotReached] = keepNodes(allLeftNodes,allLeftEdges,keepLeft);
[rightCoords,rightIndices,keepRight] = intersectCols(coords,allRightNodes([2 1 3],:));
[rightNodes,rightEdges,nRightNotReached] = keepNodes(allRightNodes,allRightEdges,keepRight);

% Concantenate the left and right gray graphs
if ~isempty(rightNodes)
    rightNodes(5,:) = rightNodes(5,:) + length(leftEdges);
    rightEdges = rightEdges + size(leftNodes,2);
end
nodes = [leftNodes rightNodes];
edges = [leftEdges rightEdges];

% Save coords.mat
if ~exist(fullfile(newSession,'Gray'),'dir')
    mkdir(newSession,'Gray')
end
pathStr = fullfile(newSession,'Gray','coords.mat');
save(pathStr,'coords','nodes','edges',...
    'allLeftNodes','allLeftEdges','allRightNodes','allRightEdges',...
    'leftPath','rightPath');

return

