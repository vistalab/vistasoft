baseDir = '/biac2/wandell2/data/reading_longitude/dti_adults/*';
[f,sc] = findSubjects(baseDir, '*_dt6', {});
%[f,sc] = findSubjects('','_dt6',{'es041113','tk040817'});
N = length(f);
addpath('/home/bob/matlab/stats/');
% The longest fibers in a normal brain dont exceed 25cm
maxFiberLen = 250;

% Warp normalized ROIs to each subject's brain and intersect the FGs.
roiDir = '/biac2/wandell2/data/reading_longitude/dtiGroupAnalysis/sgOcc_SIRL55_ROIs/';
%d = dir(fullfile(roiDir,'*.mat'));
l(1) = load(fullfile(roiDir, 'LLO'));
l(2) = load(fullfile(roiDir, 'LV3AB7'));
l(3) = load(fullfile(roiDir, 'LV12d'));
l(4) = load(fullfile(roiDir, 'LV12v'));
l(5) = load(fullfile(roiDir, 'LV3hV4'));
r(1) = load(fullfile(roiDir, 'RLO'));
r(2) = load(fullfile(roiDir, 'RV3AB7'));
r(3) = load(fullfile(roiDir, 'RV12d'));
r(4) = load(fullfile(roiDir, 'RV12v'));
r(5) = load(fullfile(roiDir, 'RV3hV4'));
nRois = 1; %nRois = 5;
for(ii=1:nRois)
    l(ii).roi.coords = l(ii).roi.coords(~any(isnan(l(ii).roi.coords')),:);
    r(ii).roi.coords = r(ii).roi.coords(~any(isnan(r(ii).roi.coords')),:);
    %l(ii).roi = dtiRoiClean(l(ii).roi,3,{'fillHoles','removeSat','dilate'});
    %l(ii).roi.name = ['sg_' l(ii).roi.name];
    %r(ii).roi = dtiRoiClean(r(ii).roi,3,{'fillHoles','removeSat','dilate'});
    %r(ii).roi.name = ['sg_' r(ii).roi.name];
end

% Create fiber groups by normalizing the standard-space ROIs to each brain
% and doing an ROI-fiber intersect.
templateName = 'SIRL54ms_warp2_T1_brain.img';
tdir = '/biac2/wandell2/data/reading_longitude/templates/';
spm_defaults;
snParams = defaults.normalise.estimate;
snParams.smosrc = 4;
colors = [200 200 20; 20 200 20; 20 200 200; 200 20 200; 200 20 20];
template = fullfile(tdir, templateName);
for(ii=1:N)
    fname = f{ii};
    disp(['Processing ' fname '...']);

    fiberPath = fullfile(fileparts(fname), 'fibers');
    roiPath = fullfile(fileparts(fname), 'ROIs');
    cc = load(fullfile(roiPath, 'CC_FA')); cc = cc.roi;
    % We'll remove any fibers that penetrate a plane that is 25% the length
    % of the CC, starting from the posterior edge.
    apClip = (max(cc.coords(:,2))-min(cc.coords(:,2)))*.25+min(cc.coords(:,2));

    dt = load(fname);
    dt.xformToAcPc = dt.anat.xformToAcPc*dt.xformToAnat;
    if(~isfield(dt.t1NormParams,'name') | length(dt.t1NormParams)==1)
      disp(['   Computing spatial norm to ' template]);
      img = mrAnatHistogramClip(double(dt.anat.img), 0.4, 0.98);
      img(~dt.anat.brainMask) = 0;
      sn = mrAnatComputeSpmSpatialNorm(img, dt.anat.xformToAcPc, template, snParams);
      t1NormParams(1).name = 'MNI';
      t1NormParams(1).sn = dt.t1NormParams(1).sn;
      t1NormParams(2).name = 'SIRL54';
      t1NormParams(2).sn = sn;
      save(fname,'t1NormParams','-APPEND');
    else
      % *** FIX ME! We assume that the SIRL55 sn is 2nd.
      sn = dt.t1NormParams(2).sn;
    end
    try
      if(exist(fullfile(fiberPath,'LOccFG.mat'),'file')) fgName = 'LOccFG';
      elseif(exist(fullfile(fiberPath,'LOcc_newFG.mat'),'file')) fgName = 'LOcc_newFG';
      elseif(exist(fullfile(fiberPath,'LOcc_adjustedFG.mat'),'file')) fgName = 'LOcc_adjustedFG';
      elseif(exist(fullfile(fiberPath,'leftOccFG.mat'),'file')) fgName = 'leftOccFG';
      else error('no FG found.'); end
      fgL = load(fullfile(fiberPath,fgName));
      fgL.fg.name = 'LOcc';
      fgL.fg = dtiCleanFibers(fgL.fg,[],maxFiberLen);
      fgL.fg = dtiIntersectFibersWithRoi(0, {'and'}, 1, cc, fgL.fg, inv(dt.xformToAcPc));
      fgL.fg.colorRgb = [200 20 20];
      dtiWriteFiberGroup(fgL.fg, fullfile(fiberPath, fgL.fg.name));
      if(exist(fullfile(fiberPath,'ROccFG.mat'),'file')) fgName = 'ROccFG';
      elseif(exist(fullfile(fiberPath,'ROcc_newFG.mat'),'file')) fgName = 'ROcc_newFG';
      elseif(exist(fullfile(fiberPath,'ROcc_adjustedFG.mat'),'file')) fgName = 'ROcc_adjustedFG';
      elseif(exist(fullfile(fiberPath,'rightOccFG.mat'),'file')) fgName = 'rightOccFG';
      else error('no FG found.'); end
      fgR = load(fullfile(fiberPath,fgName));
      fgR.fg.name = 'ROcc';
      fgR.fg = dtiCleanFibers(fgR.fg,[],maxFiberLen);
      fgR.fg = dtiIntersectFibersWithRoi(0, {'and'}, 1, cc, fgR.fg, inv(dt.xformToAcPc));
      fgR.fg.colorRgb = [20 20 200];
      dtiWriteFiberGroup(fgR.fg, fullfile(fiberPath, fgR.fg.name));

      for(jj=1:nRois)
        roi = l(jj).roi;
        roi.coords = mrAnatXformCoords(sn, roi.coords);
        dtiWriteRoi(roi, fullfile(roiPath, roi.name), l(jj).versionNum, 'acpc');
        fg = dtiIntersectFibersWithRoi(0, {'and','endpoints'}, 3, roi, fgL.fg, inv(dt.xformToAcPc));
        fg = dtiCleanFibers(fg, [NaN apClip NaN]);
        fg.colorRgb = colors(jj,:);
        dtiWriteFiberGroup(fg, fullfile(fiberPath, fg.name), 1, 'acpc');
        roi = r(jj).roi;
        roi.coords = mrAnatXformCoords(sn, roi.coords);
        dtiWriteRoi(roi, fullfile(roiPath, roi.name), r(jj).versionNum, 'acpc');
        fg = dtiIntersectFibersWithRoi(0, {'and','endpoints'}, 3, roi, fgR.fg, inv(dt.xformToAcPc));
        fg = dtiCleanFibers(fg, [NaN apClip NaN]);
        fg.colorRgb = colors(jj,:);
        dtiWriteFiberGroup(fg, fullfile(fiberPath, fg.name), 1, 'acpc');
      end
    catch
      disp([sc{ii} ': No FG- skipping.']);
    end
end

error('Finished creating ROIs and FGs.');

% Create and save the 3-axis 'screen-save' images showing the fiber groups
% on select slices.
outDir = '/silver/scr1/dti/sgOcc';
upSamp = 2;
acpcPos = [0 -50 10];
for(ii=1:N)
    disp(['Processing ' num2str(ii) ': ' sc{ii} '...']);
    fiberPath = fullfile(fileparts(f{ii}), 'fibers');
    roiPath = fullfile(fileparts(f{ii}), 'ROIs');
    cc = load(fullfile(roiPath, 'CC_FA')); cc = cc.roi;

    load(fullfile(fiberPath, 'LOcc_adjusted+CC_FA+LV3AB7d')); fgs(1) = fg;
    load(fullfile(fiberPath, 'LOcc_adjusted+CC_FA+LV12d')); fgs(2) = fg;
    load(fullfile(fiberPath, 'LOcc_adjusted+CC_FA+LV12v')); fgs(3) = fg;
    load(fullfile(fiberPath, 'LOcc_adjusted+CC_FA+LV3hV4')); fgs(4) = fg;
    load(fullfile(fiberPath, 'ROcc_adjusted+CC_FA+RV3AB7d')); fgs(5) = fg;
    load(fullfile(fiberPath, 'ROcc_adjusted+CC_FA+RV12d')); fgs(6) = fg;
    load(fullfile(fiberPath, 'ROcc_adjusted+CC_FA+RV12v')); fgs(7) = fg;
    load(fullfile(fiberPath, 'ROcc_adjusted+CC_FA+RV3hV4')); fgs(8) = fg;

    % Generate the slice images
    dt = load(f{ii}, 'xformToAnat', 'anat');
    bg = dt.anat;
    bg.img = mrAnatHistogramClip(double(bg.img), 0.4, 0.98);
    bg.acpcToImgXform = inv(bg.xformToAcPc);

    [fgs(1:8).visible] = deal(1);
    fname = fullfile(outDir, [sc{ii} '_LRocc']);
    dtiSaveImageSlicesOverlays(0, fgs, [], 0, fname, upSamp, acpcPos, bg);
    [fgs(5:8).visible] = deal(0);
    fname = fullfile(outDir, [sc{ii} '_Locc']);
    dtiSaveImageSlicesOverlays(0, fgs, [], 0, fname, upSamp, acpcPos, bg);
    [fgs(1:4).visible] = deal(0); [fgs(5:8).visible] = deal(1);
    fname = fullfile(outDir, [sc{ii} '_Rocc']);
    dtiSaveImageSlicesOverlays(0, fgs, [], 0, fname, upSamp, acpcPos, bg);
    % Do a simple left/right overlap
    [fgs(1:8).visible] = deal(1);
    fname = fullfile(outDir, [sc{ii} '_LRoverlap']);
    [fgs(1:4).colorRgb] = deal([200 20 20]);
    [fgs(5:8).colorRgb] = deal([20 20 200]);
    dtiSaveImageSlicesOverlays(0, fgs, [], 0, fname, upSamp, acpcPos, bg);
end

nFgs = length(fgs);
% Compute overlap index
clear fiberCC;
for(ii=1:N)
    disp(['Processing ' num2str(ii) ': ' sc{ii} '...']);
    fiberPath = fullfile(fileparts(f{ii}), 'fibers');
    roiPath = fullfile(fileparts(f{ii}), 'ROIs');
    tmp = load(fullfile(roiPath, 'CC_FA')); cc(ii) = tmp.roi;

    load(fullfile(fiberPath, 'LOcc_adjusted+CC_FA+LV3AB7d')); fgs(1) = fg;
    load(fullfile(fiberPath, 'LOcc_adjusted+CC_FA+LV12d')); fgs(2) = fg;
    load(fullfile(fiberPath, 'LOcc_adjusted+CC_FA+LV12v')); fgs(3) = fg;
    load(fullfile(fiberPath, 'LOcc_adjusted+CC_FA+LV3hV4')); fgs(4) = fg;
    load(fullfile(fiberPath, 'ROcc_adjusted+CC_FA+RV3AB7d')); fgs(5) = fg;
    load(fullfile(fiberPath, 'ROcc_adjusted+CC_FA+RV12d')); fgs(6) = fg;
    load(fullfile(fiberPath, 'ROcc_adjusted+CC_FA+RV12v')); fgs(7) = fg;
    load(fullfile(fiberPath, 'ROcc_adjusted+CC_FA+RV3hV4')); fgs(8) = fg;

    % Compute overlap index
    midSagCoords = cc(ii).coords(cc(ii).coords(:,1)==min(abs(cc(ii).coords(:,1))),:)';
    for(kk=1:length(fgs))
        for(jj=1:length(fgs(kk).fibers))
            % for each fiber point, find the nearest midSag point.
            [nearCoords, distSq] = nearpoints(fgs(kk).fibers{jj}, midSagCoords);
            % for all fiber points, select the one that is closest to a
            % midSag point. We'll store this one as the point where this
            % fiber passes through the mid sag plane.
            nearest = find(distSq==min(distSq)); nearest = nearest(1);
            fiberCC(ii,kk).dist(jj) = sqrt(distSq(nearest));
            fiberCC(ii,kk).fiberCoord(jj,:) = fgs(kk).fibers{jj}(:,nearest);
            fiberCC(ii,kk).ccRoiCoord(jj,:) = midSagCoords(:,nearCoords(nearest));
        end
    end
end

% compute cc area
areaFgs = zeros(N,nFgs);
areaCC = zeros(N,1);
for(ii=1:N)
    midSagX = min(abs(cc(ii).coords(:,1)));
    midSagCcCoords = cc(ii).coords(cc(ii).coords(:,1)==midSagX, 2:3);
    areaCC(ii) = length(unique(midSagCcCoords, 'rows'));
    for(jj=1:nFgs)
        if(~isempty(fiberCC(ii,jj).ccRoiCoord))
            midSagFgCoords = fiberCC(ii,jj).ccRoiCoord(fiberCC(ii,jj).ccRoiCoord(:,1)==midSagX,2:3);
            areaFgs(ii,jj) = length(unique(midSagFgCoords,'rows'));
        end
    end
end

[behaveData, colNames] = dtiGetBehavioralData(f);
for(ii=1:nFgs)
    [p,s,df] = statTest(areaFgs(:,ii),behaveData(:,6),'r');
    fprintf('%s: %0.2f (%0.4f, %d)\n', fgs(ii).name, s, p, df);
end


fprintf('\n\n');
fgnames = {'all','dorsal','V12d','V12v','ventral'};
clear overlap overlapVox;
for(ii=1:N)
    left = [fiberCC(ii,1).ccRoiCoord; ...
            fiberCC(ii,2).ccRoiCoord; ...
            fiberCC(ii,3).ccRoiCoord; ...
            fiberCC(ii,4).ccRoiCoord];
    right =[fiberCC(ii,5).ccRoiCoord; ...
            fiberCC(ii,6).ccRoiCoord; ...
            fiberCC(ii,7).ccRoiCoord; ...
            fiberCC(ii,8).ccRoiCoord];
   left =  left(:,2:3);
   right = right(:,2:3);
    %figure; hist3(left, 'FaceColor','r'); 
    %hold on; hist3(right, 'FaceColor','b');
    c = intersect(left, right, 'rows');
    u = unique([right; left], 'rows');
    m = ismember([right; left], c, 'rows');
    overlap(1,ii) = sum(m)/length(m);
    overlapVox(1,ii) = length(c)/length(u);
    fprintf('%s: overlap=%0.0f%% (%d);  overlapVox=%0.0f%% (%d/%d); ', sc{ii}, ...
            overlap(1,ii)*100, length(m), overlapVox(1,ii)*100, length(c), length(u));
    for(jj=1:4)
        if(~isempty(fiberCC(ii,jj).ccRoiCoord) && ~isempty(fiberCC(ii,jj+4).ccRoiCoord))
            left = fiberCC(ii,jj).ccRoiCoord(:,2:3); 
            right = fiberCC(ii,jj+4).ccRoiCoord(:,2:3);
            c = intersect(left, right, 'rows');
            u = unique([right; left], 'rows');
            m = ismember([right; left], c, 'rows');
            overlap(jj+1,ii) = sum(m)/length(m);
            overlapVox(jj+1,ii) = length(c)/length(u);
            fprintf(' %s %0.0f%% (%0.0f%%)', ...
                fgnames{jj+1},  overlap(jj+1,ii)*100, overlapVox(jj+1,ii)*100);
        else
            overlap(jj+1,ii) = 0;
            overlapVox(jj+1,ii) = 0;
        end
    end
    fprintf('\n');
end
fprintf('\n');
% The percentage of all fibers that hit a 1mm voxel that also has a fiber
% coming in from the other side:
for(ii=1:5)
    o = overlap(ii,:);
    fprintf('%s: median=%0.3f, mean=%0.3f, std=%0.4f, min=%0.3f, max=%0.3f\n', fgnames{ii}, ...
        median(o), mean(o), std(o), min(o), max(o));
end
% The # of 1mm voxels that have at least one fiber from each side divided by
% the total # of voxels that have any fiber:
for(ii=1:5)
    o = overlapVox(ii,:);
    fprintf('%s: median=%0.3f, mean=%0.3f, std=%0.4f, min=%0.3f, max=%0.3f\n', fgnames{ii}, ...
        median(o), mean(o), std(o), min(o), max(o));
end

overlapMat = zeros(4,4,N);
for(ii=1:N)
    for(jj=1:4)
        for(kk=1:4)
            left = fiberCC(ii,jj).ccRoiCoord;
            right = fiberCC(ii,kk+4).ccRoiCoord;
            if(~isempty(left) && ~isempty(right))
                left =  left(:,2:3);
                right = right(:,2:3);
                c = intersect(left, right, 'rows');
                m = ismember([right; left], c, 'rows');
                overlapMat(jj,kk,ii) = sum(m)/length(m);
            end
        end
    end
end
mean(overlapMat,3)

for(jj=1:4)
    for(kk=1:4)
        
    end
end

    
% Normalize fibers
for(ii=1:length(f))
    fname = f{ii};
    disp(['Processing ' fname '...']);
    fiberPath = fullfile(fileparts(fname), 'fibers');
    roiPath = fullfile(fileparts(fname), 'ROIs');
    load(fullfile(fiberPath, 'LOcc_adjusted+CC_FA+LV3AB7d')); fgs(1) = fg;
    load(fullfile(fiberPath, 'LOcc_adjusted+CC_FA+LV12d')); fgs(2) = fg;
    load(fullfile(fiberPath, 'LOcc_adjusted+CC_FA+LV12v')); fgs(3) = fg;
    load(fullfile(fiberPath, 'LOcc_adjusted+CC_FA+LV3hV4')); fgs(4) = fg;
    load(fullfile(fiberPath, 'ROcc_adjusted+CC_FA+RV3AB7d')); fgs(5) = fg;
    load(fullfile(fiberPath, 'ROcc_adjusted+CC_FA+RV12d')); fgs(6) = fg;
    load(fullfile(fiberPath, 'ROcc_adjusted+CC_FA+RV12v')); fgs(7) = fg;
    load(fullfile(fiberPath, 'ROcc_adjusted+CC_FA+RV3hV4')); fgs(8) = fg;
    % Normalize fiber coords
    dt = load(fname, 't1NormParams');
    % *** FIX ME! We assume that the SIRL55 sn is 2nd.
    xform = dt.t1NormParams(2);
    [xform.deformX, xform.deformY, xform.deformZ] = mrAnatInvertSn(xform.sn);
    % The xform that goes from acpc space to the deformation field space:
    xform.inMat = inv(xform.sn.VF.mat);
    for(kk=1:length(fgs))
        normFG(ii,kk) = dtiXformFiberCoords(fgs(kk), xform);
    end
end
for(kk=1:size(normFG,2))
  fg = normFG(1,kk);
  fg.fibers = vertcat(normFG(:,kk).fibers);
  dtiWriteFiberGroup(fg, fullfile(['/teal/scr1/dti/' ...
                      'childSpmNorm_SIRL55msWarp2_trilin/fibers'],fg.name));
end
notes = ['created on ' datestr(now) ' by Bob. See dtiReadingOccRoiAnalysis.m.'];
save /teal/scr1/dti/childSpmNorm_SIRL55msWarp2_trilin/allFibers normFG notes sc

genFibers = 0;
if(genFibers)
    faThresh = 0.25;
    opts.stepSizeMm = 1;
    opts.faThresh = 0.15;
    opts.lengthThreshMm = 20;
    opts.angleThresh = 30;
    opts.wPuncture = 0.2;
    opts.whichAlgorithm = 1;
    opts.whichInterp = 1;
    opts.seedVoxelOffsets = [0.25 0.75];
    for(ii=1:length(f))
        fname = f{ii};
        disp(['Processing ' fname '...']);
        roiPath = fullfile(fileparts(fname), 'ROIs');
        fiberPath = fullfile(fileparts(fname), 'fibers');
    
        cc = load(fullfile(roiPath,'CC_FA'));
        dt = load(fname);
        dt.dt6(isnan(dt.dt6)) = 0;
        dt.xformToAcPc = dt.anat.xformToAcPc*dt.xformToAnat;
        fa = dtiComputeFA(dt.dt6);
    
        roiOcc = dtiNewRoi('occ');
        mask = fa>=faThresh;
        [x,y,z] = ind2sub(size(mask), find(mask));
        roiOcc.coords = mrAnatXformCoords(dt.xformToAcPc, [x,y,z]);
    
        % LEFT ROI
        posteriorEdgeOfCC = min(cc.roi.coords(:,2));
        roi = dtiRoiClip(roiOcc, [0 80], [posteriorEdgeOfCC 80]);
        roi = dtiRoiClean(roi, 3, {'fillHoles', 'removeSat'});
        roi.name = 'LOcc';
        dtiWriteRoi(roi, fullfile(roiPath, roi.name));
    
        % LEFT FIBERS
        fg = dtiFiberTrack(dt.dt6, roi.coords, dt.mmPerVox, dt.xformToAcPc, 'LOccFG',opts);
        fg = dtiCleanFibers(fg);
        dtiWriteFiberGroup(fg, fullfile(fiberPath, fg.name), 1, 'acpc', []);
        fg = dtiIntersectFibersWithRoi(0, {'and'}, 1, cc.roi, fg, inv(dt.xformToAcPc));
        dtiWriteFiberGroup(fg, fullfile(fiberPath, fg.name), 1, 'acpc', []);
    
        % RIGHT ROI
        roi = dtiRoiClip(roiOcc, [-80 0], [posteriorEdgeOfCC 80]);
        roi = dtiRoiClean(roi, 3, {'fillHoles', 'removeSat'});
        roi.name = 'ROcc';
        dtiWriteRoi(roi, fullfile(roiPath, roi.name));
    
        % RIGHT FIBERS
        fg = dtiFiberTrack(dt.dt6, roi.coords, dt.mmPerVox, dt.xformToAcPc, 'ROccFG',opts);
        fg = dtiCleanFibers(fg);
        dtiWriteFiberGroup(fg, fullfile(fiberPath, fg.name), 1, 'acpc', []);
        fg = dtiIntersectFibersWithRoi(0, {'and'}, 1, cc.roi, fg, inv(dt.xformToAcPc));
        dtiWriteFiberGroup(fg, fullfile(fiberPath, fg.name), 1, 'acpc', []);
    end
end

