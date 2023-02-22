function [fg, fg_unclassified]=dtiFindMoriTracts(dt6File, outFile, fgFile, Atlas, showFig, saveQuench, saveMrDiffusion, useJhuFa, useInterhemisphericSplit, useRoiBasedApproach)
%Categorizes fibers based on Mori white matter atlas.
%
%  dtiFindMoriTracts(dt6File, [outFile=fullfile(fileparts(dt6File), 'fibers', 'MoriGroups.mat')], fgFile,...
%      [Atlas='MNI_JHU_tracts_prob.nii.gz'], [showFig=false],[saveQuench=false],...
%      [saveMrDiffusion=false], [useJhuFa=false],...
%      [useInterhemisphericSplit=true], [useRoiBasedApproach=true]);
%
% By default whole brain tractography is performed and then
% Mori-classified. Otherwise, provide a file name fgFile for a fiber group
% if willing to Mori-classify an existing fiber group.
%
% Input parameters: 
% fgFile                   - A file with previously tracked elsewhere fibers 
%                          to be categorized.
% Atlas                    - probabilistic atlas defining probabilities for
%                          each voxel to be passed by a fiber within each of
%                          atlas fiber groups. We usually use Mori atlas
%                          supplied with fsl: MNI_JHU_tracts_prob.nii.gz.
%                          This atlas is not symmetric. For a "symmetrified"
%                          atlas use 'MNI_JHU_tracts_prob_Symmetric.nii.gz'
%                          but we strongly recommend using the original
%                          atlas. 
% useInterhemisphericSplit - cut fibers crossing between hemispheres with a
%                          midsaggital plane below z=-10. This is to get
%                          rid of 
% useRoiBasedApproach      - use the approach describing in Zhang (2008)
%                           Neuroimage 42. For each of the 20 Mori Groups 2
%                           critical ROIs are computed by spatially
%                           transforming ROIs provided in
%                           templates/MNI_JHU_tracts_ROIs. A fiber becomes
%                           a candidate to being labeled as a part of a
%                           given Mori group if this fiber "passes through"
%                           both critical ROIs for that Mori group. Our
%                           modification of Zhang (2008) approach: In case
%                           a single fiber is a candidate for >1 Mori
%                           group, respective cumulative probabilities are
%                           computed with probabilistic Mori atlas, then
%                           compared. useRoiBasedApproach can take the
%                           following values: (1) 'false' (to not use the
%                           approach); (2) 'true'(use the approach; the
%                           minimal distance from a fiber to ROI to count
%                           as "a fiber  is crossing the ROI" minDist=2mm);
%                           (3) a scalar value for minDist in mm; (4) a
%                           vector with the first value being minDist and
%                           the second value being a flag 1/0 for whether
%                           ROIs should be recomputed (and overwritten) for
%                           this subject (1, by default). This is useful
%                           because sometimes if you  are rerunning
%                           dtiFindMoriTracts with different parameters,
%                           you do not need to recompute ROIs. E.g., to
%                           avoid recomputing  ROIs and use minDist of 4mm
%                           one would pass [useRoiBasedApproach=[4 0]];
%
% Output parameters: 
% fg              - fibers structure containing all fibers assigned to 
%                   one of Mori Groups. Respective group labeles are stored 
%                   in fg.subgroups field.
% fg_unclassified - fiber structure containing the rest of the (not Mori) fibers. 
%
% Example: 
%    dt6File = '/biac3/wandell4/data/reading_longitude/dti_y1234/at040918/dti06trilinrt/dt6.mat';
%    fg = dtiFindMoriTracts(dt6File); 
%
% See also: dtiSplitInterhemisphericFibers.m  
%
% Usage Notes:
%    Text explaining the usage of this code for publication can be found at
%    the end of this code along with references.
%
% (c) Stanford University, Vistalab
    
% HISTORY:
% 2008.10.08 RFD wrote it. 2009.01.08 EIR added an option of Mori-categorizing 
%            a provided FG (do not supply a fgFile parameter, or supply []
%            if want whole brain tractography performed)
% 2009.01.09 RFD removed the feature that discarded fibers that scored too
%            high on more than one atlas group. This was causing too many
%            good fibers to be removed, especially for groups 19 & 20
%            (arcuate).
% 2009.01.30 EIR modified to write out Mori labels as fg.subgroup
% 2009.02.01 EIR added an option to use symmetrified Mori atlas 
% 2009.05.31 EIR modified to output fghandle in addition to fg
% 2009.07.21 EIR modified to output unclassified fibers
% 2009.08.28 EIR added interhemispheric fiber split below ACPC and removed
%                fghandle output (because the parent FG is modified to add
%                split fibers.
% 2009.09.27 ER  added useRoiBasedApproach option which implements Zhang 
%                (2008) Neuroimage 42 method.
% 2009.10.2 ER:  no longer need to fit Quench state file labels to 8 grp 
%                limit.


%% Check INPUTS

if ~exist('showFig', 'var')|| isempty(showFig)
    showFig= false;
end
if ~exist('saveQuench', 'var')|| isempty(saveQuench)
    saveQuench = false;
end
if ~exist('saveMrDiffusion', 'var')|| isempty(saveMrDiffusion)
    saveMrDiffusion= false;
end
if ~exist('useJhuFa', 'var')|| isempty(useJhuFa)
    useJhuFa = false; %JhuFa should never be used
end
if ~exist('useInterhemisphericSplit', 'var')|| isempty(useInterhemisphericSplit)
    useInterhemisphericSplit=true;
end
if ~exist('useRoiBasedApproach', 'var')|| isempty(useRoiBasedApproach)
    useRoiBasedApproach=true;
end

if useRoiBasedApproach==false
    recomputeROIs = false;
elseif length(useRoiBasedApproach)<2
    recomputeROIs=1;
else
    recomputeROIs=useRoiBasedApproach(2);
end

if recomputeROIs
    display('dtiFindMoriTracts: You chose to recompute ROIs');
end

% E.g., to avoid recomputing  ROIs and use minDist of 4mm one would pass [useRoiBasedApproach=[4 0]];
if isnumeric(useRoiBasedApproach)
    minDist = useRoiBasedApproach(1);
    useRoiBasedApproach = 'true';
else
    minDist=2; %.89;
end
display(['Fibers that get as close to the ROIs as ' num2str(minDist) 'mm will become candidates for the Mori Groups']);

if(~exist('Atlas','var') || isempty(Atlas))
    % Default scenario: use original Mori Atlas
    Atlas='MNI_JHU_tracts_prob.nii.gz';
end

if(~exist('fgFile','var') || isempty(fgFile))
    % Default scenario: perform whole brain tractogrpahy
    wholeBrainFlag=1;
else
    wholeBrainFlag=0;
end

if(~exist('outFile','var') || isempty(outFile))
    bd = fileparts(dt6File);
    if(isempty(bd)), bd = pwd; end
    outFile = fullfile(bd,'fibers', 'MoriGroups.mat');
end


%%

% Load a dt6 file
dt = dtiLoadDt6(dt6File);

tdir = fullfile(fileparts(which('mrDiffusion.m')), 'templates');
spm_defaults; global defaults; params = defaults.normalise.estimate;
if(useJhuFa)
    template = fullfile(tdir,'MNI_JHU_FA.nii.gz');
    alignIm = dtiComputeFA(dt.dt6);
    params.cutoff = 19;
    params.reg = 0.09;
else
    % Spatially normalize it with the MNI (ICBM) template
    template = fullfile(tdir,'MNI_JHU_T2.nii.gz');
    alignIm = mrAnatHistogramClip(double(dt.b0),0.3,0.99);
end

[sn, Vtemplate, invDef] = mrAnatComputeSpmSpatialNorm(alignIm, dt.xformToAcpc, template, params);

% check the normalization
mm = diag(chol(Vtemplate.mat(1:3,1:3)'*Vtemplate.mat(1:3,1:3)))';
bb = mrAnatXformCoords(Vtemplate.mat,[1 1 1; Vtemplate.dim]);
alignIm_sn = mrAnatResliceSpm(alignIm, sn, bb, [2 2 2], [1 1 1 0 0 0], 0);
tIm = mrAnatResliceSpm(double(Vtemplate.dat), inv(Vtemplate.mat), bb, [2 2 2], [1 1 1 0 0 0], 0);
im(:,:,:,1) = uint8(tIm);
im(:,:,:,2) = uint8(round(clip(alignIm_sn)*255));
im(:,:,:,3) = im(:,:,:,2);

if(showFig)

    showMontage(im);
else
    if(~exist(fileparts(outFile),'dir')), mkdir(fileparts(outFile)); end
    imwrite(makeMontage(im),[outFile(1:end-4) '_snCheck.png']);
end

% Load the Mori atlas maps and the corresponding label files
% ldir = fileparts(which('dtiGetBrainlabel.m'));
moriTracts = niftiRead(fullfile(tdir, Atlas));
% 15 is a subregion of 19 and 16 a subregion of 20. To better separate them,
% we subtract 19 from 15 and 20 from 16.
moriTracts.data(:,:,:,15) = moriTracts.data(:,:,:,15)-moriTracts.data(:,:,:,19);
moriTracts.data(:,:,:,16) = moriTracts.data(:,:,:,16)-moriTracts.data(:,:,:,20);

labels = readTab(fullfile(tdir,'MNI_JHU_tracts_prob.txt'),',',false);
labels = labels(1:20,2);
% If you wanted to inverse-normalize the maps to this subject's brain:
% invDef.outMat = moriTracts.qto_ijk;
% bb = mrAnatXformCoords(dt.xformToAcpc,[1 1 1; size(dt.b0)]);
% tprob = mrAnatResliceSpm(tprob, invDef, bb, dt.mmPerVoxel, [1 1 1 0 0 0]);

if wholeBrainFlag
    % Track all white matter fibers in the native subject space. We do this by
    % seeding all voxels with high FA (>0.3).
    faThresh = 0.30;
    opts.stepSizeMm = 1;
    opts.faThresh = .2; %0.15
    opts.lengthThreshMm = [50 250];
    opts.angleThresh = 50;
    opts.wPuncture = 0.2;
    opts.whichAlgorithm = 1;
    opts.whichInterp = 1;
    opts.seedVoxelOffsets = [0.25 0.75];
    opts.offsetJitter = 0.1;
    fa = dtiComputeFA(dt.dt6);
    fa(fa>1) = 1; fa(fa<0) = 0;
    roiAll = dtiNewRoi('all');
    mask = dtiCleanImageMask(fa>=faThresh);
    [x,y,z] = ind2sub(size(mask), find(mask));
    clear mask fa;
    roiAll.coords = mrAnatXformCoords(dt.xformToAcpc, [x,y,z]);
    clear x y z;
    fg = dtiFiberTrack(dt.dt6, roiAll.coords, dt.mmPerVoxel, dt.xformToAcpc, 'wholeBrain', opts);
    clear roiAll
    % wholeBrainFGFile=fullfile(fileparts(dt6File), 'fibers', 'all.mat');
    % dtiWriteFiberGroup(fg, wholeBrainFGFile);
    % fghandle.parent=wholeBrainFGFile;
else
    % get fg from a file
    fg = fgRead(fgFile);
    %fg = dtiLoadFiberGroup(fgFile);
    %fghandle.parent=fgFile;
end


%Cut the fibers below acpc, to disentangle CST& ATL crossing at the pons
%level.
if useInterhemisphericSplit
    fgname=fg.name;
    [fg]=dtiSplitInterhemisphericFibers(fg, dt, -10);
    fg.name=fgname; %To avoid "bilaterally split" extra long comment in the fg name.
end

%Because we know that we are looking for major Mori tracts, we should
%keep only 5 points or longer fibers (otherwise spline in contrack
%crashes).  This is important for Blue matter procedures planned, but wont hurt otherwise (for Mori detection) either.
if sum(cellfun(@length, fg.fibers)<5)~=0
    if isfield(fg, 'subgroup')&&~isempty(fg.subgroup)
        fg.subgroup(cellfun(@length, fg.fibers)<5)=[];
    end
    if isfield(fg, 'seeds')&&~isempty(fg.seeds)
        fg.seeds(cellfun(@length, fg.fibers)<5, :)=[];
    end
    fg.fibers(cellfun(@length, fg.fibers)<5)=[];
    fprintf('dtiFindMoriTracts: Removing %s fibers with 5 points or less \n', num2str(sum(cellfun(@length, fg.fibers)<5)));
end


% Warp the fibers in 'fg' to the MNI standard space:
fg_sn = dtiXformFiberCoords(fg, invDef);

% moriTracts.data is a an XxYxZx20 array contianing the 20 Mori probability
% atlases (range is 0-100 where 100 represents p(1)).
sz = size(moriTracts.data);

% fg_sn fiber coords are in MNI space- now convert them to atlas space by
% applying the affine xform from the atlas NIFTI header. SInce the atlas is
% already in MNI space, this transform will just account for any
% translation and scale differences between the atlas maps and the MNI
% template used to compute our sn.
fgCoords = mrAnatXformCoords(moriTracts.qto_ijk, horzcat(fg_sn.fibers{:}));
clear fg_sn;   % what we need from fg_sn is now stored in fgCoords
fgLen = cellfun('size',fg.fibers,2);

% Now loop over the 20 atlases and get the atlas probability score for each
% fiber point. We collapse the scores across all pints in a fiber by taking
% the mean. Below, we will use these 20 mean scores to categorize the fibers.
% TO DO: consider doing something more sophisticated than taking the mean.
fp = zeros(sz(4),numel(fg.fibers));
for(ii=1:sz(4))
    % Get the Mori atlas score for each point in the fibers using
    % trilinear interpolation.
    p = myCinterp3(double(moriTracts.data(:,:,:,ii))/100, sz([1,2]), sz(3), fgCoords(:,[2,1,3]));
    % The previous line interpolated one giant array with all fiber points
    % concatenated. The next loop will separate the coordinates back into
    % fibers and take the mean score for the points within each fiber.
    fiberCoord = 1;
    for(jj=1:numel(fg.fibers))
        fp(ii,jj) = nanmean(p([fiberCoord:fiberCoord+fgLen(jj)-1]));
        fiberCoord = fiberCoord+fgLen(jj);
    end
end
clear p fgCoords;

if useRoiBasedApproach
    %Warp Mori ROIs to individual space; collect candidates for each fiber
    %group based on protocol of 2 or > ROIs a fiber should travel thru.
    %The following ROIs are saved within
    %trunk/mrDiffusion/templates/MNI_JHU_tracts_ROIs folder and are created using MNI template as
    %described in Wakana et al.(2007) Neuroimage 36 with a single modification:
    %For SLFt Roi2, they recommend drawing the ROI at the AC level, whereas we
    %use a lisce just inferior of CC splenium. The reason for this modification
    %is that Wakana et al. ACPC aligned images appear different from MNI images
    %(the latter we use for defininng ROIs). If defining SLFt-Roi2 on a slice
    %actually at the AC level (althought highly consistently across human
    %raters), many SLFt fibers were not correctly labeled as they extend
    %laterally into temporal lobe just above the aforementioned ROI plane.

    moriRois={'ATR_roi1_L.nii.gz',  'ATR_roi2_L.nii.gz'; 'ATR_roi1_R.nii.gz', 'ATR_roi2_R.nii.gz'; ...
        'CST_roi1_L.nii.gz', 'CST_roi2_L.nii.gz'; 'CST_roi1_R.nii.gz',  'CST_roi2_R.nii.gz'; ...
        'CGC_roi1_L.nii.gz', 'CGC_roi2_L.nii.gz'; 'CGC_roi1_R.nii.gz', 'CGC_roi2_R.nii.gz'; ...
        'HCC_roi1_L.nii.gz', 'HCC_roi2_L.nii.gz'; 'HCC_roi1_R.nii.gz', 'HCC_roi2_R.nii.gz';...
        'FP_R.nii.gz', 'FP_L.nii.gz'; ...
        'FA_L.nii.gz', 'FA_R.nii.gz'; ...
        'IFO_roi1_L.nii.gz', 'IFO_roi2_L.nii.gz'; 'IFO_roi2_R.nii.gz', 'IFO_roi1_R.nii.gz'; ...
        'ILF_roi1_L.nii.gz', 'ILF_roi2_L.nii.gz'; 'ILF_roi1_R.nii.gz', 'ILF_roi2_R.nii.gz'; ...
        'SLF_roi1_L.nii.gz', 'SLF_roi2_L.nii.gz'; 'SLF_roi1_R.nii.gz', 'SLF_roi2_R.nii.gz'; ...
        'UNC_roi1_L.nii.gz', 'UNC_roi2_L.nii.gz'; 'UNC_roi1_R.nii.gz', 'UNC_roi2_R.nii.gz'; ...
        'SLF_roi1_L.nii.gz', 'SLFt_roi2_L.nii.gz'; 'SLF_roi1_R.nii.gz', 'SLFt_roi2_R.nii.gz'};

    midSaggitalRoi = dtiRoiMakePlane([0, dt.bb(1, 2), dt.bb(1, 3); 0 , dt.bb(2, 2) , dt.bb(2, 3)], 'midsaggital', 'g');
    
    keep1 = zeros(length(fg.fibers), size(moriRois, 1)); keep2=zeros(length(fg.fibers), size(moriRois, 1));
    
    [fgOut,contentiousFibers,InterHemisphericFibers] = dtiIntersectFibersWithRoi([], 'not', [], midSaggitalRoi, fg); 
    %NOTICE: ~keep3 (not "keep3") will mark fibers that DO NOT cross midSaggitalRoi.
    keep3 = repmat(InterHemisphericFibers, [1 size(moriRois, 1)]);

    fgCopy=fg; fgCopy.subgroup=[];
    for roiID=1:size(moriRois, 1)
        
        ROI_img_file=fullfile(tdir, 'MNI_JHU_tracts_ROIs',  [moriRois{roiID, 1}]);
        if recomputeROIs
            [RoiFileName, invDef, roi]=dtiCreateRoiFromMniNifti(dt6File, ROI_img_file, invDef, true);
        else
            RoiFileName=fullfile(fileparts(dt6File), 'ROIs',  [prefix(prefix(ROI_img_file, 'short'), 'short') '.mat']);
            load(RoiFileName);

        end
        [fgOut,contentiousFibers, keep1(:, roiID)] = dtiIntersectFibersWithRoi([], 'and', minDist, roi, fg);
        keepID1=find(keep1(:, roiID));

        ROI_img_file=fullfile(tdir, 'MNI_JHU_tracts_ROIs',  [moriRois{roiID, 2}]);
        if recomputeROIs
            [RoiFileName, invDef, roi]=dtiCreateRoiFromMniNifti(dt6File, ROI_img_file, invDef, true);
        else
            RoiFileName=fullfile(fileparts(dt6File), 'ROIs',  [prefix(prefix(ROI_img_file, 'short'), 'short') '.mat']);
            load(RoiFileName);
        end

        %To speed up the function, we intersect with the second ROI not all the
        %fibers, but only those that passed first ROI.
        fgCopy.fibers=fg.fibers(keepID1(keepID1>0));
        [a,b, keep2given1] = dtiIntersectFibersWithRoi([], 'and', minDist, roi, fgCopy);
        keep2(keepID1(keep2given1), roiID)=true;

    end
    clear fgOut contentiousFibers keepID
    %Note: forceps major and minor should NOT have interhemipsheric fibers
    %excluded
    keep3(:, 9:10)=keep3(:, 9:10).*0;
    fp(~(keep1'&keep2'&~keep3'))=0;
    %Also note: Tracts that cross through slf_t rois should be automatically
    %classified as slf_t, without considering their probs.
    fp(19, (keep1(:, 19)'&keep2(:, 19)'&~keep3(:, 19)'))=max(fp(:));
    fp(20, (keep1(:, 20)'&keep2(:, 20)'&~keep3(:, 20)'))=max(fp(:));

end

% We have a set of atlas scores for each each fiber. To categorize the
% fibers, we will find the atlas with the highest score (using 'sort').
[atlasScore,atlasInd] = sort(fp,1,'descend');
% Eliminate fibers that don't match any of the atlases very well:
unclassified=atlasScore(1,:)==0; %ER 09.15.09 dropped this threshold to zero
goodEnough = atlasScore(1,:)~=0; % RFD 09.01.09: removed "& atlasScore(1,:)>sum(atlasScore(2:end,:),1);"

for ii=1:sz(4)
    curAtlasFibers{ii} = find(atlasInd(1,:)==ii & goodEnough);
    %    if(showFig)
    %        fc = round(mrAnatXformCoords(inv(dt.xformToAcpc), horzcat(fg.fibers{curAtlasFibers{ii}})));
    %        im = dt.b0;
    %        inds = sub2ind(size(dt.b0),fc(:,1),fc(:,2),fc(:,3));
    %        im(inds) = 1;
    %        makeMontage3(im,dt.b0,dt.b0);
    %        set(gcf,'name',labels{ii},'NumberTitle','off');
    %    end
end

% We now have a cell array (curAtlasFibers) that contains 20 arrays, each
% listing the fiber indices for the corresponding atlas group. E.g.,
% curAtlasFibers{3} is a list of indices into fg.fibers that specify the
% fibers belonging to group 3.

%Create a FG for unclassified fibers
fg_unclassified=fg; 
fg_unclassified.name=[fg.name ' not Mori Groups'];
fg_unclassified.fibers = fg.fibers(unclassified); %prepare fg output
if ~isempty(fg.seeds)
    fg_unclassified.seeds = fg.seeds(unclassified);
end
fg_unclassified.subgroup=zeros(size(fg.fibers(unclassified)))'+(1+sz(4));
fg_unclassified.subgroupNames(1)=struct('subgroupIndex', 1+sz(4), 'subgroupName', 'NotMori');

% Modify fg.fibers to discard the fibers that didn't make it into any of
% the atlas groups:
fg.name=[fg.name ' Mori Groups'];
%fghandle.name=fg.name;
fg.fibers = fg.fibers([curAtlasFibers{:}]); %prepare fg output
%fghandle.ids=horzcat(curAtlasFibers{:}); %prepare fghandle output

if ~isempty(fg.seeds)
    fg.seeds = fg.seeds([curAtlasFibers{:}],:);
end


% We changed the size of fg.fibers by discarding the uncategorized fibers,
% so we need to create a new array to categorize the fibers. This time we
% make an array with one entry corresponding to each fiber, with integer
% values indicating to which atlas group the corresponding fiber belongs.
fg.subgroup = zeros(1,numel(fg.fibers));
curInd = 1;
for(ii=1:numel(curAtlasFibers))
    fg.subgroup(curInd:curInd+numel(curAtlasFibers{ii})-1) = ii;
    %fghandle.subgroup(curInd:curInd+numel(curAtlasFibers{ii})-1) = ii;
    curInd = curInd+numel(curAtlasFibers{ii});
    %Save labels for the fiber subgroups within the file
    fg.subgroupNames(ii)=struct('subgroupIndex', ii, 'subgroupName', labels(ii));
    %fghandle.subgroupNames(ii)=struct('subgroupIndex', ii, 'subgroupName', labels(ii));
end

% Save in mrDiffusion format:
if (saveMrDiffusion)
    if(~exist(fileparts(outFile),'dir')), mkdir(fileparts(outFile)); end
    dtiWriteFiberGroup( fg, outFile);
end

if(saveQuench)
    if(~exist(fileparts(outFile),'dir')), mkdir(fileparts(outFile)); end
    % Also save a Quench pdb file/state file to show the fiber groups.
    % Should we use dtiWriteFibersPdb?
    dtiWriteFibersPdb(fg,dt.xformToAcpc, [outFile(1:end-4) '.pdb']);
    % merge some of the groups to fit into the Quench 8-group limit:
    fgInds = fg.subgroup;
    dtiQuenchSaveFibersState(fgInds, [outFile(1:end-4) '.qst']);
end

return;

%%

% To run this on a bunch of subjects:
bd = '/biac3/wandell4/data/reading_longitude/dti_y1234';
[dt6Files,subCodes,subDirs,subIn] = findSubjects(fullfile(bd,'*'), 'dti06rt');
subIn = unique(subIn);
doThese = [1:numel(dt6Files)]; % strmatch('pt0',subCodes)';
for(ii=doThese)
    fiberDir = fullfile(fileparts(dt6Files{ii}),'Mori');
    if(~exist(fiberDir,'dir')), mkdir(fiberDir); end
    outBase = fullfile(fiberDir,'MoriGroups');
    if(~exist([outBase '.mat'],'file'))
        fprintf('Processing %s...\n',dt6Files{ii});
        dtiFindMoriTracts(dt6Files{ii},outBase);
    end
end

subs = []; doThese = [];
for(ii=1:numel(subIn))
    cur = strmatch([subIn{ii} '0'],subCodes);
    if(numel(cur)==4)
        subs = [subs cur'];
    end
end
for(ii=subs)
    fiberDir = fullfile(fileparts(dt6Files{ii}),'Mori');
    if(exist(fiberDir,'dir')&&exist(fullfile(fiberDir,'MoriGroups.mat')))
        %disp([subCodes{ii} ' is finished.']);
    else
        disp([subCodes{ii} ' is MISSING.']);
        doThese = [doThese ii];
    end
end


% To analyze a bunch of subjects:
outDir = '/biac3/wandell4/data/reading_longitude/moriGroupAnalysis';
bd = '/biac3/wandell4/data/reading_longitude/dti_y1234';
[dt6Files,subCodes,subDirs,subLetters] = findSubjects(fullfile(bd,'*'), 'dti06rt');
nGroups = 20;
nSubs = numel(dt6Files);
sgVol = zeros(nSubs,nGroups);
for(ii=1:nSubs)
    fname = fullfile(fileparts(dt6Files{ii}),'Mori','MoriGroups.mat');
    fprintf('Processing %s (%d of %d)...\n',fname,ii,numel(dt6Files));
    fg = dtiReadFibers(fname);
    for(jj=1:nGroups)
        sgCoords = fg.fibers(fg.subgroup==jj);
        % crude volume measure:
        sgVol(ii,jj) = size(unique(round(horzcat(sgCoords{:}))','rows'),1);
    end
end

% Get the labels for the 20 groups:
labels = readTab(which('MNI_JHU_tracts_prob.txt'),',',false);
labels = labels(:,2);
save(fullfile(outDir,'moriGroupSum.mat'),'bd','labels','sgVol','dt6Files','subCodes','subLetters');


outDir = '/biac3/wandell4/data/reading_longitude/moriGroupAnalysis';
load(fullfile(outDir,'moriGroupSum.mat'));
nGroups = size(sgVol,2);
nSubs = size(sgVol,1);
mn = mean(sgVol)/1000;
sd = std(sgVol)/1000;
rng = [max(sgVol); min(sgVol)]/1000;
for(ii=1:nGroups)
    fprintf('%50s:\t %0.2fcc (%0.3f, %0.2f-%0.2f)\n',labels{ii},mn(ii),sd(ii),rng(1,ii),rng(2,ii));
end

[bd, colNames, sc, subYr] = dtiGetBehavioralData(subCodes);

yr = 4;
bdVars = {'Passage Comprehension.', 'Rapid Naming.', 'Word attack ss.', 'Phonological Awareness.', 'Calculation.','WISC Full-Scale IQ.','DTI Age.','Sex (1=male)'};
for(ii=1:numel(bdVars))
    for(jj=1:2:nGroups-1)
        if(bdVars{ii}(end)=='.'), bVar = sprintf('%s%d',bdVars{ii},yr);
        else bVar = bdVars{ii}; end
        s = subYr==yr;
        x = bd(s,strmatch(bVar,colNames,'exact'));
        if(~isempty(x))
            y = sgVol(s,jj+1)-sgVol(s,jj);  % sgVol(s,jj);
            gv = ~isnan(x)&~isnan(y);
            x = x(gv); y = y(gv);
            %figure(34); plot(x,y,'.');
            [p,r,df] = myStatTest(x,y,'r');
            fprintf('%25s vs. %50s:\t r=%+0.3f (p=%0.2g, df=%d)\n',bVar,labels{jj},r,p,df);
        end
    end
end



%% TEXT FOR PUBLICATION

% The fiber tracts from the whole brain tractography were automatically
% classified into twenty fiber structures as defined in the JHU
% white-matter tractography atlas (Wakana et al., 2007) using a modified
% form of the reference ROI approach ( [Wakana et al., 2007] , [Zhang et
% al., 2008] , [Hua et al., 2008] and [Zhang et al., 2010] ). Specifically,
% we manually defined reference ROIs (rROIs) describing two waypoints for
% each of the 20 major white matter tracts described in (Wakana et al.,
% 2007). These ROIs were drawn in MNI space on the ICBM-DTI-81 atlas by two
% experts. The rROIs were warped from MNI space into each individual's
% diffusion space and fibers were retained if they passed through any pair
% of rROIs. Note that some fibers passed through the rROIs for more than
% one major tract. Thus, we applied an additional inclusion criterion by
% warping each fiber to MNI space and measuring the approximate overlap
% between the fiber points and each of the major tracts of the
% probabilistic JHU tractography atlas (Wakana et al., 2007). The fiber was
% classified as representing the JHU tract with which it had the highest
% degree of overlap.
% 

%% REFERENCES:
% 
% Wakana, Setsu et al. 2007. “Reproducibility of quantitative tractography
% methods applied to cerebral white matter.” NeuroImage 36(3): 630-44.
% 
% Zhang, Weihong, Alessandro Olivi, Samuel J Hertig, Peter van Zijl, et
% al. 2008. “Automated fiber tracking of human brain white matter using
% diffusion tensor imaging.” NeuroImage 42(2): 771-7.
% 
% Hua, K, J Zhang, S Wakana, H Jiang, et al. 2008. “Tract probability maps
% in stereotaxic spaces: analyses of white matter anatomy and
% tract-specific quantification.” Neuroimage 39(1): 336-347.
% 
% Zhang et al., 2010 Y. Zhang, J. Zhang, K. Oishi, A. Faria, H. Jiang, X.
% Li, K. Akhter, P. Rosa-Neto, G. Pike, A. Evans, A. Toga, R. Woods, J.
% Mazziotta, M. Miller, P. van Zijl and S. Mori, Atlas-guided tract
% reconstruction for automated and comprehensive examination of the white
% matter anatomy, . Neuroimage, 52 4 (2010), pp. 1289–1301 (May).

