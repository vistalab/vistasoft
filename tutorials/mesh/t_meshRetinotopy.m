% t_meshTemplate
%
% Demonstrates how one reads in the Benson et al. (2014) template from a
% FreeSurfer subject's directory and displays it on their FreeSurfer mesh.
% Note that this template requires that:
%  (1) You have a FreeSurfer subject
%  (2) on which you've run the nben/occipital_atlas docker
% To run the docker, visit the following website:
%  https://hub.docker.com/r/nben/occipital_atlas
%
% Dependencies: 
%   The FreeSurfer function MRIread is required; this is included with
%   FreeSurfer in the $FREESURFER_HOME/matlab directory.
%
% Summary:
%  (a) Make sure FreeSurfer paths are valid and do sanity checks
%  (b) Read in the FreeSurfer mesh
%  (c) Read in the template data
%  (d) Visualize the template on the mesh
%  (e) Clean up
%
% Tested 08/17/2016 - MATLAB r2014a, Mac OS 10.11.6
%
% See also: t_initAnatomyFromFreesurfer
%
% Author: Noah C. Benson <nben@nyu.edu>

%% Configuration:
freesurfer_subject = 'ernie'; % on which FreeSurfer subject have we run the
                              % atlas Docker?
display_mesh       = 'pial'; % which FreeSurfer mesh surface should we use?
hemi               = 'lh';    % which hemisphere?
plot_colors        = 'label'; % plot the label, angle, or eccen?
max_eccen          = 20;      % the max eccentricity to plot


%% (a) Perform checks and tests

% Make sure we know where FreeSurfer is
fs_home = getenv('FREESURFER_HOME');
if isempty(fs_home)
    % sometimes, Matlab doesn't get the environment, but we can pull it out of
    % a system command like so:
    [retval, output] = system('/bin/bash -ci ''echo -n $FREESURFER_HOME''');
    if retval == 0, fs_home = output; end
end
if isempty(fs_home)
    error(['FreeSurfer not found; make sure you have your FREESURFER_HOME' ...
           ' environment variable set correctly']);
end
addpath(fullfile(fs_home, 'matlab'));

% Make sure there is a subjects dir
subjects_dir = getenv('SUBJECTS_DIR');
if isempty(subjects_dir)
    % sometimes, Matlab doesn't get the environment, but we can pull it out of
    % a system command like so:
    [retval, output] = system('/bin/bash -ci ''echo -n $SUBJECTS_DIR''');
    if retval == 0, subjects_dir = output; end
end
if isempty(subjects_dir)
    error(['FreeSurfer subject directory not found; make sure you have your' ...
           ' SUBJECTS_DIR environment variable set correctly']);
end

% Make sure there is a directory for the subjects in particular
subject_dir = fullfile(subjects_dir, freesurfer_subject);
if ~exist(subject_dir, 'dir')
    error(sprintf('No such FreeSurfer subject found: %s', freesurfer_subject));
end
% And that the template files exist
tmpl_str = '%s.template_%s.mgz';
angle_file = fullfile(subject_dir, 'surf', sprintf(tmpl_str, hemi, 'angle'));
eccen_file = fullfile(subject_dir, 'surf', sprintf(tmpl_str, hemi, 'eccen'));
label_file = fullfile(subject_dir, 'surf', sprintf(tmpl_str, hemi, 'areas'));
if ~exist(angle_file, 'file'), error(['File not found: ' angle_file]); end
if ~exist(eccen_file, 'file'), error(['File not found: ' eccen_file]); end
if ~exist(label_file, 'file'), error(['File not found: ' label_file]); end

%% (b) Import the VistaSoft mesh

mesh_path = fullfile(subject_dir, 'surf', [hemi '.' display_mesh]); % the path
msh       = fs_meshFromSurface(mesh_path); % Load the mesh


%% (c) Read in the template data

% Get the data
angles = MRIread(angle_file);
eccens = MRIread(eccen_file);
labels = MRIread(label_file);
% Extract the relevant vector of values-per-vertex
angles = squeeze(angles.vol);
eccens = squeeze(eccens.vol);
labels = squeeze(labels.vol);
% Pick out areas V1, V2, and V3
v1_indices = find(labels == 1);
v2_indices = find(labels == 2);
v3_indices = find(labels == 3);
v123_indices = find(labels ~= 0);
% Also, pick out the indices that are within the max eccentricity
plot_indices = intersect(v123_indices, find(eccens < max_eccen));

%% (d) Visualize the template on the mesh

% By default, the msh.colors is set to curvature colors; we want to change this
% to be color we've picked
if     strcmp(plot_colors, 'angle')
    cm = 255 * colormap('jet')';
    n = size(cm, 2);
    % angle varies from 0 to 180 for both hemispheres
    color_indices = round((angles(plot_indices) / 180) * (n - 1) + 1);
    msh.colors(1:3, plot_indices) = cm(:, color_indices);
elseif strcmp(plot_colors, 'eccen')
    cm = 255 * colormap('jet')';
    n = size(cm, 2);
    % the eccen values of plot_indices varies from 0 to max_eccen
    color_indices = round((eccens(plot_indices) / max_eccen)  * (n - 1) + 1);
    msh.colors(1:3, plot_indices) = cm(:, color_indices);
elseif strcmp(plot_colors, 'label')
    msh.colors(1:3, plot_indices) = 0;
    msh.colors(1,   intersect(plot_indices, v1_indices)) = 255;
    msh.colors(2,   intersect(plot_indices, v2_indices)) = 255;
    msh.colors(3,   intersect(plot_indices, v3_indices)) = 255;
else
    error('plot_colors must be one of ''angle'', ''eccen'', or ''label''');
end

% Now, with the new colors, plot the mesh:
meshVisualize(msh)
