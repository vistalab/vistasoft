function mr = mrReadDicom(pth, dims, sz, interleave);
%
% mr = mrReadDicom(pth, [dims], [sz], [interleave]);
%
% Read a single DICOM file into the mr struct format. Uses built-in
% MATLAB dicomread and dicominfo functions.
%
% If pth is a file pattern, can read and concatenate several
% files together. In this case, the DIMS and SZ arguments specify how to
% concatenate the files:
%
% * If you want to concatenate across a single dimension, input the
% dimension in DIMS: e.g., 3 for slices, 4 for time points.
%
% * If you want to concatenate across multiple dimensions (e.g., both
% slices and time points), indicate the dimensions as a vector in DIMS, and
% the size of each dimension in SZ.
% E.g., if there are 25 slices and 4 time points, use:
% mr = mrReadDicom(pth, [3 4], [25 4]);
%
% ras, 10/2007.
if notDefined('dims'),			dims = [];			end
if notDefined('sz'),			sz = [];			end
if notDefined('interleave'),	interleave = 0;		end


%% init mr struct
[p f ext] = fileparts(pth);
mr = mrCreateEmpty;
mr.path = pth;
mr.name = f;
mr.format = 'dicom';


%% Read in the data and mr.hdr
if isempty(dims)
	%% single slice
	mr.data = dicomread(pth);
	mr.hdr = dicominfo(pth);

else
	% search for file pattern
	w = dir(pth);
	nFiles = length(w);
	
	if nFiles==0
		error( sprintf('No files matching pattern: %s', pth) )
	end

	% get mr.hdr info from first file
	mr.hdr = dicominfo( fullfile(p, w(1).name) );

	% get data
	if length(dims)==1
		%% concat along single dimension
		for ii = 1:nFiles
			filePath = fullfile(p, w(ii).name);
			mr.data = cat(dims, mr.data, dicomread(filePath));
		end

	else
		%% concat along multiple dimensions
		% size checks
		if isempty(sz)
			error('Need to specify size along each dimension.')
		end

		if nFiles < prod(sz)
			msg = sprintf('Not enough files %i specified, %i exist.', ...
				prod(sz), nFiles);
			error(msg)
		end

		% loop across dims
		% (lame way: I assume there are exactly 2 dimensions;
		% I'll worry about generalizing if it ever comes up)
		for jj = 1:sz(2)
			subVol = [];
			for ii = 1:sz(1)
				cnt = (jj - 1) * sz(1) + ii;
				filePath = fullfile(p, w(cnt).name);
				subVol = cat(dims(1), subVol, dicomread(filePath));
			end

			mr.data = cat(dims(2), mr.data, subVol);
		end

	end
end


%% get important resolution and size fields
mr.dims = size(mr.data);
for ii = length(mr.dims)+1:4   % ensure length 4
	mr.dims(ii) = 1;
end
if isfield(mr.hdr, 'SpacingBetweenSlices')
	% this takes into account inter-slice gaps in the acquisition
	sliceThickness = mr.hdr.SpacingBetweenSlices;
elseif isfield(mr.hdr, 'SliceThickness')
	sliceThickness = mr.hdr.SliceThickness;
else
	% uh-oh. Most DICOM files should have at least one of the above fields
	warning('Can''t read slice thickness. Setting to 1mm. THIS IS PROBABLY WRONG.')
	sliceThickness = 1;
end
if ~checkfields(mr, 'hdr', 'RepetitionTime'), 
    mr.hdr.RepetitionTime = 1000;
    warning('Missing field: mr.hdr.RepetitionTime. Setting to 1000 ms');
end

mr.voxelSize = [mr.hdr.PixelSpacing(:)' sliceThickness ...
				mr.hdr.RepetitionTime ./ 1000];
mr.extent = mr.dims .* mr.voxelSize;

mr.dimUnits = {'mm' 'mm' 'mm' 'sec'};
mr.dataUnits = 'T2*-Weighted Intensity';
mr.dataRange = [min(mr.data(:)) max(mr.data(:))];


%% interleave slice order if specified
% (TODO: see if this is specified in the mr.hdr so the argument is
% not necessary)
if interleave==1
	% we assume the data were collected: [odd slices, even slices]
	% we need to use SORT to find the indexing to reverse this:
	interleavedOrder = [1:2:mr.dims(3) 2:2:mr.dims(3)];
	[vals newOrder] = sort(interleavedOrder);

	% use the sorting index to reorder the slice dimension
	mr.data = mr.data(:,:,[newOrder],:);
end

%% Figure out coordinate spaces
mr.spaces = mrStandardSpaces(mr);

% build a space defining the scanner coords, where the
% xform maps from the pixCorners to the R|A|S coords of the
% the three corners from the header:
if isempty(dims)
	hdrPath = pth;
else
	hdrPath = fullfile(p, w(1).name);
end

try
	mr.spaces(end+1).name = 'Scanner';
	mr.spaces(end).xform = inv( affineScanner2Pixels(hdrPath) );
	mr.spaces(end).dirLabels = {'L <--> R' 'P <--> A'  'I <--> S'};
	mr.spaces(end).sliceLabels =  {'Sagittal' 'Coronal' 'Axial'};
	mr.spaces(end).units = 'mm';
	mr.spaces(end).coords = [];
	mr.spaces(end).indices = [];
	
	% also update the direction labels on the pixel and L/R flipped spaces,
	% using the header info:
	dirs = mrIfileDirections(hdrPath);
	for i=1:3, mr.spaces(i).dirLabels = dirs; end
	mr.spaces(3).dirLabels{2} = dimFlip(mr.spaces(3).dirLabels{2});

catch
	if prefsVerboseCheck
		warning('Couldn''t read DICOM header alignment fields.')
	end
end


%% get info fields
mr.info.scanner = mr.hdr;
mr.info.subject = [mr.hdr.PatientName.FamilyName]; % may be other fields
mr.info.subjectSex = mr.hdr.PatientSex;

% rather than checking for occasional fields like this, which are singled
% out because they produced an error at some point, we should have a
% function mrReadDicomCheckHeaders which checks for all necessary fields,
% and adds default values where needed.
if ~checkfields(mr, 'hdr', 'PatientWeight'), 
    mr.hdr.PatientWeight = 100;
    warning('Missing field: mr.hdr.PatientWeight. Setting to default value of 100. lbs(?)');
end
mr.info.subjectWeight = mr.hdr.PatientWeight;
mr.info.subjectDOB = datestr( parseDicomDate(mr.hdr.PatientBirthDate) );
[mr.info.date, mr.info.scanStart] =  ...
	parseDicomDate(mr.hdr.AcquisitionDate, mr.hdr.AcquisitionTime);

mr.info.subjectAge = datevec(mr.info.date) - datevec(mr.info.subjectDOB);

try
	mr.info.studyID = mr.hdr.StudyID;
	mr.info.subjectID = mr.hdr.PatientID;
	mr.info.facility = mr.hdr.InstitutionName;
	mr.info.scannerType = [mr.hdr.Manufacturer mr.hdr.ManufacturerModelName];
	mr.info.seriesNumber = mr.hdr.SeriesNumber;
	mr.info.protocol = mr.hdr.ProtocolName;
	mr.info.coil = sprintf('Transmit: %s, Receive: %s', mr.hdr.TransmitCoilName, ...
						mr.hdr.ReceiveCoilName);
catch
	if prefsVerboseCheck
		warning('Couldn''t read all DICOM mr.hdr fields.')
	end
end



return