function mr = mrReadNifti(pth)
%
% mr = mrReadNifti(pth)
%
% Read a NIFTI format file using Bob's code,
% and parse the header fields into a format
% compatible with mrVista mr objects.
%
%
% ras 07/02/05. 
mr = mrCreateEmpty;

% note 08/2008: the niftiRead MEX file doesn't work for some
% combinations of operating system / MATLAB version / CPU. Try a couple of
% things:
try
	mr.hdr = niftiRead(pth);
catch ME
    warning(ME.identifier, ME.message);
	error(['[%s]: The MEX file "niftiRead" is not working on this ' ...
             'MATLAB version'], mfilename);
	  
end

% 2011.07.26 RFD: apply the cannonical transform to handle niftis
% properly regardless of the data orientation.
mr.hdr  = niftiApplyCannonicalXform(mr.hdr);
mr.data = mr.hdr.data;
mr.hdr  = rmfield(mr.hdr,'data');

% Fix ill-specified quaternion xforms so that they do something reasonable.
if(all(mr.hdr.qto_ijk(1:3,4) == [0 0 0]'))
    sz = size(mr.data);
    mr.hdr.qto_ijk(1:3,4) = (sz(1:3)/2 + 0.5)';
    mr.hdr.qto_xyz = inv(mr.hdr.qto_ijk);
end

[p f] = fileparts(pth); %#ok<ASGLU>


% add additional mr fields
mr.name = f;
mr.path = pth;
mr.format = 'nifti';
mr.spaces = [];

mr.voxelSize = mr.hdr.pixdim; %(1:3);

mr.dims = size(mr.data);
mr.extent = mr.dims(1:3) .* mr.voxelSize(1:3);

mr.info.subject = mr.hdr.descrip;

% define R|A|S and I|P|R spaces, get any xform info present
mr.spaces(1).name = 'R|A|S';
mr.spaces(1).xform = eye(4); % will modify this below, if possible
mr.spaces(1).dirLabels =  {'L <--> R' 'P <--> A' 'I <--> S'};
mr.spaces(1).sliceLabels =  {'Sagittal' 'Coronal' 'Axial'};
mr.spaces(1).units = 'mm';
mr.spaces(1).coords = [];
mr.spaces(1).indices = [];   

% There are 3 possible methods for determining the NIFTI
% xform into canonical space: parse which format is used 
% and modify the R|A|S xform field accordingly:
% (Still needs to be done)
% http://nifti.nimh.nih.gov/pub/dist/src/niftilib/nifti1.h
if mr.hdr.qform_code==0
    % old Analyze 7.5 xform: just scale, assume data's
    % already in R|A|S space
    mr.spaces(1).xform = affineBuild([0 0 0],[0 0 0],mr.voxelSize,[0 0 0]);
elseif mr.hdr.qform_code>0
    % 2007.09.17 RFD: changed the line above from 'sform_code==0' 
	% to 'qform_code>0' and simplified the code below to simply use
    % the 4x4 xform that the nifti code computes for us from the quaternion.
% $$$     % quaternion method: tricky 
% $$$     % first, compute rotation matrix R
% $$$     % (The theory behind this code is extremely complicated
% $$$     % and is described on the NIFTI webpage above, sorry it's
% $$$     % not more transparent):
% $$$     b = mr.hdr.quatern_b;
% $$$     c = mr.hdr.quatern_c;
% $$$     d = mr.hdr.quatern_d;
% $$$     a = sqrt(1 - (b*b+c*c+d*d));
% $$$     R(1,1) = a*a + b*b - c*c - d*d;
% $$$     R(1,2) = 2*b*c - 2*a*d;
% $$$     R(1,3) = 2*b*d + 2*a*c;
% $$$     R(2,1) = 2*b*c + 2*a*d;
% $$$     R(2,2) = a*a + c*c - b*b - d*d;
% $$$     R(2,3) = 2*c*d - 2*a*b;
% $$$     R(3,1) = 2*b*d - 2*a*c;
% $$$     R(3,2) = 2*c*d + 2*a*b;
% $$$     R(3,3) = a*a + d*d - c*c - b*b;
% $$$     
% $$$     % next, use rotation, scaling, and translation
% $$$     % info to build 4 x 4 xform matrix:
% $$$     % (This is the same process as used in 
% $$$     % the old inplane2VolXform):
% $$$     scale = diag([1./mr.voxelSize].*[1 1 mr.hdr.qfac]);
% $$$     mr.spaces(1).xform = zeros(4,4);
% $$$     mr.spaces(1).xform(1:3,1:3)=R*scale;
% $$$     mr.spaces(1).xform(1:3,4)= [mr.hdr.qoffset_x; ...
% $$$                                mr.hdr.qoffset_y; ...
% $$$                                mr.hdr.qoffset_z];
% $$$     mr.spaces(1).xform(4,4)=1;
	mr.spaces(1).xform = mr.hdr.qto_xyz;
else
    % general affine transform:
    mr.spaces(1).xform = [fliplr(mr.hdr.srow_x); ...
                          fliplr(mr.hdr.srow_y); ...
                          fliplr(mr.hdr.srow_z); ...
                          1 1 1 1];
end

mr.spaces(2).name = 'I|P|R';
mr.spaces(2).xform = ras2ipr(mr.spaces(1).xform,mr.dims,mr.voxelSize);
mr.spaces(2).dirLabels =  {'S <--> I' 'A <--> P' 'L <--> R'};
mr.spaces(2).sliceLabels =  {'Axial' 'Coronal' 'Sagittal'};
mr.spaces(2).units = 'mm';
mr.spaces(2).coords = [];
mr.spaces(2).indices = [];

% pre-pend standard space definitions
mr.spaces = [mrStandardSpaces(mr) mr.spaces];

return
