function status = roiSave(ROI, pth);
% Save a mrVista2 ROI.
%
% status = roiSave(roi, <pth=dialog>);
%
% Will save according to the format specified in the 
% ROI.viewType field (this name used for back-compatiblity
% reasons with mrVista 1). Formats are:
%	'Inplane': save as a mrVista Inplane ROI. (Requires that a session be
%		loaded.).
%	'Volume': save as a mrVista Volume/Gray ROI. (Requires that a session be
%		loaded.).
%	'mat': save as a MATLAB file, with each ROI field saved as a different
%		variable (using save(...'-struct'...)).
%	'text': create an ASCII text list of coordinates and header info
%		for the ROI.
%
% Returns status=1 if the save was successful and status=0 otherwise.
%
% ras, 02/24/07.

% Note: I use capital ROI as a local variable instead of lowercase roi
% to make back-compatibility w/ mrVista 1 files easier.
status = 0;

if nargin<1, error('Not enough input args.'); end

if notDefined('pth')
	% for mrVista Inplane and Volume ROIs, the path is determined
	% by the ROI.name and roiDir:
	switch lower(ROI.viewType)
		case 'inplane', 
			mrGlobals2;
			hI = initHiddenInplane;
			pth = fullfile(roiDir(hI), ROI.name);
		case 'volume',
			mrGlobals2;
			hV = initHiddenVolume;
			pth = fullfile(roiDir(hV, 0), ROI.name);
		otherwise,
			pth = mrvSelectFile('w', 'mat', [], 'Save an ROI...');
	end
end

if ~isfield(ROI, 'viewType') | isempty(ROI.viewType)
	ROI.viewType = 'mat';
end

switch lower(ROI.viewType)
	case {'inplane' 'volume'}
		ROI = roiCheckCoords(ROI, ROI.referenceMR);
		save(pth, 'ROI');
		
	case 'mat'
		save(pth, '-struct', 'ROI');
		
	case 'text'
		fid = fopen(pth, 'w');
		
		fprintf(fid, 'ROI %s\n', ROI.name);
		fprintf(fid, 'Reference Coordinate Space: %s\n', ROI.reference);
		fprintf(fid, 'Type: %s\n', ROI.type);		
		fprintf(fid, '# Voxels: %i\n', size(ROI.coords, 2));
		fprintf(fid, 'Drawing Type: %s\n', ROI.fillMode);
		fprintf(fid, 'Coordinates: \n');
		
		for v = 1:nVoxels
			fprintf(fid, '%s\n', num2str(ROI.coords(:,v)');
		end
		
		fprintf(fid, 'Comments: \n %s', ROI.comments);
		
		fclose(fid);
		
		
	otherwise
		error('Invalid ROI format specified in ROI.viewType.')
		
end

if exist(pth, 'file')
	status = 1;
end

return