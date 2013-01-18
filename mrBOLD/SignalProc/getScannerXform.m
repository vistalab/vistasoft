function scannerXform = getScannerXform(rawFile)
% Get the transform matrix from INPLANE coordinates (x,y,z, indices) to
% scanner coordinates (in mm). 
%   
%  scannerXform = getScannerXform([rawFile])
% 
% The transform will yield:
%   scannerCoords = scannerXform * ipCoords;
%
% 8/2009: Siphoned off from RAS's code computeB0DirectionMap. 
%
% That code is now shorter. And we can now use this transform for other things
% such as getting a 3-vector for the B0 direction in a scan
%
% Example: scannerXform = getScannerXform;

% Find the raw inplane dicoms
if notDefined('rawFile'),
    rawFile = fullpath('Raw/Anatomy/Inplane');
end

if exist(rawFile, 'dir')
	% allow rawFile to be a directory containing DICOM files
	pattern = fullfile(rawFile, '*.dcm');
	w = dir(pattern);
	if isempty(w)
		pattern = fullfile(rawFile, '*.DCM');
		w = dir(pattern);
	end

	if isempty(w)
		% still not found? We have a problem.
		error(['No DICOM files found in %s. Please provide a ' ...
			'file path if the raw file is not in DICOM format.'], ...
			rawFile);
	end

	% got here? then we have some files. Take the first one.
	rawFile = fullfile(rawFile, w(1).name);

elseif ~exist(rawFile, 'file')
	% no file or directory found with this name? Can't proceed.
	error('%s is not a file or directory.', rawFile);
end


% load the raw file and make sure we have an xform into scanner space
[p f ext] = fileparts(rawFile);
if strncmpi( ext, '.dcm', 4 )
	inplane = mrReadDicom(rawFile);
else
	inplane = mrLoad(rawFile);
end

if ~isfield(inplane, 'spaces') || isempty(inplane.spaces)
	error('No scanner-coordinate information found in the header fields');
end

% find the alignment to the scanner coordinate space
spaces = {inplane.spaces.name};
I = cellfind(spaces, 'Scanner');
if isempty(I)
	error('No scanner-coordinate information found in the header fields');
end

scannerXform = inplane.spaces(I).xform;