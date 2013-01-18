function mtrPrepParConTrack(subjName)

machineListHalf1 = {'deep-lumen1','deep-lumen1','deep-lumen2','deep-lumen2','deep-lumen4','deep-lumen4'};
machineListHalf2 = {'deep-lumen5','deep-lumen5','deep-lumen6','deep-lumen6','deep-lumen8','deep-lumen8'};
localSubjDirName = fullfile('/teal/scr1/dti/sisr',subjName);
remoteSubjDirName = fullfile('/radlab_share/home/tony/images',subjName);
pcSubjDirName = fullfile('c:\cygwin\home\sherbond\images',subjName);
mtrTwoRoiSamplerSISR(localSubjDirName, 'CC_FA.mat', 'RV3AB7d.mat', 'conTrack/met_params.txt', 'RDOCC_met_params_dl.txt', 'paths_RDOCC.dat', 'rdoccRoisMask.nii.gz', 'track_RDOCC.sh',remoteSubjDirName,machineListHalf1);
mtrTwoRoiSamplerSISR(localSubjDirName, 'CC_FA.mat', 'RV3AB7d.mat', 'conTrack/met_params.txt', 'RDOCC_met_params_pc.txt', 'paths_RDOCC.dat', 'rdoccRoisMask.nii.gz', 'temp_trash',pcSubjDirName,machineListHalf1);
mtrTwoRoiSamplerSISR(localSubjDirName, 'CC_FA.mat', 'RV3AB7d.mat', 'conTrack/met_params.txt', 'RDOCC_met_params.txt', 'paths_RDOCC.dat', 'rdoccRoisMask.nii.gz');
mtrTwoRoiSamplerSISR(localSubjDirName, 'CC_FA.mat', 'LV3AB7d.mat', 'conTrack/met_params.txt', 'LDOCC_met_params_dl.txt', 'paths_LDOCC.dat', 'ldoccRoisMask.nii.gz', 'track_LDOCC.sh',remoteSubjDirName,machineListHalf2);
mtrTwoRoiSamplerSISR(localSubjDirName, 'CC_FA.mat', 'LV3AB7d.mat', 'conTrack/met_params.txt', 'LDOCC_met_params_pc.txt', 'paths_LDOCC.dat', 'ldoccRoisMask.nii.gz', 'temp_trash',pcSubjDirName,machineListHalf2);
mtrTwoRoiSamplerSISR(localSubjDirName, 'CC_FA.mat', 'LV3AB7d.mat', 'conTrack/met_params.txt', 'LDOCC_met_params.txt', 'paths_LDOCC.dat', 'ldoccRoisMask.nii.gz');
mtrTwoRoiSamplerSISR(localSubjDirName, 'RMT.mat', 'CC_FA.mat', 'conTrack/met_params.txt', 'RMT_met_params_dl.txt', 'paths_RMT.dat', 'rmtRoisMask.nii.gz', 'track_RMT.sh',remoteSubjDirName,machineListHalf1);
mtrTwoRoiSamplerSISR(localSubjDirName, 'RMT.mat', 'CC_FA.mat', 'conTrack/met_params.txt', 'RMT_met_params_pc.txt', 'paths_RMT.dat', 'rmtRoisMask.nii.gz', 'temp_trash',pcSubjDirName,machineListHalf1);
mtrTwoRoiSamplerSISR(localSubjDirName, 'RMT.mat', 'CC_FA.mat', 'conTrack/met_params.txt', 'RMT_met_params.txt', 'paths_RMT.dat', 'rmtRoisMask.nii.gz');
mtrTwoRoiSamplerSISR(localSubjDirName, 'LMT.mat', 'CC_FA.mat', 'conTrack/met_params.txt', 'LMT_met_params_dl.txt', 'paths_LMT.dat', 'lmtRoisMask.nii.gz', 'track_LMT.sh',remoteSubjDirName,machineListHalf2);
mtrTwoRoiSamplerSISR(localSubjDirName, 'LMT.mat', 'CC_FA.mat', 'conTrack/met_params.txt', 'LMT_met_params_pc.txt', 'paths_LMT.dat', 'lmtRoisMask.nii.gz', 'temp_trash',pcSubjDirName,machineListHalf2);
mtrTwoRoiSamplerSISR(localSubjDirName, 'LMT.mat', 'CC_FA.mat', 'conTrack/met_params.txt', 'LMT_met_params.txt', 'paths_LMT.dat', 'lmtRoisMask.nii.gz');

delete(fullfile(localSubjDirName,'conTrack','temp_trash'));