
% Note: This script is to be run on teal.stanford.edu (due to memory and
% processing demand)!

fgID = 'SupPar';

mmBeyond = 50;

outDir = '/biac2/wandell2/data/DTI_Blind';

% adult group
adultDir = '/biac2/wandell2/data/reading_longitude/dti_adults/*0*';

% skip these subjects in the normally sighted group
skipSubjectList = { 'ams051015','bw040922','dla050311','gd040901',...
    'jl040806','kt040517','rk050524','sc060523','sd050527','sr040513',...
    'tl051015' };

[adultFile,adultSubCode] = findSubjects(adultDir, '*_dt6_noMask', skipSubjectList);

numAdult = length(adultFile);

% children group
childDir = '/biac2/wandell2/data/reading_longitude/dti/*0*';

[childFile,childSubCode] = findSubjects(childDir, '*_dt6_noMask', skipSubjectList);

numChild = length(childFile);


dt6File = [ adultFile , childFile ];
sc      = [ adultSubCode , childSubCode ];
gpID    = [ ones(1,numAdult) , ones(1,numChild)*2 ];

%%
N           = length(dt6File);
maxFiberLen = 250;

% set up parameters for different segments
segNames = {'Occ','Temp','PostPar','SupPar','SupFront','AntFront','Orb'};%,'LatFront'};
nSegs    = length(segNames);
% NaN means no clip plane, 0 means clip at the SI/LR plane passing
% through the CC midpoint, -1 clips at the SI/LR plane passing
% through the posterior edge of the CC, and +1 clips at the
% anterior edge of the CC.
% We clip fibers from the anterior frontal FGs that go too
% far posterior. (eg. some tapetum fibers that make a wrong
% turn pass through the anterior frontal ROI.), and similarly
% for posterior FGs that extend too far anterior.
clipPlane = [0 NaN 0 0.166 NaN 0 0];
colors    = [20 200 20; 200 20 200; 200 200 20; 20 90 200; 200 20 20; 235 165 55; 55 165 235; 20 20 100];

clear segs;
% segs = zeros(nSegs+1,1);
for ii=1:nSegs
    segs(ii).name      = segNames{ii};
    segs(ii).roi       = ['Mori_%s' segNames{ii}];
    segs(ii).color     = colors(ii,:);
    segs(ii).clipPlane = clipPlane(ii);
end
segs(end+1).name = 'Scraps';
segs(end).color  = [100 100 100];

% % % % % % % % % % % % % % % % %
% generate callosal fiber group %
% % % % % % % % % % % % % % % % %

cSeg = find(strcmp(segNames,fgID));

% Find the fibers by intersecting with pre-defined ROIs
clear fg fileName;
nSubs   = 0;
allSegs = 1:nSegs;
for ii=1:N
    clear newFg;
    fname = dt6File{ii};
    disp(['Processing ' fname '...']);

    fiberPath = fullfile(fileparts(fname), 'fibers');
    roiPath   = fullfile(fileparts(fname), 'ROIs');

    % check if roi directory exists AND roi definition for CC exists
    if ~exist(roiPath,'dir') || ~exist(fullfile(roiPath, 'CC_FA.mat'),'file')
        disp('no CC_FA roi - skipping...');
        continue;
    end
    cc = dtiReadRoi(fullfile(roiPath, 'CC_FA'));

    % skip if number of Mori ROIs is less than expected (at least 10)
    if length(dir(fullfile(roiPath,'Mori_*'))) < 10
        disp('no Mori ROIs found - skipping...');
    else
        try
            % Load all the ROIs
            % roiL = zeros(nSegs,1);
            % roiR = zeros(nSegs,1);
            for jj=1:nSegs
                roiL(jj) = dtiReadRoi(fullfile(roiPath, sprintf(segs(jj).roi,'L')));
                roiR(jj) = dtiReadRoi(fullfile(roiPath, sprintf(segs(jj).roi,'R')));
            end
        catch
            disp('some Mori ROIs missing - skipping...');
            continue;
        end

        % load and clean left and right callosal fibers
        lfgName = fullfile(fiberPath,'LFG+CC_FA.mat');
        rfgName = fullfile(fiberPath,'RFG+CC_FA.mat');
        fgL     = dtiReadFibers(fullfile(fiberPath,'LFG+CC_FA.mat'));
        fgL     = dtiCleanFibers(fgL,[],maxFiberLen);
        fgR     = dtiReadFibers(fullfile(fiberPath,'RFG+CC_FA.mat'));
        fgR     = dtiCleanFibers(fgR,[],maxFiberLen);


        tmpFgL = dtiIntersectFibersWithRoi(0, {'and'}, 1, roiL(cSeg), fgL);
        tmpFgR = dtiIntersectFibersWithRoi(0, {'and'}, 1, roiR(cSeg), fgR);
        % Remove fibers that intersect with other ROIs with exception for temp
        % fibers do not exclude those that follow ILF into orb and anterior
        % frontal ROIs
        if cSeg==2
            tmpFgL = dtiIntersectFibersWithRoi(0, {'not'}, 1, roiL([1:cSeg-1,cSeg+1:5]), tmpFgL);
            tmpFgR = dtiIntersectFibersWithRoi(0, {'not'}, 1, roiR([1:cSeg-1,cSeg+1:5]), tmpFgR);
        else
            tmpFgL = dtiIntersectFibersWithRoi(0, {'not'}, 1, roiL([1:cSeg-1,cSeg+1:nSegs]), tmpFgL);
            tmpFgR = dtiIntersectFibersWithRoi(0, {'not'}, 1, roiR([1:cSeg-1,cSeg+1:nSegs]), tmpFgR);
        end

        if ~isnan(segs(cSeg).clipPlane)
            ccLength = max(cc.coords(:,2))-min(cc.coords(:,2));
            ccMid    = min(cc.coords(:,2))+ccLength/2;
            apClip   = segs(jj).clipPlane*0.5*ccLength+ccMid;
            tmpFgL   = dtiCleanFibers(tmpFgL, [NaN apClip NaN]);
            tmpFgR   = dtiCleanFibers(tmpFgR, [NaN apClip NaN]);
        end

        newFg = dtiMergeFiberGroups(tmpFgL,tmpFgR);
        newFg.name = segs(cSeg).name;
        newFg.colorRgb = segs(cSeg).color;

        nSubs     = nSubs+1;
        fg(nSubs) = newFg;
        subCode(nSubs)  = sc(ii);
        fileName(nSubs) = dt6File(ii);
    end
end
clear cc tmpFgL tmpFgR roiL roiR fgL fgR newFg;

%%
% % % % % % % % % % % % % % % % % % % %
% align fiber coordinates to mid-sag  %
% % % % % % % % % % % % % % % % % % % %

% number of 1-mm steps per fiber
nSamplesPerFiber = mmBeyond*2+1;

ccCoords = cell(nSubs,1);
% fiberCC  = zeros(size(fg));
for ii=1:nSubs
    fname = fileName{ii};
    disp(sprintf('Extracting points for %d of %d: %s...', ii, nSubs, subCode{ii}));

    roiPath   = fullfile(fileparts(fname), 'ROIs');
    cc        = dtiReadRoi(fullfile(roiPath, 'CC_FA'));

    % find mid-sag fiber crossings
    ccCoords{ii} = cc.coords(cc.coords(:,1)==min(abs(cc.coords(:,1))),:)';

    nFibers = length(fg(ii).fibers);
    
    fiberCC(ii).fiberCoord = zeros(3,nFibers,nSamplesPerFiber)*NaN;
    
    for jj=1:nFibers
        % For each fiber point, find the nearest CC ROI point
        [nearCoords, distSq] = nearpoints(fg(ii).fibers{jj}, ccCoords{ii});
        % For all fiber points, select the one that is closest to a
        % midSag point. We'll store this one as the point where this
        % fiber passes through the mid sag plane.
        nearest              = find(distSq==min(distSq));
        nearest              = nearest(1);
        fiberCC(ii).dist(jj) = sqrt(distSq(nearest));
        fiberCoords          = nearest-mmBeyond:nearest+mmBeyond;
        
        fiberCoords(fiberCoords<1)                         = NaN;
        fiberCoords(fiberCoords>size(fg(ii).fibers{jj},2)) = NaN;
        
        fiberCC(ii).fiberCoord(:,jj,~isnan(fiberCoords)) = ...
            fg(ii).fibers{jj}(:,fiberCoords(~isnan(fiberCoords)));
        
        % flip the coords so that all start from left ...
        if fiberCC(ii).fiberCoord(1,jj,mmBeyond) > fiberCC(ii).fiberCoord(1,jj,mmBeyond+2)
            fiberCC(ii).fiberCoord(:,jj,:) = reshape(fliplr(squeeze(fiberCC(ii).fiberCoord(:,jj,:))),3,1,mmBeyond*2+1);
        end
    end

    ccCoords{ii} = ccCoords{ii}(2:3,:);
end
clear cc fg;

%%
% % % % % % % % % % % % % % % % % % % % % % %
% create dt6 matrices for the fiber groups  %
% % % % % % % % % % % % % % % % % % % % % % %

fiberDt6Tri = cell(size(fiberCC));
fiberDt6NN  = cell(size(fiberCC));
for ii=1:nSubs
    disp(sprintf('Loading tensors for %d of %d: %s (SLOW!)...', ii, nSubs, subCode{ii}));
    dt      = load(fileName{ii}, 'dt6','xformToAcPc');
    nFibers = size(fiberCC(ii).fiberCoord,2);
    coords  = reshape(fiberCC(ii).fiberCoord,3,nFibers*nSamplesPerFiber);
    coords  = mrAnatXformCoords(inv(dt.xformToAcPc), coords);
    
    % Trilinear interpolation
    tdt6            = dtiGetValFromTensors(dt.dt6, coords, [], 'dt6','trilin');
    fiberDt6Tri{ii} = reshape(tdt6, nFibers, nSamplesPerFiber, 6);
    
    % Do it again using nearest-neighbor interpolation
    tdt6           = dtiGetValFromTensors(dt.dt6, coords, [], 'dt6','nearest');
    fiberDt6NN{ii} = reshape(tdt6, nFibers, nSamplesPerFiber, 6);
end

% % % % % % % % % % %
% save the outputs  %
% % % % % % % % % % %

fiberDt6 = fiberDt6Tri;
save(fullfile(outDir,sprintf('%s_devInterpTL',lower(fgID))),'gpID','subCode','fileName','ccCoords',...
    'fiberCC','segs','fiberDt6');

fiberDt6 = fiberDt6NN;
save(fullfile(outDir,sprintf('%s_devInterpNN',lower(fgID))),'gpID','subCode','fileName','ccCoords',...
    'fiberCC','segs','fiberDt6');


