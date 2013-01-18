function camPaths = dtiLoadBfloatPaths(filename,xform, bEndOnly)
%
% camPaths = dtiLoadCaminoPaths(filename)
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
% 2011.07.21 renamed to dtiLoadBfloatPaths to deal with old Bfloat formats.

%% Endpoints only?
if ieNotDefined('bEndOnly')
    bEndOnly = 0;
end

%% Open file and read all raw data in
fid = fopen(filename,'rb','b');
rawPaths = fread(fid,'float'); fclose(fid);

%% Create pathway structure 
camPaths.statHeader(1).agg_name = 'Length';
camPaths.pathwayInfo = [];
camPaths.pathways = {};

%% Read each pathway
sPtr = 1;
pp = 1;
while sPtr < length(rawPaths)
    [pathway, seedID, sPtr] = mtrReadCaminoPathwayFromStream(rawPaths, sPtr);
    if(length(pathway) > 3)
        camPaths.pathwayInfo(pp).algo_type = 1;
        camPaths.pathwayInfo(pp).seed_point_index = seedID;
        camPaths.pathwayInfo(pp).pathStat(1) = length(pathway);
        if bEndOnly==0
            camPaths.pathways{pp,1} = pathway;
        else
            camPaths.pathways{pp,1} = [pathway(:,1) pathway(:,end)];
        end
        pp = pp+1;
    end
end

% Transform all fiber coords in one go (much faster!)
% I don't know why this offset is still necessary, isn't ACPC space all
% ACPC space??
%XXX XFORM HACK, we are given the DTI SPACE XFORM
%xformToMatlab = [0.5 0 0 0; 0 0.5 0 0; 0 0 0.5 0; 0 0 0 1];
%xformToAcpc = xformToMatlab*xform;
%xform(1:3,4) = 2*xform(1:3,4);
%camPaths.pathways = dtiXformFiberCoords(camPaths.pathways, xformToAcpc);
xform(1,1)=1; xform(2,2)=1; xform(3,3)=1;
camPaths.pathways = dtiXformFiberCoords(camPaths.pathways, xform);


return;

