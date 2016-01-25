function test_niftiStruct
%
%
% USAGE: Performs unit tests on the nifti data structure and ensures that
% niftiGet, niftiSet and niftiCreate all work properly.
%
% INPUT: N/A
% Automatically creates a nifti in memory, loads data into it and then
% checks that the data has been created correctly.
%
% OUTPUT: N/A
% Errors will occur if functionality not correct


%Create test data

[~,niftiData] = sort(rand(256,256),2);
niftiData = niftiData(:,1:256);

c = ones(256,256,2);

niftiData(:,:,2) = niftiData.*c(:,:,2);
dim = size(niftiData);
ndim = length(dim);
pixdim = ones(1,ndim);
minVal = min(min(min(min(niftiData))));
maxVal = max(max(max(max(niftiData))));
dataType = niftiClass2DataType(class(niftiData));

nii = niftiCreate('data',niftiData);

%Let's do some niftiSets which we can check afterwards

fileName = fullfile(pwd,'testNifti.ni.gz');
nii = niftiSet(nii,'filepath',fileName);
phaseDim = 1;
freqDim = 2;
sliceDim = 3;
nii = niftiSet(nii,'phase Dim',phaseDim);
nii = niftiSet(nii,'freq Dim',freqDim);
nii = niftiSet(nii,'slice Dim',sliceDim);


%Tests:
assertEqual(niftiGet(nii,'data'),niftiData);
assertEqual(niftiGet(nii,'dim'),dim);
assertEqual(niftiGet(nii,'ndim'),ndim);
assertEqual(niftiGet(nii,'pixdim'),pixdim);
assertEqual(niftiGet(nii,'Cal Min'),minVal);
assertEqual(niftiGet(nii,'Cal Max'),maxVal);
assertEqual(niftiGet(nii,'Data Type'),dataType);
assertEqual(niftiGet(nii,'F Name'),fileName);
assertEqual(niftiGet(nii,'Phase Dim'),phaseDim);
assertEqual(niftiGet(nii,'Freq Dim'),freqDim);
assertEqual(niftiGet(nii,'Slice Dim'),sliceDim);

mrvCleanWorkspace;