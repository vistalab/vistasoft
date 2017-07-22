function mr = mrReadMag(pth, t, slices);
% Read a P*.7.mag file from Gary's Recon code into 
% an mr struct.
%
% Usage: mr = mrReadMag(pth, [time points], [slices]);
%
% ras, 07/05
if notDefined('slices'),	slices = [];			end
if notDefined('t'),			t = [];					end

% init mr struct
[p f ext] = fileparts(pth);
mr = mrCreateEmpty;
mr.path = pth;
mr.name = f;
mr.format = 'pmag';

% first read header file, determine if little endian
% format needs to be used (for Lucas 3T scanner @ Stanford):
[func, mr.hdr] = mrReadMagHeader(pth);
mr.info = mr.hdr;
mr.info.scanner = '';
mr.info.subject = mr.hdr.name;
mr.info.subjectSex = '';
mr.info.subjectAge = [];
[mr.info.date, mr.info.scanStart] = parsePmagDate(mr.hdr.date, mr.hdr.time);
if (mr.info.scanStart(1)<2005) & (mr.info.scanStart(2)<3)  % GE switched from big Endian to little Endian in March 2005
    littleEndian = 0;
else
    littleEndian = 1;
end
mr.info.effectiveResolution = func.effectiveResolution;
mr.info.coil = mr.hdr.coil;

% now read data, get other info:
mr.data = readMagFile(pth, slices, littleEndian);
if ~isempty(t)
	% sub-select time points
	mr.data = mr.data(:,:,:,t);
end
pixdim = mr.hdr.FOV/mr.hdr.equivMatSize;
mr.voxelSize = [pixdim pixdim mr.hdr.sliceThickness mr.hdr.tAcq/1000];
mr.dims = size(mr.data);
mr.dims(3) = size(mr.data, 3);  % in case of 2-D or 3-D data:
mr.dims(4) = size(mr.data, 4);  % enforce 1x4 dims vector
mr.extent = mr.voxelSize .* mr.dims;
mr.spaces = mrStandardSpaces(mr);
mr.dimUnits = {'mm' 'mm' 'mm' 'sec'};
mr.dataUnits = 'T2*-Weighted Intensity';
mr.dataRange = mrvMinmax(mr.data);

% build a space defining the scanner coords, where the
% xform maps from the pixCorners to the R|A|S coords of the
% the three corners from the header:
try
	mr.spaces(end+1).name = 'Scanner';
	mr.spaces(end).xform = mrReadMag_affineScannerXform(mr.hdr);
	mr.spaces(end).xform(1:3,4) = mr.extent(1:3) ./ 2;
	mr.spaces(end).dirLabels = {'L <--> R' 'P <--> A'  'I <--> S'};
	mr.spaces(end).sliceLabels =  {'Sagittal' 'Coronal' 'Axial'};
	mr.spaces(end).units = 'mm';
	mr.spaces(end).coords = [];
	mr.spaces(end).indices = [];
	
    % NOT YET IMPLEMENTED:
% 	% also update the direction labels on the pixel and L/R flipped spaces,
% 	% using the header info:
% 	dirs = mrEfileDirections(hdrPath);
% 	for i=1:3, mr.spaces(i).dirLabels = dirs; end
% 	mr.spaces(3).dirLabels{2} = dimFlip(mr.spaces(3).dirLabels{2});

catch
	if prefsVerboseCheck
		warning('Couldn''t read E-file header alignment fields.')
	end
end

return
% /-------------------------------------------------------------------/ %



% /-------------------------------------------------------------------/ %
function xform = mrReadMag_affineScannerXform(hdr);
%% given a Mag-file header, compute a 4x4 affine transform mapping from
%% pixel space into the scanner coordinate system.

% E-file headers give us the scanner coordinates of three points from
% each slice:
%	gw_point1 = upper left-hand corner  (x=1, y=1)
%	gw_point2 = lower left-hand corner  (x=1, y=nrows)
%	gw_point3 = upper right-hand corner (x=ncols, y=1)
% We know which points in pixel space coorrespond to these points, so we
% take the combined set of corner coordinates, and the corresponding
% scanner coords, and solve for the best xform to map between them.

% combine the scanner coordinates together
scanCoords = [hdr.gw_point1, hdr.gw_point2, hdr.gw_point3];

% get the corresponding pixel coordinates
[X Y Z] = meshgrid([1 hdr.imgsize], [1 hdr.imgsize], 1:hdr.slquant);
pixCoords = [Y(:) X(:) Z(:)]';

% now we have to clip and resort: every 4th coord here is the
% lower-right-hand corner, which we don't have, so remove these:
pixCoords(:,2:4:end) = [];

% do I have the order of points correct?
pixCoords = pixCoords([1 2 3],:);

% now re-sort to match the order of points in scanCoords:
% [ulhc across slices, llhc across slices, urhc across slices]:
pixCoords = [pixCoords(:,[1:3:end]), ...
			 pixCoords(:,[2:3:end]), ...
			 pixCoords(:,[3:3:end])];

% solve for the xform
xform = affineSolve(pixCoords, scanCoords);

% one last step: we need to account for the shift specified by the start
% location in the header:
xform(1:3,4) = hdr.start_loc;

xform = inv(xform);

return
