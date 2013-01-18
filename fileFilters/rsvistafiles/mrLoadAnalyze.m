function mr = mrLoadAnalyze(pth);
% Load an ANALYZE 7.5-format file as a mrVista mr struct.
%
%  mr = mrLoadAnalyze(pth);
%
%
% ras, 01/06.
mr = mrCreateEmpty;

[mr.data, mr.voxelSize, mr.hdr] = mrReadAnalyzeData(pth);       
mr.dims = size(mr.data);

%% check for file with extra fields
[p f ext] = fileparts(pth);
extraFieldsFile = fullfile(p, [f '.mat']);
if exist(extraFieldsFile, 'file')
	tmp = load(extraFieldsFile);
	fields = setdiff(fieldnames(tmp), 'M');
	for i = 1:length(fields)
		field = fields{i};
		if isfield(mr, field)
			% combine the existing and additional info
			mr.(field) = mergeStructures(mr.(field), tmp.(field));
		else
			mr.(field) = tmp.(field);
		end
	end
end

%% add spaces
mr.spaces = mrStandardSpaces(mr);

mr.spaces(end+1).name = 'R|A|S';
mr.spaces(end).xform = mr.hdr.mat;
mr.spaces(end).dirLabels =  {'R <--> L' 'A <--> P' 'S <--> I'};
mr.spaces(end).sliceLabels = {'Sagittal' 'Coronal' 'Axial'};

mr.spaces(end+1) = mr.spaces(end);
mr.spaces(end).name = 'I|P|R';
mr.spaces(end).xform = ras2ipr(mr.spaces(end-1).xform, mr.dims);
mr.spaces(end).dirLabels =  {'S <--> I' 'A <--> P' 'L <--> R'};
mr.spaces(end).sliceLabels = {'Axial' 'Coronal' 'Sagittal'};


return