

diffusivityUnitStr = '(\mum^2/msec)';

if(~exist('dataDir','var'))
    dataDir = 'dti';
end

if(ispc)
    baseDir = '//171.64.204.10/biac2-wandell2/data/reading_longitude';
else
    baseDir = '/biac2/wandell2/data/reading_longitude';
end

subDir = fullfile(baseDir,dataDir,'*0*');
outFileName = ['mniRoiAnalysis_' dataDir];
outDir = fullfile(baseDir,'roiAnalyses');
if(~exist(outDir,'dir')) mkdir(outDir); end
dataSumFile = fullfile(outDir,[outFileName '_sum.mat']);
logFileName = fullfile(outDir,[outFileName '_log_' datestr(now,'yymmdd_HHMM') '.txt']);

if(~exist(dataSumFile,'file'))
    % Klingberg:
    % "The VOI had a volume of 960 mm^3, and was located within x = -36 to -26,
    % y = -50 to -10, and z = 0 to 32 mm relative the to anterior commissure."
    % (These are presumably MNI coordinates; peak at [-28 -20 28])
    %kCoordsMni = [-31 -20 26];
    % Beaulieu: -28 -14 24
    % Klingberg: -28 -20 28 (reported in Tal: -28 -22 29)
    % Deutsch: -28 -28 24 (reported in Tal: -28 -26 23)
    % Nagy: -27 -29 5 (reported in Tal: -27 -28 6)
    % Niogy: hard to tell. The slice shown has a coord above it, probably Tal, -28 -11 26, which is in MNI: -28 -12 28.
    clear c mniRois;
    c(1).name = 'Klingberg'; c(1).coords = [-28 -20 28];
    c(2).name = 'Deutsch'; c(2).coords = [-28 -28 24];
    c(3).name = 'Nagy'; c(3).coords = [-27 -29 5];
    c(4).name = 'Niogi'; c(4).coords = [-28 -12 28];
    for(ii=1:length(c))
        mniRois(ii,1) = dtiNewRoi([c(ii).name '03']); mniRois(ii,1).coords = dtiBuildSphereCoords(c(ii).coords, 3);
        mniRois(ii,2) = dtiNewRoi([c(ii).name '05']); mniRois(ii,2).coords = dtiBuildSphereCoords(c(ii).coords, 5);
    end
    mniRois = mniRois(:);
    
    excludeSubs = {'dh040607','an041018','hy040602','lg041019','mh040630','tk040817'};
    [f,sc] = findSubjects(subDir,'*_dt6_noMask',excludeSubs);
    N = length(f);

    goodSubs = ones(1,N);
    clear data;
    s=license('inuse'); userName = s(1).user;
    analysisDate = datestr(now,31);
    analyzedBy = userName;
    logFile = fopen(logFileName,'wt');
    fprintf(logFile, '* * * Analysis run by %s on %s * * *\n', userName, analysisDate);
    nSubs = 0;
    for(ii=1:N)
        tic;
        fname = f{ii};
        disp(['Processing ' fname '...']);
        fprintf(logFile, ['Processing ' fname ': ']);
        roiPath = fullfile(fileparts(fname), 'ROIs');
        fiberPath = fullfile(fileparts(fname), 'fibers');

        dt = load(f{ii});
        % We need to invert the spatial normalization
        def = dt.t1NormParams(1);
        if(isfield(def,'name')&&~strcmp(def.name,'MNI'))
            error(['Problem with MNI sn for ' fname '.']);
        end
        [def.deformX, def.deformY, def.deformZ] = mrAnatInvertSn(def.sn);
        def.inMat = inv(def.sn.VF.mat); % xform from acpc space to deformation field space

        data(ii).sc = sc{ii};
        % WARP MNI ROIS TO THIS BRAIN & GET THE TENSORS
        for(jj=1:length(mniRois))
            roi = mniRois(jj);
            roi.coords = mrAnatXformCoords(dt.t1NormParams.sn, roi.coords);
            roi.coords = unique(round(roi.coords),'rows');
            roi = dtiRoiClean(roi, 3, {'fillHoles', 'removeSat'});
            %dtiWriteRoi(roi, fullfile(roiPath, roi.name), 1, 'acpc');
            data(ii).rois(jj) = roi;
            % get the tensors for this ROI
            data(ii).dt6{jj} = dtiGetValFromTensors(dt.dt6, roi.coords, inv(dt.xformToAcPc), 'dt6', 'nearest');
        end
        fprintf('(%0.1f seconds) ',toc);
    end
    fclose(logFile);
    save(dataSumFile, 'data', 'f', 'mniRois', 'analysisDate', 'analyzedBy');
else
    disp(['Loading ' dataSumFile '...']);
    load(fullfile(outDir,[outFileName '_sum.mat']));
end

behavDataFile = fullfile(baseDir,'read_behav_measures.csv');
[bd,bdColNames] = dtiGetBehavioralData({data(:).sc},behavDataFile);
ageInd = strmatch('Age',bdColNames);
paInd = strmatch('Phonological Awareness',bdColNames);
widInd = strmatch('Word ID ss',bdColNames);
readerTypeInd = strmatch('Type of Reader',bdColNames);
goodReaders = bd(:,readerTypeInd)'>=0;

%goodSubs=[1:43,45:length(f)];
goodSubs=[1:length(f)];

clear fa md rd ad pdd;
for(ii=1:length(data))
  for(jj=1:length(data(ii).dt6))
    [vec,val] = dtiEig(data(ii).dt6{jj});
    val = val./1000;
    fa(ii,jj) = mean(dtiComputeFA(val));
    md(ii,jj) = mean(val(:));
    rd(ii,jj) = mean((val(:,2)+val(:,3))./2);
    ad(ii,jj) = mean(val(:,1));
    pdd(ii,jj,:) = mean(squeeze(vec(:,:,1)));
  end
end

logFile = fopen(logFileName,'wt');
fprintf(logFile, '\nSTATS:\n');
roiNames = {mniRois.name};
bdInds = [1:3,5,7:20];
roiInds = [1:8];
valNames = {'fa','md','rd'};
for(valNum=1:length(valNames))
    eval(['val=' valNames{valNum} ';']);
    fprintf('\n\n%s:\n',upper(valNames{valNum}));
    fprintf(logFile,'\n\n%s:\n',upper(valNames{valNum}));
    for(ii=bdInds)
        [r,p] = corrcoef([bd(goodSubs,ii),val(goodSubs,:)]);
        r = r(2:end,1); p = p(2:end,1);
        fprintf('%031s:',bdColNames{ii});
        fprintf(logFile,'%031s:',bdColNames{ii});
        for(jj=roiInds)
            if(p(jj)<0.01) sig='***'; elseif(p(jj)<0.05) sig='** '; elseif(p(jj)<0.1) sig='*  '; else sig='   '; end
            fprintf('\t%s r=%+0.2f %s',roiNames{jj},r(jj),sig);
            fprintf(logFile,'\t%s r=%+0.2f %s',roiNames{jj},r(jj),sig);
        end
        fprintf('\n'); fprintf(logFile,'\n');
    end
end
fclose(logFile);

bdInds = [3,5,7,8,9,10];
for(jj=bdInds)
    figure; set(gcf,'name',bdColNames{jj});
    for(ii=1:4)
        subplot(2,2,ii);
        x = bd(goodSubs,jj);
        y = fa(goodSubs,ii);
        plot(x,y,'k.');
        xlabel(bdColNames{jj});
        ylabel(['FA (' roiNames{ii} ')']);
        [r,p] = corr(x,y);
        title(sprintf('r=%0.2f (p=%0.4f)',r,p));
    end
end

for(jj=bdInds)
    for(ii=1:4)
        x = bd(goodSubs,jj);
        y = fa(goodSubs,ii);
        xlabel(bdColNames{jj});
        ylabel(['FA (' roiNames{ii} ')']);
        [r,p] = corr(x,y);
        title(sprintf('r=%0.2f (p=%0.4f)',r,p));
    end
end


meanPdd = dtiDirMean(permute(pdd,[2 3 1]));
error('stop here');



%% Whole-brain analysis

diffusivityUnitStr = '(\mum^2/msec)';
dataDir = 'dti';
baseDir = '/biac2/wandell2/data/reading_longitude';
subDir = fullfile(baseDir,dataDir,'*0*');
outFileName = ['mniRoiAnalysis_' dataDir];
outDir = fullfile(baseDir,'roiAnalyses');
if(~exist(outDir,'dir')) mkdir(outDir); end
dataSumFile = fullfile(outDir,[outFileName '_sum.mat']);
logFileName = fullfile(outDir,[outFileName '_log_' datestr(now,'yymmdd_HHMM') '.txt']);
excludeSubs = {'dh040607','an041018','hy040602','lg041019','mh040630','tk040817'};
[f,sc] = findSubjects(subDir,'*_dt6_noMask',excludeSubs);
N = length(f);
    
addpath /home/bob/matlab/stats/

behavDataFile = fullfile(baseDir,'read_behav_measures.csv');
[bd,bdColNames] = dtiGetBehavioralData(sc,behavDataFile);
ageInd = strmatch('Age',bdColNames);
paInd = strmatch('Phonological Awareness',bdColNames);
widInd = strmatch('Word ID ss',bdColNames);
readerTypeInd = strmatch('Type of Reader',bdColNames);
goodReaders = bd(:,readerTypeInd)'>=0;
goodSubs=[1:length(f)];

ni = niftiRead(fullfile('/silver/scr1/mniWarpAnalysis/data/',[sc{1} '_FA_sn.nii.gz']));
xform = ni.qto_xyz;
fa = zeros([size(ni.data),N]);
fa(:,:,:,1) = ni.data;
for(ii=2:N)
   ni = niftiRead(fullfile('/silver/scr1/mniWarpAnalysis/data/',[sc{ii} '_FA_sn.nii.gz']));
   fa(:,:,:,ii) = ni.data;
end

mnFa = mean(fa,4);
%mask = mnFa>=0.25;
mask = dtiCleanImageMask(all(fa>=0.15,4));
maskInds = find(mask);
showMontage(mask);
faInd = zeros(N,length(maskInds));
for(ii=1:N)
   tmp = fa(:,:,:,ii);
   faInd(ii,:) = tmp(maskInds);
end

bdInd = paInd;
valName = 'FA';
%[p,s] = myStatTest(bd(:,bdInd),faInd,'r');
[p,s] = myStatTest(bd(:,bdInd),faInd,'k');

imP=zeros(size(mask)); imP(maskInds)=p; 

slAc=[10:2:40];
slIm = inv(xform)*[ones(2,length(slAc));slAc;ones(1,length(slAc))];
slIm = round(slIm(3,:));

% Remove 26-connected regions samller than clustThresh voxels
clustThresh = 10;
pThresh = 0.05;

imR=zeros(size(mask)); imR(maskInds)=s; 
threshIm = imP<pThresh & imR<0; threshIm(~mask) = 0;
threshIm = bwareaopen(threshIm,clustThresh,26);
imR(~threshIm) = 0;
mrAnatOverlayMontage(-imR, xform, mnFa, xform, autumn(256), [0.1 1], slAc, fullfile(outDir,'FA_PA_negCorr'), 3, 1, true, 1);
set(gcf,'name','negative correlations');

imR=zeros(size(mask)); imR(maskInds)=s; 
threshIm = imP<pThresh & imR>0; threshIm(~mask) = 0;
threshIm = bwareaopen(threshIm,clustThresh,26);
imR(~threshIm) = 0;
%showMontage(imR);
mrAnatOverlayMontage(imR, xform, mnFa, xform, autumn(256), [0.1 1], slAc, fullfile(outDir,'FA_PA'), 3, 1, true, 1);
set(gcf,'name','positive correlations');

% Show stats for each cluster
[clustLabel,clustN] = bwlabeln(threshIm, 26);
fprintf('%s vs. %s: %d clusters passed the size threshold of %d.\n',bdColNames{bdInd},valName,clustN,clustThresh);
plotBest = false;
for(jj=1:clustN)
    % Get the original data for each cluster and summarize it.
    curClust = clustLabel==jj;
    nvox = sum(curClust(:));
    clustInds = find(curClust(:));
    [inMask,maskLoc] = ismember(clustInds,maskInds);
    [x,y,z] = ind2sub(size(mask),clustInds);
    bestVox = find(p(maskLoc)==min(p(maskLoc)));
    mniCoords = mrAnatXformCoords(xform, [x,y,z]);
    mnMni = mean(mniCoords);
    bestMni = mniCoords(bestVox,:);
    if(mean(s(maskLoc))<0) sSum = min(s(maskLoc));
    else sSum = max(s(maskLoc)); end
    fprintf('   Cluster %d: size = %d voxels; tau = %0.2f; p = %0.5f; mean MNI: [%d %d %d]\n',...
        jj, nvox, sSum, min(p(maskLoc)), round(mnMni));
    % Plot the mean or best data within the cluster vs. behavior
    if(plotBest)
        mnDataVal = faInd(:,maskLoc(bestVox(1)));
    else
        mnDataVal = mean(faInd(:,maskLoc),2);   
    end
    bdSum = bd(:,bdInd);
    notNan = ~isnan(bdSum);
    [curP,curR,curDf] = myStatTest(mnDataVal(notNan),bdSum(notNan),'r');
    [curKP,curKR] = myStatTest(mnDataVal(notNan),bdSum(notNan),'k');
    figure;
    set(gcf,'Name',sprintf('%d: %s vs. %s Scatter',jj,valName,bdColNames{bdInd}));
    plot(mnDataVal(notNan),bdSum(notNan),'ko');
    axis square;
    %fprintf('[%d %d %d]: r=%0.2f (p=%0.1e), tau=%0.2f (p=%0.1e), n=%d\n',round(mnMni),curR,curP,curKR,curKP,nvox);
    xlabel(valName);
    ylabel(bdColNames{bdInd});
end
  


[sigN,sigInd] = fdr(p,0.2,'original','mean');

