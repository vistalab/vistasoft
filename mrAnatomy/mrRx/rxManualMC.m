function rxManualMc(sessDir,dataType,base,targets);
%
% rxManualMc([sessDir,dataType,base,targets]);
%
% Shell to call mrRx in manual motion-correct
% mode. sessDir is the directory w/ the 
% mrSESSION file; defaults to pwd.
% 
%
% ras 03/05.
if ieNotDefined('sessDir')
    sessDir = pwd;
end

if ieNotDefined('dataType')
    dataType = 'Original';
end

if ieNotDefined('base')
    base = 1;
end

if ieNotDefined('targets')
    targets = 2;
end

load(fullfile(sessDir,'Inplane',dataType,'meanMap.mat'));
load mrSESSION;
res = mrSESSION.functionals(base).voxelSize;

rx = mrRx(map{targets(1)},map{base},'refRes',res,'volRes',res);

rx = rxOpenCompareFig(rx);

rxRefresh(rx,1);

return