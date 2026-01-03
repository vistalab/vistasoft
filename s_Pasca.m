%% s_Pasca - Seed-based correlation analysis of organoid fMRI data
%
% This script analyzes fMRI BOLD data from Pasca lab organoid experiments.
% It computes seed-based correlation maps: selecting a voxel and finding
% how correlated its time series is with every other voxel.
%
% Data types:
%   - High-res T2w anatomy (100 x 100 x 300 um) - for visualization
%   - Low-res T2w anatomy  (200 x 200 x 500 um) - matches BOLD resolution
%   - BOLD fMRI (200 um in-plane, TR=1000ms, 600 timepoints)
%
% MR acquisition parameters:
%   fMRI: T2star FID EPI, TR/TE = 1000/11.5 ms, 600 repetitions
%         BW=300 KHz, FOV=18x13 mm2, matrix 90x65 (200 um in-plane)
%         Slice thickness=0.5mm, 28 interleaved slices
%   DTI:  B=1000 s/mm2, 40 dirs, TR/TE = 3500/21 ms
%         FOV=18x15 mm2, matrix 120x100 (150 um in-plane)

%% Parameters

% Data directory (adjust path as needed for your system)
pascaData = '/Users/wandell/Library/CloudStorage/GoogleDrive-wandell@stanford.edu/My Drive/Data/MRI_Pasca/flywheel/pasca/Kaganovsky-Pasca/Apallial_20_R1F/Pasca_Apallial_20_R1F_9-9-24 - 240909094232';

% Analysis parameters (all in BOLD/low-res space)
boldSlice = 6;         % Slice to analyze (in BOLD/low-res coordinates)
seedRow   = 40;         % Seed voxel row (y) in BOLD/low-res space
seedCol   = 15;         % Seed voxel column (x) in BOLD/low-res space

%% Load anatomical data (high resolution - for reference)

highResFile = fullfile(pascaData, '5_T2w_highres', ...
    '1_5_T2w_HR_100x100x300_E4_multiframe_5_T2w_highres_20240909094232_40001.nii.gz');
highResAnat = niftiRead(highResFile);
highResAnat.fname = highResFile;  % Workaround for niftiView bug
% Note: niftiView slice here won't match boldSlice (different resolutions)
% niftiView(highResAnat, 'slice', boldSlice);

%% Load BOLD fMRI data

boldFile = fullfile(pascaData, 'T2star_FID_EPI_300KHz_200micron', ...
    '1_T2star_FID_EPI_300KHz_200micron_E2_multiframe_T2star_FID_EPI_300KHz_200micron_20240909094232_20001.nii.gz');
boldData = niftiRead(boldFile);
[nRows, nCols, nSlices, nTimepoints] = size(boldData.data);

%% Load anatomical data (low resolution - matches BOLD)

lowResFile = fullfile(pascaData, '4_T2w_lowres', ...
    '1_4_T2w_200x200x500_E5_multiframe_4_T2w_lowres_20240909094232_50001.nii.gz');
lowResAnat = niftiRead(lowResFile);
lowResAnat.fname = lowResFile;  % Workaround for niftiView bug
% niftiView(lowResAnat, 'slice', boldSlice);

% Verify that low-res anatomy matches BOLD spatial dimensions
assert(isequal(size(lowResAnat.data), [nRows, nCols, nSlices]), ...
    'Low-res anatomy dimensions do not match BOLD data');

%% Compute seed-based correlation map
%
% Extract time series from the seed voxel, then compute the peak
% cross-correlation between this seed and every other voxel in the slice.
% peakxcorr returns:
%   C(:,:,1) - peak correlation coefficient [-1, 1]
%   C(:,:,2) - lag at peak in samples (positive = other voxel leads seed)
%              With TR=1s, lag is in seconds

% Extract the slice as (rows x cols x time)
sliceData = squeeze(boldData.data(:,:,boldSlice,:));

% Get seed voxel time series
seedTimeSeries = squeeze(sliceData(seedRow, seedCol, :));

% Compute correlation with all voxels
corrMap = peakxcorr(seedTimeSeries, sliceData);

%% Visualize results

mrvNewGraphWin('Seed Correlation Analysis');
tiledlayout(2, 2);

% Map seed voxel from BOLD space to high-res anatomy space
hrCoords = niftiMapCoords(boldData, [seedRow, seedCol, boldSlice], highResAnat);
hrSlice = round(hrCoords(3));
hrRow   = round(hrCoords(1));
hrCol   = round(hrCoords(2));

% Panel 1: High-res anatomical reference with mapped seed location
nexttile;
imagesc(highResAnat.data(:,:,hrSlice)');
axis image; colormap(gca, 'gray');
hold on; plot(hrRow, hrCol, 'ro', 'MarkerSize', 10, 'LineWidth', 2);
title(sprintf('High-res anatomy (slice %d) with seed', hrSlice));
xlabel('Row'); ylabel('Column');

% % Panel 1 (original): Low-res anatomical reference
% nexttile;
% imagesc(lowResAnat.data(:,:,boldSlice)');
% axis image; colormap(gca, 'gray');
% hold on; plot(seedRow, seedCol, 'ro', 'MarkerSize', 10, 'LineWidth', 2);
% title('Anatomy with seed location');
% xlabel('Row'); ylabel('Column');

% Panel 2: Peak correlation map
nexttile;
imagesc(corrMap(:,:,1)');
axis image; colormap(gca, 'parula');
hold on; plot(seedRow, seedCol, 'ko', 'MarkerSize', 10, 'LineWidth', 2);
colorbar; clim([-1 1]);
title('Peak correlation');
xlabel('Row'); ylabel('Column');

% Panel 3: Lag map (time shift at peak correlation)
nexttile;
imagesc(corrMap(:,:,2)');
axis image; colormap(gca, 'parula');
hold on; plot(seedRow, seedCol, 'ko', 'MarkerSize', 10, 'LineWidth', 2);
colorbar;
title('Lag at peak (samples)');
xlabel('Row'); ylabel('Column');

% Panel 4: Histogram of correlation values
nexttile;
histogram(corrMap(:,:,1), 50);
xlabel('Correlation'); ylabel('Count');
title('Distribution of correlations');
xline(0, 'k--');

%% Overlay correlation on low-res anatomy
%
% Overlay the correlation map on the aligned low-res anatomy,
% showing only voxels with |correlation| > threshold.

corrThreshold = 0.7;

% Get the anatomy slice (same resolution as BOLD/correlation)
anatSliceData = lowResAnat.data(:,:,boldSlice)';

% Get correlation data
corrData = corrMap(:,:,1)';

% Create masked overlay (only show |corr| > threshold)
corrMasked = corrData;
corrMasked(abs(corrData) < corrThreshold) = NaN;

% Display overlay using two axes
mrvNewGraphWin('Correlation Overlay on Anatomy');
clf;

ax1 = axes;
imagesc(ax1, anatSliceData);
axis image; colormap(ax1, 'gray');
hold on;

ax2 = axes;
h = imagesc(ax2, corrMasked);
axis image;
colormap(ax2, 'jet');  % Use jet for correlation overlay
clim(ax2, [-1 1]);
set(h, 'AlphaData', ~isnan(corrMasked));
ax2.Visible = 'off';
linkaxes([ax1, ax2]);

% Add colorbar for correlation
cb = colorbar(ax2, 'Position', [0.85 0.15 0.03 0.7]);
cb.Label.String = 'Correlation';

% Mark seed location (plot on ax2 so it's on top of overlay)
hold(ax2, 'on');
plot(ax2, seedRow, seedCol, 'wo', 'MarkerSize', 12, 'LineWidth', 2);

title(ax1, sprintf('Correlations |r| > %.1f on anatomy (slice %d)', corrThreshold, boldSlice));
xlabel(ax1, 'Row'); ylabel(ax1, 'Column');

%% Make a mask
%{

lowA = low_res_anat.data;
mrvNewGraphWin;
histogram(lowA(:));

% mrvNewGraphWin; plot(T);


%% Clustering

% k-means on the time series?
%}
