function [meshes, fnames] = meshImportFreesurferSurfaces(subjid, hemi, surfaces)
% Import and save freesurfer surfaces in vistasoft form
% [meshes, fnames] = meshImportFreesurferSurfaces(subjid, [hemi], [surfaces], [vw])
%
% Freesurfer autosegmentation produces at least 4 meshes per subject:
% white, pial, inflated, and sphere. The white mesh is closest to what
% vistasoft BuildMesh produces, and we take this to be the base mesh,
% defining the initVertices for all meshes. We then create and one or more
% meshes for one or both hemispheres, and save them as .mat files in
% vistasoft format.
%
% Inputs:
%   subjid: Either the subjid recognized by freesurfer, or the path to the
%               freesurfer subject directory.
%   hemi:   'l', 'r', or 'b' (left, right, or both). [Default = 'b']
%   surfaces: cell array with one or more of 'white', 'pial', 'sphere',
%               'inflated'
%                [Default = {'white' 'pial' 'sphere' 'inflated'};]
%                   
% Outputs:
%   meshes: structured array with vistasoft compatible meshes
%   fnames: paths to the created meshes
%
% Example:
%   % Install Ernie freesurfer directory and ernie vistasession
%   forceOverwrite = false;
%   fssubjectsdir = getenv('SUBJECTS_DIR');
%   mrtInstallSampleData('anatomy/freesurfer', 'ernie', fssubjectsdir, forceOverwrite);
%   erniePRF = mrtInstallSampleData('functional', 'erniePRF', [], forceOverwrite);
%   cd(erniePRF);
%   % Create and save meshes
%   [meshes, fnames] = meshImportFreesurferSurfaces('ernie');


if notDefined('subjid'), help(mfilename); error('subjid is required'); end
if notDefined('hemi'), hemi = 'b'; end
if notDefined('surfaces'), surfaces = {'white' 'pial' 'sphere' 'inflated'}; end

% open a hidden view to determine location to store meshes
%vw = initHiddenInplane;

% Check for subject directory
if exist(subjid, 'dir')
    subjdir = subjid;
else    
    fsPath = getenv('SUBJECTS_DIR');
    if ~exist(fsPath, 'dir'), error('Freesurfer subjects directory not found'); end
    subjdir = fullfile(fsPath, subjid);
end

if ~exist(subjdir, 'dir')
    error('Subject freesurfer directory %s not found', subjdir);
end

switch lower(hemi(1))
    case 'l', hs.fs = 'lh'; hs.vista = 'Left'; 
    case 'r', hs.fs = 'rh'; hs.vista = 'Right'; 
    case 'b'
        hs(1).fs = 'lh'; hs(1).vista = 'Left'; 
        hs(2).fs = 'rh'; hs(2).vista = 'Right'; 
    otherwise
        error('Hemi %s not recognized', hemi);
end

nummeshes = length(hs) * length(surfaces);
fnames = cell(1, nummeshes);

for h = 1:length(hs)
    
    % Read in the white mesh for this hemifield. This is the base mesh for
    % the hemifield. All other meshes will have the same initVertices, the
    % same curvature values (for coloration), and the same faces
    
    fsSurface  = fullfile(subjdir, 'surf', sprintf('%s.%s', hs(h).fs, 'white'));
    msh0         = fs_meshFromSurface(fsSurface);
    msh0.name    = sprintf('%s_white', hs(h).vista);

    % intialize the structured array meshes for output. This will contain
    % all the mesh structs created
    if h==1, meshes = msh0; end
    
    % Loop over surfaces for this hemisphere
    for ii = 1:length(surfaces)
        
        % Create this mesh and store it temporarily in the variable msh1
        fsSurface   = fullfile(subjdir, 'surf', sprintf('%s.%s', hs(h).fs, surfaces{ii}));        
        msh1         = fs_meshFromSurface(fsSurface);
        msh1.name    = sprintf('%s_%s', hs(h).vista, surfaces{ii});
        
        % The mesh we will save is called msh, and combines values from the
        % white mesh (msh0) and the current mesh (msh1)
        msh = msh0;
        msh.vertices = msh1.vertices;
        msh.name = msh1.name;        
        
        % Previously, we looked up the mesh directory stored in the mrVista
        %   view structure. 
        % savepth = viewGet(vw, 'MeshDir', hs(h).vista);
        savepth = fullfile('./3DAnatomy', hs(h).vista, '3DMeshes'); 
        if ~exist(savepth, 'dir'), mkdir(savepth); end
        fname = fullfile(savepth, msh.name);
        save(fname, 'msh')
        
        % save for output
        meshnum = length(surfaces) * (h-1) + ii;
        meshes(meshnum) = msh;
        fnames{meshnum} = fname;
        
    end
    
end

