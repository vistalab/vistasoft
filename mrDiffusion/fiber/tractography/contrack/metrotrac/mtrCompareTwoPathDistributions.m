function [corrSummary] = mtrCompareTwoPathDistributions(path1Filename, path2Filename, dt6Filename)

% Path1
if( ieNotDefined('path1Filename') )
    [f,p] = uigetfile({'*.dat';'*.*'},'Select the first path file...');
    if(isnumeric(f)), disp('Loading path file cancelled.'); return; end
    path1Filename = fullfile(p,f); 
    % or for base name
    %filename = fullfile(p,f(1:end-3));
end

% Lets calculate density image if it doesn't exist already
densityFilename = [path1Filename(1:end-3) 'nii.gz'];
fd1Img = [];
if (length(dir(densityFilename)) == 0)
    % Compute density image
    if( ieNotDefined('dt6Filename') )
        [f,p] = uigetfile({'*.mat';'*.*'},'Select the dt6 file...');
        if(isnumeric(f)), disp('Loading dt6 file cancelled.'); return; end
        dt6Filename = fullfile(p,f);
    end
    dt6 = load(dt6Filename);
    imSize = size(dt6.anat.img);imSize = imSize(1:3);
    mmPerVoxel = [2 2 2];
    xformImgToAcpc = dt6.anat.xformToAcPc;
    
    fg = mtrImportFibers(path1Filename, dt6.xformToAcPc);
    disp('Calculating fiber density map ...');
    fd1Img = dtiComputeFiberDensityNoGUI(fg, xformImgToAcpc, imSize, 1);
    msg = sprintf('Saving density image to %s ...',densityFilename);
    disp(msg);
    dtiWriteNiftiWrapper(fd1Img, dt6.anat.xformToAcPc, densityFilename);
else
    % Load density image
    msg = sprintf('Loading %s ...',densityFilename);
    disp(msg);
    ni = niftiRead(densityFilename);
    fd1Img = ni.data;
end
    
% 2
if( ieNotDefined('path2Filename') )
    [f,p] = uigetfile({'*.dat';'*.*'},'Select the second path file...');
    if(isnumeric(f)), disp('Loading path file cancelled.'); return; end
    path2Filename = fullfile(p,f); 
end

% Lets calculate density image if it doesn't exist already
densityFilename = [path2Filename(1:end-3) 'nii.gz'];
fd2Img = [];
if (length(dir(densityFilename)) == 0)
    % Compute density image
    if( ieNotDefined('dt6Filename') )
        [f,p] = uigetfile({'*.mat';'*.*'},'Select the dt6 file...');
        if(isnumeric(f)), disp('Loading dt6 file cancelled.'); return; end
        dt6Filename = fullfile(p,f);
    end
    dt6 = load(dt6Filename);
    imSize = size(dt6.anat.img);imSize = imSize(1:3);
    mmPerVoxel = [2 2 2];
    xformImgToAcpc = dt6.anat.xformToAcPc;
    
    fg = mtrImportFibers(path2Filename, dt6.xformToAcPc);
    disp('Calculating fiber density map ...');
    fd2Img = dtiComputeFiberDensityNoGUI(fg, xformImgToAcpc, imSize, 1);
    msg = sprintf('Saving density image to %s ...',densityFilename);
    disp(msg);
    dtiWriteNiftiWrapper(fd2Img, dt6.anat.xformToAcPc, densityFilename);
else
    % Load density image
    msg = sprintf('Loading %s ...',densityFilename);
    disp(msg);
    ni = niftiRead(densityFilename);
    fd2Img = ni.data;
end

cc = corrcoef(fd1Img(:),fd2Img(:));
corrSummary = cc(1,2);

