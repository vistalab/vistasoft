function mtrStratifiedTwoRoiSamplerSetup(dt6File, roi1File, roi2File, samplerOptsFile, fgFile, logFile, outDir, stratDist)
% Runs MetroTrac for generating a distribution of pathways between 2 ROIs.
% 
%  mtrTwoRoiSampler(dt6File, roi1File, roi2File, samplerOptsFile, fgFile)
%
% The metroTrac output paths are saved in the fgFile
%
% Examples:   
%
% See also: mtrTwoRoiScript
%
% AJS
%

% Make sure all inputs to the script exist or get them
if (ieNotDefined('dt6File'))
    [f,p] = uigetfile('*.mat', 'Load the dt6 file');
    dt6File = fullfile(p,f);
end
if (ieNotDefined('samplerOptsFile')) 
    [f,p] = uigetfile('*.txt', 'Load the MetroTrac options file');
    samplerOptsFile = fullfile(p,f);
end
if (ieNotDefined('roi1File')) 
    [f,p] = uigetfile('*.mat', 'Load the ROI 1 file');
    roi1File = fullfile(p,f);
end
if (ieNotDefined('roi2File')) 
    [f,p] = uigetfile('*.mat', 'Load the ROI2 file');
    roi2File = fullfile(p,f);
end
if (ieNotDefined('fgFile'))
    [f,p] = uiputfile('*.dat', 'Save fibers (MetroTrac format)');
    if(isnumeric(f)) error('user canceled.'); end
    fgFile = fullfile(p,f);
end
if (ieNotDefined('logFile'))
    logFile = [];
end

% Here is the dt6, probably don't need this if we expect the bin directory
% to exist
dt = load(dt6File);
dt.dt6(isnan(dt.dt6)) = 0;

% Get sampler options file
fid = fopen(samplerOptsFile,'r');
if(fid ~= -1)
    fclose(fid);
    mtr = mtrLoad(samplerOptsFile,dt.xformToAcPc);
end

% Put second ROI into MetroTrac structure
roi1 = dtiReadRoi(roi1File); % roi = dtiReadRoi(roi1File, dt.t1NormParams);

roi2 = dtiReadRoi(roi2File); % roi = dtiReadRoi(roi2File, dt.t1NormParams);
mtr = mtrSet(mtr,'roi',roi2.coords,2,'coords');

% Try to make the supplied directory
mkdir(outDir);

% Make a params file for each coord in the first ROI
for cc = 1:size(roi1.coords,1)
    newcoords = roi1.coords(cc,:) - 0.5*stratDist;
    newcoords(2,:) = roi1.coords(cc,:) + 0.5*stratDist;
    mtr = mtrSet(mtr,'roi',newcoords,1,'coords');
    mtrSave(mtr,samplerOptsFile,xform);
    filename = sprintf('met_params_%d.txt',cc);
    samplerOptsFile = fullfile(outDir,filename);
end

%fg = mtrPaths(mtr, dt.xformToAcPc, samplerOptsFile, fgFile, logFile);

% No need to write out fibers as that is already done in mtrPaths