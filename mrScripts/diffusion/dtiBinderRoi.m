% Warp normalized ROIs to each subject's brain and intersect the FGs.
f = findSubjects;
roiDir = '/snarp/u1/data/reading_longitude/dtiGroupAnalysis/binder_rois/';
b(1) = load(fullfile(roiDir, 'binder1_MNI.mat'));

for(ii=1:length(b))
    b(ii).roi.coords = b(ii).roi.coords(~any(isnan(b(ii).roi.coords')),:);
    b(ii).roi = dtiRoiClean(b(ii).roi, 3, {'fillHoles','removeSat'});
    b(ii).roi.name = ['mho_' b(ii).roi.name];
end

colors = [20 200 20; 20 200 200; 200 20 200; 200 20 20];
roiVerNum = b(1).versionNum;
for(ii=1:length(f))
    fname = f{ii};
    disp(['Processing ' fname '...']);
    fiberPath = fullfile(fileparts(fname), 'fibers');
    roiPath = fullfile(fileparts(fname), 'ROIs');
    cc = load(fullfile(roiPath, 'CC_FA')); cc = cc.roi;
    % We'll clip any fibers that penetrate a plane that is 25% the length
    % of the CC, starting from the posterior edge.
    %apClip =
    %(max(cc.coords(:,2))-min(cc.coords(:,2)))*.25+min(cc.coords(:,2));
    apClip = NaN;
    dt = load(fname, 't1NormParams', 'xformToAnat', 'anat');
    dt.xformToAcPc = dt.anat.xformToAcPc*dt.xformToAnat;
    fgL = load(fullfile(fiberPath,'LOccFG+CC_FA'));
    %fgR = load(fullfile(fiberPath,'ROccFG+CC_FA'));
    for(jj=1:length(b))
        roi = b(jj).roi;
        roi.coords = mrAnatXformCoords(dt.t1NormParams.sn, roi.coords);
        dtiWriteRoi(roi, fullfile(roiPath, roi.name), roiVerNum, 'acpc');
        fg = dtiIntersectFibersWithRoi(0, {'and'}, 1, roi, fgL.fg, inv(dt.xformToAcPc));
        fg = dtiCleanFibers(fg, [NaN apClip NaN]);
        fg.colorRgb = colors(jj,:);
        dtiWriteFiberGroup(fg, fullfile(fiberPath, fg.name), 1, 'acpc');
    end
end

f = findSubjects;
outDir = '/silver/scr1/dti';
upSamp = 4;
talPos = [-16, -85, 5];
for(ii=1:length(f))
    [junk,bn] = fileparts(f{ii});
    us = strfind(bn,'_'); bn = bn(1:us(1)-1);
    disp(['Processing ' num2str(ii) ': ' bn '...']);
    fiberPath = fullfile(fileparts(f{ii}), 'fibers');
    dt = load(f{ii}, 'xformToAnat', 'anat');
    acpcPos = mrAnatTal2Acpc(dt.anat.talScale, talPos);
    bg = dt.anat;
    bg.img = mrAnatHistogramClip(double(bg.img), 0.3, 0.98);
    bg.acpcToImgXform = inv(bg.xformToAcPc);

    load(fullfile(fiberPath, 'LOccFG+CC_FA+mho_binder1')); fgs(1) = fg;

    [fgs.visible] = deal(1);
    fname = fullfile(outDir, [bn '_binder1']);
    dtiSaveImageSlicesOverlays(0, fgs, [], 0, fname, upSamp, acpcPos, bg);
end
 
