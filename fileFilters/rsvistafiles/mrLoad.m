function mr = mrLoad(pth, format, varargin)
% Load a file containing MRI data into an mr object.
%
% mr = mrLoad([filePath], [format]); 
%
% MRI data can be 2-D, 3-D or 4-D (fMRI, 3 spatial dimensions
% plus time). An mr object is a struct containing the data, and
% as much information as possible about it from header files or
% other sources. It is the basic currency of mrVista.
%
% If filePath is omitted, a dialog appears for the user to select
% what file to load. If you're loading data from a series of files
% like GE I-files or DICOM files, select one file in the directory
% you want to load (doesn't matter which).
%
% You may also load several files and concatenate them, using a pattern
% identifier (e.g., 'V*.img'). In this case, you can specify the dimension
% along which to concatenate (e.g. 3=concat slices, 4=concat time) as 
% an optional third argument. [default is to concat along 4th dimension.]
%
% If the format is omitted, mrLoad tries to infer the format of
% the file from its filename. Otherwise, the format can be
% explicitly specified (see format list below).
%
% Type 'mrFormatDescription' for a detailed description of the 
% mr object format.
%
% The following file formats are supported for MRI data:
%   'nifti'         NIFTI (updated ANALYZE) format. Can be compressed.
%   'analyze'       ANALYZE 7.5 format. To parse as this instead of 
%                   NIFTI, specify the header file (*.hdr) rather than
%                   the image file (*.img).
%	'dicom'			Single DICOM file (*.dcm).
%   'dicomdir'      DICOM files (*.dcm). If many are in a directory,
%                   will loop across files and load them all into a 
%                   volume.
%	'dicompattern'	Set of DICOM files matching a pattern (e.g. 'MR*.dcm').
%					This is different from 
%   'pmag'          P*.7.mag file, w/ E-file header (E*.7, rather 
%                   than E*.hdr).
%   'ifile'         GENESIS I-file (format used by older anatomical
%                   images at the Stanford Lucas Center).
%   '1.0tSeries'    All mrVista 1.0 tSeries files in a directory (inplane
%                   only).
%   '1.0anat'       mrVista 1.0 Inplane anat.mat file.
%
%   '1.0map'        mrVista 1.0 parameter map file.
%
%   '1.0corAnal'    mrVista 1.0 corAnal file.
%
%   'vanat'         mrVista 1.0 / mrGray vAnatomy.dat file.
%
%	'class'			mrGray classification file.
%
% ras, 06/30/05: started writing it.
if notDefined('pth'), pth = '';            end
if notDefined('format'), format = '';      end

% get list of possible file formats
[formats, filters] = mrLoadFormats; %#ok<ASGLU>
[p, f, ext] = fileparts(pth);

% if pth is empty, prompt user
if isempty(pth)
    pth = mrSelectDataFile('stayput','r',filters,'Select MR data file...');
end

% allow directories containing I-files (change?):
if exist(pth,'dir')
	dicomCheck = dir(fullfile(pth, '*.dcm'));
	if ~isempty(dicomCheck)
        disp('Directory Entered. Assuming DICOM or I files')
		format = 'dicomdir';
	else
		ifileCheck = dir(fullfile(pth, 'I*'));
		if ~isempty(ifileCheck)
			disp('Directory Entered. Assuming DICOM or I files')
			pth = fullfile(pth, ifileCheck(1).name);
			format = 'ifile';
		end
	end
	
elseif isempty(ext)
	% if extension omitted, but a file exists w/ this pattern, choose the
	% first such file
	w = dir([pth '*']);
	if ~isempty(w)
		pth = fullfile( fileparts(pth), w(1).name );
	end
	
end

% if format omitted, try to infer from path name
if isempty(format), format = mrParseFormat(pth);    end

% special: if the path is a file pattern (e.g. 'V*.img'), recursively
% load each file along the [dim] dimension.
if contains(f, '*')
	fileList = dir(pth);
	if isempty(fileList)
		error('No files found matching pattern %s.', pth )
	end
	
	if length(varargin) >= 1 && ~isempty(varargin{1})
		dim = varargin{1};
	else
		dim = 4;
	end
	
	mr = mrLoad(fullfile(p, fileList(1).name), format);
	
	for ii = 2:length(fileList)
		subMr = mrLoad(fullfile(p, fileList(ii).name), format);
		mr.data = cat(dim, mr.data, subMr.data);
	end
	mr.dims(dim) = length(fileList);
	mr.extent = mr.dims .* mr.voxelSize;
	return
end

% check if file exists
if ~exist(pth, 'file') 
    % check if it's a matlab file
    if exist([pth '.nii.gz'], 'file')
        pth = [pth '.nii.gz'];
    elseif exist([pth '.mat'],'file')
        pth = [pth '.mat'];
    else
        error('%s not found.',pth); 
    end
end

% init mr struct
mr = mrCreateEmpty;
mr.path = fullpath(pth);
mr.name = f;
mr.format = format;

% read in data based on format
switch format
    case 'mat'
        % should already be loaded, but if not, load it
        if isempty(mr.data), mr = load(pth); end
        mr.path = pth;
        
 case 'nifti' 
        mr = mrReadNifti(pth);
        
        % check if there's a matlab file w/ the 
        % same name, which would presumably have
        % extensions to the file:
        periods = strfind(pth,'.');
        if isempty(periods), periods = length(pth)+1; end
        extFile = [pth(1:periods(1)-1) '.mat'];
        if exist(extFile,'file')
            % fprintf('Loading extra info from %s ...\n',extFile);
            xtra = load(extFile);
            for j = fieldnames(xtra)'
                mr.(j{1}) = xtra.(j{1});
            end
        end
        
    case 'analyze'     
		mr = mrLoadAnalyze(pth);
        
    case {'vfiles' 'spm' 'pattern'}
		% get the file pattern, and the dimension along which
		% to concatenate:
		switch length(varargin)
			case 0, dim = 1; pattern = 'V*.img';
			case 1, dim = 1; pattern = varargin{1};
			otherwise, dim = varargin{2}; pattern = varargin{1};
		end
		
        % find out how many files are in the directory:
        fullPattern = fullfile(pth, pattern);
		files =  dir(fullPattern);
        nFiles = length( files );

        % get header info, etc from first file
        mr = mrLoad( fullfile(pth, files(1).name), 'analyze' );
        
        % append subsequent frames
        for n = 2:nFiles
            frame = mrLoad( fullfile(pth, files(n).name), 'analyze' );
            mr.data = cat(dim, mr.data, frame.data);
        end
        
	case {'dicom' 'singledicom' 'dicomfile'}
		% read a single DICOM format file
		mr = mrReadDicom(pth);  % see this file for more options
		
    case {'dicomdir' 'alldicomfiles'}
		% read all DICOM files in a directory (same convention as 'ifiles')
        mr = mrReadDicomDir( pth );
        
    case {'ifile' 'ifiles'}
		% read all GE I-files in a directory (older format)
        mr = mrReadIfileDir(pth);   
        
    case 'pmag'
        mr = mrReadMag(pth); 
        
    case 'vanat'                       
        mr = mrReadVAnat(pth);
        
    case '1.0tSeries'
        mr = mrReadOldTSeries(mr.path);
		
    case '1.0anat'
        mr = mrReadOldInplaneAnat(mr.path);
		
    case '1.0map'
        mr = mrReadOldParamMap(mr.path);        
		
    case '1.0corAnal'
        [co, amp, ph] = mrReadOldCorAnal(mr.path);
        mr = [co amp ph];        
        return
		
	case 'class'
		% mrGray class file
		if length(varargin) >= 1
			mr = mrReadClass(pth, varargin{1});
		else
			mr = mrReadClass(pth);
		end
		
    case 'vmr'
        mr = mrReadVmr(mr.path);
        
    case 'bfloat'
        mr.data = loopOverMRFiles(p,'*.bshort','readBfloat');
        mr.spaces = mrStandardSpaces(mr);
        
    case 'bshort'
        mr.data = loopOverMRFiles(p,'*.bshort','readBshort');
        mr.spaces = mrStandardSpaces(mr);
        
end

% some finishing calculations 
mr.path = pth;
mr.dims = size(mr.data);
mr.data = single(mr.data);   % enforce smaller type data

if length(mr.voxelSize)<4
    fprintf('[%s]: mr.voxelSize has length<4: concatenating a "1" to it\n', mfilename)
    mr.voxelSize(end+1:4) = 1; 
end

if length(mr.dims)<4    
    fprintf('[%s]: mr.dims has length<4: concatenating a "1" to it\n', mfilename)
    mr.dims(end+1:4) = 1;     
end

mr.extent = mr.voxelSize .* mr.dims;
mr.dataRange = mrvMinmax(mr.data);
if ~isfield(mr, 'params'), mr.params = []; end

return





