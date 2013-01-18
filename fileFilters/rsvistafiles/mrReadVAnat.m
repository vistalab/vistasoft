function mr = mrReadVAnat(pth)
% Read a mrGray vAnatomy .dat file into an mr struct.
%
% mr = mrReadVAnat([path to file])
%
% Loads the vAnatomy.dat file specified by fileName (full path!)
% into the [rows,cols,planes] image cube 'img'.
%
% If fileName is omitted, a get file dialog appears.
%
% RETURNS:
%   * img is the [rows,cols,planes] intensity array
%   * mmPerPix is the voxel size (in mm/pixel units)
%   * fileName is the full-path to the vAnatomy.dat file. (If 
%     you pass fileName in, you obviously don't need this. But 
%     it may be useful when the user selects the file.)
%
% ras, 06/30/05: imported into mrVista 2.0 Test repository.

% initialize mr struct
[p f ext] = fileparts(pth);
mr = mrCreateEmpty;
mr.format = 'vanat';
mr.pth = pth;
mr.name = f;

[mr.data, mr.voxelSize, mr.dims] = readFileVAnat(pth);        
mr.data = double(mr.data);
mr.spaces = mrStandardSpaces(mr);

% based on the usual format of vAnatomy files, we can
% label the directions in the pixel space with a good guess:
mr.spaces(1).dirLabels = {'S <--> I'  'A <--> P'  'L <--> R'};
mr.spaces(1).sliceLabels =  {'Axial' 'Coronal' 'Sagittal'};
mr.spaces(2).dirLabels = {'S <--> I'  'A <--> P'  'L <--> R'};
mr.spaces(2).sliceLabels =  {'Axial' 'Coronal' 'Sagittal'};


mr.spaces(end+1) = mr.spaces(2); % add I|P|R space
mr.spaces(end).name = 'I|P|R';

mr.spaces(end+1) = mr.spaces(end);
mr.spaces(end).name = 'R|A|S';
mr.spaces(end).dirLabels =  {'L <--> R' 'P <--> A' 'I <--> S'};
mr.spaces(end).sliceLabels =  {'Sagittal' 'Coronal' 'Axial'};
mr.spaces(end).xform = ipr2ras(mr.spaces(4).xform,mr.dims,mr.voxelSize);

mr.dimUnits = {'mm' 'mm' 'mm' 'sec'};
mr.dataUnits = 'Scaled T1 Intensity';


return
