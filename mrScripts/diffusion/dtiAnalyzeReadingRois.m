% default to nearest-neighbor
excludeSubs = {'bw040806','tk040817','dh040607','an041018'};
diffusivityUnitStr = '(\mum^2/msec)';

if(~exist('dataDir','var'))
    dataDir = 'dti';
end

if(ispc)
    baseDir = '//171.64.204.10/biac2-wandell2/data/reading_longitude';
else
    baseDir = '/biac2/wandell2/data/reading_longitude';
end
behavDataFile = fullfile(baseDir,'read_behav_measures.csv');
subDir = fullfile(baseDir,dataDir,'*0*');
outFileName = ['scrAnalysis_' dataDir];

[f,sc] = findSubjects(subDir,'*_dt6_noMask',excludeSubs);
outDir = fullfile(baseDir,'roiAnalyses');
if(~exist(outDir,'dir')) mkdir(outDir); end
N = length(f);

ftOpts.stepSizeMm = 1;
ftOpts.faThresh = 0.12;
ftOpts.lengthThreshMm = [20 60];
ftOpts.angleThresh = 50;
ftOpts.wPuncture = 0.2;
ftOpts.whichAlgorithm = 1;
ftOpts.whichInterp = 1;
ftOpts.seedVoxelOffsets = [0.25 .75];

goodSubs = ones(1,N);
clear data;
s=license('inuse'); userName = s(1).user;
analysisDate = datestr(now,31);
analyzedBy = userName;
logFile = fopen(fullfile(outDir,[outFileName '_log_' datestr(now,'yymmdd_HHMM') '.txt']),'wt');
fprintf(logFile, '* * * Analysis run by %s on %s * * *\n', userName, analysisDate);
nSubs = 0;
for(ii=1:N)
    fname = f{ii};
    disp(['Processing ' fname '...']);
    fprintf(logFile, ['Processing ' fname ': ']);
    fiberPath = fullfile(fileparts(fname), 'fibers');
    roiPath = fullfile(fileparts(fname), 'ROIs');
    if(~exist(roiPath,'dir') | ~exist(fullfile(roiPath, 'CC_FA.mat'),'file') ...
            | ~exist(fullfile(roiPath, 'lscr.mat'),'file') | ~exist(fullfile(roiPath, 'rscr.mat'),'file'))
        disp('    Some ROIs missing- skipping...');
        fprintf(logFile, 'Some ROIs missing- skipping...\n');
    else
        nSubs = nSubs+1;
        dt = load(fname,'dt6','xformToAcPc','mmPerVox');
        cc = dtiReadRoi(fullfile(roiPath, 'CC_FA'));
        lscr = dtiReadRoi(fullfile(roiPath, 'lscr'));
        rscr = dtiReadRoi(fullfile(roiPath, 'rscr'));

        % Track fibers from each SCR ROI
        nPts = 41;
        lscrFg = dtiFiberTrack(dt.dt6, lscr.coords, dt.mmPerVox, dt.xformToAcPc, 'lscrFg', ftOpts);
        slPos = mean(lscr.coords(:,3));
        clipPts = [slPos-15 slPos+15];
        lscrFg = dtiFiberAlign(lscrFg, [NaN NaN slPos], (nPts-1)./2, clipPts);
        %dtiWriteFiberGroup(lscrFg, fullfile(fiberPath,lscrFg.name));
        %guidata(gcf,dtiAddFG(lscrFg,guidata(gcf)));

        rscrFg = dtiFiberTrack(dt.dt6, rscr.coords, dt.mmPerVox, dt.xformToAcPc, 'rscrFg', ftOpts);
        slPos = mean(rscr.coords(:,3));
        clipPts = [slPos-15 slPos+15];
        rscrFg = dtiFiberAlign(rscrFg, [NaN NaN slPos], (nPts-1)./2, clipPts);
        %dtiWriteFiberGroup(rscrFg, fullfile(fiberPath,rscrFg.name));

        data(nSubs).subCode = sc{ii};
        data(nSubs).ccRoiCoords = cc.coords;
        data(nSubs).lscrRoiCoords = lscr.coords;
        data(nSubs).rscrRoiCoords = rscr.coords;
        data(nSubs).lscrFibers = lscrFg.fibers;
        data(nSubs).rscrFibers = rscrFg.fibers;
        data(nSubs).lscrDt6 = dtiGetValFromTensors(dt.dt6, [lscrFg.fibers{:}], inv(dt.xformToAcPc), 'dt6', 'nearest');
        data(nSubs).lscrDt6 = reshape(data(nSubs).lscrDt6, [nPts,length(lscrFg.fibers),6]);
        data(nSubs).rscrDt6 = dtiGetValFromTensors(dt.dt6, [rscrFg.fibers{:}], inv(dt.xformToAcPc), 'dt6', 'nearest');
        data(nSubs).rscrDt6 = reshape(data(nSubs).rscrDt6, [nPts,length(rscrFg.fibers),6]);
    end
end
fclose(logFile);

save(fullfile(outDir,[outFileName '_dataSum']),'data','analysisDate','analyzedBy');

[bd,bdColNames] = dtiGetBehavioralData({data(:).subCode},behavDataFile);
ageInd = strmatch('Age',bdColNames);
paInd = strmatch('Phonological Awareness',bdColNames);
readerTypeInd = strmatch('Type of Reader',bdColNames);
goodReaders = bd(:,readerTypeInd)'>=0;

bdInds = [1:3,5,7:20];

lscrRoiPos = cellfun(@mean,{data(:).lscrRoiCoords},'UniformOutput',false);
lscrRoiPos = vertcat(lscrRoiPos{:});
rscrRoiPos = cellfun(@mean,{data(:).rscrRoiCoords},'UniformOutput',false);
rscrRoiPos = vertcat(rscrRoiPos{:});

clipToPosteriorSCR = false;
clear lvals rvals lpos rpos lfa rfa;
nFibers = size(data(1).lscrFibers{1},2);
for(ii=1:length(data))
    lCoordsY = data(ii).lscrRoiCoords(:,2);
    rCoordsY = data(ii).rscrRoiCoords(:,2);
    if(clipToPosteriorSCR)
        % Identify the posterior half of the SCR
        lCut = (max(lCoordsY)-min(lCoordsY))./2 + min(lCoordsY);
        rCut = (max(rCoordsY)-min(rCoordsY))./2 + min(rCoordsY);
        lFiberY = vertcat(data(ii).lscrFibers{:});
        lFiberY = lFiberY(2:3:end,(nFibers+1)/2);
        rFiberY = vertcat(data(ii).rscrFibers{:});
        rFiberY = rFiberY(2:3:end,(nFibers+1)/2);
        lKeep = lFiberY<lCut;
        rKeep = rFiberY<rCut;
    else
        lKeep = ones(size(lCoordsY));
        rKeep = ones(size(rCoordsY));
    end
    %[mean(lFiberY(lKeep)) mean(lFiberY(~lKeep))]
    [vec,val] = dtiEig(data(ii).lscrDt6);
    lfa = dtiComputeFA(val);
    lvals(ii,:) = mean(lfa(:,lKeep),2);
    lpos(ii,:) = mean(data(ii).lscrRoiCoords(:,1:2));
    [vec,val] = dtiEig(data(ii).rscrDt6);
    rfa = dtiComputeFA(val);
    rvals(ii,:) = mean(rfa(:,rKeep),2);    
    rpos(ii,:) = mean(data(ii).rscrRoiCoords(:,1:2));
end
lskelMn = mean(lvals);
rskelMn = mean(rvals);
lskelCI = std(lvals)./sqrt(size(lvals,1)-1).*2;
rskelCI = std(rvals)./sqrt(size(rvals,1)-1).*2;
x = [1:length(lskel)]-1-(length(lskel)-1)/2+round(mean(lscrRoiPos(:,3)));
figure;errorbar(x,lskelMn,lskelCI,'b'); hold on; errorbar(x,rskelMn,rskelCI,'r'); hold off;
xlabel('Z position (mm from AC)');
ylabel('FA');
for(ii=1:length(data))
    lparams(ii,:) = dtiAlignCurve(lvals(ii,:),lskel);
    rparams(ii,:) = dtiAlignCurve(rvals(ii,:),rskel);
end
figure; hold on;
for(ii=1:length(data))
    plot(dtiWarpStep(x,lparams(ii,1:2)),(lvals(ii,:)+lparams(ii,4))*lparams(ii,3),'b');
end
plot(x,lskel,'ro-'); hold off;
for(ii=bdInds)
    disp([num2str(ii) ': ' bdColNames{ii}]);
    %[r,p] = corrcoef([bd(:,ii) lpos]);disp([r(1,2:end); -log10(p(1,2:end))])
    %[r,p] = corrcoef([bd(:,ii) rpos]);disp([r(1,2:end); -log10(p(1,2:end))])
    %[r,p] = corrcoef([bd(:,ii) lpos-rpos]);disp([r(1,2:end); -log10(p(1,2:end))])

    [r,p] = corrcoef([bd(:,ii) lparams]);disp([r(1,2:end); -log10(p(1,2:end))])
    [r,p] = corrcoef([bd(:,ii) rparams]);disp([r(1,2:end); -log10(p(1,2:end))])
    [r,p] = corrcoef([bd(:,ii) lparams-rparams]);disp([r(1,2:end); -log10(p(1,2:end))])
    
    [r,p] = corrcoef([bd(:,ii) lparams(:,2)-lscrRoiPos(:,3)]);disp([r(1,2:end); -log10(p(1,2:end))])
    [r,p] = corrcoef([bd(:,ii) rparams(:,2)-rscrRoiPos(:,3)]);disp([r(1,2:end); -log10(p(1,2:end))])   
end

ind = 7;
figure;plot(bd(:,ind),lparams(:,1),'k.');
xlabel(bdColNames{ind});
ylabel('Left FA SCR Scale');

figure;plot(bd(:,ind),lparams(:,2)-lscrRoiPos(:,3),'k.');
xlabel(bdColNames{ind});
ylabel('Left SCR FA min (Z mm)');

figure;plot(bd(:,ind),rparams(:,2)-rscrRoiPos(:,3),'k.');
xlabel(bdColNames{ind});
ylabel('Right SCR FA min (Z mm)');




