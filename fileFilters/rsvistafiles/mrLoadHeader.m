function mr = mrLoadHeader(pth, format, varargin)
% Load header information only (not data) from an MR data file.
%
% mr = mrLoadHeader(pth, format, varargin);
%
% Currently only works with the following formats:
%   'mat', MATLAB 7.0 mr file.
%   'nifti', NIFTI (compressed or uncompressed) file
%   'vanat', vAnatomy.dat format
%   'analyze', analyze format.
%   'pmag', Lucas P*.mag file.
%   
% Returns an mr struct with the 'data' field empty, but with as many of the
% other fields as possible filled out as normal.
%
% ras, 12/05.
if notDefined('pth'), pth = '';            end
if notDefined('format'), format = '';      end

% get list of possible file formats
[formats, filters] = mrLoadFormats; %#ok<ASGLU>

% if pth is empty, prompt user
if isempty(pth)
    pth = mrSelectDataFile('stayput', 'r', filters, 'Select MR data file...');
end

% check if file exists
if ~exist(pth, 'file'), 
	% first, check if it's a file pattern ('*' in the name):
	% if so, we'll read the header from the first file
	if strfind(pth, '*')
		w = dir(pth);
		if ~isempty(w)
			pth = fullfile( fileparts(pth), w(1).name );
		end
		
	else
		% check if it's a matlab file
		if exist([pth '.nii.gz'], 'file')
			pth = [pth '.nii.gz'];
		elseif exist([pth '.mat'],'file')
			pth = [pth '.mat'];
		else
			error('%s not found.\n',pth); 
		end
		
	end
end

if isempty(format), format = mrParseFormat(pth); end


[p, f] = fileparts(pth); %#ok<ASGLU>
mr = mrCreateEmpty;
mr.path = pth;
mr.name = f;
mr.format = format;

switch lower(format)
    case 'mat',
        mr = load(pth, 'name', 'format', 'hdr', 'info', 'spaces', ...
                'voxelSize', 'dims', 'extent', 'dimUnits', 'dataUnits', ...
                'dataRange', 'params');
            
    case 'nifti',
        % just have to do a quick load and remove data for now --
        % really, I should rewrite this to not load the data
        mr = mrLoad(pth, 'nifti');
        mr = rmfield(mr, 'data');
        
    case 'vanat',
        [mr.voxelSize, mr.dims, mr.path] = readVolAnatHeader(pth);
        mr.extent = mr.voxelSize .* mr.dims;
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

        mr.info = [];
		        
    case 'analyze'
%         mr.hdr = readAnalyzeHeader(pth);     % incomplete
		% this doesn't save any time, but produces consistent fields
		mr = mrLoad(pth, 'analyze');
		mr.data = [];  
      
    case 'pmag',
        [func, mr.hdr] = mrReadMagHeader(pth);
		mr.hdr = mergeStructures(mr.hdr, func);
        mr.dims = [mr.hdr.imgsize mr.hdr.imgsize mr.hdr.slquant mr.hdr.nframes];
        %pixdim = mr.hdr.FOV/mr.hdr.equivMatSize;
        mr.voxelSize = [func.voxelSize func.framePeriod];
        mr.extent = mr.voxelSize .* mr.dims;
        mr.spaces = mrStandardSpaces(mr);
        mr.dimUnits = {'mm' 'mm' 'mm' 'sec'};
        mr.dataUnits = 'T2*-Weighted Intensity';
        mr.dimUnits = {'mm' 'mm' 'mm' 'sec'};
        mr.dataUnits = 'T2*-Weighted Intensity';
        
        mr.info = mr.hdr;
        mr.info.scanner = '';
        mr.info.subject = mr.hdr.name;
        mr.info.subjectSex = '';
        mr.info.subjectAge = [];
        [mr.info.date, mr.info.scanStart] = parsePmagDate(mr.hdr.date,mr.hdr.time);
        % These lines appear to have no effect
        %         if (mr.info.scanStart(1)>=2005) && (mr.info.scanStart(2)>=3)
        %             littleEndian = 1;
        %         else
        %             littleEndian = 0;
        %         end
		mr.info.effectiveResolution = func.effectiveResolution;
        mr.info.coil = mr.hdr.coil;       
		
	case '1.0anat'
		mr = mrHeaderLoadInplaneAnat(pth);

    otherwise, 
        % just load the whole data, then remove the data field
        % inefficient but at least it doesn't crash
        mr = mrLoad(pth);
        mr.data = [];

end


return
