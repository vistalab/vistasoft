function fixScaleFac
%
% Fixes scaleFac, enablin you to redo an alignment.
%
% Loads bestrotvol
% Loads mrSESSION to get inplane pixel size
% Loads vAnatomy header to get volume pixel size
% Modifies scaleFac
% Resaves bestrotvol
%
% djh, 8/2001

load bestrotvol
load mrSESSION
vAnatPath = getvAnatomyPath(mrSESSION.subject);
[volume,mmPerPix,volSize] = readVolAnat(vAnatPath);
volume_pix_size = 1./mmPerPix;
% This only works in mrLoadRet3
% inplane_pix_size = 1./mrSESSION.inplanes.voxelSize;
% scaleFac = [inplane_pix_size;volume_pix_size];
scaleFac(2,:) = volume_pix_size;

save bestrotvol inpts rot scaleFac trans volpts
