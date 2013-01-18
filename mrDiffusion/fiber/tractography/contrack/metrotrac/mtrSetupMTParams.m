function mtrSetupMTParams(subjID)

% Setting up parameters files for a subject based on ROIs assumes
% 1. You are in the subject directory
% 2. A met_params.txt file is already in the conTrack directory
%subjID = 'ss040804';
localSubjDir = ['/teal/scr1/dti/sisr/' subjID];
dlhSubjDir = ['/radlab_share/home/tony/images/' subjID];
lappySubjDir = ['c:/cygwin/home/sherbond/images/' subjID];
machineListL = {'deep-lumen1','deep-lumen2','deep-lumen4'};
machineListR = {'deep-lumen5','deep-lumen6','deep-lumen8'};
mtrTwoRoiSamplerSISR(localSubjDir, 'LMT.mat', 'CC_FA.mat', 'met_params.txt', 'LMT_met_params.txt', 'paths_LMT.dat', 'lmtRoisMask.nii.gz');
mtrTwoRoiSamplerSISR(localSubjDir, 'RMT.mat', 'CC_FA.mat', 'met_params.txt', 'RMT_met_params.txt', 'paths_RMT.dat', 'rmtRoisMask.nii.gz');
mtrTwoRoiSamplerSISR(localSubjDir, 'LMT.mat', 'CC_FA.mat', 'met_params.txt', 'LMT_met_params_dl.txt', 'paths_LMT.dat', 'lmtRoisMask.nii.gz', 'track_LMT.sh', dlhSubjDir, machineListL);
mtrTwoRoiSamplerSISR(localSubjDir, 'RMT.mat', 'CC_FA.mat', 'met_params.txt', 'RMT_met_params_dl.txt', 'paths_RMT.dat', 'rmtRoisMask.nii.gz', 'track_RMT.sh', dlhSubjDir, machineListR);
mtrTwoRoiSamplerSISR(localSubjDir, 'LMT.mat', 'CC_FA.mat', 'met_params.txt', 'LMT_met_params_lap.txt', 'paths_LMT.dat', 'lmtRoisMask.nii.gz', 'temp.sh', lappySubjDir, machineListL);
mtrTwoRoiSamplerSISR(localSubjDir, 'RMT.mat', 'CC_FA.mat', 'met_params.txt', 'RMT_met_params_lap.txt', 'paths_RMT.dat', 'rmtRoisMask.nii.gz', 'temp.sh', lappySubjDir, machineListR);

delete(fullfile(localSubjDir,'conTrack','temp.sh'));