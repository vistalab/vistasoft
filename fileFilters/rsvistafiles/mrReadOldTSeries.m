function mr = mrReadOldTSeries(pth)
% Converts mrVIsta 1.0 tSeries to 2.0 mr object
%
%   mr = mrReadOldTSeries(pth)
%
% This routine tries to extract as much information as possible from the
% mrSESSION file, returning the rest in the mr.hdr field.
%
% For now, this only works on Original, Inplane TSeries (or TSeries files
% whose params aren't significantly changed from the Original tSeries). The
% tSeries files must be in a directory named 'Scan[#]'. 
%
% ras, 07/08/05
% ras, 07/21/07: can now either specify a tSeries file, or just the folder.

% check if a file, or a directory, was provided
if exist(pth, 'dir')
	p = pth;
elseif exist(pth, 'file')
	p = fileparts(pth);
else
	pth
	error('Huh? File path doesn''t seem to exist.')
end

% init mr struct
mr = mrCreateEmpty;
mr.path = p;
mr.format = '1.0tSeries';
mr.dimUnits = {'mm' 'mm' 'mm' 'sec'};
mr.dataUnits = 'T2*-Weighted Intensity';

% read in hdr from mrSESSION:
% if we can't do this, we can't read the data
sessDir = fileparts( fileparts( fileparts( fileparts(p) ) ) );
mrSessPath = fullfile(sessDir,'mrSESSION.mat');
if exist(mrSessPath,'file')
    load(mrSessPath,'mrSESSION','dataTYPES');
else
    % dialog to get file
    error('No mrSESSION file found!')
end

% scan #, the tSeries must be in a directory like 'Scan2/'
% (Also, if other data types modified basic properties
% of the functionals like voxel size, can't deal w/ this)
[tmp scanDir] = fileparts(p);
[ignore dt] = fileparts( fileparts(tmp) );
scanNum = str2double(scanDir(5:end)); 
dtNames = {dataTYPES.name};
dtNum = cellfind(dtNames,dt);
mr.hdr = mrSESSION.functionals(scanNum);
mr.name = sprintf('%s Scan %i',dt,scanNum);
mr.voxelSize = [mr.hdr.voxelSize mr.hdr.framePeriod]; 
nFrames = dataTYPES(dtNum).scanParams(scanNum).nFrames;
mr.dims = [mr.hdr.cropSize length(mr.hdr.slices) nFrames];
mr.extent = mr.dims .* mr.voxelSize;

% add info from mrSESSION to .info field
mr.info = mrSESSION.functionals(scanNum);
mr.info.scan = dataTYPES(dtNum).scanParams(scanNum).annotation;

% if the E-file associated w/ this tSeries exists, get the
% header info for it and add that info as well:
if checkfields(mr,'hdr','PfileName')
    pfileName = mr.hdr.PfileName(1:end-4); % remove '.mag' from name
    pattern = fullfile(sessDir,'Raw','Pfiles',sprintf('E*%s',pfileName));
    w = dir(pattern);
    if ~isempty(w)
        eHdr = readHeaderMag(fullfile(fileparts(pattern),w(1).name));
        for f = fieldnames(eHdr)', mr.info.(f{1}) = eHdr.(f{1}); end
    end
else
    warndlg('No P-files listed in mrSESSION.  Missing header information')
end

% also check for a Readme.txt file
readme = fullfile(sessDir,'Readme.txt');
if exist(readme,'file')
    tmp = readReadme(readme);
    for f = fieldnames(tmp)', mr.info.(f{1}) = tmp.(f{1}); end
end
    

% loop over and read tSeries files 
h = mrvWaitbar(0,'Reading mrVista 1.0 tSeries files');
for slice = 1:mr.dims(3)
    fname = fullfile(p, sprintf('tSeries%i.mat',slice));
    if ~exist(fname, 'file')
        close(h);
        error('%s not found.', fname);
    end
    load(fname,'tSeries');
    mr.data(:,:,slice) = int16(tSeries);
    mrvWaitbar(slice/mr.dims(3));
end
close(h);
mr.data = permute(mr.data,[2 3 1]);
mr.data = reshape(mr.data,mr.dims);

if isfield(mrSESSION,'alignment')
    mr.spaces(1).name = 'I|P|R';
    mr.spaces(1).xform = mrSESSION.alignment;
    mr.spaces(1).dirLabels =  {'S <--> I' 'A <--> P' 'L <--> R'};
    mr.spaces(1).sliceLabels =  {'Sagittal' 'Coronal' 'Axial'};
    mr.spaces(1).units = 'mm';
    mr.spaces(1).coords = [];
    mr.spaces(1).indices = [];
    
    % account for differences between inplane / functional resolutions
    % for the alignment:
    % the mrVista 1.0 alignments mapped from inplane coords to volume
    % coords, rather than the map / tSeries:
    szRatio = mr.voxelSize(1:3) ./ mrSESSION.inplanes.voxelSize;
    [trans rot scale] = affineDecompose(mr.spaces(1).xform);
    mr.spaces(1).xform = affineBuild(trans,rot,scale.*szRatio);    
    
    mr.spaces(2).name = 'R|A|S';
    mr.spaces(2).xform = ipr2ras(mr.spaces(1).xform,mr.dims,mr.voxelSize);
    mr.spaces(2).dirLabels =  {'L <--> R' 'P <--> A' 'I <--> S'};
    mr.spaces(2).sliceLabels =  {'Axial' 'Coronal' 'Sagittal'};
    mr.spaces(2).units = 'mm';
    mr.spaces(2).coords = [];
    mr.spaces(2).indices = [];    
end

% pre-pend standard space definitions
mr.spaces = [mrStandardSpaces(mr) mr.spaces];

% enfore the setting of the data field as int16
mr.data = int16(mr.data);

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

