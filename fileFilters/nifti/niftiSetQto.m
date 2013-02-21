function ni = niftiSetQto(ni, xformXyz, setStoToo)
%  Set the qto transform fields in the nifti struct ni
%
% ni = niftiSetQto(ni, xformXyz, [setStoToo=false])
%
% it will update the following fields:
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
%
% (c) Stanford Vista Team 2012

% HISTORY:
% 2007.05.16 RFD: wrote it.
% 2008.08.24 RFD: pixdim is now properly set if the scale factors change
%                 and/or the dims are permuted.
% 2013.02.07  AS: updated to use niftiGet and niftiSet

q = matToQuat(xformXyz);
%ni.qform_code = 2;
ni = niftiSet(ni,'qform_code',2); %Hardcoded, just like before

%ni.qto_xyz = xformXyz;
ni = niftiSet(ni,'qto_xyz',xformXyz);

%ni.qto_ijk = inv(xformXyz);
ni = niftiSet(ni,'qto_ijk',inv(xformXyz));

%ni.quatern_b = q.quatern_b;
ni = niftiSet(ni,'quatern_b',q.quatern_b);

%ni.quatern_c = q.quatern_c;
ni = niftiSet(ni,'quatern_c ',q.quatern_c);

%ni.quatern_d = q.quatern_d;
ni = niftiSet(ni,'quatern_d',q.quatern_d);

%ni.qoffset_x = q.quatern_x;
ni = niftiSet(ni,'qoffset_x',q.quatern_x);

%ni.qoffset_y = q.quatern_y;
ni = niftiSet(ni,'qoffset_y',q.quatern_y);

%ni.qoffset_z = q.quatern_z;
ni = niftiSet(ni,'qoffset_z',q.quatern_z);

%ni.qfac = q.qfac;
ni = niftiSet(ni,'qfac',q.qfac);

%Pixdims are no longer set here. It is instead set outside of this function
%newPixDim = niftiGet(ni,'pixdim');
%newPixDim(1:3) = [q.dx q.dy q.dz];
%ni = niftiSet(ni, 'pixdim', newPixDim); 

if(exist('setStoToo','var')&&~isempty(setStoToo)&&setStoToo)
  %ni.sto_xyz = ni.qto_xyz;
  %ni.sto_ijk = ni.qto_ijk;
    ni = niftiSet(ni,'sto_xyz',niftiGet(ni,'qto_xyz'));
	ni = niftiSet(ni,'sto_ijk',niftiGet(ni,'qto_ijk'));

end

return;
