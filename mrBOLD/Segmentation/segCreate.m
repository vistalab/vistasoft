function seg = segCreate(name, classPath,  grayPath, anatFile);
% Create an empty segmentation object. Includes a description of
% the segmentation format.
%
% seg = segCreate(<name>, <classPath>, <grayPath>, <anatFile>);
%
% If any of the input arguments are omitted, prompts for them. 
%
% returns a struct with the following fields:
%   name: name of the segmentation. E.g., 'Right', 'Left', 'Both'.
%   subject: subject info.
%   class: path to classification file, or loaded class struct (see 
%           readClassFile for description).
%   nodes: 8xN list of gray nodes (see segGet for a description).
%   edges: set of gray edges. 
%   mesh: cell array of meshes which may be loaded/built from this
%   segmentation.
%   anatFile: name or path to anat file that was segmented.
%   created: date stamp, set in this function, when it was first created.
%   modified: date stamp, describing the time when it was last modified.
%
% Note that the segmentation struct, in itself, doesn't contain info on the
% anatomy that was segmented. Rather, it simply points to the original 
% segmented file. This is because I am intending for segmentations to be 
% attached to an mr struct, rather than the other way around (e.g., left, 
% right, and both segmentations on the anatomy). 
%
%           
% ras, 04/06.
if notDefined('name')
    name = inputdlg('Name of Segmentation?', mfilename, 1, {'Right'});
    if isempty(name), return; else, name = name{1}; end    
end

if notDefined('classPath')
    classPath = mrvSelectFile('r', '*lass', 'Select Class File');
end

[p f ext] = fileparts(classPath);

if notDefined('grayPath') & ~strfind(ext, 'nii')
	% (don't need a gray graph for NIFTI classifications...)
    grayPath = mrvSelectFile('r', '*ray', 'Select Gray File', p);
end

if notDefined('anatFile')
	ttl = 'Select the anatomy file that was segmented';
    anatFile = mrvSelectFile('r', '*', ttl, fileparts(p));
end

seg.name = name;
seg.subject = [];
seg.anatFile = anatFile;
seg.class = classPath;
seg.gray = grayPath;
seg.nodes = [];
seg.edges = [];
seg.mesh = {};
seg.settings.mesh = 0; % currently selected mesh
seg.params.numLayers = 3;
seg.params.layer0 = 0;
seg.params.meshDir = '';
seg.created = datestr(clock);
seg.modified = datestr(clock);
if isempty('grayPath')
	[seg.nodes seg.edges] = mrgGrowGray(classPath, seg.params.numLayers, ...
                                    seg.params.layer0); 
else
	[seg.nodes seg.edges] = readGrayGraph(grayPath);
end

try
	hdr = mrLoadHeader(anatFile);
	seg.subject = hdr.info;
	seg.voxelSize = hdr.voxelSize(1:3);
catch
	disp('Couldn''t load subject header info. Guessing 1x1x1 voxel size')
	seg.voxelSize = [1 1 1];
end

if exist(fullfile(fileparts(seg.class), '3DMeshes'), 'dir')
    seg.params.meshDir = fullfile(fileparts(seg.class), '3DMeshes');
end

return
