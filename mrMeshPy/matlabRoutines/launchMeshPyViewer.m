% a launcher for mrMeshPy viewer from within matlab

%% new code
% get directory of matlab routine - same place as pyMeshBuild to call later
meshBuildPath = which(mfilename);
[meshBuildDir,~,~] = fileparts(meshBuildPath);

cmdString = [meshBuildDir,'/launchMeshPy.sh ',meshBuildDir,'/../mrMeshPy.py'] %TODO set python path?
system(cmdString);
