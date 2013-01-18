function [co, amp, ph] = mrReadOldCorAnal(pth);
% Reads in a mrVista 1.0 corAnal file as a set of three 
% mrVista 2.0 co objects. Tries to extract as 
% much information as possible from the mrSESSION 
% file, returning the rest in the co.hdr field.
%
%  [co, amp, ph] = mrReadOldCorAnal(pth);
%
%
% For now, this only works on Original, Inplane TSeries (or 
% TSeries files whose params aren't significantly
% changed from the Original tSeries). The tSeries files
% must be in a directory named 'Scan[#]'. 
%
% ras, 07/08/05.

[p f ext] = fileparts(pth);

% init co struct
co = mrCreateEmpty;
co.path = pth;
co.format = '1.0corAnal';
co.dimUnits = {'mm' 'mm' 'mm'};

% read in header info from mrSESSION:
% if we can't do this, we can't read the data
mrSessPath = fullfile(p,'..','..','mrSESSION.mat');
if exist(mrSessPath,'file')
    load(mrSessPath,'mrSESSION','dataTYPES');
else
    % dialog to get file
    error('No mrSESSION file found!')
end


% load the corAnal file; find the first scan
% assigned
anal = load(pth);

% find scans for which data are assigned:
for i = 1:length(anal.co), scans(i) = ~isempty(anal.co{i}); end
scans = find(scans);
nScans = length(scans);

if nScans==0
    warning('No data defined in this corAnal file.');
    return
end

% initialze co, amp, ph structs with data from the first assigned scan
co.data = anal.co{scans(1)};
co.dataUnits = 'Normalized';
co.name = 'Coherence';
co.dataRange = [0 1];

% get other header info, using first assigned
% scan as index
co.hdr = mrSESSION.functionals(scans(1));
if (~isfield(co.hdr,'voxelSize')) && (isfield(co.hdr,'effectiveResolution'))
    co.hdr.voxelSize=co.hdr.effectiveResolution;
end
co.voxelSize = [co.hdr.voxelSize]; 
co.dims = [co.hdr.cropSize length(co.hdr.slices)];
co.extent = co.dims .* co.voxelSize;

if isfield(mrSESSION,'alignment')
    co.spaces(1).name = 'I|P|R';
    co.spaces(1).xform = mrSESSION.alignment;
    co.spaces(1).dirLabels =  {'S <--> I' 'A <--> P' 'L <--> R'};
    co.spaces(1).sliceLabels =  {'Axial' 'Coronal' 'Sagittal'};
    co.spaces(1).units = 'mm';
    co.spaces(1).coords = [];
    co.spaces(1).indices = [];
    
    % account for differences between inplane / functional resolutions
    % for the alignment:
    % the mrVista 1.0 alignments mapped from inplane coords to volume
    % coords, rather than the co / tSeries:
    szRatio = co.voxelSize(1:3) ./ mrSESSION.inplanes.voxelSize;
    [trans rot scale] = affineDecompose(co.spaces(1).xform);
    co.spaces(1).xform = affineBuild(trans,rot,scale.*szRatio);
    
    co.spaces(2).name = 'R|A|S';
    co.spaces(2).xform = ipr2ras(co.spaces(1).xform,co.dims,co.voxelSize);
    co.spaces(2).dirLabels =  {'L <--> R' 'P <--> A' 'I <--> S'};
    co.spaces(2).sliceLabels =  {'Sagittal' 'Coronal' 'Axial'};
    co.spaces(2).units = 'mm';
    co.spaces(2).coords = [];
    co.spaces(2).indices = [];    
end


% pre-pend standard space definitions
co.spaces = [mrStandardSpaces(co) co.spaces];

% assign ph and amp
ph = co;
amp = co;
ph.data = anal.co{scans(1)};
amp.data = anal.amp{scans(1)};
ph.name = 'Phase'; 
ph.dataUnits = 'Radians';
ph.dataRange = [0 2*pi];
ph.phaseFlag = 1;
amp.name = 'Amplitude';
amp.dataUnits = 'Sinusoid Amplitude';
amp.dataRange = [0 max(amp.data(:))];

% record the scans for which the data belong
co.info.comments = sprintf('Computed for scans: %s',num2str(scans));
ph.info.comments = sprintf('Computed for scans: %s',num2str(scans));
amp.info.comments = sprintf('Computed for scans: %s',num2str(scans));

%% for >1 scan assigned, make co, amp, and ph struct arrays
if nScans > 1
    co = repmat(co, [1 nScans]);
    amp = repmat(amp, [1 nScans]);
    ph = repmat(ph, [1 nScans]);
    
    for t = 1:nScans
        co(t).data = anal.co{scans(t)};
        amp(t).data = anal.amp{scans(t)};
        ph(t).data = anal.ph{scans(t)};
    end
end

%% append text annotation to each scan
% first, we need to figure out which data types index to use:
dtNames = {dataTYPES.name};
[ignore corAnalDt] = fileparts(p);
dtIndex = cellfind(dtNames, corAnalDt);
if isempty(dtIndex) 
    return;         
end

if nScans > 1
    for scan = 1:nScans
        annot = dataTYPES(dtIndex).scanParams(scans(scan)).annotation;
        co(scan).name = sprintf('Coherence, %s', annot);
        amp(scan).name = sprintf('Amplitude, %s', annot);
        ph(scan).name = sprintf('Phase, %s', annot);
    end
end

%% final check: conversion to real-world units.
% there is code to coarsely map from corAnal phase to real-world
% units such as visual degrees. This requires some parameters
% have been set using retinoSetParams. Check if these params
% have been set, and if so, offer to convert the phase map.

% now, check if the retinotopy params are defined for at least one scan:
ok = logical( zeros(1, nScans) );
for scan = 1:nScans
    bParams = dataTYPES(dtIndex).blockedAnalysisParams(scan);
    ok(scan) = checkfields(bParams, 'visualFieldMap');
end

% if any are defined, offer to conver those to real units
if any(ok)
    % let's allow for a preference to always convert over
    if ispref('VISTA', 'convertCorAnalToRealUnits')
        convert = getpref('VISTA', 'convertCorAnalToRealUnits');
    else
        % dialog
        q = ['Retinotopy params are defined for some scans. Use these ' ...
             'params to convert the phase from radians -> real units?'];
        ttl = 'Read mrVista 1.0 corAnal file';
        resp = questdlg(q, ttl, 'Yes', 'No', 'Always Convert', 'Yes');
        switch resp
            case 'Yes', convert = 1;
            case 'Always Convert', 
                convert = 1; 
                setpref('VISTA', 'convertCorAnalToRealUnits', 1);
            otherwise, convert = 0;
        end
    end
    
    % convert if answer is yes
    if convert==1
        for s = find(ok)
            p = dataTYPES(dtIndex).blockedAnalysisParams(scans(s)).visualFieldMap;
            annot = dataTYPES(dtIndex).scanParams(scans(s)).annotation;
            
			if ~isempty(p)
				if isequal(p.type, 'polar_angle')
					ph(s).data = polarAngle(ph(s).data, p);
					ph(s).dataUnits = 'degrees CW from 12-o-clock';
					ph(s).dataRange = [0 360];
					ph(s).name = sprintf('Polar Angle, %s', annot);

				elseif isequal(p.type, 'eccentricity')
					ph(s).data = eccentricity(ph(s).data, p);
					ph(s).dataUnits = 'degrees';
					ph(s).dataRange = [min(ph(s).data(:)) max(ph(s).data(:))];
					ph(s).name = sprintf('Eccentricity, %s', annot);
				end 
			end
        end     % ok scans loop
    end     % if converting ph data
end     % if any scans ok 


return

