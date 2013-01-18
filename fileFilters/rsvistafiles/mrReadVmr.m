function mr = mrReadVmr(pth);
%
% mr = mrReadVmr(pth);
%
% Read a BrainVoyager .vmr format file. Stub code.
%
% ras, 01/2007.
if ~exist(pth, 'file')
    error( sprintf('%s not found. ', pth) );
end

mr = mrCreateEmpty;

fid = fopen(pth,'r','l');

mr.dims(1) = fread(fid,1,'uint16');
mr.dims(2) = fread(fid,1,'uint16');
mr.dims(3) = fread(fid,1,'uint16');

[mr.data] = fread(fid,prod(mr.dims) ,'uint8');
mr.data = reshape(mr.data, mr.dims);

fclose(fid);

[p f ext] = fileparts(pth);
mr.name = f;
mr.format = 'vmr';
mr.path = pth;

mr.voxelSize = [1 1 1]; % assume, haven't figured out how to read this..
mr.extent = mr.dims .* mr.voxelSize; 

%%%%%spaces
mr.spaces = mrStandardSpaces(mr);

mr.spaces(end+1).name = 'R|A|S';
mr.spaces(end).xform = eye(4);
mr.spaces(end).dirLabels =  {'R <--> L' 'A <--> P' 'S <--> I'};
mr.spaces(end).sliceLabels = {'Sagittal' 'Coronal' 'Axial'};
mr.spaces(end+1) = mr.spaces(end);

mr.spaces(end).name = 'I|P|R';
mr.spaces(end).xform = ras2ipr(mr.spaces(end-1).xform, mr.dims);
mr.spaces(end).dirLabels =  {'S <--> I' 'A <--> P' 'L <--> R'};
mr.spaces(end).sliceLabels = {'Axial' 'Coronal' 'Sagittal'};


return
