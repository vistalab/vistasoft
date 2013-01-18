function roi = roiCreate(reference,coords,varargin)
% Create an ROI for an MR object. [May want to add distinct
% function for creating mesh ROIs, though it seems they may
% rather be Xformed from mrMesh...?]
%
%  roi = roiCreate(reference,coords,'Property',[value],...)
%
% Inputs: 
% reference: can be either a string specifying a space type
%   (see mrFormatDescription for some possible spaces) or an
%   mr object. 
%
%   If it is a string, the ROI can only be processed
%   by mr objects which have that space defined in their spaces
%   fields, and the coordinates will be transformed into the
%   data space of each MR object as needed.
%
%   If it is an mr object,
%   the coords will be considered to refer to rows, columns, and
%   slices in the mr.data field, and can be xformed to other mr objects
%   which share a common space definition with the reference MR object.
%
% coords: 3xN array (integer or double) in which different columns
%   represent different coordinates/voxels in the reference space.
%   The rows describe [Y X Z] in that space: that is the first row of
%   coords describes the rows in each space, the second row describes
%   columns, and the third describes slices. If omitted, coords are
%   left empty.
%   
% Properties are:
%   'name',[string]: specify a name for the ROI. 
%   'color',[char or [R G B]]: specify a color [default 'b', blue]
%   'referenceMR',[mr]:  mr object on which the ROI has been defined (for when
%       defining with reference to an xformed space -- e.g, if defined
%       on a talairached volume anatomy)
%    'type':  ROI types include:
%               'volume': volume of interest, usually defined on an MR object
%               'patch': 2D patch, usually defined on a surface mesh
%               'line': 1D line, e.g. AC/PC line, or isoeccentricity line
%               'point': single 0D point, e.g. AC or PC, center of a volume ROI
% Wandell and ras, 2005
% ras, 2006: removed requirement for a reference space. Can just return an
% empty ROI.

if notDefined('reference'), reference = 'Raw Data in Pixels'; end
if notDefined('coords'), coords = []; end

%%%%%create a blank ROI
roi.name = 'New ROI';
roi.type = 'volume';
roi.reference = ''; % coordinate space on which ROI is defined
roi.coords = coords;
roi.space = '';
roi.referenceMR =[]; % MR object on which ROI is defined
roi.definedCoords = coords; % coords on which ROI was initially defined
roi.voxelSize = [];  % size of voxels for coords
roi.dimUnits = {'mm' 'mm' 'mm'};
roi.color = 'b';     % can be [R G B] or 'c' -- here 'b'=blue
roi.fillMode = 'perimeter'; % 'perimeter', 'filled', 'patches'
roi.viewType = 'Inplane'; % default: should be over-ridden later
roi.created = datestr(clock);  % permanent stamp on when ROI is created
roi.modified = datestr(clock); % stamp on date of last ROI modification
roi.comments = '';
roi.local = 'local'; % save in local or shared directory

%%%%%parse reference space
if ischar(reference)
    roi.reference = reference;
    
elseif isstruct(reference)
    roi.reference = 'Pixel Space';
    roi.referenceMR.name = reference.name;
    roi.referenceMR.path = reference.path;
    roi.referenceMR.voxelSize = reference.voxelSize;
    roi.referenceMR.dims = reference.dims;
    roi.referenceMR.extent = reference.extent;
    roi.referenceMR.spaces = reference.spaces;
    
end

%%%%%parse properties
for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'name', roi.name = varargin{i+1};
        case 'color', roi.color = varargin{i+1};
        case 'referencemr', roi.referenceMR = varargin{i+1};
        case 'type', roi.type = varargin{i+1};
		case 'voxelsize', roi.voxelSize = varargin{i+1};
        otherwise, % quietly ignore
    end
end


%%%%%if an mr struct is provided, get the voxel size from it
if ~isempty(roi.referenceMR)
	if ischar(roi.referenceMR), hdr = mrLoadHeader(roi.referenceMR);
	else,						hdr = roi.referenceMR;
	end
	roi.voxelSize = hdr.voxelSize;
end


return;