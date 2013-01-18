function hdr = mrHeaderLoadInplaneAnat(pth);
%
%  hdr = mrHeaderLoadInplaneAnat(pth);
%
% Reads in header information from a mrVista Inplane/anat.mat file,
% without actually loading the anatomy data.
%
% ras, 07/08/05.

[p f ext] = fileparts(pth);

% init hdr struct
hdr = mrCreateEmpty;
[sessDir hdr.name] = fileparts(p);
hdr.path = pth;
hdr.format = '1.0anat';
hdr.dimUnits = 'mm';
hdr.dataUnits = 'T1-Weighted Intensity';

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
hdr.hdr = mrSESSION.inplanes;
hdr.voxelSize = [hdr.hdr.voxelSize]; 
hdr.dims = [hdr.hdr.cropSize hdr.hdr.nSlices];
hdr.extent = hdr.dims .* hdr.voxelSize;

hdr.dataRange = [];
hdr.dimUnits = {'mm' 'mm' 'mm' 'Underlay'};

% parse subject/scan info from mrSESSION
hdr.info.scanner = 'STANFORD LUCAS 3T MR'; % guess
hdr.info.subject = mrSESSION.subject;
hdr.info.subjectSex = 'Not Specified';
hdr.info.subjectAge = 100;
hdr.info.subjectSpecies = 'human'; % guess
if isfield(mrSESSION,'functionals') | ~isempty(mrSESSION.functionals)
    hdr.info.coil = mrSESSION.functionals(1).reconParams.coil;
    hdr.info.date = [mrSESSION.functionals(1).reconParams.date ...
                        ' ' mrSESSION.functionals(1).reconParams.time];
    hdr.info.scanStart = [mrSESSION.functionals(1).reconParams.date ...
                        ' ' mrSESSION.functionals(1).reconParams.time];
end
hdr.info.session = mrSESSION.sessionCode;
hdr.info.description = mrSESSION.description;
hdr.info.examNum = mrSESSION.examNum;
hdr.info.effectiveResolution = mrSESSION.functionals(1).effectiveResolution;

% check if a readme.txt file is available; if so, try to
% read it to get more info
try
	readme = fullfile(p,'..','Readme.txt');
	if exist(readme,'file')
		tmp = readReadme(readme);
		hdr.info.protocol = tmp.protocol;
		hdr.info.operator = tmp.operator;
		hdr.info.examNum = tmp.examNumber;
	end
end

if isfield(mrSESSION,'alignment')
    hdr.spaces(1).name = 'I|P|R';
    hdr.spaces(1).xform = mrSESSION.alignment;
    hdr.spaces(1).dirLabels =  {'S <--> I' 'A <--> P' 'L <--> R'};
    hdr.spaces(1).sliceLabels =  {'Axial' 'Coronal' 'Sagittal'};
    hdr.spaces(1).units = 'mm';
    hdr.spaces(1).coords = [];
    hdr.spaces(1).indices = [];
    
    hdr.spaces(2).name = 'R|A|S';
    hdr.spaces(2).xform = ipr2ras(hdr.spaces(1).xform,hdr.dims);
    hdr.spaces(2).dirLabels =  {'L <--> R' 'P <--> A' 'I <--> S'};
    hdr.spaces(2).sliceLabels =  {'Sagittal' 'Coronal' 'Axial'};
    hdr.spaces(2).units = 'mm';
    hdr.spaces(2).coords = [];
    hdr.spaces(2).indices = [];    
end


% pre-pend standard space definitions
hdr.spaces = [mrStandardSpaces(hdr) hdr.spaces];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% try to get more info from the raw files, if they're around %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rawInplanes = fullfile(sessDir,'Raw','Anatomy','Inplane');
if exist(rawInplanes,'dir')
    w = dir(fullfile(rawInplanes,'I*'));
    try

        [ignore, hdr1] = mrReadIfile(fullfile(rawInplanes,w(1).name));
        [ignore, hdr2] = mrReadIfile(fullfile(rawInplanes,w(end).name));

        hdr.info.scanner = char(hdr1.exam.hospname');
        hdr.info.subject = char(hdr1.exam.patname');
        sex = {'not entered' 'female' 'male' };
        date = parseGEDate(hdr1.image.im_actual_dt);
        if date(1) > 1900 & date(1) < 2004  % old format (1900: parsing error)
            hdr.info.subjectSex = sex{hdr1.exam.patsex};
        else                        % new format
            hdr.info.subjectSex = sex{hdr1.exam.patsex+2};
        end
        hdr.info.subjectAge = hdr1.exam.patage;
        hdr.info.subjectSpecies = 'human'; % may not always be the case, find field
        hdr.info.date = datestr(parseGEDate(hdr1.series.se_datetime));
        hdr.info.scanStart = datestr(parseGEDate(hdr1.image.im_actual_dt));
        hdr.info.examNum = hdr1.exam.ex_no;
        hdr.info.protocol = char(hdr1.series.prtcl');
        hdr.info.coil = hdr1.image.cname;
        hdr.info.magnetStrength = hdr1.exam.magstrength/10000;

        % get coordinates of 3 corners of the last image and
        % express in R|A|S coords:
        tmp = hdr1.image;
        hdr.info.cornerCoords = [tmp.tlhc_R tmp.trhc_R tmp.brhc_R; ...
                                tmp.tlhc_A tmp.trhc_A tmp.brhc_A; ...
                                tmp.tlhc_S tmp.trhc_S tmp.brhc_S];
        tmp = hdr2.image;
        hdr.info.cornerCoords = [hdr.info.cornerCoords; ...
                                tmp.tlhc_R tmp.trhc_R tmp.brhc_R; ...
                                tmp.tlhc_A tmp.trhc_A tmp.brhc_A; ...
                                tmp.tlhc_S tmp.trhc_S tmp.brhc_S];    

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Use the corner coords to estimate transform into  %
        % scanner space:                                    %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % first, get the coordinates of the corners of the last slice
        % in pixel coords:
        tlhc = [1 1 hdr.dims(3)]'; % top left-hand-corner
        trhc = [1 hdr.dims(2:3)]'; % top right-hand-corner
        brhc = [hdr.dims]';        % bottom right-hand-corner
        pixCorners = [tlhc trhc brhc];

        % now build a space defining the scanner coords, where the
        % xform maps from the pixCorners to the R|A|S coords of the
        % the three corners from the header:
        firstIfile = fullfile(rawInplanes,w(1).name);
        hdr.spaces(end+1).name = 'Scanner';
        hdr.spaces(end).xform = inv(affineScanner2Pixels(firstIfile));
        hdr.spaces(end).dirLabels = {'L <--> R' 'P <--> A'  'I <--> S'};
        hdr.spaces(end).sliceLabels =  {'Sagittal' 'Coronal' 'Axial'};
        hdr.spaces(end).units = 'mm';
        hdr.spaces(end).coords = [];
        hdr.spaces(end).indices = [];

        % also update the direction labels on the pixel and L/R flipped spaces,
        % using the header info:
        dirs = mrIfileDirections(rawInplanes);
        for i=1:3, hdr.spaces(i).dirLabels = dirs; end
        hdr.spaces(3).dirLabels{2} = dimFlip(hdr.spaces(3).dirLabels{2});
        
        
    catch
        
        % don't worry about it
        disp(lasterr);
        
    end
    
end



return
