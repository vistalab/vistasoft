% Fix ac-pc origin misalignment in t1's and tensors. (y1)
spm_defaults; global defaults;
estParams = defaults.coreg.estimate;
estParams.params = [0 0 0];
bd = '/biac3/wandell4/data/reading_longitude/dti_y1';
od = '/biac3/wandell4/data/reading_longitude/dti_y1_old';
d = dir(bd);
for(ii=1:length(d))
  dtFn = fullfile(od,d(ii).name,[d(ii).name '_dt6_noMask.mat']);
  t1Fn = fullfile(bd,d(ii).name,'t1','t1.nii.gz');
  dtiFn = fullfile(bd,d(ii).name,'dti06','bin');
  if(d(ii).isdir && exist(dtFn,'file'))
	dt = load(dtFn,'anat');
	Vdst.uint8 = uint8(mrAnatHistogramClip(double(dt.anat.img), 0.4, 0.99)*255+0.5);
	Vdst.mat = dt.anat.xformToAcPc;
	clear dt;
	if(~exist(t1Fn,'file')) 
	  disp(['ERROR: t1 not found- skipping t1 for ' d(ii).name '.']);
	else
	  disp(['Processing t1 for ' d(ii).name '...']);
	  t1 = niftiRead(t1Fn);
	  Vsrc.uint8 = uint8(mrAnatHistogramClip(double(t1.data), 0.4, 0.99)*255+0.5);
	  Vsrc.mat = t1.qto_xyz;
	  x = spm_coreg(Vdst,Vsrc,estParams);
	  x = round(x);
	  if(any(x~=0))
		xf = t1.qto_xyz;
		xf(1:3,4) = xf(1:3,4)-x';
		% o=mrAnatXformCoords(inv(xf),[0 0 0]); imagesc(t1.data(:,:,o(3))); axis image; colormap gray; hold on; plot(o(2),o(1),'ro'); hold off
		t1 = niftiSetQto(t1, xf);
		writeFileNifti(t1);
	  end
	  clear t1;
	end
	if(~exist(dtiFn,'dir')||~exist(fullfile(dtiFn,'b0.nii.gz'),'file')) 
	  disp(['ERROR: dti dir not found- skipping tensors for ' d(ii).name '.']);
	else
	  disp(['Processing tensors for ' d(ii).name '...']);
	  b0 = niftiRead(fullfile(dtiFn,'b0.nii.gz'));
	  Vsrc.uint8 = uint8(mrAnatHistogramClip(double(b0.data), 0.4, 0.99)*255+0.5);
	  Vsrc.mat = b0.qto_xyz;
	  clear b0;
	  x = spm_coreg(Vdst,Vsrc,estParams);
	  x = round(x);
	  if(any(x~=0))
		xf = Vsrc.mat;
		xf(1:3,4) = xf(1:3,4)-x';
		% o=mrAnatXformCoords(inv(xf),[0 0 0]); imagesc(b0.data(:,:,o(3))); axis image; colormap gray; hold on; plot(o(2),o(1),'ro'); hold off
		tf = dir(fullfile(dtiFn,'*.nii.gz'));
		for(jj=1:length(tf))
		   ni = niftiRead(fullfile(dtiFn,tf(jj).name));
		   if(all(ni.qto_xyz(:)==Vsrc.mat(:)))
			 disp(['  Fixing xform in ' tf(jj).name '...']);
			 ni = niftiSetQto(ni, xf);
			 writeFileNifti(ni);
		   else
			 disp(['  ERROR: xform mismatch in ' tf(jj).name '- xform not fixed.']);
		   end
		end
	  end
	end
  end
end

%
% Fix ac-pc origin misalignment in t1's and tensors. (y2 & up)
%
spm_defaults; global defaults;
estParams = defaults.coreg.estimate;
estParams.params = [0 0 0];
d2Dir = '/biac3/wandell4/data/reading_longitude/dti_y3';
d1Dir = '/biac3/wandell4/data/reading_longitude/dti_y2';
d2 = dir(fullfile(d2Dir,'*06*'));
d1 = dir(fullfile(d1Dir,'*05*'));
d1 = {d1.name}; d2 = {d2.name};
for(ii=1:length(d2))
  y2sc = d2{ii};
  sc = explode('0',y2sc); sc = sc{1};
  y1sc = strmatch(sc,d1);
  if(isempty(y1sc)||numel(y1sc)>1)
	disp(['Problem locating previous year data for ' y2sc '- skipping.']);
	continue;
  end
  y1sc = d1{y1sc};
  y1T1Fn = fullfile(d1Dir,y1sc,'t1','t1.nii.gz');
  y2T1Fn = fullfile(d2Dir,y2sc,'t1','t1.nii.gz');
  y2DtFn = fullfile(d2Dir,y2sc,'dti06','bin');
  if(exist(y1T1Fn,'file'))
	ni = niftiRead(y1T1Fn);
	Vdst.uint8 = uint8(mrAnatHistogramClip(double(ni.data), 0.4, 0.99)*255+0.5);
	Vdst.mat = ni.qto_xyz;
	clear ni;
	if(~exist(y2T1Fn,'file')) 
	  disp(['ERROR: t1 not found- skipping t1 for ' y2sc '.']);
	else
	  disp(['Processing t1 for ' y2sc '...']);
	  ni = niftiRead(y2T1Fn);
	  Vsrc.uint8 = uint8(mrAnatHistogramClip(double(ni.data), 0.4, 0.99)*255+0.5);
	  Vsrc.mat = ni.qto_xyz;
	  x = spm_coreg(Vdst,Vsrc,estParams);
	  x = round(x);
	  if(any(x~=0))
		xf = ni.qto_xyz;
		xf(1:3,4) = xf(1:3,4)-x';
        % o=mrAnatXformCoords(inv(xf),[0 0 0]); imagesc(ni.data(:,:,o(3))); axis image; colormap gray; hold on; plot(o(2),o(1),'ro'); hold off
		ni = niftiSetQto(ni, xf);
		writeFileNifti(ni);
	  end
	  clear ni;
	end
	if(~exist(y2DtFn,'dir')||~exist(fullfile(y2DtFn,'b0.nii.gz'),'file')) 
	  disp(['ERROR: dti bin dir not found- skipping tensors for ' y2sc '.']);
	else
	  disp(['Processing tensors for ' y2sc '...']);
	  b0 = niftiRead(fullfile(y2DtFn,'b0.nii.gz'));
	  Vsrc.uint8 = uint8(mrAnatHistogramClip(double(b0.data), 0.4, 0.99)*255+0.5);
	  Vsrc.mat = b0.qto_xyz;
	  clear b0;
	  x = spm_coreg(Vdst,Vsrc,estParams);
	  x = round(x);
	  if(any(x~=0))
        xf = Vsrc.mat;
        xf(1:3,4) = xf(1:3,4)-x';
		% o=mrAnatXformCoords(inv(xf),[0 0 0]); imagesc(b0.data(:,:,o(3))); axis image; colormap gray; hold on; plot(o(2),o(1),'ro'); hold off
		tf = dir(fullfile(y2DtFn,'*.nii.gz'));
		for(jj=1:length(tf))
		   ni = niftiRead(fullfile(y2DtFn,tf(jj).name));
		   if(all(ni.qto_xyz(:)==Vsrc.mat(:)))
			 disp(['  Fixing xform in ' tf(jj).name '...']);
			 ni = niftiSetQto(ni, xf);
			 writeFileNifti(ni);
		   else
			 disp(['  ERROR: xform mismatch in ' tf(jj).name '- xform not fixed.']);
		   end
		end
	  end
	end
  end
end


%
% Making an fMRI movie:
%
ni = niftiRead('214_visual_mcf.nii.gz');
sliceNum = 10;
sz = size(ni.data);
ni.data = uint8(mrAnatHistogramClip(single(ni.data),0.4,0.99)*255);
M = squeeze(ni.data(:,:,sliceNum,:));
clear ni;
M = flipdim(permute(M,[2,1,3]),1);

% Autocrop the movie frames
mask = imblur(mean(M,3),2)>40;
tmp = find(sum(mask,2));
crop(:,1) = [min(tmp) max(tmp)];
tmp = find(sum(mask,1));
crop(:,2) = [min(tmp) max(tmp)];
pad = 5;
if(any(diff(crop)./sz([1:2]) < 0.8))
    crop(1,:) = max([1 1],crop(1,:)-pad);
    crop(2,:) = min(sz([1:2]),crop(2,:)+pad);
    [X,Y,Z] = ndgrid([crop(1,1):crop(2,1)],[crop(1,2):crop(2,2)],[1:sz(3)]);
    x = sub2ind(sz,X(:), Y(:), Z(:)); clear X Y Z;
    newSz = [diff(crop)+1 sz(3)];
    M = reshape(M(x),newSz);
end

outBaseName = '/tmp/fmri2_mcf';
%mpOrig = mplay(int2struct(M),10);
% Save a gif. Cropping and using only 64 colors makes for a
% fairly compact file, suitable for a website. Using 256 colors
% might make a slightly nicer image.
M = M./4; M(M>63) = 63;
% The gif writer wants a 4d dataset (???)
M = reshape(M,[size(M,1),size(M,2),1,size(M,3)]);
imwrite(M,gray(64),[outBaseName '.gif'],'DelayTime',0.1,'LoopCount',65535);



%
% Hack to allow old CINCH to read new-format data
%
bd = '/biac3/wandell4/data/reading_longitude/dti_y4/';
d = dir(fullfile(bd,'*0*'));
for(ii=1:length(d))
   binDir = fullfile(bd,d(ii).name,'dti06','bin');
   t1 = fullfile(bd,d(ii).name,'t1','t1.nii.gz');
   bkDir = fullfile(binDir,'backgrounds');
   if(exist(binDir,'dir')&&exist(t1,'file')&&~exist(bkDir))
      disp(['Processing ' d(ii).name '...']);
      mkdir(bkDir);
      ni = niftiRead(t1);
      ni.data = single(mrAnatHistogramClip(double(ni.data),0.4,0.99));
      ni.fname = fullfile(bkDir,'t1.nii.gz');
      writeFileNifti(ni);
   else
      disp(['Skipping ' d(ii).name '.']);
   end
end

