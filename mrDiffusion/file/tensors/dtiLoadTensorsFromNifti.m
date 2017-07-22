function [dt6, xformToAcpc, mmPerVoxel, fileName, desc, intentName] = dtiLoadTensorsFromNifti(ni)
%Load a dt6 (tensor) data file in mrDiffusion format from NIFTI format.
%
%  [dt6, xformToAcpc, mmPerVox, fileName, desc, intentName] = dtiLoadTensorsFromNifti(niFile)
%   
% The six entries are the diffusion tensor values, derived from the raw
% data.  The raw data can be in many different directions.  The diffusion
% tensor is a 3x3 positive-definite matrix, D.  The entries in the matrix
% are stored in a vector: 
%
%    Dxx Dyy Dzz Dxy Dxz Dyz
%
% or equivalently
%
%    D(1,1), D(2,2), D(3,3), D(1,2), D(1,3), D(2,3)
%
% HISTORY:
%  2007.10.04 AJS: Wrote it.
%
% (c) Stanford VISTA Team

if(~exist('ni','var')||isempty(ni))
    [f,p] = uigetfile({'*.nii.gz';'*.*'},'Select a NIFTI tensor file...');
    if(isnumeric(f)), disp('User canceled.'); return; end
    ni = fullfile(p,f); 
end

if(ischar(ni))
    if exist(ni,'file'), ni = niftiRead(ni);
    else error('Can not find file %s\n',ni);
    end
end

fileName = ni.fname;

% We convert from the 5d, lower-tri row order NIFTI tensor format used by
% other groups, such as FSL, which stores (x,y,z,1,directions)
%    direction ordering:  (Dxx Dxy Dyy Dxz Dyz Dzz)
%
% to our 4d tensor format, (x,y,z,directions)
%    direction ordering: (Dxx Dyy Dzz Dxy Dxz Dyz).
%
dt6 = double(squeeze(ni.data(:,:,:,1,[1 3 6 2 4 5])));
xformToAcpc = ni.qto_xyz;
mmPerVoxel = ni.pixdim(1:3);
desc = ni.descrip;
intentName = ni.intent_name;

return
