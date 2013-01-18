function [camPaths lengthVec statsVec] = dtiLoadCaminoPathsMatrix(filename, xform, maxLength)
%
% [camPaths lengthVec statsVec] = dtiLoadCaminoPathsMatrix(filename, xform, maxLength)
%
% Loads fiber pathways from a Camino .Bfloat file. 
% 
% Notes: Pathways are assumed to be stored in the following Camino format:
% [<N>, <seed point index>, <x_1>, <y_1>, <z_1>,...,<x_numPoints>, <y_N>,
% <z_N>, <N>,...,<z_N>]
%  
% xform is from T1 space to ACPC space
% 
% HISTORY:
% 2007.09.07 Written by Anthony Sherbondy

%% Endpoints only?
if ieNotDefined('bEndOnly')
    bEndOnly = 0;
end

%% Open file and read all raw data in
fid = fopen(filename,'rb','b');
rawPaths = fread(fid,'float'); fclose(fid);

%% Read each pathway
sPtr = 1;
pp = 1;
storeInc = 1000;
camPaths = zeros(3,maxLength,storeInc);
lengthVec = zeros(1,storeInc);
statsVec = zeros(3,storeInc); % Only take first 3 stats for now XXX
while sPtr < length(rawPaths)
    [pathway, stats, sPtr] = mtrReadCaminoPathwayFromStream(rawPaths, sPtr);
    if(length(pathway)>3)
        if(pp>size(camPaths,3))
            % Grow storage
            camPaths(:,:,end+1:end+storeInc) = zeros(3,maxLength,storeInc);
            lengthVec(end+1:end+storeInc) = zeros(1,storeInc);
            statsVec(:,end+1:end+storeInc) = zeros(3,storeInc);
        end
        camPaths(:,1:size(pathway,2),pp) = pathway;
        lengthVec(pp) = size(pathway,2);
        statsVec(1:min(length(stats),3),pp) = stats(1:min(length(stats),3));
        pp = pp+1;
    end
end
numPaths = pp-1;
camPaths = camPaths(:,:,1:numPaths);

% Transform all fiber coords in one go (much faster!)
% I don't know why this offset is still necessary, isn't ACPC space all
% ACPC space??
%xformToMatlab = [1 0 0 2; 0 1 0 2; 0 0 1 2; 0 0 0 1];
xformToMatlab = eye(4);
xformToAcpc = xformToMatlab*xform;

% Get coords into 2D format and then transform
camPaths = reshape(camPaths,3,maxLength*numPaths);
camPaths = mrAnatXformCoords(xformToAcpc,camPaths');
%camPaths = mrAnatXformCoords(eye(4),camPaths);
camPaths = reshape(camPaths',[3,maxLength,numPaths]);
lengthVec = lengthVec(1:size(camPaths,3));
statsVec = statsVec(:,1:size(camPaths,3));
return;

