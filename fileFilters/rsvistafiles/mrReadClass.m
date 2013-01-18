function mr = mrReadClass(pth, voxelSize)
%
%  mr = mrReadClass(pth, [voxelSize=[1 1 1]]);
%
% Reads in a mrGray .class file as a mrVista 2.0 mr object. 
%
% The optional voxelSize argument specifies the size of the voxel in mm.
% (This is usually inherited from an associated vAnatomy.dat file, which
% can't be guessed based only on the file path.) If omitted, the code
% assumes the class file is 1x1x1 mm iso-voxel.
%
% ras, 07/08/05.
if notDefined('voxelSize')
	voxelSize = [1 1 1 1];
else
	voxelSize(4) = 1; % ensure we have 4 elements
end

[p f ext] = fileparts(pth);

% init mr struct
mr = mrCreateEmpty;
[ignore mr.name] = fileparts(p);
mr.path = pth;
mr.format = 'class';
mr.dimUnits = 'mm';
mr.dataUnits = 'Tissue Classification';

% read the class file
class = readClassFile(pth, 0, 0);
mr.data = class.data;
mr.voxelSize = voxelSize;
mr.dims = [size(mr.data) 1];
mr.extent = mr.dims .* mr.voxelSize;  

% parse header info
class = rmfield(class, 'data');
mr.hdr = class;
mr.spaces = mrStandardSpaces(mr);

% the class data are stored in P|I|R orientation rather than I|P|R. So,
% permute:
mr.data = permute(mr.data, [2 1 3]);
mr.voxelSize = mr.voxelSize([2 1 3]);
mr.dims = mr.dims([2 1 3]);
mr.extent = mr.extent([2 1 3]);
mr.hdr.header.voi = mr.hdr.header.voi([3 4 1 2 5 6]);
mr.hdr.header.xsize = mr.dims(1);
mr.hdr.header.ysize = mr.dims(2);

% add spaces    
mr.spaces(1).name = 'I|P|R';
mr.spaces(1).xform = eye(4);
mr.spaces(1).dirLabels =  {'S <--> I' 'A <--> P' 'L <--> R'};
mr.spaces(1).sliceLabels =  {'Axial' 'Coronal' 'Sagittal'};
mr.spaces(1).units = 'mm';
mr.spaces(1).coords = [];
mr.spaces(1).indices = [];

mr.spaces(2).name = 'R|A|S';
mr.spaces(2).xform = ipr2ras(mr.spaces(1).xform, mr.dims(1:3), mr.voxelSize(1:3));
mr.spaces(2).dirLabels =  {'L <--> R' 'P <--> A' 'I <--> S'};
mr.spaces(2).sliceLabels =  {'Sagittal' 'Coronal' 'Axial'};
mr.spaces(2).units = 'mm';
mr.spaces(2).coords = [];
mr.spaces(2).indices = [];    


% pre-pend standard space definitions
mr.spaces = [mrStandardSpaces(mr) mr.spaces];


return
