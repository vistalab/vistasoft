function nfgCompareProjectomeToGold(phantomDir, projType, bWriteBundledProj, bDoTrueError, bDoArclength)
%Compare projectome with gold standard.
%
%   nfgCompareProjectomeToGold(phantomDir, projType, bWriteBundledProj)
%
% This loads the gold standard pathways and bundle info.  For each bundle,
% the corresponding pathways are found in the projectome solution and the
% volume of the gold standard and the projectome estimate bundles are
% calculated.
%
% Input the projectome type is a cell array and can be any or all of 
%   ('stt', 'stt_bm', 'ctr_bm', 'trk', or 'gold').
%
% NOTES: 

if ieNotDefined('bWriteBundledProj'); bWriteBundledProj=0; end
if isempty(projType) || ~iscellstr(projType)
    error('Must provide cell array of projectome types to compare!');
end

% Directories
fiberDir = nfgGetName('fiberDir',phantomDir);
% Input Files
volExFile = nfgGetName('volExFile',phantomDir);
goldPDBFile = nfgGetName('goldPDBFile',phantomDir);
goldInfoFile = nfgGetName('goldInfoFile',phantomDir);
projFile={};
for pp=1:length(projType)
    projFile{pp} = nfgGetName([projType{pp},'PDBFile'],phantomDir); %#ok<AGROW>
end
% Output
bundleOutFile = fullfile(fiberDir,'gold');

% Validate existence of directories
if ~isdir(fiberDir)
    error('Must provide a valid path to an NFG simulation phantom!');
end

% What types of comparisons should we do?
if ieNotDefined('bDoTrueError'); bDoTrueError = 0; end
if ieNotDefined('bDoArclength'); bDoArclength = 1; end
if ieNotDefined('bDoFiberCount'); bDoFiberCount = 0; end
 
% Get bundle ID and radius of each gold pathway from info file
gi = load(goldInfoFile);
g_bundleID = zeros(1,length(gi.strand_info));
g_radius = zeros(1,length(gi.strand_info));
for ii=1:length(gi.strand_info)
    g_bundleID(ii) = gi.strand_info(ii).bundleID+1;
    g_radius(ii) = gi.strand_info(ii).radius;
end

% XXX For testing
%g_bundleID(g_bundleID>30) = -1;

% Set the distance threshold to be equal to the diameter of the gold fiber
% bundle + the voxel resolution.  Ideally we would like the distance to be the radius of the gold
% plus the radius of the projectome, but we don't know the radii for all
% projectome estimates
vol = niftiRead(volExFile);
dThresh = max(vol.pixdim) + 2*max(g_radius);

% Compare Gold to the Projectome
disp('Importing gold projectome ...');
fgG = mtrImportFibers(goldPDBFile);
% Prepare output file
fg = dtiNewFiberGroup();
fg.fibers = fgG.fibers;
fgAllNonSel = dtiNewFiberGroup();
iAllNonSelGroup = [];
iGroupStat = zeros(1,length(fgG.fibers));
iBundleStat = g_bundleID;
% Radii to search through to compare projectomes
vR = 0.005:0.0005:0.07;
% For common summary info
fpCount = zeros(1,length(projFile));
tpCount = zeros(1,length(projFile));
% For arclength calculations
alE = zeros(length(projFile),max(g_bundleID));
fvol = zeros(length(projFile),max(g_bundleID));
fvolG = zeros(1,max(g_bundleID));
% For trueerror calculations
teE = zeros(length(projFile),max(g_bundleID));
teW = zeros(1,max(g_bundleID));
% For normalized fiber count comparison
%nfc = zeros(length(projFile),max(g_bundleID));
%nfcG = nfgGetNormalizeFiberCount(g_bundleID,g_bundleID);
numBundlesGold = sum(unique(g_bundleID)>0);
numFibersGold = sum(g_bundleID>0);
vID = {};
for pp=1:length(projFile)
    % Get the projectome to test
    disp(' ');disp(['Importing test projectome ' projFile{pp} ' ...']);
    fgProj = mtrImportFibers(projFile{pp});
    % Match the projectome fibers to bundles in the gold set
    [fibersSel, fibersNonSel, iBundleSel] = nfgMatchProjectome(fgG,g_bundleID,fgProj,dThresh);
    % False positives
    fpCount(pp) = length(fibersNonSel) / (length(fibersNonSel) + length(fibersSel)) * 100;
    % True positives
    tpCount(pp) = sum(unique(iBundleSel)>0) / numBundlesGold * 100;
    
    
    % Calculate the volume estimate of the test fibers compared with gold
    if bDoTrueError 
        [teE(pp,:), teW] = nfgCompareAllVolumeTrueError(fgG,g_bundleID,g_radius,fibersSel,iBundleSel,phantomDir);
    end
    if bDoArclength
        %[alE(pp,:)] = nfgCompareAllVolumeArclength(fgG,g_bundleID,g_radius,vR,fibersSel,fibersNonSel,iBundleSel);
        bApplyHagmannW = 0;
        if strcmp(projType{pp},'trk')
            [fvol(pp,:), fvolG, fvolNon] = nfgCompareAllVolumeArclength(fgG,g_bundleID,g_radius,vR,fibersSel,fibersNonSel,iBundleSel,bApplyHagmannW);
        else
            [fvol(pp,:), fvolG, fvolNon] = nfgCompareAllVolumeArclength(fgG,g_bundleID,g_radius,vR,fibersSel,fibersNonSel,iBundleSel,0);
        end
    end
    if bDoFiberCount
        vID{pp} = iBundleSel; %#ok<AGROW>
        %nfc(pp,:) = nfgGetNormalizeFiberCount(iBundleSel,g_bundleID);
    end
    
    % Preparing for output pdb
    nSel = length(fibersSel);
    nNonSel = length(fibersNonSel);
    fg.fibers(end+1:end+nSel) = fibersSel;
    fg.fibers(end+1:end+nNonSel) = fibersNonSel;
    iGroupStat(end+1:end+nSel) = pp;
    iGroupStat(end+1:end+nNonSel) = pp;
    %fgAllNonSel.fibers(end+1:end+nNonSel) = fibersNonSel;
    %iAllNonSelGroup(end+1:end_nSel) = pp;
    iBundleStat(end+1:end+nSel) = iBundleSel;
    iBundleStat(end+1:end+nNonSel) = -1;
    [foo, projName] = fileparts(projFile{pp});
    bundleOutFile = [bundleOutFile '-' projName]; %#ok<AGROW>
end

[nfc, nfcG] = nfgGetNormalizeFiberCount(vID,g_bundleID);

% Plotting and Reporting
summary_info = {};

if bDoTrueError
    % First plot the unweighted trueerror volume error
    figure;
    bar(teE','group');
    xlabel('Bundle ID');
    ylabel('Within Bundle Volume Error (% compared to bundle volume)');
    title('Unnormalized trueError Estimation');
    legend(projType);
    
    % Second plot trueerror volume error normalized by total volume
    figure;
    teNE = teE.*repmat(teW/sum(teW),size(teE,1),1);
    bar(teNE','group');
    xlabel('Bundle ID');
    ylabel('Within Bundle Volume Error (% compared to total volume)');
    title('Normalized trueError Estimation');
    legend(projType);
end

if bDoFiberCount
    % Do plots by sorting NFC Gold
    [foo, iSort] = sort(nfcG,'descend');
    % First plot the normalized fiber counts 
    figure;
    bar([nfcG(iSort)*numFibersGold; nfc(:,iSort)*numFibersGold]','group');
    xlabel('Bundle ID');
    ylabel('Number of fibers compared to smallest');
    title('Normalized Fiber Count');
    legend(['Gold', projType(:)']);
    
    % Second plot the normalized fiber count error
    figure;
    nfcE = abs(repmat(nfcG*numFibersGold,size(nfc,1),1)-nfc*numFibersGold);
    bar(nfcE(:,iSort)','group');
    xlabel('Bundle ID');
    ylabel('Difference betweeen NFC and NFC Gold');
    title('Normalized Fiber Count Error');
    legend(projType);
    strE = 'NFC Error divided by number of bundles: ';
    for pp=1:length(projType)
        strE = [strE num2str(sum(nfcE(pp,:))/numBundlesGold) ' (' projType{pp} ') ']; %#ok<AGROW>
    end
    summary_info{end+1} = strE;
end

if bDoArclength
    % Do plots by sorting NFC Gold
    [foo, iSort] = sort(fvolG,'descend');
    % First plot the normalized fiber counts 
    figure;
    bar([fvolG(iSort)*100; fvol(:,iSort)*100]','group');
    xlabel('Bundle ID');
    ylabel('Bundle Volume Percent of Total');
    title('Normalized Fiber Volume');
    legend(['Gold', projType(:)']);
    
    % Second plot the normalized fiber count error
%     figure;
     fvolE = abs(repmat(fvolG,size(fvol,1),1)-fvol)*100;
%     bar(nfcE(:,iSort)','group');
%     xlabel('Bundle ID');
%     ylabel('Difference betweeen NFC and NFC Gold');
%     title('Normalized Fiber Count Error');
%     legend(projType);
    strE = 'Max/Sum Volume Error Percentage: ';
    for pp=1:length(projType)
        strE = [strE num2str(max(fvolE(pp,:))) '/' num2str(sum(fvolE(pp,:))) ' (' projType{pp} ') ']; %#ok<AGROW>
    end
    summary_info{end+1} = strE;
end

% False positive report
strFPs = 'False Positives: ';
for pp=1:length(projFile)
    strFPs = [strFPs num2str(fpCount(pp)) '% (' projType{pp} ') ']; %#ok<AGROW>
end
summary_info{end+1} = strFPs;
% True positive report
strTPs = 'True Positives: ';
for pp=1:length(projFile)
    strTPs = [strTPs num2str(tpCount(pp)) '% (' projType{pp} ') ']; %#ok<AGROW>
end
summary_info{end+1} = strTPs;

% Write out full report
disp(' '); disp('Summary Info');
for ii=1:length(summary_info)
    disp(summary_info{ii});
end

% Write out pathway file that combines bundled gold and bundled projectome
if bWriteBundledProj
    fg = dtiClearQuenchStats(fg);
    fg = dtiCreateQuenchStats(fg,'Bundle ID',iBundleStat);
    fg = dtiCreateQuenchStats(fg,'Group',iGroupStat);
    % Need to put the extension on the file
    bundleOutFile = [bundleOutFile '.pdb'];
    mtrExportFibers(fg,bundleOutFile);
end

return;

% Color wheel
% vC = {'b','g','r','c','m','y','k'}; 



% 
%     % Calculate normalized true error volume error and store mean
%     teNE = teE.*teW/sum(teW);
%     pE1W(pp) = mean(teNE(teE<100 & teE>0));
%     % Store unnormalized volume error as well
%     pE1(pp) = mean(teE(teE<100 & teE>0));
%     
%     % Plotting and Reporting Error
%     percentE = sum(abs(E),2)/sum(volG)*100;
%     %figure(100);
%     %plot(vR,percentE,vC{pp}); hold on;
%     figure(100);
%     teNE = teE.*teW/sum(teW);
%     plot(teNE,vC{pp}); hold on;
%     pE1W(pp) = mean(teNE(teE<100 & teE>0));
%     figure(101);
%     plot(teE,vC{pp}); hold on;
%     pE1(pp) = mean(teE(teE<100 & teE>0));
%     [minE, minI] = min(percentE);
%     disp(['Minimum within bundle error of ' num2str(minE) '% found with radius ' num2str(vR(minI))]);
%     percentENonBundle = volPNonBundle * vR(minI)^2 / sum(volG) * 100;
%     
%     %disp([projName ' non-bundle error is ' num2str(percentENonBundle) '%']);
%     pE2(pp) = 100*length(fibersNonSel)/(length(fibersNonSel)+length(fibersSel));
%     %disp([projName ' non-bundle error is ' num2str(100*length(fibersNonSel)/(length(fibersNonSel)+length(fibersSel))) '%.']);
%     
