function mr = mrReadOldInplaneAnat(pth);
%
%  mr = mrReadOldInplaneAnat(pth);
%
% Reads in a mrVista 1.0 Inplane/anat.mat file
% as a mrVista 2.0 mr object. Tries to extract as 
% much information as possible from the mrSESSION 
% file, returning the rest in the mr.hdr field.
%
% For now, this only works on Original, Inplane TSeries (or 
% TSeries files whose params aren't significantly
% changed from the Original tSeries). The tSeries files
% must be in a directory named 'Scan[#]'. 
%
% ras, 07/08/05.

[p f ext] = fileparts(pth);

% init mr struct
mr = mrCreateEmpty;
[sessDir mr.name] = fileparts(p);
mr.path = pth;
mr.format = '1.0anat';
mr.dimUnits = 'mm';
mr.dataUnits = 'T1-Weighted Intensity';

% read in header info from mrSESSION:
% if we can't do this, we can't read the data
mrSessPath = fullfile(p,'..','mrSESSION.mat');
if exist(mrSessPath,'file')
    load(mrSessPath,'mrSESSION','dataTYPES');
else
    % dialog to get file
    error('No mrSESSION file found!')
end

% scan #, the tSeries must be in a directory like 'Scan2/'
% (Also, if other data types modified basic properties
% of the functionals like voxel size, can't deal w/ this)
mr.hdr = mrSESSION.inplanes;
mr.voxelSize = [mr.hdr.voxelSize]; 
mr.dims = [mr.hdr.cropSize mr.hdr.nSlices];
mr.extent = mr.dims .* mr.voxelSize;

% load the anat file
A = load(pth);
mr.data = A.anat;
mr.dataRange = [min(mr.data(:)) max(mr.data(:))];
if isfield(A,'underlay')
    % grab all underlays
	try
		for i = 1:length(A.underlay)
			mr.data(:,:,:,i) = histoThresh(A.underlay(i).data);
		end
		mr.dataRange = [min(mr.data(:)) max(mr.data(:))];
		mr.dimUnits = {'mm' 'mm' 'mm' 'Underlay'};
	catch
		if prefsVerboseCheck >= 1
			fprintf('[%s]: Couldn''t load underlays.\n', mfilename);
		end
	end
end

% parse subject/scan info from mrSESSION
mr.info.scanner = 'STANFORD LUCAS 3T MR'; % guess
mr.info.subject = mrSESSION.subject;
mr.info.subjectSex = 'Not Specified';
mr.info.subjectAge = 100;
mr.info.subjectSpecies = 'human'; % guess

if checkfields(mrSESSION, 'functionals', 'reconParams')
    try
		mr.info.coil = mrSESSION.functionals(1).reconParams.coil;
		mr.info.date = [mrSESSION.functionals(1).reconParams.date ...
                        ' ' mrSESSION.functionals(1).reconParams.time];
        mr.info.scanStart = [mrSESSION.functionals(1).reconParams.date ...
                        ' ' mrSESSION.functionals(1).reconParams.time];
        mr.info.coil = mrSESSION.functionals(1).reconParams.coil;
    end
end	

mr.info.session = mrSESSION.sessionCode;
mr.info.description = mrSESSION.description;
mr.info.examNum = mrSESSION.examNum;
mr.info.effectiveResolution = mrSESSION.functionals(1).effectiveResolution;

% check if a readme.txt file is available; if so, try to
% read it to get more info
readme = fullfile(p,'..','Readme.txt');
if exist(readme,'file')
	try
	    tmp = readReadme(readme);
		mr.info.protocol = tmp.protocol;
	    mr.info.operator = tmp.operator;
		mr.info.examNum = tmp.examNumber;
	catch
		% don't sweat it
	end
end


if isfield(mrSESSION,'alignment')
    mr.spaces(1).name = 'I|P|R';
    mr.spaces(1).xform = mrSESSION.alignment;
    mr.spaces(1).dirLabels =  {'S <--> I' 'A <--> P' 'L <--> R'};
    mr.spaces(1).sliceLabels =  {'Axial' 'Coronal' 'Sagittal'};
    mr.spaces(1).units = 'mm';
    mr.spaces(1).coords = [];
    mr.spaces(1).indices = [];
    
    mr.spaces(2).name = 'R|A|S';
    mr.spaces(2).xform = ipr2ras(mr.spaces(1).xform,mr.dims);
    mr.spaces(2).dirLabels =  {'L <--> R' 'P <--> A' 'I <--> S'};
    mr.spaces(2).sliceLabels =  {'Sagittal' 'Coronal' 'Axial'};
    mr.spaces(2).units = 'mm';
    mr.spaces(2).coords = [];
    mr.spaces(2).indices = [];    
end


% pre-pend standard space definitions
mr.spaces = [mrStandardSpaces(mr) mr.spaces];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% try to get more info from the raw files, if they're around %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rawInplanes = fullfile(sessDir,'Raw','Anatomy','Inplane');
if exist(rawInplanes,'dir')
    w = dir(fullfile(rawInplanes,'I*'));
    try

        [ignore, hdr1] = mrReadIfile(fullfile(rawInplanes,w(1).name));
        [ignore, hdr2] = mrReadIfile(fullfile(rawInplanes,w(end).name));

        mr.info.scanner = char(hdr1.exam.hospname');
        mr.info.subject = char(hdr1.exam.patname');
        sex = {'not entered' 'female' 'male' };
        date = parseGEDate(hdr1.image.im_actual_dt);
        if date(1) < 2004  % old format (1900: parsing error)
            mr.info.subjectSex = sex{hdr1.exam.patsex};
        else                        % new format
            mr.info.subjectSex = sex{hdr1.exam.patsex+2};
        end
        mr.info.subjectAge = hdr1.exam.patage;
        mr.info.subjectSpecies = 'human'; % may not always be the case, find field
        mr.info.date = datestr(parseGEDate(hdr1.series.se_datetime));
        mr.info.scanStart = datestr(parseGEDate(hdr1.image.im_actual_dt));
        mr.info.examNum = hdr1.exam.ex_no;
        mr.info.protocol = char(hdr1.series.prtcl');
        mr.info.coil = hdr1.image.cname;
        mr.info.magnetStrength = hdr1.exam.magstrength/10000;

        % get coordinates of 3 corners of the last image and
        % express in R|A|S coords:
        tmp = hdr1.image;
        mr.info.cornerCoords = [tmp.tlhc_R tmp.trhc_R tmp.brhc_R; ...
                                tmp.tlhc_A tmp.trhc_A tmp.brhc_A; ...
                                tmp.tlhc_S tmp.trhc_S tmp.brhc_S];
        tmp = hdr2.image;
        mr.info.cornerCoords = [mr.info.cornerCoords; ...
                                tmp.tlhc_R tmp.trhc_R tmp.brhc_R; ...
                                tmp.tlhc_A tmp.trhc_A tmp.brhc_A; ...
                                tmp.tlhc_S tmp.trhc_S tmp.brhc_S];    

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Use the corner coords to estimate transform into  %
        % scanner space:                                    %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % first, get the coordinates of the corners of the last slice
        % in pixel coords:
        tlhc = [1 1 mr.dims(3)]'; % top left-hand-corner
        trhc = [1 mr.dims(2:3)]'; % top right-hand-corner
        brhc = [mr.dims(1:3)]';        % bottom right-hand-corner
        pixCorners = [tlhc trhc brhc];

        % now build a space defining the scanner coords, where the
        % xform maps from the pixCorners to the R|A|S coords of the
        % the three corners from the header:
        firstIfile = fullfile(rawInplanes,w(1).name);
        mr.spaces(end+1).name = 'Scanner';
        mr.spaces(end).xform = inv(affineScanner2Pixels(firstIfile));
        mr.spaces(end).dirLabels = {'L <--> R' 'P <--> A'  'I <--> S'};
        mr.spaces(end).sliceLabels =  {'Sagittal' 'Coronal' 'Axial'};
        mr.spaces(end).units = 'mm';
        mr.spaces(end).coords = [];
        mr.spaces(end).indices = [];

        % also update the direction labels on the pixel and L/R flipped spaces,
        % using the header info:
        dirs = mrIfileDirections(rawInplanes);
        for i=1:3, mr.spaces(i).dirLabels = dirs; end
        mr.spaces(3).dirLabels{2} = dimFlip(mr.spaces(3).dirLabels{2});
        
        
    catch
        
        % don't worry about it
        disp(lasterr);
        
    end
    
end



return
