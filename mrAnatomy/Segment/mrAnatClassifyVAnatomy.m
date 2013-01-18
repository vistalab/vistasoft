function [wm, gm, csf] = mrAnatClassifyVAnatomy(volFileName,tissueProbThreshold,classFileNoExt)
% mrAnatClassifyVAnatomy - Read a vAnatomy.dat and apply SPM2 white matter classification 
%
% [wm, gm, csf] = mrAnatClassifyVAnatomy(fname,[tissueProbThreshold = 0],[classFileName])
%
% Examples:
%
%   [wm, gm, csf] = mrAnatClassifyVanatomy;
%   volFileName = '//snarp/u1/data/reading_longitude/dti/Test/t1/vAnatomy.dat';
%   mrAnatClassifyVanatomy(volFileName,[0 .01],'spmClass01.class');
%   [wm, gm, csf] = mrAnatClassifyVanatomy(volFileName,0.1,'myClassFile.class');
%
% HISTORY:
% 2005.06.05 BW, RFD, MBS wrote it.
% 2005.06.16 SOD some modification /split off mrAnatSpm2Class.m

if ieNotDefined('volFileName'), 
  volFileName = mrvSelectFile('r','dat','vAnatomy');
  if isempty(volFileName);return;end; % quit gracefully
  drawnow;
end;
if ieNotDefined('tissueProbThreshold'), 
  tissueProbThreshold = [0];
end;
if ieNotDefined('classFileNoExt'), 
  classFileNoExt = 'spmClass'; 
end;

% check for spm
spmDir = fileparts(which('spm_defaults'));
if isempty(spmDir), 
    errordlg('You must have spm2 on your path: \white\matlabToolbox\mri\spm2');
    return;
end

% make output directory
[mypath] = fileparts(volFileName);
if isempty(mypath),
  mypath=[pwd filesep];
else,
  mypath=[mypath filesep];
end;
warning off MATLAB:MKDIR:DirectoryExists;
mkdir(mypath,'spmSegmentation');
outputDirectory = [mypath 'spmSegmentation' filesep];

% load
[vol, mmPerPix, vSize, filename, format] = loadVolume(volFileName);

% Build the parameters needed to call SPM segmenter. Then call it.
% First the we need the transformation from image coordinates into physical
% units (mm).
xformImage2Physical = mrAnatXform(mmPerPix,vSize,'vanatomy2acpc');

% To check the xform make a montage.  These should be axial images with eyes
% facing to the right. 
%
% newvol = mrAnatResliceSpm(vol, inv(xformImage2Physical)); 
% imagesc(makeMontage(newvol)); colormap(gray); axis equal
% 

fprintf('[%s]:SPM Segmenter...',mfilename);
templateFileName = fullfile(spmDir, 'templates', 'T1.mnc');
[wm, gm, csf] = mrAnatSpmSegment(vol,xformImage2Physical,templateFileName);
fprintf('Done.\n');

% save SPMsegments wm gm csf
save([outputDirectory classFileNoExt],'wm','gm','csf');

% Create the mrGray class file from SPM's segmentation.  
mrAnatSpm2Class([outputDirectory classFileNoExt],tissueProbThreshold);
return;
