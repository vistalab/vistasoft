function rx = rxInit(vol,ref,varargin);
%
% rx = rxInit(vol,ref,[options]);
%
% Initialize the rx struct for mrRx. 
%
% Several decisions are made at this stage:
%
% The size of the rx is decided based on
% whether a reference volume is supplied or
% not. If a reference volume is provided, the
% rx is an imaginary box the same size and
% resolution as the reference volume, which can
% be moved around the xformed volume vol. If it's
% omitted (or empty), the rx is the same size/res
% as the xformed volume. (So it's like you're just
% moving the xformed volume around). Optional
% input arguments can override these settings:
%
% rxRes, [value]: specify the size of voxels in the prescription, in
%                 mm, as a 1x3 vector.
% volRes, [value]: specify the size of voxels in the prescribed volume,
%                  in mm, as a 1x3 vector.
% refRes, [value]: specify the size of voxels in the reference volume,
%                  in mm, as a 1x3 vector.
% rxDims, [value]: specify the dims (# of voxels -- rows cols slices)
%                  for the prescription.
% rxSizeMM, [value]: specify the total size of the prescription in mm.
%                   This is overridden if rxDims is specified. 
%
% Note these parameters can be used to specify vol
% and ref as being at different resolutions, and the
% prescription at a third resolution.
%
%
% 02/05 ras.

%%%%% params/defaults
volVoxelSize = [1 1 1];
refVoxelSize = [1 1 1];
rxVoxelSize = [];
rxDims = [];
rxSizeMM = [];

%%%%% parse the option flags
% we got the varargin from another function;
% we need to un-nest the cells
varargin = unNestCell(varargin);

for i = 1:length(varargin)
    if ischar(varargin{i})
        switch lower(varargin{i})
            case {'rxres','rxvoxelsize'},
                rxVoxelSize = varargin{i+1};
            case {'volres','volvoxelsize'},
                volVoxelSize = varargin{i+1};
            case {'refres','refvoxelsize'},
                refVoxelSize = varargin{i+1};
            case {'rxdims'},
                rxDims = varargin{i+1};
            case {'rxsizemm'},
                rxSizeMM = varargin{i+1};
        end

    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% init fields of rx struct %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% these fields are included for possible use of
% older mrVista view-based functions:
rx.name = 'mrRx';
rx.refreshFn = 'rxRefresh';

% these fields contain information
% about the theoretical box for the
% prescription. Empty for now,
% will be decided below:
rx.rxDims = [];      % dimensions of rx box in voxels
rx.rxVoxelSize = []; % size of voxel in mm
rx.rxSizeMM = [];    % total size of rx box in mm

% required fields for user interface
% handles:
rx.ui.controlFig = [];
rx.ui.rxFig = [];
rx.ui.interpFig = [];
rx.ui.refFig = [];
rx.ui.compareFig = [];
rx.ui.ssFig = []; 
rx.ui.controlAxes = [];
rx.ui.rxAxes = [];
rx.ui.interpAxes = [];
rx.ui.refAxes = [];
rx.ui.compareAxes = [];
rx.ui.ssAxes = []; 


% fill in the main field: the volume to be prescribed
% unfortunately, this seems to require a double-precision matrix
% (the myCinterp3 function used in interpolating requires it; if
% we could support uint8 or single types, we would save a lot of memory and
% not lose a lot of precision):
rx.vol = double(vol);  

% these fields contain info about
% the transformed volume and 
% reference volume:
rx.volDims = size(vol);
rx.volSizeMM = [];
rx.volVoxelSize = volVoxelSize;
rx.nVolSlices = size(vol,3);
rx.ref = ref;
rx.refDims = size(ref);
if length(rx.refDims) < 3, rx.refDims(3) = 0; end
rx.refSizeMM = [];
rx.refVoxelSize = refVoxelSize;
rx.nRefSlices = size(ref,3);

% create a slot for ROIs, in case we want to visualize these:
rx.rois = struct('name', '', 'volCoords', [], 'color', []);
rx.rois = rx.rois([]); % no entries


% fields related to prefs
% on how to compute things:
rx.sampleSpacing = 1; % spacing of pixels in viewed interp slice

% this field is the main output
% of the program, the 4x4 xform matrix:
rx.xform = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get estimated sizes in mm %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
volSizePix = size(vol);
if size(vol,3)==1
    volSizePix(3) = 1; % size omits this otherwise
end
rx.volSizeMM = volSizePix .* volVoxelSize;

refSizePix = size(ref);
if size(ref,3)==1
    refSizePix(3) = 1; % size omits this otherwise
end
rx.refSizeMM = refSizePix .* refVoxelSize;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% decide size of rx based on input args %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% only if it hasn't been provided by
% an optional input argument
if isempty(rxDims) & isempty(rxSizeMM) & isempty(rxVoxelSize)
    if isempty(ref)
		% lacking any information, rx matches the volume.
        rxDims = size(vol); rxDims(3) = size(vol,3); % force read dim 3.
		rxSizeMM = rx.volSizeMM;
        rxVoxelSize = rx.volVoxelSize;
	else
		% inherit rx dimensions from reference 
        rxDims = size(ref); rxDims(3) = size(ref,3); % force read dim 3.
		rxSizeMM = rx.refSizeMM;
        rxVoxelSize = rx.refVoxelSize;
	end
elseif ~isempty(rxVoxelSize)
	if isempty(rxDims)
		rxDims = size(vol);
		rxDims(3) = size(vol, 3); % force read dim 3
	end
	rxSizeMM = rxDims .* rxVoxelSize;	
elseif ~isempty(rxDims)
    rxSizeMM = rxVoxelSize .* rxDims;
elseif ~isempty(rxSizeMM)
    rxDims = rxSizeMM ./ rxVoxelSize;
end

rx.rxDims = rxDims;
rx.rxSizeMM = rxSizeMM;
rx.rxVoxelSize = rxVoxelSize;
    

return
