% script_convertDicomSesssion:
% 
% This is an example script providing a template for initializing fMRI data
% into a mrVista session, in the case where:
% (1) the raw data are stored as DICOM files;
% (2) each DICOM file represents one time point in a functional time series
% (3) each time point is stored as a 2-D mosaic of slices, rather than a 3D
% matrix.
%
% For other initialization cases, 
%
% ras, 02/2008.

%%%%% SET PARAMETERS HERE
% session directory -- this is a hypothetical example session
% change to match the session you want to initialize
sessDir = '/RAID/data/mySession/Raw';
cd(sessDir);

%% output mrVISTA session
% (this output session will be a subdirectory of the sessDir)
targetDir = '/RAID/data/mySession/';
ensureDirExists(targetDir);

%% inplane DICOM params
% first, is there a separate T1-weighted Inplane anatomy, or should the
% code just initialize the mean image of the first functional as the
% inplane?
separateT1Inplane = 1;  % set to 0 to use mean functional

% if there's a separate inplane, where is it?
ipDir = 'Raw/Anatomy/Inplane/*.dcm';

nSlices = 29; % # slices -- should match functional files

%% functional DICOM params
% root directory for functional DICOM files
functionalDir = 'Raw/Functionals/';

% each DICOM image appears to be a montage across slices, rather than
% a 3-D matrix. Allow this size to be user-specified (probably kept 
% somewhere in the header, but I couldn't find it):
funcMontageSize = [6 6];


%%%%%% DO INITIALIZATION HERE
% find all directories within this
funcList = {};
w = dir(functionalDir);
for i=1:length(w)
	if w(i).isdir & ~ismember(w(i).name, {'.' '..'})
		funcList{end+1} = fullfile(functionalDir, w(i).name);
	end
end

%% initialize the inplanes
if separateT1Inplane==1
	% this is easy: just read and convert the inplane image
	mr = mrReadDicom(ipDir, 3, nSlices);
	mrSave(mr, targetDir, '1.0anat');
else
	% a little trickier: we need to load the first functional, and take the
	% average across time points. This includes re-arranging the slices
	% from the mosaic.
	cd(sessDir);

	inputPath = [funcList{n} filesep '*.dcm'];
	mr = mrReadDicom(inputPath, 3, funcTRs);
	
	% several empirically-derived steps are needed
	% here: these are mainly to re-order the data for each
	% temporal frame from a 2D, row-ordered matrix inot a 3-D
	% matrix. 
	
	% step 1: separate out each row and column of the montage and data
	nX = funcMontageSize(1); % = # rows in montage
	nY = funcMontageSize(2); % = # columns in montage
	szX = mr.dims(2) ./ nX;  % = # voxels in a column of one slice
	szY = mr.dims(1) ./ nY;  % = # voxels in a row of one slice
	mr.data = reshape(mr.data, [szY nY szX nX funcTRs]);
	
	% step 2: arrange dimensions so that the slice (row,cols) and the
	% montage (row,cols) are together
	mr.data = permute(mr.data, [1 3 2 4 5]);
	
	% step 3: smoosh the rows and columns together
	mr.data = reshape(mr.data, [szY szX nX*nY funcTRs]);
	
	% step 4: get slices in the proper order
	% the slices got shuffled, since MATLAB counts data along columns,
	% but the montage counts it along rows. There's probably an elegant
	% way to reorder -- this is kinda grungy but readily done:
	newOrder = [];  % great band...
	for j = 1:nX
		newOrder = [newOrder j:nY:nX*nY];
	end
	mr.data = mr.data(:,:,newOrder,:);
	
	% step 5: only take slices with data (some may be blank to pad out the
	% montage)
	mr.data = mr.data(:,:,1:nSlices,:);
	mr.dims = size(mr.data);
	
	%% compute the mean image across time points
	mr = mrComputeMeanMap(mr);
	
	%% save the mean as the inplane anatomy
	mr.dims = size(mr.data);
	mrSave(mr, targetDir, '1.0anat');
end


%% initialize the functionals
for n = 1:length(funcList)
	cd(sessDir);

	inputPath = [funcList{n} filesep '*.dcm'];
	mr = mrReadDicom(inputPath, 3, funcTRs);
	
	% several empirically-derived steps are needed
	% here: these are mainly to re-order the data for each
	% temporal frame from a 2D, row-ordered matrix inot a 3-D
	% matrix. 
	
	% step 1: separate out each row and column of the montage and data
	nX = funcMontageSize(1); % = # rows in montage
	nY = funcMontageSize(2); % = # columns in montage
	szX = mr.dims(2) ./ nX;  % = # voxels in a column of one slice
	szY = mr.dims(1) ./ nY;  % = # voxels in a row of one slice
	mr.data = reshape(mr.data, [szY nY szX nX funcTRs]);
	
	% step 2: arrange dimensions so that the slice (row,cols) and the
	% montage (row,cols) are together
	mr.data = permute(mr.data, [1 3 2 4 5]);
	
	% step 3: smoosh the rows and columns together
	mr.data = reshape(mr.data, [szY szX nX*nY funcTRs]);
	
	% step 4: get slices in the proper order
	% the slices got shuffled, since MATLAB counts data along columns,
	% but the montage counts it along rows. There's probably an elegant
	% way to reorder -- this is kinda grungy but readily done:
	newOrder = [];  % great band...
	for j = 1:nX
		newOrder = [newOrder j:nY:nX*nY];
	end
	mr.data = mr.data(:,:,newOrder,:);
	
	% step 5: only take slices with data (some may be blank to pad out the
	% montage)
	mr.data = mr.data(:,:,1:nSlices,:);
	
	
	%% save this functional scan
	mr.dims = size(mr.data);
	mrSave(mr, targetDir, '1.0tSeries');
	
	% let's name each scan after the input file, so we can keep track of
	% where data came from
	loadSession;
	dataTYPES(1).scanParams(n).annotation = mr.path;
	saveSession;
end

return

	