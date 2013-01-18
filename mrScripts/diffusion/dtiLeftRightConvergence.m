% dtiLeftRightConvergence

doNormCoords = true;
saveSliceImages = false;
% The longest fibers in a normal brain dont exceed 25cm
maxFiberLen = 250;
outDir = '/biac1/wandell/docs/2005_NYAS_DTI_Dougherty/convergeAnalysis/adults';
upSamp = 2;
acpcPos = [0 -50 10];

%[f,sc] = findSubjects('','_dt6',{'es041113','tk040817'});
[f,sc] = findSubjects(baseDir, '*_dt6', {'bw040806','da050311','jl040902','ka040923'});

N = length(f);

if(~exist(outDir,'dir')) mkdir(outDir); end
recomputeCC = false;
if(recomputeRois)
  for(ii=1:N)
    fname = f{ii};
    disp(['Processing ' fname '...']);
    
    fiberPath = fullfile(fileparts(fname), 'fibers');
    roiPath = fullfile(fileparts(fname), 'ROIs');
    cc = load(fullfile(roiPath, 'CC_FA')); cc = cc.roi;
    % We'll remove any fibers that penetrate a plane that is 25% the length
    % of the CC, starting from the posterior edge.
    %apClip = (max(cc.coords(:,2))-min(cc.coords(:,2)))*.25+min(cc.coords(:,2));
    %fg = dtiCleanFibers(fg, [NaN apCLip NaN]);
    
    dt = load(fname,'xformToAcPc');
    
    fgL = load(fullfile(fiberPath,'LOcc_newFG'));
    fgL.fg = dtiCleanFibers(fgL.fg,[],maxFiberLen);
    fgL.fg = dtiIntersectFibersWithRoi(0, {'and'}, 1, cc, fgL.fg, inv(dt.xformToAcPc));
    fgL.fg.colorRgb = [200 20 20];
    dtiWriteFiberGroup(fgL.fg, fullfile(fiberPath, fgL.fg.name));
    fgR = load(fullfile(fiberPath,'ROcc_newFG'));
    fgR.fg = dtiCleanFibers(fgR.fg,[],maxFiberLen);
    fgR.fg = dtiIntersectFibersWithRoi(0, {'and'}, 1, cc, fgR.fg, inv(dt.xformToAcPc));
    fgR.fg.colorRgb = [20 20 200];
    dtiWriteFiberGroup(fgR.fg, fullfile(fiberPath, fgR.fg.name));
  end
end

fgNames = {'all','LO','V3AB7d','V12d','V12v','V3hV4'};
clear fgs fiberCC;
for(ii=1:N)
  disp(['Processing ' num2str(ii) ': ' sc{ii} '...']);
  fiberPath = fullfile(fileparts(f{ii}), 'fibers');
  roiPath = fullfile(fileparts(f{ii}), 'ROIs');
  tmp = load(fullfile(roiPath, 'CC_FA')); cc(ii) = tmp.roi;
  
  load(fullfile(fiberPath, 'LOcc_adjusted+CC_FA')); fgs(1) = fg;
  load(fullfile(fiberPath, 'LOcc_adjusted+CC_FA+LLO')); fgs(2) = fg;
  load(fullfile(fiberPath, 'LOcc_adjusted+CC_FA+LV3AB7d')); fgs(3) = fg;
  load(fullfile(fiberPath, 'LOcc_adjusted+CC_FA+LV12d')); fgs(4) = fg;
  load(fullfile(fiberPath, 'LOcc_adjusted+CC_FA+LV12v')); fgs(5) = fg;
  load(fullfile(fiberPath, 'LOcc_adjusted+CC_FA+LV3hV4')); fgs(6) = fg;
  load(fullfile(fiberPath, 'ROcc_adjusted+CC_FA')); fgs(7) = fg;
  load(fullfile(fiberPath, 'ROcc_adjusted+CC_FA+RLO')); fgs(8) = fg;
  load(fullfile(fiberPath, 'ROcc_adjusted+CC_FA+RV3AB7d')); fgs(9) = fg;
  load(fullfile(fiberPath, 'ROcc_adjusted+CC_FA+RV12d')); fgs(10) = fg;
  load(fullfile(fiberPath, 'ROcc_adjusted+CC_FA+RV12v')); fgs(11) = fg;
  load(fullfile(fiberPath, 'ROcc_adjusted+CC_FA+RV3hV4')); fgs(12) = fg;
  % We'll remove any fibers that penetrate a plane that is 33% the length
  % of the CC, starting from the posterior edge.
  apClip = (max(cc(ii).coords(:,2))-min(cc(ii).coords(:,2)))*.33+min(cc(ii).coords(:,2));
  for(jj=1:length(fgs))
    fgs(jj) = dtiCleanFibers(fgs(jj), [NaN apClip NaN]);
  end
  
  % Generate the slice images
  dt = load(f{ii}, 'xformToAnat', 'anat');
  bg = dt.anat;
  bg.img = mrAnatHistogramClip(double(bg.img), 0.4, 0.98);
  bg.acpcToImgXform = inv(bg.xformToAcPc);
  
  if(saveSliceImages)
    % Do a simple left/right overlap image
    fname = fullfile(outDir, [sc{ii} '_Lareas']);
    dtiSaveImageSlicesOverlays(0, fgs(1:5), [], 0, fname, upSamp, acpcPos, bg);
    fname = fullfile(outDir, [sc{ii} '_Rareas']);
    dtiSaveImageSlicesOverlays(0, fgs(6:10), [], 0, fname, upSamp, acpcPos, bg);
  end
  
  % Find mid-sagittal fiber points
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
  if(doNormCoords)
    disp('Computing normed coords...');
    dt = load(f{ii}, 't1NormParams');
    % *** FIX ME! We assume that the SIRL55 sn is 2nd.
    xform = dt.t1NormParams(2);
    [xform.deformX, xform.deformY, xform.deformZ] = mrAnatInvertSn(xform.sn);
    % The xform that goes from acpc space to the deformation field space:
    xform.inMat = inv(xform.sn.VF.mat);
    for(kk=1:length(fgs))
      fiberCC(ii,kk).normFiberCoord = mrAnatXformCoords(xform, fiberCC(ii,kk).fiberCoord);
    end
    normCcCoord{ii} = mrAnatXformCoords(xform, cc(ii).coords);
  end
end

save(fullfile(outDir, 'convergeData.mat'), 'sc', 'cc', 'normCcCoord', 'fiberCC', 'fgNames');
for(ii=1:size(fiberCC,1))
  for(jj=1:size(fiberCC,2))
    if(~isempty(fiberCC(ii,jj).fiberCoord))
      fiberCoord{ii,jj} = fiberCC(ii,jj).fiberCoord(:,2:3);
    else
      fiberCoord{ii,jj} = [];
    end
    if(isfield(fiberCC(ii,jj),'normFiberCoord')&~isempty(fiberCC(ii,jj).fiberCoord))
      normFiberCoord{ii,jj} = fiberCC(ii,jj).normFiberCoord(:,2:3);
    else
      normFiberCoord{ii,jj} = [];
    end
  end
end
for(ii=1:length(cc))
  ccCoord{ii} = unique(cc(ii).coords(:,2:3),'rows');
  normCcCoord{ii} = unique(normCcCoord{ii}(:,2:3),'rows');
end
save(fullfile(outDir, 'convergeDataSum.mat'), 'fgNames', 'sc', 'fiberCoord', 'normFiberCoord', 'ccCoord', 'normCcCoord');


% The convergence data have been summarized by doing the following for all
% left fibers and all right fibers:
% - load the CC ROI and use this to find the user-defined mid-sagittal plane.
% - for each fiber, find the point that falls nearest to one of the CC ROI
% points.
%
% fiberCC is an Nx2 array of stucts with the summary data. There is a row
% for each subject and two columns (1=left, 2=right) The fields are:
%
% fiberCoord- an array of points, one for each fiber from the original
% fiber group. These are the points that came closest to the mid-sagittal
% plane. This is probably all you need to analyze.
%
% ccRoiCoord- the original CC ROI points. These are usually sampled on
% a 1mm grid and are 3mm thick. That is, the mid-sag 'plane' can be found
% by taking the average of the X (left-right) coords.
%
% dist- the distance between each fiberCoord and its associated nearest
% ccRoiCoord.
%
