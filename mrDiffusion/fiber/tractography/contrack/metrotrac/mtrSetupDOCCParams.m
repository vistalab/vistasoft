function mtrSetupDOCCParams(subjID)

% Setting up parameters files for a subject based on ROIs assumes
% 1. You are in the subject directory
% 2. A met_params.txt file is already in the conTrack directory
%subjID = 'ss040804';
localSubjDir = ['/teal/scr1/dti/sisr/' subjID];
dlhSubjDir = ['/radlab_share/home/tony/images/' subjID];
lappySubjDir = ['c:/cygwin/home/sherbond/images/' subjID];
machineListL = {'deep-lumen1','deep-lumen2','deep-lumen4'};
machineListR = {'deep-lumen5','deep-lumen6','deep-lumen8'};
mtrTwoRoiSamplerSISR(localSubjDir, 'CC_FA.mat', 'LV3AB7d_cleaned.mat', 'met_params.txt', 'LDOCC_met_params.txt', 'paths_LDOCC.dat', 'ldoccRoisMask.nii.gz');
mtrTwoRoiSamplerSISR(localSubjDir, 'CC_FA.mat', 'RV3AB7d_cleaned.mat', 'met_params.txt', 'RDOCC_met_params.txt', 'paths_RDOCC.dat', 'rdoccRoisMask.nii.gz');
mtrTwoRoiSamplerSISR(localSubjDir, 'CC_FA.mat', 'LV3AB7d_cleaned.mat', 'met_params.txt', 'LDOCC_met_params_dl.txt', 'paths_LDOCC.dat', 'ldoccRoisMask.nii.gz', 'track_LDOCC.sh', dlhSubjDir, machineListL);
mtrTwoRoiSamplerSISR(localSubjDir, 'CC_FA.mat', 'RV3AB7d_cleaned.mat', 'met_params.txt', 'RDOCC_met_params_dl.txt', 'paths_RDOCC.dat', 'rdoccRoisMask.nii.gz', 'track_RDOCC.sh', dlhSubjDir, machineListR);
mtrTwoRoiSamplerSISR(localSubjDir, 'CC_FA.mat', 'LV3AB7d_cleaned.mat', 'met_params.txt', 'LDOCC_met_params_lap.txt', 'paths_LDOCC.dat', 'ldoccRoisMask.nii.gz', 'temp.sh', lappySubjDir, machineListL);
mtrTwoRoiSamplerSISR(localSubjDir, 'CC_FA.mat', 'RV3AB7d_cleaned.mat', 'met_params.txt', 'RDOCC_met_params_lap.txt', 'paths_RDOCC.dat', 'rdoccRoisMask.nii.gz', 'temp.sh', lappySubjDir, machineListR);

delete(fullfile('conTrack','temp.sh'));