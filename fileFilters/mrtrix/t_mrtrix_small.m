%% Run mrTrix on a small white matter mask
%
% We download and select a small white matter mask using 
%
%  t_niftiSelect.m
%
% We assume that has been done and start here.
%
%

%% Initialize
baseDir = fullfile(vistaRootPath,'local','diffusion');

% Has pointers to everything
dt6File = fullfile(baseDir,'dti96trilin_run1_res2','dt6.mat');
if ~exist(dt6File,'file'), error('No dt6 file'); end

% CSD model
lmax = 8;

% Output directory
mrtrix_folder = fullfile(baseDir,'mrtrix');
if ~exist(mrtrix_folder,'dir')
    mkdir(mrtrix_folder); 
else
    % Clear the directory
    delete(fullfile(mrtrix_folder,'*'));
end

%% Make small white matter mask
wmMask  = fullfile(vistaRootPath,'local','diffusion','dti96trilin_run1_res2','bin','wmMask.nii.gz');
nii = niftiRead(wmMask);

% Select out a cube and save the file
p.keepLR = 20:30; p.keepPA = 20:30; p.keepIS = 40:50;
p.niiNewName  = fullfile(vistaRootPath,'local','diffusion','dti96trilin_run1_res2','bin','wmMaskCube.nii.gz');
niftiSelect(nii,p);

%% Run it

files = mrtrix_init(dt6File,lmax,mrtrix_folder,wmMaskCube);

%%