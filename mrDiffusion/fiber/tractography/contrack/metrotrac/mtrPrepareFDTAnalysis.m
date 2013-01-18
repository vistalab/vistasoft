function mtrPrepareFDTAnalysis(bRunBedpost, bRunPostBedpost)
%
%  mtrPrepareFDTAnalysis(bRunBedpost, bRunPostBedpost)
%
%Author: AJS
%Purpose:
%   Prepare FDT analysis directories and run bedpost optionally and perform
%   post bedpost processing.
%
% HISTORY:
%  2007.07.15: AJS wrote it


%% Get the user input
if ieNotDefined('bRunBedpost')
    bRunBedpost=0;
end
if ieNotDefined('bRunPostBedpost')
    bRunPostBedpost=0;
end
if ieNotDefined('fdtDir')
    fdtDir = uigetdir('','FDT directory');
    if(isnumeric(fdtDir)), disp('Preparation canceled.'); return; end
end
fdtBedpostDir = [fdtDir '.bedpost'];

ogDir = pwd;

%% Create FDT directory
if ~exist(fdtDir,'dir')
    % Create FDT directory
    mkdir(fdtDir);

    % Copy necessary files into FDT directory
    if ieNotDefined('rawDir')
        rawDir = uigetdir(fileparts(fdtDir),'Raw directory');
        if(isnumeric(rawDir)), disp('Preparation canceled.'); return; end
    end
    if ieNotDefined('mrdDir')
        mrdDir = uigetdir(fileparts(fdtDir),'mrDiffusion directory');
        if(isnumeric(rawDir)), disp('Preparation canceled.'); return; end
    end
    copyfile(fullfile(rawDir,'rawDti_aligned.bvecs'),fullfile(fdtDir,'bvecs'));
    copyfile(fullfile(rawDir,'rawDti_aligned.bvals'),fullfile(fdtDir,'bvals'));
    copyfile(fullfile(rawDir,'rawDti_aligned.nii.gz'),fullfile(fdtDir,'data.nii.gz'));
    copyfile(fullfile(mrdDir,'bin','b0.nii.gz'),fullfile(fdtDir,'nodif.nii.gz'));
    copyfile(fullfile(mrdDir,'bin','brainMask.nii.gz'),fullfile(fdtDir,'nodif_brain_mask.nii.gz'));
    
    % Convert bvals and bvecs into appropriate format
    bvals = dlmread(fullfile(fdtDir,'bvals'));
    bvecs = dlmread(fullfile(fdtDir,'bvecs'));
    % XXX HACK because I am not sure if FDT can handle different bValue
    % units
    if max(bvals) < 10
        bvals=bvals*1000;
    end
    bvecs(1,:) = -bvecs(1,:);
    dlmwrite(fullfile(fdtDir,'bvecs'),bvecs,'\t');
    dlmwrite(fullfile(fdtDir,'bvals'),bvals,'\t');
end

%% Run bedpost
if bRunBedpost
    cd(fdtDir);
    % Run bedpost
    cmd = 'bedpost .';
    disp(cmd);
    if(ispc)
        mtrExecuteWinBash(cmd,pwd);
    else
        system(cmd,'-echo');
    end
    disp('Done');
end

%% Post bedpost processing
if bRunPostBedpost
    % Finish bedpost post process if it crashed
    % This is necessary if bedpost crashes after computing all the necessary
    % diffusion info, which happens frequently for some reason.
    if ~exist(fullfile(fdtBedpostDir,'merged_thsamples.nii.gz'),'file')
        cmd = ['finishBedpost ' fdtBedpostDir];
        disp(cmd);
        if(ispc)
            mtrExecuteWinBash(cmd,pwd);
        else
            system(cmd,'-echo');
        end
    end

    % Flip the resulting images along the X-axis
    cd(fdtBedpostDir);
    imageFiles = dir('*.nii.gz');
    for ff = 1:length(imageFiles)
        mtrMRD2FDTImage(imageFiles(ff).name);
    end
end

cd(ogDir);

return;
    
