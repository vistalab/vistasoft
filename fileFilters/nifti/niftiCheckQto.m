function ni = niftiCheckQto(ni)
% Changes the qto_* or/and sto_* fields in the NIFTI hearder if not properly
% set. Also changes other fields see below.
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

% if(isfield(ni,'data')&&~isempty(niftiGet(ni, 'data')))
%     % sanity-check ni.dim
%     sz = size(niftiGet(ni, 'data'));
%     if(any(ni.dim(1:3)~=sz(1:3)))
%         fprintf('[%s] NIFTI volume dim wrong- setting it to the actual data size.\n',mfilename);
%         ni.dim(1:3) = sz(1:3);
%     end
% end

if(niftiGet(ni, 'qform_code')==0 && niftiGet(ni, 'sform_code')~=0)
    fprintf('[%s] ni.qform_code is zero and sform_code ~=0. Setting ni.qto_* from ni.sto_*...\n',mfilename);
    ni = niftiSetQto(ni, niftiGet(ni, 'sto_xyz'));
end

qto_ijk = niftiGet(ni, 'qto_ijk');
origin = [qto_ijk(1:3,:)*[0 0 0 1]']';

nidim = niftiGet(ni, 'dim');
if(any(origin<2)||any(origin>nidim(1:3)-2))
  [t,r,s,k] = affineDecompose(qto_ijk);
  t = nidim/2;
  fprintf('[%s] NIFTI header origin is at or outside the image volume.\n',mfilename)
  fprintf('[%s] Origin to the image center [%2.3f,%2.3f,%2.3f] pix.\n',mfilename,t(1),t(2),t(3));
  ni = niftiSetQto(ni, inv(affineBuild(t,r,s,k)));
end

return;