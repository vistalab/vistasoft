function rescaleROIs(sourceRes, targetRes, sourceDir, targetDir)
% rescaleROIs(sourceRes, targetRes, [sourceDir], [targetDir])
%
% Purpose: Convert ROI from one spatial resolution to another. 
% 
% written by JW 04.02.08
%
%   inputs: 
%
%       sourceRes: 3d resolution of ROIs in source dir, in mm (e.g, [1 1 1])
%       targetDir: 3d resolution of new ROIs, in mm (e.g, [0.7 0.7 0.7])
%       sourceDir: a source directory containing ROIs; default = pwd
%       targetDir: a destination directory; default = sourceDir


if ieNotDefined('sourceDir'), sourceDir = pwd; end
if ieNotDefined('targetDir'), targetDir = sourceDir; end


scaleFactor = diag(sourceRes/diag(targetRes));

%% find all .mat files in the source directory
currentDir = pwd;
cd(sourceDir);

w = dir('*.mat');
fileList = {w.name};

for i = 1:length(fileList)
    load (fileList{i})
    ROI.coords = single(round(scaleFactor * ROI.coords));
    savePath = fullfile(targetDir, [ROI.name '_resampled.mat']);
    save (savePath, 'ROI')
end

cd(currentDir);
