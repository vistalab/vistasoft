function dwi = dwiCreate(varargin)
% Create a dwi structure for use with dwiGet and dwiSet
% 
%   dwi = dwiCreate([varargin]);
%
% name:     ['Default dwi']
% 
% type:     ['dwi']
% 
% nifti:    [] - Path to the nifti image of the motion corrected, ac-pc
%           aligned dwi data
%
% bvecs:    [] - Path to the tab delimeted text file specifying the gradient
%           directions that were applied during the diffusion weighted data
%           acquisition. 
%           Should be a 3xN matrix where N is the number of 
%           volumes
%           NOTE: If you applied motion correction to your 
%           data it is essential that the same rotations were aplied
%           to the vector directions stored in the bvecs file.
%           The convention for mrDiffusion is that a new bvecs file is
%           created and appended with _aligned.
%
% bvals:    [] - Path to the tab delimeted text file specifying the b value
%           applide to each dwi volume.  Should be a 1xN vector where N 
%           is the number of volumes
% 
% Web Resources:
%           mrvBrowseSVN('dwiCreate')
% 
% Example:
%      >> dwi = dwiCreate('nifti','dwi.nii.gz','bvecs','dwi.bvecs','bvals','dwi.bvals');
%          dwi = 
%           name: 'Default dwi'
%           type: 'dwi'
%           nifti: [1x1 struct]
%           bvecs: [87x3 double]
%           bvals: [87x1 double]
% 
% See Also:
%           dwiGet.m ; dwiSet.m ; dwiLoad
% 
% 
% (C) Stanford University, VISTA Lab [2011]
%

% PROGRAMMING TODO
%  9/25 Simplify.  Just create the structure.  Don't do all the other stuff.
%  Model it after the other create functions. (BW)
%  9/26 - Now all the data loading is done from within dwiLoad (lmp)


%% Create dwi structure

dwi.name  = 'Default dwi'; 
dwi.type  = 'dwi';
dwi.nifti = [];
dwi.bvecs = [];
dwi.bvals = [];
dwi.files = {};
dwi.files.nifti = {};
dwi.files.bvecs = {};
dwi.files.bvals = {};


%% If the user has set some inputs, overwrite the defaults here

dwi = mrVarargin(dwi,varargin); 


return

%% OLD CODE

% %% Try to get the names from this directory
% % 
% % nifti = dir('*.nii.gz');
% % bvecs = dir('*.bvec*');
% % bvals = dir('*.bval*');
% % 
% % if ~isempty(nifti) && numel(nifti(:,1)) == 1
% %     dwi.nifti = nifti.name;
% % end
% % if ~isempty(bvecs) && numel(bvecs(:,1)) == 1
% %     dwi.bvecs = bvecs.name;
% % end
% % if ~isempty(bvals) && numel(bvals(:,1)) == 1
% %     dwi.bvals = bvals.name;
% % end
% 
% 
% %% If the user provided file names load the data here
% % % Maybe we don't want to do this either. This functionality exists in
% % % dwiLoad, which can be called to load the data. That would be ideal
% % % because there should only be one place where we load the data. 
% % 
% % if ~isempty(dwi.nifti) && exist(dwi.nifti,'file')
% %     dwi.nifti = niftiRead(dwi.nifti);
% %     if strfind(dwi.name,'Default') ==1
% %         dwi.name  = dwi.nifti.fname;
% %     end
% % end
% % 
% % if ~isempty(dwi.bvecs) && exist(dwi.bvecs,'file')
% %     dwi.bvecs = dlmread(dwi.bvecs);
% % end
% % 
% % if ~isempty(dwi.bvals) && exist(dwi.bvals,'file')
% %     dwi.bvals = dlmread(dwi.bvals);
% % end
% % 
% % % If we loaded bvals and bvecs check that they're in the proper format.
% % if ~ischar(dwi.bvecs) && ~ischar(dwi.bvals) && ~isempty(dwi.bvecs) && ~isempty(dwi.bvals)
% %     [dwi.bvecs,dwi.bvals] = dwiCheckBvecsBvals(dwi.bvecs,dwi.bvals,dwi.nifti);
% % end
% % 
% % return
% 

