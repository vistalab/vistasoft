function mr = mrReadOldParamMap(pth);
%
%  mr = mrReadOldParamMap(pth);
%
% Reads in a mrVista 1.0 Parameter map file
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
% ras, 03/01/07: reads in data units for newer param maps.

[p f ext] = fileparts(pth);

% init mr struct
mr = mrCreateEmpty;
mr.path = pth;
mr.format = '1.0map';
mr.dimUnits = {'mm' 'mm' 'mm' 'scan'};

% read in header info from mrSESSION:
% if we can't do this, we can't read the data
mrSessPath = fullfile(p,'..','..','mrSESSION.mat');
if exist(mrSessPath,'file')
    load(mrSessPath,'mrSESSION','dataTYPES');
else
    % dialog to get file
    error('No mrSESSION file found!')
end


% load the param map file
M = load(pth);
if ~isfield(M, 'map') | ~isfield(M, 'mapName')
	error( sprintf('%s needs ''map'' and ''mapName'' variables.', pth) );
end

mr.name = M.mapName;
map = M.map;  M.map =[]; % quick hack for back-compatibility

% check for an empty map
if isempty(cellfind(map))
    myErrorDlg('Map File is empty!');
end

% since most contrast maps are named w/ the format
% '[active]V[control]', and no other common param 
% map has a V in it, make an educated guess about 
% units:
if isfield(M, 'units'),				mr.dataUnits = M.units;
elseif findstr(M.mapName,'V'),		mr.dataUnits = '-log_{10}(p)';
else,								mr.dataUnits = M.mapName;
end

% assign each volume that is nonempty to a new time point:
for i = 1:length(map), ind(i) = ~isempty(map{i}); end
ind = find(ind);
for t = 1:length(ind)
    mr.data(:,:,:,t) = map{ind(t)};
	mr.info.scans(t) = ind(t);
end

% get other header info, using first assigned scan as index
% (first, we see if this map reflects data from the Original data type:
%  if so, we can use the scan index as an index into the functional
%  headers. Otherwise, we guess the first scan header is appropriate.)
[p2 f2] = fileparts(p);
if isequal(f2, 'Original')
	nScan = ind(1);
else
	nScan = 1; % guess the 1st scan
end
mr.hdr = mrSESSION.functionals(nScan);
mr.hdr.comments = sprintf('Computed for scans: %s',num2str(ind));
if (~isfield(mr.hdr,'voxelSize')) && (isfield(mr.hdr,'effectiveResolution'))
    mr.hdr.voxelSize=mr.hdr.effectiveResolution;
end
    
mr.voxelSize = [mr.hdr.voxelSize]; 
mr.dims = [mr.hdr.cropSize length(mr.hdr.slices)];
mr.extent = mr.dims .* mr.voxelSize;

if isfield(mrSESSION,'alignment')
    mr.spaces(1).name = 'I|P|R';
    mr.spaces(1).xform = mrSESSION.alignment;
    mr.spaces(1).dirLabels =  {'S <--> I' 'A <--> P' 'L <--> R'};
    mr.spaces(1).sliceLabels =  {'Axial' 'Coronal' 'Sagittal'};
    mr.spaces(1).units = 'mm';
    mr.spaces(1).coords = [];
    mr.spaces(1).indices = [];
    
    % account for differences between inplane / functional resolutions
    % for the alignment:
    % the mrVista 1.0 alignments mapped from inplane coords to volume
    % coords, rather than the map / tSeries:
    szRatio = mr.voxelSize ./ mrSESSION.inplanes.voxelSize;
    [trans rot scale] = affineDecompose(mr.spaces(1).xform);
    mr.spaces(1).xform = affineBuild(trans,rot,scale.*szRatio);
    
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


return

