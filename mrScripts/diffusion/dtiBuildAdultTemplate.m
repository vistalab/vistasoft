tic;
doChild = true;
if(ispc)
    tdir = '\\white.stanford.edu\biac2-wandell2\data\reading_longitude\templates\';
    baseDir = '\\white.stanford.edu\biac2-wandell2\data\reading_longitude\';
else
    %tdir = '/biac2/wandell2/data/reading_longitude/templates/';
    tdir = '/silver/scr1/data/templates/';
    baseDir = '/biac2/wandell2/data/reading_longitude/';
end
if(doChild)
    baseDir = fullfile(baseDir,'dti','*0*');
    tdir = fullfile(tdir,'child_new');
    % es's data are OK now.
    %excludeList = {'es041113','tk040817'};
    excludeList = {'tk040817'};
    tBaseName = 'SIRL%02d';
else
    baseDir = fullfile(baseDir,'dti_adults','*0*');
    tdir = fullfile(tdir,'adult_new');
    excludeList = {'ah051003','gf050826','da050311','bw040806'};
    tBaseName = 'SIRL%02dadult';
end

if(isempty(mfilename)) thisfilename = 'dtiBuildAdultTemplate.m'; 
else  thisfilename = mfilename; end
%[files,subCodes] = findSubjects(baseDir,
%'*_dt6',{'ah051003','gf050826'});
% 2006.03.28 RFD: we now excude da050311 because the top of the
% brain is cut-off in the dti and 'bw040806' as an age outlier.
[files,subCodes] = findSubjects(baseDir, '*_dt6_noMask',excludeList);
N = length(files);

forceBuildAll = false;
useBrainMaskScales = true;
tensorInterpMethod = 1;
tBaseName = sprintf(tBaseName,N);
useBrainMask = true;
if(useBrainMaskScales) suffix{1} = '_bmms'; 
else suffix{1} = '_ms'; end
suffix{2} = 'warp1'; suffix{3} = 'warp2'; suffix{4} = 'warp3';
mmPerVox = [1 1 1];

if(~exist(tdir,'dir'))
    mkdir(tdir);
end

spm_defaults; global defaults; defaults.analyze.flip = 0;
params = defaults.normalise.estimate;
params.smosrc = 4;

% 1. BOOTSTRAP THE INITIAL TEMPLATE
curName = [tBaseName suffix{1}];
curTemplate = fullfile(tdir,curName);
if(forceBuildAll | ~exist([curTemplate '.img'],'file'))
    % Build the zeroth-iteration template from a simple average
    % of all the ac-pc aligned brains

    % measure brain masks to get the minimumand maximum brain extent in
    % each dimension.
    clear minAcPc maxAcPc;
    for(ii=1:N)
        fprintf(['Measuring ' subCodes{ii} ':\t']);
        d = load(files{ii},'anat');
        % find x,y limits
        tmp = sum(d.anat.brainMask,3);
        x = find(sum(tmp,1)); x = [x(1) x(end)];
        y = find(sum(tmp,2)); y = [y(1) y(end)];
        % find z limits
        tmp = squeeze(sum(d.anat.brainMask,1));
        z = find(sum(tmp,1)); z = [z(1) z(end)];
        curSizeAcPc = mrAnatXformCoords(d.anat.xformToAcPc,[y;x;z]');
        minAcPc(ii,:) = curSizeAcPc(1,:);
        maxAcPc(ii,:) = curSizeAcPc(2,:);
        fprintf('RAS = [% 3.1f % 3.1f % 3.1f] mm, LPI: [% 3.1f % 3.1f % 3.1f] mm.\n',curSizeAcPc(2,:),abs(curSizeAcPc(1,:)));
    end
    meanBrainSizeFromMask = [mean(minAcPc); mean(maxAcPc)];

    % Load all the talscales
    for(ii=[1:N])
        fprintf('Loading scale factors from %s (%d of %d)...\n',subCodes{ii}, ii, N);
        d = load(files{ii},'anat');
        sf(ii) = d.anat.talScale;
    end
    % To get the mean extent, we average the Talairach scale factors
    % and then divide Talairach's actual dimensions (in mm) by these
    % scales.
    tal = mrAnatGetTalairachDists;
    if(useBrainMaskScales)
        meanExtent.sac = abs(meanBrainSizeFromMask(2,3));
        meanExtent.iac = abs(meanBrainSizeFromMask(1,3));
        meanExtent.lac = abs(meanBrainSizeFromMask(1,1));
        meanExtent.rac = abs(meanBrainSizeFromMask(2,1));
        meanExtent.aac = abs(meanBrainSizeFromMask(2,2));
        % We still need the AC-to-PC talScale, since the brain mask doesn't
        % give us that one. But, that one is also immune to the ambiguity
        % that plagues marking the brain-edge.
        meanExtent.acpc = abs(tal.acpc)/mean([sf(:).acpc]);
        meanExtent.ppc = abs(meanBrainSizeFromMask(1,2)) - meanExtent.acpc;
    else
        meanExtent.sac = abs(tal.sac)/mean([sf(:).sac]);
        meanExtent.iac = abs(tal.iac)/mean([sf(:).iac]);
        meanExtent.lac = abs(tal.lac)/mean([sf(:).lac]);
        meanExtent.rac = abs(tal.rac)/mean([sf(:).rac]);
        meanExtent.aac = abs(tal.aac)/mean([sf(:).aac]);
        meanExtent.acpc = abs(tal.acpc)/mean([sf(:).acpc]);
        meanExtent.ppc = abs(tal.ppc)/mean([sf(:).ppc]);
    end
    for(ii=[1:N])
        if(useBrainMaskScales)
            extent(ii).sac = abs(maxAcPc(ii,3));
            extent(ii).iac = abs(minAcPc(ii,3));
            extent(ii).lac = abs(minAcPc(ii,1));
            extent(ii).rac = abs(maxAcPc(ii,1));
            extent(ii).aac = abs(maxAcPc(ii,2));
            extent(ii).acpc = abs(tal.acpc)/sf(ii).acpc;
            extent(ii).ppc = abs(minAcPc(ii,2)) - meanExtent.acpc;
        else
            extent(ii).sac = abs(tal.sac)/sf(ii).sac;
            extent(ii).iac = abs(tal.iac)/sf(ii).iac;
            extent(ii).lac = abs(tal.lac)/sf(ii).lac;
            extent(ii).rac = abs(tal.rac)/sf(ii).rac;
            extent(ii).aac = abs(tal.aac)/sf(ii).aac;
            extent(ii).acpc = abs(tal.acpc)/sf(ii).acpc;
            extent(ii).ppc = abs(tal.ppc)/sf(ii).ppc;
        end
        newScale(ii).sac = meanExtent.sac/extent(ii).sac;
        newScale(ii).iac = meanExtent.iac/extent(ii).iac;
        newScale(ii).lac = meanExtent.lac/extent(ii).lac;
        newScale(ii).rac = meanExtent.rac/extent(ii).rac;
        newScale(ii).aac = meanExtent.aac/extent(ii).aac;
        newScale(ii).acpc = meanExtent.acpc/extent(ii).acpc;
        newScale(ii).ppc = meanExtent.ppc/extent(ii).ppc;
        newScale(ii).pcReference = -meanExtent.acpc;
    end

    % Reslice using the talscale measurements.
    d = load(files{1},'anat');
    ac = round(mrAnatXformCoords(inv(d.anat.xformToAcPc),[0 0 0]));
    im = double(d.anat.img);
    im = im./max(im(:));
    im(~d.anat.brainMask) = 0;
    sz = size(im);
    % t1's from dt6 files shouldn't need histogram clipping. But we will
    % scale every brain to 0-1.
    %imSkull = mrAnatHistogramClip(double(imSkull), 0.5, 0.99);
    %proportionNonBrain = sum(~d.anat.brainMask(:))./prod(size(d.anat.brainMask));
    %im = mrAnatHistogramClip(double(im), proportionNonBrain, 0.99);
    bb = [-d.anat.mmPerVox.*(ac-1); d.anat.mmPerVox.*(sz-ac)];
    ts = newScale(1); ts.talScaleDir = 'tal2acpc';
    % warp T1 to tal space
    ts.outMat = inv(d.anat.xformToAcPc);
    [im,newXform] = mrAnatResliceSpm(im,ts,bb,mmPerVox,[7 7 7 0 0 0],0);
    im(isnan(im)) = 0;
    im(im<0) = 0; im(im>1) = 1;
    allIm = zeros([sz N]);
    allIm(:,:,:,1) = im;
    for(ii=[2:N])
        fprintf('Processing %s (%d of %d)...\n',subCodes{ii}, ii, N);
        d = load(files{ii},'anat');
        % All coords should be the same.
        ac = round(mrAnatXformCoords(inv(d.anat.xformToAcPc),[0 0 0]));
        im = double(d.anat.img); 
        im = im./max(im(:));
        im(~d.anat.brainMask) = 0;
        ts = newScale(ii); ts.talScaleDir = 'tal2acpc';
        ts.outMat = inv(d.anat.xformToAcPc);
        [im,newXform] = mrAnatResliceSpm(im,ts,bb,mmPerVox,[7 7 7 0 0 0],0);
        im(isnan(im)) = 0;
        im(im<0) = 0; im(im>1) = 1;
        allIm(:,:,:,ii) = im;
    end
    % Save all the resliced brains in a temp file.
    save(fullfile(tempdir, [curName '_all.mat']), 'allIm');
    for(ii=1:N)
        allIm(:,:,:,ii) = mrAnatHistogramClipOptimal(allIm(:,:,:,ii));
    end
    meanIm = mean(allIm,4);
    figure; image(makeMontage(uint8(meanIm*255))); colormap(gray(256)); axis equal tight off;

    ax = flipdim(permute(squeeze(allIm(:,:,ac(3),:)),[2,1,3]),1);
    cr = flipdim(permute(squeeze(allIm(:,ac(2),:,:)),[2,1,3]),1);
    sg = flipdim(permute(squeeze(allIm(ac(1),:,:,:)),[2,1,3]),1);
    ax(:,:,N+1) = mean(ax(:,:,[1:N]), 3);
    cr(:,:,N+1) = mean(cr(:,:,[1:N]), 3);
    sg(:,:,N+1) = mean(sg(:,:,[1:N]), 3);
    ax = uint8(ax.*255+0.5);
    cr = uint8(cr.*255+0.5);
    sg = uint8(sg.*255+0.5);

    figure;image(makeMontage(ax));colormap(gray(256));axis equal tight off;
    figure;image(makeMontage(cr));colormap(gray(256));axis equal tight off;
    figure;image(makeMontage(sg));colormap(gray(256));axis equal tight off;

    imwrite(makeMontage(ax), gray(256), fullfile(tdir, [tBaseName '_ax.png']));
    imwrite(makeMontage(cr), gray(256), fullfile(tdir, [tBaseName '_cr.png']));
    imwrite(makeMontage(sg), gray(256), fullfile(tdir, [tBaseName '_sg.png']));

    % Now build an atlas from the mean image
    V.dat = int16(meanIm.*(2^15-1)+0.5);
    notes = [curName ': average of ' num2str(N) ' mean-Tal-scaled brains. Created at ' datestr(now,31)];
    hdr = saveAnalyze(V.dat, curTemplate, mmPerVox, notes, ac);
    save(fullfile(tdir,[curName '_details.mat']), 'meanIm','notes','extent','meanExtent','ac','mmPerVox');
else
   disp([curTemplate ' exists- skipping. (Set forceBuildAll to rebuild.)']); 
end

% 2. BUILD THE INTERMEDIATE TEMPLATE BY WARPING TO THE INITIAL TEMPLATE
prevTemplate = curTemplate;
curName = [tBaseName suffix{2}];
curTemplate = fullfile(tdir,curName);
if(forceBuildAll | ~exist([curTemplate '.img'],'file'))
    % Now use the mean-scaled template to generate a refined template using
    % non-linear warping.

    [im,mm,hdr] = loadAnalyze(prevTemplate);
    ac = round(mrAnatXformCoords(inv(hdr.mat),[0 0 0]));

    d = load(files{1},'anat');
    im = double(d.anat.img);
    im = im./max(im(:));
    sz = size(im);
    bb = [-d.anat.mmPerVox.*(ac-1); d.anat.mmPerVox.*(sz-ac)];
    % warp T1 to template space
    xform = d.anat.xformToAcPc;
    if(useBrainMask) im(~d.anat.brainMask) = 0; end
    sn = mrAnatComputeSpmSpatialNorm(im, xform, [prevTemplate '.img'], params);
    sn.outMat = inv(sn.VF.mat);
    [im,newXform] = mrAnatResliceSpm(im,sn,bb,mmPerVox,[7 7 7 0 0 0],0);
    im(isnan(im)) = 0;
    im(im<0) = 0; im(im>1) = 1;
    allIm = zeros([sz N]);
    allIm(:,:,:,1) = im;
    for(ii=[2:N])
        fprintf('Processing %s (%d of %d)...\n',subCodes{ii}, ii, N);
        d = load(files{ii},'anat');
        [p,f,e] = fileparts(files{ii});
        im = double(d.anat.img);
        im = im./max(im(:));
        xform = d.anat.xformToAcPc;
        if(useBrainMask) im(~d.anat.brainMask) = 0; end
        sn = mrAnatComputeSpmSpatialNorm(im, xform, [prevTemplate '.img'], params);
        sn.outMat = inv(sn.VF.mat);
        [im,newXform] = mrAnatResliceSpm(im,sn,bb,mmPerVox,[7 7 7 0 0 0],0);
        im(isnan(im)) = 0;
        im(im<0) = 0; im(im>1) = 1;
        allIm(:,:,:,ii) = im;
    end
    % Save all the resliced brains in a temp file.
    save(fullfile(tempdir, [curName '_all.mat']), 'allIm');
    for(ii=1:N)
        allIm(:,:,:,ii) = mrAnatHistogramClipOptimal(allIm(:,:,:,ii));
    end

    meanIm = mean(allIm,4);
    figure; image(makeMontage(uint8(meanIm*255)));
    colormap(gray(256)); axis equal tight off;

    ax = flipdim(permute(squeeze(allIm(:,:,ac(3),:)),[2,1,3]),1);
    cr = flipdim(permute(squeeze(allIm(:,ac(2),:,:)),[2,1,3]),1);
    sg = flipdim(permute(squeeze(allIm(ac(1),:,:,:)),[2,1,3]),1);
    ax(:,:,N+1) = mean(ax(:,:,[1:N]), 3);
    cr(:,:,N+1) = mean(cr(:,:,[1:N]), 3);
    sg(:,:,N+1) = mean(sg(:,:,[1:N]), 3);
    ax = uint8(ax.*255+0.5);
    cr = uint8(cr.*255+0.5);
    sg = uint8(sg.*255+0.5);
    figure;image(makeMontage(ax));colormap(gray(256));axis equal tight off;
    figure;image(makeMontage(cr));colormap(gray(256));axis equal tight off;
    figure;image(makeMontage(sg));colormap(gray(256));axis equal tight off;
    imwrite(makeMontage(ax), gray(256), fullfile(tdir, [tBaseName '_ax.png']));
    imwrite(makeMontage(cr), gray(256), fullfile(tdir, [tBaseName '_cr.png']));
    imwrite(makeMontage(sg), gray(256), fullfile(tdir, [tBaseName '_sg.png']));

    % Now build an atlas from the mean image
    V.dat = int16(meanIm.*(2^15-1)+0.5);
    [p,f,e]=fileparts(prevTemplate); tname = [f e];
    notes = [curName ': average of ' num2str(N) ' brains warped to ' tname '. Created at ' datestr(now,31)];
    hdr = saveAnalyze(V.dat, curTemplate, mmPerVox, notes, ac);
else
    disp([curTemplate ' exists- skipping. (Set forceBuildAll to rebuild.)']);
end

%
% 3. BUILD THE FINAL TEMPLATE BY WARPING TO THE INTERMEDIATE TEMPLATE
%
prevTemplate = curTemplate;
curName = [tBaseName];
curTemplate = fullfile(tdir,curName);
if(forceBuildAll | ~exist([curTemplate '.img'],'file'))
    outDir = fullfile(tdir, [tBaseName suffix{3}]);
    if(~exist(outDir)) mkdir(outDir); end
    for(ii=[1:N])
        fprintf('Processing %s (%d of %d)...\n',subCodes{ii}, ii, N);
        d = load(files{ii});
        im = double(d.anat.img);
        im = im./max(im(:));
        xform = d.anat.xformToAcPc;
        if(useBrainMask) im(~d.anat.brainMask) = 0; end
        sn = mrAnatComputeSpmSpatialNorm(im, xform, [prevTemplate '.img'], params);
        t1Rng = [min(d.anat.img(:)) max(d.anat.img(:))];
        b0Rng = [min(d.b0(:)) max(d.b0(:))];
        d = dtiSpmDeformer(d, sn, tensorInterpMethod, mmPerVox);
        d.anat.img(d.anat.img<t1Rng(1)) = t1Rng(1);
        d.anat.img(d.anat.img>t1Rng(2)) = t1Rng(2);
        d.anat.img = int16(d.anat.img+0.5);
        d.b0(d.b0<b0Rng(1)) = b0Rng(1);
        d.b0(d.b0>b0Rng(2)) = b0Rng(2);
        d.b0 = int16(d.b0+0.5);
        newFileName = fullfile(outDir, [subCodes{ii} '_sn']);
        disp(['Saving to ' newFileName '...']);
        dtiSaveStruct(d, newFileName);
    end

    % Now load all the warped dt6 files and build a template from them.
    snFiles = findSubjects(outDir, '*_sn*',{});
    disp(['Loading ' snFiles{1} '...']);
    dt = load(snFiles{1});
    avg = dt;
    avg.b0 = mrAnatHistogramClip(double(avg.b0),0.5,0.99);
    avg.anat.img = mrAnatHistogramClip(double(avg.anat.img),0.5,0.99);
    if(isfield(avg.anat,'brainMask'))
        avg.anat.brainMask = double(avg.anat.brainMask);
    end
    Nb0 = double(avg.b0>0);
    Nt1 = double(avg.anat.img>0);
    for(ii=2:length(snFiles))
        disp(['Loading ' snFiles{ii} '...']);
        dt = load(snFiles{ii});
        dt.dt6(isnan(dt.dt6)) = 0;
        b0 = mrAnatHistogramClip(double(dt.b0),0.4,0.99);
        b0(isnan(b0)) = 0;
        avg.b0 = avg.b0+b0;
        avg.dt6 = avg.dt6+dt.dt6;
        t1 = mrAnatHistogramClip(double(dt.anat.img),0.4,0.99);
        t1(isnan(t1)) = 0;
        avg.anat.img = avg.anat.img+t1;
        if(isfield(avg.anat,'brainMask') && isfield(dt.anat,'brainMask'))
            avg.anat.brainMask = avg.anat.brainMask+double(dt.anat.brainMask);
        end
        Nb0 = Nb0+double(b0>0);
        Nt1 = Nt1+double(t1>0);
    end
    avg.b0(Nb0>0) = avg.b0(Nb0>0)./Nb0(Nb0>0);
    for(ii=1:6)
        tmp = avg.dt6(:,:,:,ii);
        tmp(Nb0>0) = tmp(Nb0>0)./Nb0(Nb0>0);
        avg.dt6(:,:,:,ii) = tmp;
    end
    avg.anat.img(Nt1>0) = avg.anat.img(Nt1>0)./Nt1(Nt1>0);
    if(isfield(avg.anat,'brainMask'))
        avg.anat.brainMask = avg.anat.brainMask./N;
    end
    % Apply a new dt mask based on the average B0
    mask = dtiCleanImageMask(avg.b0>0.3, 5);
    avg.dt6(repmat(~mask, [1,1,1,6])) = 0;
    avg.notes.dataFiles = snFiles;
    avg.notes.normalizationTemplate = prevTemplate;
    avg.notes.normalizationParams = params;
    avg.notes.createdOn = datestr(now,31);
    fid=fopen(which(mfilename),'rt');thisScript=fread(fid);fclose(fid);
    avg.notes.buildScript = char(thisScript');
    newFileName = fullfile(outDir, ['average_dt6']);
    disp(['Saving to ' newFileName '...']);
    dtiSaveStruct(avg, newFileName);

    % Save mean T1 in analyze format
    V.dat = int16(avg.anat.img.*(2^15-1)+0.5);
    [p,f,e]=fileparts(prevTemplate); tname = [f e];
    notes = ['average of ' num2str(N) ' brains warped to ' tname '. Created at ' datestr(now,31)];
    origin = round(mrAnatXformCoords(inv(avg.anat.xformToAcPc),[0 0 0]));
    saveAnalyze(V.dat, fullfile(tdir,curName), mmPerVox, notes, origin);

    % Save mean T1 (skull-stripped) in analyze format
    % V.dat(avg.anat.brainMask<0.5) = 0;
    % saveAnalyze(V.dat, fullfile(tdir,'SIRL54ms_warp2_brain_thresh'), mmPerVox, notes, origin);
    % An alternative method of skull-stipping. This method essentially
    % treats the brainMask as a probability map rather than a hard
    % threshold. The results are very similar to the hard-thresh
    % version, but it leaves a softer edge in regions of uncertainty
    % (eg. orbital frontal and cerebellium).
    V.dat = int16(avg.anat.img.*avg.anat.brainMask.*(2^15-1)+0.5);
    saveAnalyze(V.dat, fullfile(tdir,[curName '_brain']), mmPerVox, notes, origin);

    % Save mean b=0 in analyze format
    V.dat = int16(avg.b0.*(2^15-1)+0.5);
    origin = round(mrAnatXformCoords(inv(avg.xformToAcPc),[0 0 0]));
    saveAnalyze(V.dat, fullfile(tdir,[curName '_EPI']),  avg.mmPerVox, notes, origin);
else
    disp([curTemplate ' exists- skipping. (Set forceBuildAll to rebuild.)']);
end

%
% 4. BUILD AN AVERAGE DATASET BY WARPING EACH TO THE WARP2 TEMPLATE
%
prevTemplate = fullfile(tdir,[curName '_brain']);
curName = [tBaseName suffix{4}];
outDir = fullfile(tdir, curName);
if(~exist(outDir)) mkdir(outDir); end
for(ii=[1:N])
  fprintf('Processing %s (%d of %d)...\n',subCodes{ii}, ii, N);
  d = load(files{ii});
  im = double(d.anat.img);
  im = im./max(im(:));
  xform = d.anat.xformToAcPc;
  if(useBrainMask) im(~d.anat.brainMask) = 0; end
  sn = mrAnatComputeSpmSpatialNorm(im, xform, [prevTemplate '.img'], params);
  t1Rng = [min(d.anat.img(:)) max(d.anat.img(:))];
  b0Rng = [min(d.b0(:)) max(d.b0(:))];
  d = dtiSpmDeformer(d, sn, tensorInterpMethod, mmPerVox);
  d.anat.img(d.anat.img<t1Rng(1)) = t1Rng(1);
  d.anat.img(d.anat.img>t1Rng(2)) = t1Rng(2);
  d.anat.img = int16(d.anat.img+0.5);
  d.b0(d.b0<b0Rng(1)) = b0Rng(1);
  d.b0(d.b0>b0Rng(2)) = b0Rng(2);
  d.b0 = int16(d.b0+0.5);
  
  newFileName = fullfile(outDir, [subCodes{ii} '_sn']);
  disp(['Saving to ' newFileName '...']);
  dtiSaveStruct(d, newFileName);
end
% Now load all the warped dt6 files and build an average brain
snFiles = findSubjects(outDir, '*_sn*',{});
N = length(snFiles);
disp(['Loading ' snFiles{1} '...']);
dt = load(snFiles{1});
avg = dt;
avg.b0 = mrAnatHistogramClip(double(avg.b0),0.5,0.99);
avg.anat.img = mrAnatHistogramClip(double(avg.anat.img),0.5,0.99);
if(isfield(avg.anat,'brainMask'))
  avg.anat.brainMask = double(avg.anat.brainMask);
end
Nb0 = double(avg.b0>0);
Nt1 = double(avg.anat.img>0);
for(ii=2:N)
  disp(['Loading ' snFiles{ii} '...']);
  dt = load(snFiles{ii});
  dt.dt6(isnan(dt.dt6)) = 0;
  b0 = mrAnatHistogramClip(double(dt.b0),0.4,0.99);
  b0(isnan(b0)) = 0;
  avg.b0 = avg.b0+b0;
  avg.dt6 = avg.dt6+dt.dt6;
  t1 = mrAnatHistogramClip(double(dt.anat.img),0.4,0.99);
  t1(isnan(t1)) = 0;
  avg.anat.img = avg.anat.img+t1;
  if(isfield(avg.anat,'brainMask') && isfield(dt.anat,'brainMask'))
    avg.anat.brainMask = avg.anat.brainMask+double(dt.anat.brainMask);
  end
  Nb0 = Nb0+double(b0>0);
  Nt1 = Nt1+double(t1>0);
end
avg.b0(Nb0>0) = avg.b0(Nb0>0)./Nb0(Nb0>0);
for(ii=1:6)
  tmp = avg.dt6(:,:,:,ii);
  tmp(Nb0>0) = tmp(Nb0>0)./Nb0(Nb0>0);
  avg.dt6(:,:,:,ii) = tmp;
end
avg.anat.img(Nt1>0) = avg.anat.img(Nt1>0)./Nt1(Nt1>0);
if(isfield(avg.anat,'brainMask'))
  avg.anat.brainMask = avg.anat.brainMask./N;
end
% Apply a new dt mask based on the average B0
mask = dtiCleanImageMask(avg.b0>0.3, 5);
avg.dt6(repmat(~mask, [1,1,1,6])) = 0;
avg.notes.dataFiles = snFiles;
avg.notes.normalizationTemplate = prevTemplate;
avg.notes.normalizationParams = params;
avg.notes.createdOn = datestr(now,31);
fid=fopen(which(mfilename),'rt');thisScript=fread(fid);fclose(fid);
avg.notes.buildScript = char(thisScript');
newFileName = fullfile(outDir, ['average_dt6']);
disp(['Saving to ' newFileName '...']);
dtiSaveStruct(avg, newFileName);
disp(['Finished (' num2str(toc) ' secs)']);



error('stop here');

%% Get demographics for subjects
%
%
baseDir = '/biac2/wandell2/data/reading_longitude/';
tdir = fullfile(baseDir,'templates','adult');
[files,subCodes] = findSubjects(fullfile(tdir,'SIRL20adultwarp3_averageDataset'), '*_sn', {});
fid = fopen(fullfile(tdir,'subjectInfo.csv'),'w');
fprintf(fid,'Name,Sex,Age,ExactAge,birthDate,scanDate\n');
for(ii=1:length(subCodes))
    if(strcmp(subCodes{ii}(1:2),'ab')) subCodes{ii} = ['aab' subCodes{ii}(3:end)]; end
    if(strcmp(subCodes{ii}(1:2),'rd')) subCodes{ii} = ['rfd' subCodes{ii}(3:end)]; end
    dtDir = fullfile(baseDir,'dti_adults',subCodes{ii});
    if(~exist(dtDir,'dir'))
        dtDir = fullfile(baseDir,'dti_adults','additional_runs',subCodes{ii});
    end
    dataDir = fullfile(dtDir,'dti');
    if(~exist(dataDir,'dir')) 
        dataDir = fullfile(dtDir,'dti_6dir');
    end
    f = fullfile(dataDir,'B0_001.dcm');
    if(~exist(f,'file'))
        f = [f '.gz'];
        gunzip(f,'/tmp/');
        f = '/tmp/B0_001.dcm';
    end
    di = dicominfo(f);
    ad = datenum(di.AcquisitionDate,'yyyymmdd');
	bd = datenum(di.PatientBirthDate,'yyyymmdd');
    exactAge(ii) = (ad-bd)/364.25;
    sex(ii) = di.PatientSex=='M';
    fprintf(fid,'%s,%s,%s,%s,%0.2f,%s,%s\n',...
        subCodes{ii}, di.PatientName.FamilyName, di.PatientSex, di.PatientAge, exactAge(ii), di.PatientBirthDate, di.AcquisitionDate);
end
fclose(fid);
fprintf('Age: %0.0f - %0.0f years (mean %0.1f), %d females out of %d total.\n',...
    min(exactAge),max(exactAge),mean(exactAge),sum(~sex),length(sex));




%
% 5. BUILD AN MNI-EPI SET FOR COMPARISON
%
tic;
if(ispc)
    tdir = '\\white.stanford.edu\biac2-wandell2\data\reading_longitude\templates\adult';
    baseDir = '\\white.stanford.edu\biac2-wandell2\data\reading_longitude\dti_adults\*0*';
else
    tdir = '/biac2/wandell2/data/reading_longitude/templates/adult';
    baseDir = '/biac2/wandell2/data/reading_longitude/dti_adults/*0*';
end
tensorInterpMethod = 1;
tBaseName = 'SIRL20_adult';
mmPerVox = [1 1 1];
spm_defaults; global defaults; defaults.analyze.flip = 0;
params = defaults.normalise.estimate;
%params.smosrc = 4;
[files,subCodes] = findSubjects(baseDir, '*_dt6',{'ah051003','gf050826'});
N = length(files);

spmDir = fileparts(which('spm_normalise'));
prevTemplate = fullfile(spmDir,'templates','EPI.mnc');
curName = [tBaseName '_MNI_EPI'];
outDir = fullfile(tdir, curName);
if(~exist(outDir)) mkdir(outDir); end
for(ii=[1:N])
  fprintf('Processing %s (%d of %d)...\n',subCodes{ii}, ii, N);
  d = load(files{ii});
  im = double(d.b0);
  im = mrAnatHistogramClip(im);
  xform = d.anat.xformToAcPc;
  if(useBrainMask) im(~d.anat.brainMask) = 0; end
  sn = mrAnatComputeSpmSpatialNorm(im, xform, [prevTemplate '.img'], params);
  t1Rng = [min(d.anat.img(:)) max(d.anat.img(:))];
  b0Rng = [min(d.b0(:)) max(d.b0(:))];
  d = dtiSpmDeformer(d, sn, tensorInterpMethod, mmPerVox);
  d.anat.img(d.anat.img<t1Rng(1)) = t1Rng(1);
  d.anat.img(d.anat.img>t1Rng(2)) = t1Rng(2);
  d.anat.img = int16(d.anat.img+0.5);
  d.b0(d.b0<b0Rng(1)) = b0Rng(1);
  d.b0(d.b0>b0Rng(2)) = b0Rng(2);
  d.b0 = int16(d.b0+0.5);
  
  newFileName = fullfile(outDir, [subCodes{ii} '_sn']);
  disp(['Saving to ' newFileName '...']);
  dtiSaveStruct(d, newFileName);
end
% Now load all the warped dt6 files and build an average brain
files = findSubjects(outDir, '*_sn*',{});
N = length(files);
disp(['Loading ' files{1} '...']);
dt = load(files{1});
avg = dt;
avg.b0 = mrAnatHistogramClip(double(avg.b0),0.5,0.99);
avg.anat.img = mrAnatHistogramClip(double(avg.anat.img),0.5,0.99);
if(isfield(avg.anat,'brainMask'))
  avg.anat.brainMask = double(avg.anat.brainMask);
end
avg.dtBrainMask = double(avg.dtBrainMask);
Nb0 = double(avg.b0>0);
Nt1 = double(avg.anat.img>0);
for(ii=2:N)
  disp(['Loading ' files{ii} '...']);
  dt = load(files{ii});
  dt.dt6(isnan(dt.dt6)) = 0;
  b0 = mrAnatHistogramClip(double(dt.b0),0.4,0.99);
  b0(isnan(b0)) = 0;
  avg.b0 = avg.b0+b0;
  avg.dt6 = avg.dt6+dt.dt6;
  avg.dtBrainMask = avg.dtBrainMask+dt.dtBrainMask;
  t1 = mrAnatHistogramClip(double(dt.anat.img),0.4,0.99);
  t1(isnan(t1)) = 0;
  avg.anat.img = avg.anat.img+t1;
  if(isfield(avg.anat,'brainMask') && isfield(dt.anat,'brainMask'))
    avg.anat.brainMask = avg.anat.brainMask+double(dt.anat.brainMask);
  end
  Nb0 = Nb0+double(b0>0);
  Nt1 = Nt1+double(t1>0);
end
avg.b0(Nb0>0) = avg.b0(Nb0>0)./Nb0(Nb0>0);
for(ii=1:6)
  tmp = avg.dt6(:,:,:,ii);
  tmp(Nb0>0) = tmp(Nb0>0)./Nb0(Nb0>0);
  avg.dt6(:,:,:,ii) = tmp;
end
avg.anat.img(Nt1>0) = avg.anat.img(Nt1>0)./Nt1(Nt1>0);
if(isfield(avg.anat,'brainMask'))
  avg.anat.brainMask = avg.anat.brainMask./N;
end
avg.dtBrainMask = avg.dtBrainMask./N;
% Apply a new dt mask based on the average B0
mask = dtiCleanImageMask(avg.b0>0.3, 5);
avg.dt6(repmat(~mask, [1,1,1,6])) = 0;
avg.notes.dataFiles = files;
avg.notes.normalizationTemplate = template;
avg.notes.normalizationParams = params;
avg.notes.createdOn = datestr(now,31);
fid=fopen(which(thisfilename),'rt');thisScript=fread(fid);fclose(fid);
avg.notes.buildScript = char(thisScript');
newFileName = fullfile(outDir, ['average_dt6']);
disp(['Saving to ' newFileName '...']);
dtiSaveStruct(avg, newFileName);
disp(['Finished (' num2str(toc) ' secs)']);
