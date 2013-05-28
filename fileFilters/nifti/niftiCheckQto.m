function ni = niftiCheckQto(ni)
% Changes the qto_* or/and sto_* fields in the NIFTI hearder if nt properly
% set. Also changesother fields see below.
% 
%   ni = niftiCheckQto(ni)
%
% We expect these fields to be set at some coordinates inside the image
% volume. If the NIFTI file was created without setting these files this
% function starts up the fields by setting the center of the coordinate
% system of the image to the middle of the image.
%
% Does a simple sanity-check on the xform. Right now, we check the origin to
% make sure it is well- within the image volume. If not, the qto xform
% fields of the NIFTI struct ni will be adjusted to set the origin to the
% center of the image. The updated struct is returned and a message is
% printed to the command line indicating the fix. 
%
% it will update the follwing fields:
%  'qform_code'
%  'qto_xyz'
%  'qto_ijk'
%  'quatern_b'
%  'quatern_c'
%  'quatern_d'
%  'qoffset_x'
%  'qoffset_y'
%  'qoffset_z'
%  'qfac'
%  'pixdim'
%
% (c) Stanford Vista Team 2012

if(isfield(ni,'data')&&~isempty(ni.data))
    % sanity-check ni.dim
    sz = size(ni.data);
    if(any(ni.dim(1:3)~=sz(1:3)))
        fprintf('[%s] NIFTI volume dim wrong- setting it to the actual data size.',mfilename);
        ni.dim(1:3) = sz(1:3);
    end
end

if(ni.qform_code==0 && ni.sform_code~=0)
    fprintf('[%s] ni.qform_code is zero and sform_code ~=0. Setting ni.qto_* from ni.sto_*...',mfilename);
    ni = niftiSetQto(ni, ni.sto_xyz);
end

origin = [ni.qto_ijk(1:3,:)*[0 0 0 1]']';
if(any(origin<2)||any(origin>ni.dim(1:3)-2))
  [t,r,s,k] = affineDecompose(ni.qto_ijk);
  t = ni.dim/2;
  fprintf('[%s] NIFTI header origin is at or outside the image volume.\n',mfilename)
  fprintf('[%s] Origin to the image center [%2.3f,%2.3f,%2.3f] pix.\n',mfilename,t(1),t(2),t(3));
  ni = niftiSetQto(ni, inv(affineBuild(t,r,s,k)));
end

return;