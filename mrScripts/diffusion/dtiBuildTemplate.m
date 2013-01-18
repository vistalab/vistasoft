tdir = '/biac2/wandell2/data/templates/';

% load the zeroth-iteration template (built from a simple average
% of all the ac-pc aligned brains
%im = loadAnalyze(fullfile(tdir,'SIRL55-0.img'));

baseDir = '/biac2/wandell2/data/reading_longitude/dti/*0*';
[files,subCodes] = findSubjects(baseDir, '_dt6', {'es041113','tk040817'});
N = length(files);

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
meanExtent.sac = abs(tal.sac)/mean([sf(:).sac]);
meanExtent.iac = abs(tal.iac)/mean([sf(:).iac]);
meanExtent.lac = abs(tal.lac)/mean([sf(:).lac]);
meanExtent.rac = abs(tal.rac)/mean([sf(:).rac]);
meanExtent.aac = abs(tal.aac)/mean([sf(:).aac]);
meanExtent.acpc = abs(tal.acpc)/mean([sf(:).acpc]);
meanExtent.ppc = abs(tal.ppc)/mean([sf(:).ppc]);
for(ii=[1:N])
  extent(ii).sac = abs(tal.sac)/sf(ii).sac;
  extent(ii).iac = abs(tal.iac)/sf(ii).iac;
  extent(ii).lac = abs(tal.lac)/sf(ii).lac;
  extent(ii).rac = abs(tal.rac)/sf(ii).rac;
  extent(ii).aac = abs(tal.aac)/sf(ii).aac;
  extent(ii).acpc = abs(tal.acpc)/sf(ii).acpc;
  extent(ii).ppc = abs(tal.ppc)/sf(ii).ppc;
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
imSkull = d.anat.img; 
im = imSkull; im(~d.anat.brainMask) = 0;
sz = size(im);
%imSkull = mrAnatHistogramClip(double(imSkull), 0.5, 0.99);
proportionNonBrain = sum(~d.anat.brainMask(:))./prod(size(d.anat.brainMask));
im = mrAnatHistogramClip(double(im), proportionNonBrain, 0.99);
bb = [-d.anat.mmPerVox.*(ac-1); d.anat.mmPerVox.*(sz-ac)];
ts = newScale(1); ts.talScaleDir = 'tal2acpc';
% warp T1 to tal space
ts.outMat = inv(d.anat.xformToAcPc);
[im,newXform] = mrAnatResliceSpm(im,ts,bb,[1 1 1],[7 7 7 0 0 0],0);
im(isnan(im)) = 0;
im(im<0) = 0; im(im>1) = 1;
ax = zeros(sz(2), sz(1), N+1);
cr = zeros(sz(3), sz(1), N+1);
sg = zeros(sz(3), sz(2), N+1);
meanIm = im;
ax(:,:,1) = flipud(permute(squeeze(im(:,:,ac(3))),[2,1]));
cr(:,:,1) = flipud(permute(squeeze(im(:,ac(2),:)),[2,1]));
sg(:,:,1) = flipud(permute(squeeze(im(ac(1),:,:)),[2,1]));
for(ii=[2:N])
  fprintf('Processing %s (%d of %d)...\n',subCodes{ii}, ii, N);
  d = load(files{ii},'anat');
  % All coords should be the same.
  ac = round(mrAnatXformCoords(inv(d.anat.xformToAcPc),[0 0 0]));
  im = d.anat.img; im(~d.anat.brainMask) = 0;
  im = mrAnatHistogramClip(double(im), 0.4, 0.99);
  ts = newScale(ii); ts.talScaleDir = 'tal2acpc';
  ts.outMat = inv(d.anat.xformToAcPc);
  [im,newXform] = mrAnatResliceSpm(im,ts,bb,[1 1 1],[7 7 7 0 0 0],0);
  im(isnan(im)) = 0;
  im(im<0) = 0; im(im>1) = 1;
  meanIm = meanIm + im;
  ax(:,:,ii) = flipud(permute(squeeze(im(:,:,ac(3))),[2,1]));
  cr(:,:,ii) = flipud(permute(squeeze(im(:,ac(2),:)),[2,1]));
  sg(:,:,ii) = flipud(permute(squeeze(im(ac(1),:,:)),[2,1]));
end
meanIm = meanIm./N;
figure; image(makeMontage(uint8(meanIm*255))); 
colormap(gray(256)); axis equal tight off;
ax(:,:,N+1) = mean(ax(:,:,[1:N]), 3);
cr(:,:,N+1) = mean(cr(:,:,[1:N]), 3);
sg(:,:,N+1) = mean(sg(:,:,[1:N]), 3);
ax = uint8(ax.*255+0.5);
cr = uint8(cr.*255+0.5);
sg = uint8(sg.*255+0.5);
figure;image(makeMontage(ax));colormap(gray(256));axis equal tight off;
figure;image(makeMontage(cr));colormap(gray(256));axis equal tight off;
figure;image(makeMontage(sg));colormap(gray(256));axis equal tight off;

tdir = '/snarp/u1/data/templates/';
imwrite(makeMontage(ax), gray(256), fullfile(tdir, 'SIRL55scaledToMean_ax.png'));
imwrite(makeMontage(cr), gray(256), fullfile(tdir, 'SIRL55scaledToMean_cr.png'));
imwrite(makeMontage(sg), gray(256), fullfile(tdir, 'SIRL55scaledToMean_sg.png'));

% Now build an atlas from the mean image
V.dat = int16(meanIm.*(2^15-1)+0.5);
notes = ['SIRL55ms: average of 55 mean-Tal-scaled brains. Created at ' datestr(now,31)];
mmPerVox = d.anat.mmPerVox;
origin = ac;
hdr = saveAnalyze(V.dat, fullfile(tdir,'SIRL55ms'), mmPerVox, notes, origin);
save(fullfile(tdir,'SIRL55ms_details.mat'), 'meanIm','notes','extent','meanExtent','origin','mmPerVox');


