function [XformFlipped,rot,trans,scaleFac] = coarseFromIfile(subject)
% 
% coarseFromIfile - This function determines the rotation, translation, scale factor, and
%                   4x4 transform that map inplane pixel coordinates into volume pixel
%                   coordinates.
%
%   USAGE: [Xform,rot,trans,scaleFac] = coarseFromIfile(subject)
%
%   HISTORY:    7.15.2002 - Sunjay Lad (slad@stanford.edu) - wrote it


global HOMEDIR
global mrSESSION

% %%%% how it will eventualy work %%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% % get data from Analyze header and reconstruct 4x4
% 
% % Specifies the directory of the inplane Ifiles
% ifileDir =fullfile(HOMEDIR,'Raw','Anatomy','Inplane','I');
% 
% % Extracts the header info from the first inplane Ifile
% [su_hdr1,ex_hdr1,se_hdr1,im_hdr1] = GE_readHeader([ifileDir,'.001']);
% 
% % Locates the last inplane Ifile and extracts its header info
% d = dir([ifileDir,'*']);
% nSlices = length(d);
% [su_hdr2,ex_hdr2,se_hdr2,im_hdr2] = GE_readHeader([ifileDir,sprintf('.%03d',nSlices)]);
% 
% [rot2,trans2,scaleFac2,inplane_Xform] = scanner2Pixel(im_hdr1,im_hdr2,nSlices);
% 
% % 4x4 transform from inplane pixel coords -> volume pixel coords
% Xform = volume_Xform / inplane_Xform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Finds location of vAnatomy Ifiles
vAnatIfilePath = getvAnatomyIfilePath(subject);

% 4x4 transform from inplane GE scanner coords -> inplane pixel coords
[inplane_Xform,inplane_mmPerVox] = XformFromIfile(fullfile(HOMEDIR,'Raw','Anatomy','Inplane','I'),'inplane');

% 4x4 transform from volume GE scanner coords -> volume pixel coords
[volume_Xform,volume_mmPerVox] = XformFromIfile(fullfile(vAnatIfilePath,'I'),'volume');

% 4x4 transform from inplane pixel coords -> volume pixel coords
Xform = volume_Xform / inplane_Xform;

% Flip first 2 rows and cols so that it deals with (y,x,z) coords instead of (x,y,z)
XformFlipped = Xform;
XformFlipped([1 2],:) = XformFlipped([2 1],:);
XformFlipped(:,[1 2]) = XformFlipped(:,[2 1]);

% compile the scale factors (voxels per mm) for inplane and volume anatomies
inplane_vox_size = 1./inplane_mmPerVox;
volume_vox_size = 1./volume_mmPerVox;
scaleFac = [inplane_vox_size; volume_vox_size];

% compute rot and trans from 4x4
b = (Xform(1:3,4))';
A = Xform(1:3,1:3);
trans = b ./ scaleFac(2,:);
rot = diag(scaleFac(2,:)) \ A / diag( 1./scaleFac(1,:));

msgbox('Coarse alignment data successfully extracted');