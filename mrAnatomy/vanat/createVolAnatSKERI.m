function createVolAnatSKERI(imgPathName,outputVAnatName,outputUnfoldName, clipVals)
% createVolAnat([imgPathName],[outputVAnatName],[outputUnfoldName], ...
% [clipVals=get from UI])
%
% imgPathName is the path to one of the I-files or to an analyze-format file. 
% A file browser comes up if none is given. 
%
% If the optional clipVals (in the format of [minVal maxVal]) is provided,
% will clip the vAnatomy before converting to uint8 (0-255, a big
% annoyance resulting from older software constraints) for the .dat file.
% Otherwise, pops up some example slices and a histogram, and lets you
% select the cutoff.
%
% 2000.01.20 RFD (bob@white.stanford.edu): wrote it.
% 2001.02.21 RFD: renamed from createVanatomy and added improved
%            the clipping UI by checking for obvious cases, like
%            when no clipping is necessary.
% 2002.05.22 RFD: fixed a bug that would apply an incorrect upper clip
%            when the lower clip was not zero. THis probably didn't affect
%            anyone with the old (crappy) anatomy data, since the lower clip
%            was always best left at zero anyway.
%            I also now get the mmPerPix from the image header.
% 2002.07.30 RFD: now allow Analyze format files as input. Reorients standard
%            axial Analyze data to match the mrGray sagittal convention.
% 2002.08.05 RFD: fixed crash when imgPathName is passed that was introduced on 7/30.
% 2003.06.25 DHB (brainard@psych.upenn.edu): Allow passing of output names.
% 2004.01.24 Junjie: change GE_readHeader to readIfileHeader
% Get the input filename
if ~exist('imgPathName','var') | isempty(imgPathName)
    [fname, fullPath] = uigetfile({'*.img;*.nii;*.nii.gz','MRI images';'*.img','analyze';'*.nii','NIFTI';'*.nii.gz','NIFTI gz';'*.*','all files'}, 'Select analyze/NIFTI I-files...');
    if(isnumeric(fname))
        error('user canceled.');
    end
    imgPathName = fullfile(fullPath, fname);
end
if ~exist('outputVAnatName','var')
    outputVAnatName = [];
end
if ~exist('outputUnfoldName','var') | isempty(outputUnfoldName)
    outputUnfoldName = 'UnfoldParams';
end
[fullPath,fname,ext] = fileparts(imgPathName);
if(strcmp(ext,'.hdr') | strcmp(ext,'.img'))
    [img,mmPerPix] = loadAnalyze(fullfile(fullPath,[fname '.hdr']));
    % To make analyze data the same orientation as vAnatomy, we reorient the data.
    % Note that we assume Analyze orientation code '0'- transverse, unflipped. 
    % If that is the case, then the following will make the data look correct in mrGray.
    % It will even get left/right correct (left will be left and right right).
    img = permute(img,[3,2,1]);
    mmPerPix = [mmPerPix(3),mmPerPix(2),mmPerPix(1)];
    % flip each slice ud (ie. flip along matlab's first dimension, which is our x-axis)
    for jj=1:size(img,3)
        img(:,:,jj) = flipud(squeeze(img(:,:,jj)));
    end
    % flip each slice lr(ie. flip along matlab's second dimension, which is our y-axis)
    for jj=1:size(img,3)
        img(:,:,jj) = fliplr(squeeze(img(:,:,jj)));
    end
elseif any(strcmpi(ext,{'.nii','.gz'}))
% 	nii = load_nii(fullfile(fullPath,[fname,'.nii']));		% old_RGB flag only matters if datatype=128 & bitpix=24
% 	if isfield(nii.hdr.hist,'rot_orient')		% already RAS?
% 		img = nii.img;
% 		mmPerPix = nii.hdr.dime.pixdim(2:4);
% 	else
% 		error('unknown orientation')
% % 		k = [? ? ?];
% % 		img = permute(nii.img,k);
% % 		mmPerPix = nii.hdr.dime.pixdim(k+1);
% 	end
% 	% now orient to IPR for writeVolAnat to yield PIR vAnatomy
% 	img = permute(img,[3 2 1]);
% 	mmPerPix =mmPerPix([3 2 1]);
% 	img = flipdim(img,1);
% 	img = flipdim(img,2);

	nii = niftiRead(imgPathName);
	mmPerPix = nii.pixdim;
	img = double(nii.data);
	
	% get nifti rotation matrix
	qb = nii.quatern_b;
	qc = nii.quatern_c;
	qd = nii.quatern_d;
	qa = sqrt(1-qb^2-qc^2-qd^2);
	R = [ qa^2+qb^2-qc^2-qd^2, 2*(qb*qc+qa*qd), 2*(qb*qd-qa*qc);...
			2*(qb*qc-qa*qd), qa^2-qb^2+qc^2-qd^2, 2*(qc*qd+qa*qb);...
			2*(qb*qd+qa*qc), 2*(qc*qd-qa*qb), qa^2-qb^2-qc^2+qd^2];
	R = R';	% something about the handedness??? only if positive determinant of R???
				% rows of R now [R;A;S]
	R(:,3) = nii.qfac * R(:,3);
	disp(R)
	
	% now orient to IPR for writeVolAnat to yield PIR vAnatomy
	IPR = [0 0 0];
	[junk,IPR(3)] = max(abs(R(1,:)));	% L-R dimension
	[junk,IPR(2)] = max(abs(R(2,:)));	% P-A dimension
	[junk,IPR(1)] = max(abs(R(3,:)));	% I-S dimension
	if numel(unique(IPR))~=3
		error('bad rotation matrix')
	end
	if any(abs([R(1,IPR(3)),R(2,IPR(2)),R(3,IPR(1))]) < 0.8)
		disp('nifti quaternion inconsistent with 90deg rotations')
	end
	img = permute(img,IPR);
	if R(3,IPR(1)) >= 0
		img = flipdim(img,1);
	end
	if R(2,IPR(2)) >= 0
		img = flipdim(img,2);
	end
	if R(1,IPR(3)) < 0
		img = flipdim(img,3);
	end
	

% elseif(strcmp(ext,'.gz') | strcmp(ext,'.nii'))
elseif strcmp(ext,'.gz')
    ni = niftiRead(imgPathName);
    img = permute(double(ni.data),[3,2,1]);
    mmPerPix = [ni.pixdim(3),ni.pixdim(2),ni.pixdim(1)];
    for(jj=1:size(img,3))
        img(:,:,jj) = flipud(squeeze(img(:,:,jj)));
    end
    for(jj=1:size(img,3))
        img(:,:,jj) = fliplr(squeeze(img(:,:,jj)));
    end
else
    % get some info from the I-file header
    [su_hdr,ex_hdr,se_hdr,im_hdr,pix_hdr,im_offset] = readIfileHeader(imgPathName);
    mmPerPix = [im_hdr.pixsize_Y, im_hdr.pixsize_X, im_hdr.slthick];
%    nSlices = se_hdr.se_numimages;
% Now, the DICOM format of i-files does not provide numimages info, so you
% need to count all i-files in the folder.
    nSlices = length(getIfileNames(imgPathName));
    imDimXY = [im_hdr.dim_X, im_hdr.dim_Y];
   
    disp('Image header says:');
    disp(['  ',num2str(nSlices),' slices']);
    disp(['  ',num2str(imDimXY),' pixels inplane (x,y)']);
    disp(['  ',num2str(mmPerPix),' mm per pixel']);
    % load ifiles
    disp('Loading I-files...');
    img = makeCubeIfiles(fullfile(fullPath,fname), imDimXY, [1:nSlices]);
end
% Get image information
volume_pix_size = 1./mmPerPix;
disp('Finding optimal clip values...');
minVal = min(img(:));
maxVal = max(img(:));
   
% Set the minumum to zero
if(minVal~=0)
    disp(['Image minimum is not zero (',num2str(minVal),')- adjusting...']);
    img = img-minVal;
	 maxVal = maxVal - minVal;
	 minVal = 0;
end
    
% clip and scale, if necessary
if (maxVal <= 255)
    disp('Image values are within 8-bit range- no clipping or scaling is necessary.');
	 lowerClip = minVal;
	 upperClip = maxVal;
elseif exist('clipVals', 'var') && ~isempty(clipVals)
    % Clip and scale image values to be 0-255
    disp('Clipping intensities and scaling to 0-255...');
    img(img > clipVals(2)) = clipVals(2);
    img(img < clipVals(1)) = clipVals(1);
    img = round((img-clipVals(1))./(clipVals(2)-clipVals(1)) * 255);
	 lowerClip = clipVals(1);
	 upperClip = clipVals(2);
else
    figure(99);
    disp('Computing histogram...');
    [clippedImg, suggestedClipVals] = mrAnatHistogramClip(img, 0.5, 0.98);
    lowerClip = suggestedClipVals(1);
    upperClip = suggestedClipVals(2);
    [n,x] = hist(img(:),100);
    histHandle = subplot(2,2,1);
	 
%     bar(x,n,1);
%     lcLine = line([lowerClip,lowerClip], [0,max(n)]);
%     ucLine = line([upperClip,upperClip], [0,max(n)]);

% set yscale so you can see more than the largest histogram peak
	bar(x,n,1,'b');
	set(histHandle,'ylim',[-0.05 1.05]*2e5,'xlim',[-0.05 1.05]*max(x))
	cLineY = [-0.05,1.05]*max(n);
	lcLine = line([lowerClip,lowerClip], cLineY, 'color','r');
	ucLine = line([upperClip,upperClip], cLineY, 'color','r');
	 
	 
    % display some slices
    slice{1} = squeeze(img(round(end/2),:,:));
    slice{2} = squeeze(img(:,round(end/2),:));
    slice{3} = squeeze(img(:,:,round(end/2)));
    for(i=[1:3])
        slice{i}(slice{i}<lowerClip) = lowerClip;
        slice{i}(slice{i}>upperClip) = upperClip;
        slice{i} = slice{i}-lowerClip;
        slice{i} = round(slice{i}./upperClip*255);
        subplot(2,2,2);
        image(slice{1});colormap(gray(256));axis image;axis off;
        subplot(2,2,3);
        image(slice{2});colormap(gray(256));axis image;axis off;
        subplot(2,2,4);
        image(slice{3});colormap(gray(256));axis image;axis off;
    end
    % Loop until user says it looks good
    ok = 0;
    while(~ok)
%         answer = inputdlg({'lower clip value (min=0): ',...
%                 ['upper clip value (max=',num2str(maxVal),'):']}, ...
%                 'Set intensity clip values', 1, ...
%                 {num2str(lowerClip),num2str(upperClip)}, 'on');
%         if ~isempty(answer)
%             lowerClip = str2num(answer{1});
%             upperClip = str2num(answer{2});
%         end
        
        disp(['intensity clip values are: ' num2str(lowerClip) ', ' num2str(upperClip)]);
        infoStr = 'Click twice on the histogram to set clip values. Define the smallest range that keeps the two right peaks.';
        uiwait(helpdlg(infoStr, 'clip info'))
        axes(histHandle);
        [x,y] = ginput(2);
        lowerClip = min(x);
        upperClip = max(x);
		  
%         delete(lcLine); delete(ucLine);
%         lcLine = line([lowerClip,lowerClip], [0,max(n)]);
%         ucLine = line([upperClip,upperClip], [0,max(n)]);
			set(lcLine,'xdata',[lowerClip,lowerClip])
			set(ucLine,'xdata',[upperClip,upperClip])
		  
        % Display some slices
        slice{1} = squeeze(img(round(end/2),:,:));
        slice{2} = squeeze(img(:,round(end/2),:));
        slice{3} = squeeze(img(:,:,round(end/2)));
        for(i=[1:3])
            slice{i} = rescale2(slice{i}, [lowerClip, upperClip]);
%             slice{i}(slice{i}<lowerClip) = lowerClip;
%             slice{i}(slice{i}>upperClip) = upperClip;
%             slice{i} = slice{i}-lowerClip;
%             slice{i} = round(slice{i}./upperClip*255);
            subplot(2,2,2);
            image(slice{1});colormap(gray(256));axis image;axis off;
            subplot(2,2,3);
            image(slice{2});colormap(gray(256));axis image;axis off;
            subplot(2,2,4);
            image(slice{3});colormap(gray(256));axis image;axis off;
        end
        
        bn = questdlg('Is this OK?','Confirm clip values','Yes','No','Cancel','Yes');
        if(strcmp(bn,'Cancel'))
            error('Cancelled.');
        else
            ok = strcmp(bn,'Yes');
        end
    end
    
    % Clip and scale image values to be 0-255
    %
    % I haven't been fully satisfied by just automatically clipping off the top
    % few % of intensities (this is what mrInitRet currently does to the inplanes).
    % So, lately I've been looking at the histogram and picking intensityClip
    % by hand, then viewing the images to see how well it worked.
    disp('Clipping intensities and scaling to 0-255...');
    img(img>upperClip) = upperClip;
    img(img<lowerClip) = lowerClip;
    img = round((img-lowerClip)./(upperClip-lowerClip) * 255);
    %img = rescale2(img, [lowerClip, upperClip], [0, 255]);
end
subplot(2,2,2);
image(squeeze(img(round(end/2),:,:)));colormap(gray(256));axis image; set(gca,'xtick',[],'ytick',[]),	xlabel('right \rightarrow'),ylabel('\leftarrow posterior') %axis off;
subplot(2,2,3);
image(squeeze(img(:,round(end/2),:)));colormap(gray(256));axis image; set(gca,'xtick',[],'ytick',[]), xlabel('right \rightarrow'),ylabel('\leftarrow inferior') %axis off;
subplot(2,2,4);
image(squeeze(img(:,:,round(end/2))));colormap(gray(256));axis image; set(gca,'xtick',[],'ytick',[]), xlabel('posterior \rightarrow'),ylabel('\leftarrow inferior') %axis off;
% Crop the image cube
% (you can skip this if you want, and just do the crop in mrGray)
%figure(1);image(squeeze(img2(round(end/2),:,:))./clip.*255);colormap(gray(256));axis image;
%figure(2);image(squeeze(img2(:,round(end/2),:))./clip.*255);colormap(gray(256));axis image;
%figure(3);image(squeeze(img2(:,:,round(end/2)))./clip.*255);colormap(gray(256));axis image;
%img2 = img2(20:200,30:240,1:124);
%figure(1);image(squeeze(img(round(end/2),:,:))./clip.*255);colormap(gray(256));axis image;
%figure(2);image(squeeze(img(:,round(end/2),:))./clip.*255);colormap(gray(256));axis image;
%figure(3);image(squeeze(img(:,:,round(end/2)))./clip.*255);colormap(gray(256));axis image;
% Save
disp('Saving volume anatomy and unfolding params ...');
path = writeVolAnat(img,mmPerPix,outputVAnatName);
save([path outputUnfoldName], 'volume_pix_size', 'lowerClip', 'upperClip');
disp(['vAnatomy and UnfoldParams saved to ' path]);
return;
