function mtrCreateConTracParallelScript(machineList, binDirName, exeConTracFile, scriptFileName, scriptOptsFile, pathsRoot)

% createConTrackParallelScript(machineList, binDirName, exeConTracFile,
% scriptFileName, scriptOptsFile, pathsRoot)

% Create script for parallel processing of pathway tracing on DLs
NN = length(machineList); % compute nodes
fid = fopen(scriptFileName,'wt');
fprintf(fid,'#!/bin/bash\n');
offset = 0;
for nn = 1:NN
    mach_num = floor((nn-1)/2) + 1;
    sub_n = 2 - mod(nn,2);
    paramsFile = fullfile(binDirName,'conTrack',scriptOptsFile);
    pathsFile = fullfile(binDirName,'conTrack',sprintf('%s_%d.dat',pathsRoot,nn+offset));
    fprintf(fid,'echo ''Compute %s''\n',machineList{nn});
    fprintf(fid,'ssh %s %s -i %s -p %s &\n', machineList{nn}, exeConTracFile, paramsFile, pathsFile);
    fprintf(fid,'sleep 2\n');
end
fclose(fid);