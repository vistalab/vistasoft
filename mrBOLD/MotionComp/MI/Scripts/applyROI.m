if ~exist('ROI1','var')
    cd('C:\Guillaume\VISTASOFT\mrLoadRet-3.0\Analysis\MotionComp\MI\ROIs')
    load('ROI6.mat')
end

frame1 = reshape(meanMap{1},[1 size(meanMap{1},1)*size(meanMap{1},2) size(meanMap{1},3)]);
frame2 = reshape(meanMap{2},size(frame1));

figure
motionCompPlot3Difference(meanMap{1},meanMap{2},1,10);

for i = 1:6
    
    eval(['[coregRotMatrix' num2str(i) ', frameCorrected, param] = motionCompMutualInf(vw, frame1,frame2,'''',ROI' num2str(i) ');']);
    
    imageCorrected = reshape(frameCorrected,size(meanMap{1}));
    figure
    motionCompPlot3Difference(imageCorrected,meanMap{2},1,10);
    
    pause
    
end