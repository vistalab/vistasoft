function rx = rxLoadFSLTransform(rx, loadPath)
%
% rx = rxLoadFSLTransform([rx],[loadPath])
%
% Load a mrVista alignment from an existing FSL (flirt)
% 4x4 transform file into mrRx.
%
% Mark Hymers, 2019 YNiC ,mark.hymers@york.ac.uk
if notDefined('rx')
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end

if ieNotDefined('loadPath')
    [fname parent] = uigetfile('*.mat','Select FSL transform file...');
    loadPath = fullfile(parent,fname);
end

if ~exist(loadPath,'file')
    msg = sprintf('%s not found.', loadPath);
    myErrorDlg(msg);
end

% Check that the matrix is a 4x4 transformation matrix
fslmat = load(loadPath, '-ascii');
if ~isequal(size(fslmat), [4, 4])
    msg = sprintf('%s is not a 4x4 matrix', loadPath);
    myErrorDlg(msg);
end

% Now need to retrieve the dimensions and voxel dimensions of the inplane and
% anatomy

%% Inplane info - we need this in LAS and mrVista stores it as PRS
inplaneDim = [rx.refDims(2) rx.refDims(1) rx.refDims(3)];
inplaneVolRes = [rx.refVoxelSize(2) rx.refVoxelSize(1) rx.refVoxelSize(3)];

%% Anatomy info - we need this in LAS and mrVista stores it in IPR
structDim = [rx.volDims(3) rx.volDims(2) rx.volDims(1)];
% Temporary hack as this appears to be in LAS anyways when it shouldn't
structVolRes = [rx.volVoxelSize(1) rx.volVoxelSize(2) rx.volVoxelSize(3)];

% first, mrV inplane in PRS, we're in LAS, convert (i.e. [mat][PRS1] = [LAS1]
% adding 1 to dim as -1*[1,512]+512 = [511,0], not [512,1]
xfm1 = [0 -1  0 inplaneDim(2)+1;...
       -1  0  0 inplaneDim(1)+1;...
        0  0  1 0;...
        0  0  0 1];

% need to convert from one based indexing to zero based indexing, so
% subtract one from each dimension (equiv to VO in old script)
xfm2 = [ eye(3), -ones(3,1); 0 0 0 1 ];

% convert from inplane voxels to mm
xfm3 = diag([inplaneVolRes 1]);

% - FSL TRANSFORM GOES HERE -

% convert back to voxels, this time structural voxels
xfm4  = inv(diag([ structVolRes 1]));

% undo the shift to zero based indexing, i.e. add one to each dim
xfm5 = inv(xfm2);

% mrV volume in IPR, we're in LAS, convert (i.e. [mat][LAS1] = [IPR1]
xfm6 = [0  0 -1 structDim(3)+1;...
        0 -1  0 structDim(2)+1;...
       -1  0  0 structDim(1)+1;...
        0  0  0 1];

% create final transform
result_xfm = xfm6 * xfm5 * xfm4 * fslmat * xfm3 * xfm2 * xfm1;

% The transform in rxAlign has to have the X and Y dimensions swapped
result_xfm(:,[1 2]) = result_xfm(:,[2 1]);
result_xfm([1 2],:) = result_xfm([2 1],:);

rx = rxSetXform(rx, result_xfm, 0);

rxStore(rx,'mrVista Alignment');

return

