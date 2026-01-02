%% v_mapNiftiResolutions - Validate coordinate mapping between NIfTI resolutions
%
% This script tests the niftiMapCoords function by displaying the same
% anatomical location in both high-resolution and low-resolution images.
% If the mapping is correct, the seed marker should appear at the same
% physical location in both images.
%
% See also: niftiMapCoords, niftiRead

%% Parameters

% Data directory
pascaData = '/Users/wandell/Library/CloudStorage/GoogleDrive-wandell@stanford.edu/My Drive/Data/MRI_Pasca/flywheel/pasca/Kaganovsky-Pasca/Apallial_20_R1F/Pasca_Apallial_20_R1F_9-9-24 - 240909094232';

% Seed location in low-res/BOLD space
seedRow   = 40;
seedCol   = 15;
lowResSlice = 10;

%% Load NIfTI files

% High resolution anatomy (100 x 100 x 300 um)
highResFile = fullfile(pascaData, '5_T2w_highres', ...
    '1_5_T2w_HR_100x100x300_E4_multiframe_5_T2w_highres_20240909094232_40001.nii.gz');
highResAnat = niftiRead(highResFile);

% Low resolution anatomy (200 x 200 x 500 um) - matches BOLD
lowResFile = fullfile(pascaData, '4_T2w_lowres', ...
    '1_4_T2w_200x200x500_E5_multiframe_4_T2w_lowres_20240909094232_50001.nii.gz');
lowResAnat = niftiRead(lowResFile);

%% Map coordinates from low-res to high-res

% Map the seed voxel from low-res space to high-res space
hrCoords = niftiMapCoords(lowResAnat, [seedRow, seedCol, lowResSlice], highResAnat);
hrRow   = round(hrCoords(1));
hrCol   = round(hrCoords(2));
hrSlice = round(hrCoords(3));

% Display mapping info
fprintf('Low-res seed: [row=%d, col=%d, slice=%d]\n', seedRow, seedCol, lowResSlice);
fprintf('High-res mapped: [row=%d, col=%d, slice=%d]\n', hrRow, hrCol, hrSlice);
fprintf('High-res (fractional): [%.2f, %.2f, %.2f]\n', hrCoords(1), hrCoords(2), hrCoords(3));

%% Verify by mapping back (round-trip test)

% Map high-res coordinates back to low-res
lrCoords = niftiMapCoords(highResAnat, [hrRow, hrCol, hrSlice], lowResAnat);
fprintf('Round-trip to low-res: [%.2f, %.2f, %.2f]\n', lrCoords(1), lrCoords(2), lrCoords(3));
fprintf('Original low-res: [%d, %d, %d]\n', seedRow, seedCol, lowResSlice);

%% Visualize both images side by side

mrvNewGraphWin('Validate NIfTI Coordinate Mapping');
tiledlayout(1, 2, 'TileSpacing', 'compact');

% Panel 1: High-res anatomy with mapped seed
nexttile;
imagesc(highResAnat.data(:,:,hrSlice)');
axis image; colormap(gca, 'gray');
hold on; 
plot(hrRow, hrCol, 'ro', 'MarkerSize', 12, 'LineWidth', 2);
title(sprintf('High-res (slice %d)', hrSlice));
xlabel('Row'); ylabel('Column');

% Panel 2: Low-res anatomy with original seed
nexttile;
imagesc(lowResAnat.data(:,:,lowResSlice)');
axis image; colormap(gca, 'gray');
hold on; 
plot(seedRow, seedCol, 'ro', 'MarkerSize', 12, 'LineWidth', 2);
title(sprintf('Low-res (slice %d)', lowResSlice));
xlabel('Row'); ylabel('Column');

% Add overall title
sgtitle('Coordinate Mapping Validation: Seed should mark same anatomical location');

%% Display voxel sizes for reference

fprintf('\nVoxel sizes:\n');
fprintf('  High-res: [%.3f, %.3f, %.3f] mm\n', highResAnat.pixdim(1:3));
fprintf('  Low-res:  [%.3f, %.3f, %.3f] mm\n', lowResAnat.pixdim(1:3));
