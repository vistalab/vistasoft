function [bvecs,bvals] = dwiCheckBvecsBvals(bvecs,bvals,dwiData)
% Check that the bvecs and bvals are in the preferred format. 
% 
% [bvals,bvecs] = dwiCheckBvecsBvals(bvecs,bvals,[dwiData])
% 
% If they are not in the preferred format we transpose the array and return
% it. Also performs a check to ensure that the number of entries in bvecs
% and bvals matches the number of volumes in the raw data. This is only
% done if you pass in the raw data structure, which is optional. 
%
%  [bvals,bvecs] = dwiCheckBvecsBvals(bvecs,bvals,[dwiData])
%
% INPUTS
%      bvecs: B-bevectors array - read in using dlmread.
%      bvals: B-values array    - read in using dlmread
%    dwiData: dwi nifti structure. The data field will be used to
%             check that there is an entry in bvals and bvecs for
%             every volume. 
%
% RETURNS
%      bvals: Strength of the gradient  (1D) 
%      bvecs: Direction of the gradient (3D)
%
% Web Resources
%    mrvBrowseSVN('dtiLoadDWI');
%    mrvBrowseSVN('dwiCheckBvecsBvals');
%
% Example:
%           bvecs = dlmread('dwi.bvecs');
%           bvals = dlmread('dwi.bvals');
%         dwiData = niftiRead('dwi.nii.gz');
%   [bvecs,bvals] = dwiCheckBvecsBvals(bvecs,bvals,dwiData);
%
% See also: dwiCreate.m, dwiLoad.m
%
% 
% (C) Stanford University, VISTA Lab [2011]
% 

%% Run the checks

if size(bvecs, 2) ~= 3
    bvecs = bvecs';
end
if size(bvecs, 2) ~= 3
    error('bvecs file must be an Nx3 matrix.')
end

if size(bvals, 2) == size(bvecs, 1)
    bvals = bvals';
end

if size(bvals,1) ~= size(bvecs,1) 
    error('bvals and bvecs files must have the same number of entries.')
end

if ~notDefined('dwiData')
    if size(bvals, 1 )~= size(dwiData.data, 4) || size(bvecs, 1) ~= size(dwiData.data, 4)
        if ~isempty(bvecs) && ~isempty(bvals)
            error('bvals and bvecs must have an entry for every nifti volume.')
        end
    end
end

    
return
