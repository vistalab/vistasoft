function mtrSetupGastrocParams(subjID)

% Setting up parameters files for a subject based on ROIs assumes
% 1. You are in the subject directory
% 2. A met_params.txt file is already in the conTrack directory

localSubjDir = ['/biac2/wandell2/data/conTrack/muscle/' subjID];
dlhSubjDir = ['/radlab_share/home/tony/images/' subjID];
lappySubjDir = ['c:/cygwin/home/sherbond/images/' subjID];
machineListL = {'deep-lumen1','deep-lumen2','deep-lumen4'};
% machineListR = {'deep-lumen5','deep-lumen6','deep-lumen8'};
mtrTwoRoiSamplerSISR(localSubjDir, 'tendon_plate.mat', 'end_voi.mat', 'met_params.txt', 'GAS_met_params.txt', 'paths_GAS.dat', 'gasRoisMask.nii.gz');
mtrTwoRoiSamplerSISR(localSubjDir, 'tendon_plate.mat', 'end_voi.mat', 'met_params.txt', 'GAS_met_params_lap.txt', 'paths_GAS.dat', 'gasRoisMask.nii.gz', 'temp.sh', lappySubjDir, machineListL);

delete(fullfile('conTrack','temp.sh'));