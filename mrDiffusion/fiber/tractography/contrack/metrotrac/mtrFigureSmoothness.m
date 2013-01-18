function mtrFigureSmoothness(kSmooth,saveDir)

%Definitions
%numSamples = 2000;
bSaveImages = 1;

% Create temp directory currently if none provided
% if ieNotDefined(tempDir)
%     tempDir = 'temp';
% end
% mkdir(tempDir);
% genPlotsSphDist(kSmooth,numSamples,tempDir);
genPlotsSphFunc(kSmooth);
set(gcf,'Position',[504   751   354   195]);
if bSaveImages
    figFilename = fullfile(saveDir,['smoothPdf.png']);
    set(gcf,'PaperPositionMode','auto');
    print('-dpng', figFilename);
end
return;

function genPlotsSphFunc(kSmooth)
 % Going to color a sphere according to the desired distribution
figure;
%cmap = [autumn(255); [.25 .25 .25]];
colormap(gray);
[px py pz] = sphere(80);
testVec = [px(:) py(:) pz(:)]';
watValues = reshape(watsonPdf([0,0,1]',testVec,kSmooth),size(pz));
% Get hemisphere
pz(pz<0) = 0;
surf(px,py,pz,reshape(watValues,size(px)),'EdgeAlpha',0,'FaceAlpha',1);
colorbar;
caxis([0,max(watValues(:))]);
axis equal
axis vis3d
grid on;

return;





function genPlotsSphDist(kSmooth,numSamples,tempDir)

% Create script for sampling vectors according to desired distribution
tempScriptFile = fullfile(tempDir,'tempRun.sh');
fid = fopen(tempScriptFile,'wt');
fprintf(fid,'#!/bin/bash\n');
fprintf(fid,'sphsample -pdf watson -k %g -ns %g -outputfile tempDist.Bdouble\n',kSmooth,numSamples);
fclose(fid);
input(['Run ' tempScriptFile ' then press [return] when finished to continue.']);

% Cleanup and load the sample data
delete(tempScriptFile);
figure;
cmap = [autumn(255); [.25 .25 .25]];
sampleFile = fullfile(tempDir,'tempDist.Bdouble');
displaySphDist(sampleFile,numSamples);
%set(gca,'Postion',[0.13   0.11   0.775   0.815]);
title(['\DeltaS = ' num2str(round(180 / (pi*sqrt(kSmooth)))) ' \circ']);
delete(sampleFile);
return;

function displaySphDist(sampleFile,numSamples)

fid = fopen(sampleFile,'rb','b');
d = fread(fid,'double'); fclose(fid);
vecs = reshape(d,3,numSamples);
sub_vecs = vecs(:,vecs(3,:)>0);
plot3(sub_vecs(1,:), sub_vecs(2,:), sub_vecs(3,:), '.')
hold on
[px py pz] = sphere;
surf(px,py,pz,repmat(256,size(pz)),'EdgeAlpha',1,'FaceAlpha',0);
%alpha(0.3)
axis equal
axis vis3d
grid off;
% xlabel('x');
% ylabel('y');
% zlabel('z');

return;