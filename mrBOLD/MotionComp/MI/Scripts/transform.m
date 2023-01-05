clear all
close all
mrVista;
vw = getSelectedInplane;
motionCompMutualInfMeanInit(vw,1:6,'',1,'RigidDtiScan1','Original',1,1);

close all
clear all
mrVista
vw = getSelectedInplane;
ROI = zeros([sliceDims(vw,1) size(vw.anat,3)]);
ROI(80:100,35:70,15:19) = ones(21,36,5);
motionCompMutualInfMeanInit(vw,1:6,ROI,1,'OccLobeScan1','Original',1,0);

clear all
close all