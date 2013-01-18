function mtrFigureFascicleDirUncertainty(mCl, wCl, maxAngle, saveDir)

% mtrFigureFascicleDirUncertainty(0.175, 0.15, 100)

%Definitions
bSaveImages = 1;
numSamples = 2000;
deltaClSearch = 0.1;
maxClSearch = 0.2;
minClSearch = 0.1;
kMeasured = 205;
%ratioE3Diff = 0.1;
ratioE3Diff = 0.32;
ratioE3Same = 0.5;

if(ieNotDefined('saveDir'))
    bSaveImages=0;
    saveDir='';
end

Cl = linspace(0,0.4,50);
fCl = maxAngle ./ (1+exp(-(mCl-Cl)*10/wCl));

figure;
plot(Cl,fCl); 
hold on;
discCl = [minClSearch:deltaClSearch:maxClSearch];
stem(discCl,maxAngle ./ (1+exp(-(mCl-discCl)*10/wCl)),'fill','--')
hold off;
%axes('YTickLabel','','XTickLabel','');
%title('tensor linearity contribution to fiber uncertainty');
xlabel('C_L');
ylabel('{\delta\sigma} (degrees)');
%set(gcf,'Position',[504   751   354   195]);
set(gcf,'Position',[200   200   354   195]);
if bSaveImages
    figFilename = fullfile(saveDir,['fUncertaintySigmoid.png']);
    set(gcf,'PaperPositionMode','auto');
    print('-dpng', '-r500', figFilename);
end

% % Create temp directory currently if none provided
% if ieNotDefined('tempDir')
%     tempDir = 'temp';
% end
% mkdir(tempDir);

genPlotsSphFunc(bSaveImages,fullfile(saveDir,'fUncertaintyDiffEigs'),minClSearch,deltaClSearch,maxClSearch,ratioE3Diff,mCl,wCl,maxAngle,kMeasured,numSamples);

genPlotsSphFunc(bSaveImages,fullfile(saveDir,'fUncertaintySameEigs'),minClSearch,deltaClSearch,maxClSearch,ratioE3Same,mCl,wCl,maxAngle,kMeasured,numSamples);


% XXX This always complains because I always am within the current
% directory in the cygwin shell
%rmdir(tempDir,'s');

return;

function genPlotsSphFunc(bSaveImages,strSaveFileRoot,minClSearch,deltaClSearch,maxClSearch,ratioE3,mCl,wCl,maxAngle,kMeasured,numSamples)

nFigCols = length([minClSearch:deltaClSearch:maxClSearch]);
nn = 1;
for iCl = minClSearch:deltaClSearch:maxClSearch
    % Assume MD = 1
    figure;
    fCl = maxAngle / (1+exp(-(mCl-iCl)*10/wCl));
    dS1 = fCl*ratioE3;
    dS2 = fCl*(1-ratioE3);
    dK1 = 1 / ((dS1*pi/180)*(dS1*pi/180));
    dK2 = 1 / ((dS2*pi/180)*(dS2*pi/180));
    k1 = -kMeasured*dK1 / ( dK1 + kMeasured + 2*sqrt(kMeasured*dK1) );
    k2 = -kMeasured*dK2 / ( dK2 + kMeasured + 2*sqrt(kMeasured*dK2) );
    %subplot(1,nFigCols,nn);
    dispSphFunc(k1,k2);
    title(sprintf('C_L = %g', iCl));
    nn = nn+1;
    %set(gcf,'Position',[504   751   354   195]);
    set(gcf,'Position',[200   200   354   195]);
    colorbar('Position',[0.8 0.3 0.05 0.6]);
    if bSaveImages
        figFilename = [strSaveFileRoot '_Cl_' num2str(iCl) '.png'];
        set(gcf,'PaperPositionMode','auto');
        print('-dpng', '-r500', figFilename);
    end
end

return

function dispSphFunc(k1,k2)
 % Going to color a sphere according to the desired distribution
colormap(hot);
[px py pz] = sphere(80);
testVec = [px(:) py(:) pz(:)]';
eVecs = [0 1 0; 1 0 0]';
fbValues = reshape(fb5Pdf(eVecs,testVec,[k1,k2]),size(pz));
% Get hemisphere
%pz(pz<0) = 0;
surf(px,py,pz,reshape(fbValues,size(px)),'EdgeAlpha',0,'FaceAlpha',1);
%colorbar;
caxis([0,max(fbValues(:))]);
%caxis([-0.1,1]);
%caxis([0,3.5]);
axis equal
axis vis3d
grid on;

return;

% function genPlotsSphDist(minClSearch,deltaClSearch,maxClSearch,ratioE3,mCl,wCl,maxAngle,kMeasured,numSamples,tempDir)
% 
% % Create script for sampling vectors according to desired distribution
% tempScriptFile = fullfile(tempDir,'tempRun.sh');
% fid = fopen(tempScriptFile,'wt');
% fprintf(fid,'#!/bin/bash\n');
% 
% % EVals 2,3 are different
% for iCl = minClSearch:deltaClSearch:maxClSearch
%     fCl = maxAngle / (1+exp(-(mCl-iCl)*10/wCl));
%     dS1 = fCl*ratioE3;
%     dS2 = fCl*(1-ratioE3);
%     dK1 = 1 / ((dS1*pi/180)*(dS1*pi/180));
%     dK2 = 1 / ((dS2*pi/180)*(dS2*pi/180));
%     k1 = -kMeasured*dK1 / ( dK1 + kMeasured + 2*sqrt(kMeasured*dK1) );
%     k2 = -kMeasured*dK2 / ( dK2 + kMeasured + 2*sqrt(kMeasured*dK2) );
%     fprintf(fid,'sphsample -pdf bingham -k1 %g -k2 %g -ns %g -outputfile tempDist_cl_%g.Bdouble\n',k1,k2,numSamples,iCl);
% end
% fclose(fid);
% input(['Run ' tempScriptFile ' then press [return] when finished to continue.']);
% 
% % Cleanup and load the sample data
% delete(tempScriptFile);
% figure; 
% nn = 1;
% ratioE2 = 1-ratioE3;
% cmap = [autumn(255); [.25 .25 .25]];
% nFigCols = length([minClSearch:deltaClSearch:maxClSearch]);
% for iCl = minClSearch:deltaClSearch:maxClSearch
%     % Assume MD = 1
%     eVal1 = (3*iCl + 3*(ratioE2)) / (1+ratioE2);
%     eVal2 = (3 - eVal1)*ratioE2;
%     eVal3 = eVal2*(1-ratioE2)/ratioE2;
%     sampleFile = fullfile(tempDir,sprintf('tempDist_cl_%g.Bdouble',iCl));
%     subplot(1,nFigCols,nn);
%     displaySphDist(sampleFile,numSamples); 
%     %title(sprintf('Cl = %g, ratioE3 = %g', iCl, ratioE3));
%     title(sprintf('C_L = %g', iCl));
% %     subplot(2,nFigCols,nn+nFigCols);
%      nn = nn+1;
% %     [px py pz] = ellipsoid(0,0,0,eVal3,eVal2,eVal1,50);
% %     p = surf(px,py,pz,repmat(256,size(pz)),'EdgeAlpha',0);
% %     axis([-1 1 -2 2 -2 2]);
% %     axis manual square equal vis3d; colormap(cmap); alpha 0.75;
% %     set(p,'FaceLighting','phong','FaceColor','interp','AmbientStrength',0.5);
% %     light('Position',[1 0 0],'Style','infinite');
% 
%     delete(sampleFile);
% end
% set(gcf,'Position',[405 739 672 208]);
% 
% return

% function displaySphDist(sampleFile,numSamples)
% 
% fid = fopen(sampleFile,'rb','b');
% d = fread(fid,'double'); fclose(fid);
% vecs = reshape(d,3,numSamples);
% sub_vecs = vecs(:,vecs(3,:)>0);
% plot3(vecs(1,:), vecs(2,:), vecs(3,:), '.')
% hold on
% [px py pz] = sphere;
% surf(px,py,pz,repmat(256,size(pz)),'EdgeAlpha',1);
% alpha(0)
% axis equal
% axis vis3d
% grid off;
% set(gca,'XTick',[]);
% set(gca,'YTick',[]);
% set(gca,'ZTick',[]);
% % xlabel('x');
% % ylabel('y');
% % zlabel('z');
% 
% return;
