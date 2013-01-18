function rx = mrRx(vol,ref,varargin)
%
% rx = mrRx([vol],[referenceVol],[options]):
%
% A GUI to create, edit, and save 4 x 4 transformations to apply
% to volume matrices. Can be used to coregister a volume to a
% reference volume, evaluate motion and motion correction, and
% perform motion correction.
%
% vol: a 2D or 3D matrix (4D support may come later).
%
% referenceVol: Another volume, which is not transformed,
% to which the first volume may be compared.
% 
% The reference volume need not be the same size as the
% transformed volume. But, it will be assumed they're at 
% the same resolution, unless the 'volRes' or 'refRes' options
% are applied. 
%
% Both vol and referenceVol can be supplied as strings specifying
% paths to volume files. Can load volumes in any of the formats
% supported by loadVolume (type help loadVolume for a list). This
% includes vAnatomy .dat, analyze .img, I-files, DICOM, and others.
%
% If invoked without input arguments, just opens the control
% window, from which transformed and reference volumes
% can be loaded with dialogs.
%
% Returns rx,a struct with info about the UI state, similar to a view.
% The key field in rx is rx.xform, which specifies a 4x4 affine
% transformation matrix to transform coordinates in the rx to coordinates
% in the volume. That is:
%   volCoords = rx.xform * rxCoords;
% though these transformations can be properly accessed with the functions
% rx2vol and vol2rx.
%
% Options:
% rxRes, [1 x 3 matrix]: specify the size of voxels in the prescription, in
%                 mm, as a 1x3 vector.
% volRes, [1 x 3 matrix]: specify the size of voxels in the prescribed volume,
%                  in mm, as a 1x3 vector.
% refRes, [1 x 3 matrix]: specify the size of voxels in the reference volume,
%                  in mm, as a 1x3 vector.
% rxDims, [1 x 3 matrix]: specify the dims (# of voxels -- rows cols slices)
%                  for the prescription.
% rxSizeMM, [1 x 3 matrix]: specify the total size of the prescription in mm.
%                   This is overridden if rxDims is specified. 
%
% Note these parameters can be used to specify vol
% and ref as being at different resolutions, and the
% prescription at a third resolution.
%
% 02/17/05 ras.
if notDefined('vol')
    vol = [];
elseif ischar(vol)
    [vol volVoxelSize] = loadVolume(vol); %,'reorient');
	varargin = [varargin {'volRes' volVoxelSize}];
end

if notDefined('ref')
    ref = [];
elseif ischar(ref)
    ref = loadVolume(ref); %,'reorient');
end

% initialize the rx struct
rx = rxInit(vol, ref, varargin);

% open the main control figure:
rx = rxOpenControlFig(rx);

if ~isempty(vol)
    rx = rxOpenInterpFig(rx);
end

if ~isempty(ref)
    rx = rxOpenRefFig(rx);
end

% add rx as user data in control fig
set(rx.ui.controlFig,'UserData',rx);

rxRefresh(rx,1);

return
