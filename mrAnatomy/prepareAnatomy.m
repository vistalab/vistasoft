function fileNameList= prepareAnatomy(inFile,outFileRoot,BET_Level,clobber,monkeyFlag);
% fileNameList = prepareAnatomy([inFile],[outFileRoot],[BET_Level],[clobber]);
% 
% Take an analyze file and processes it to produce
% an anatomy file suitable for BrainVoyager's automatic segmentation routine.
% You might also like to use this file as a starting point for segmentation in mrGray.
% 
% INPUT: inFile: analyze file used as input. This might be the output of averageAnalyze
%        outFileRoot: Intermediate analyze files and the final .VMR file will be output using this 
%                       name as a root. For example, if it's 'joe_bloggs' then you will generate a final
%                       output file called 'joe_bloggs_prepped.vmr';
%        BET_Level : (Optional : Default =0.4) . The Brain Extraction Tool (BET) from the FSL
%                   toolbox uses this value to determine how enthusiastic to be when skull stripping. 
%                   Lower value mean more skull (and potentially more cortex) will be stripped.
%        clobber: (default = 1) if(~clobber) then existing files will not
%                  be overwritten. The steps that generate those files will be
%                  skipped.
%
% Our aim is to use the fsl tools to perform the initial stages of the BrainVoyager
% anatomy segmentation: removal of the inhomogeneity, iso-voxel resampling, talairach 
% alignment.
%
% But we want to avoid any sort of rescaling or shearing.
% The hope is that BV can segment a volume like this even if it's not
% scaled to Talairach coordinates.
%
% EXAMPLE: 
%          BV_PrepAnatomy('./Ifiles/I','joe_bloggs',0.3);
%
% ARW 093002: Wrote it
% 2002.11.11 RFD: added default for outFileRoot, cleaned a bit.
% 2002.12.09 RFD: changed to sinc interpolation.
% 2003.06.21 DHB: modified comments to match reality , cleaned up code.
% $Author: bob $
% $Date: 2003/12/20 00:01:51 $

% Diagnostic printouts and plots?
DIAGNOSTICPLOTS = 1;

% Set default locations for the FSL toolbox and the reference volume.
if (ispref('mrVista','fslBase'))
    fslBase = getpref('mrVista','fslBase');
else
    if(ispc)
        % Are we on a PC system? Here's where we assume the Windows version
        % of FSL to be...
        fslBase='x:\toolbox\fsl\fsl_win\';
    else
        % Here's where the unix version might be
        fslBase = '/usr/local/fsl/';
    end
end
fslPath=fullfile(fslBase,'bin')

% Set default names for FSL commands according to platform.
if(ispc)
    BETcommand='bet_16si';
    FASTcommand='fast';
    FLIRTcommand='flirt';  
else
    BETcommand='bet';
    FASTcommand='fast';
    FLIRTcommand='flirt';
end
 
if(~exist('clobber','var') | isempty(clobber))
    clobber = 1;
end
if(~exist('monkeyFlag','var') | isempty(monkeyFlag))
    monkeyFlag=0;
end

% Reference volume.  This is a volume that we took from BV. It has been rotated, aligned 
% and morphed so that it fits the BV template.  It needs to be installed in
% the fsl path.
refFile=fullfile(fslBase,'BV_RefImages','iso_acpc_tal_ref');
fprintf('BV Reference file is %s\n',refFile);
  
% Parse the inFile
if (~exist('inFile','var') | isempty(inFile))
    % You can call this routine with no arguments. It'll prompt you for an input file...
    [inFileRootName,inFileRootPath]=uigetfile('*.img','Select an Analyze file...');
    inFile=fullfile(inFileRootPath,inFileRootName);
end

% Strip off the suffix (if it exists)
[p,f,e] = fileparts(inFile);
inFile = fullfile(p,f);

% Do something smart if outfile isn't passed
if (~exist('outFileRoot','var') | isempty(outFileRoot))
    % add an 'r' for 'resliced'
    outFileRoot = [inFile,'r'];
end

% BET_Level: A parameter passed to the BET routine that says how much skull to strip. Lower is more.
if (~exist('BET_Level','var') | isempty(BET_Level))
    BET_Level=0.4;
end

% Diagnostics
if (DIAGNOSTICPLOTS)
	origImg = loadAnalyze(inFile,'ieee-le',0);
	fprintf('Original image %s:\n\tmin = %g, max = %g, mean = %g\n', ...
        inFile,min(origImg(:)),max(origImg(:)),mean(origImg(:)));
	figure(1); clf; subplot(2,3,1);
	imshow(origImg(:,:,round(size(origImg,3)/2)),[]);
	title('Original');
	clear origImg
end

% The reference image has been skull stripped. So do the same to the source
% image.
%
% Note the -m command here - outputs a binary brain image (maskFile). 
% We use this later to reconstruct the full brain (with skull).
disp('Doing brain extraction');
brainFile=[outFileRoot,'_brain'];
maskFile = [brainFile,'_mask']; 
fslCommand=[fullfile(fslPath,BETcommand),' ',inFile,' ',brainFile,' -m -f ',num2str(BET_Level)];
fprintf('BET command: %s\n',fslCommand);
if(~clobber & exist([brainFile,'.img'],'file') & exist([maskFile,'.img'],'file'))
    disp(['Skipping- ',brainFile,' exists. Use clobber flag == 1 to force overwrite.']);
else
    dos(fslCommand);
end

% Diagnostic
if (DIAGNOSTICPLOTS)
	brainImg = loadAnalyze(brainFile,'ieee-le',0);
	fprintf('Extracted image %s:\n\tmin = %g, max = %g, mean = %g\n', ...
        brainFile,min(brainImg(:)),max(brainImg(:)),mean(brainImg(:)));
	figure(1); subplot(2,3,2);
	imshow(brainImg(:,:,round(size(brainImg,3)/2)),[]);
	title('Brain Extracted');
	clear brainImg
end

% Do FAST inhomogeneity correction at this point. The image is smaller
% than it is after FLIRT so FAST will be, well, faster..
homogBrainFile=[brainFile,'_homog'];

% This fslCommand (fast) will add a _restore to the output file.
homogBrainFileRestore = [homogBrainFile,'_restore'];
if (~clobber & exist([homogBrainFileRestore,'.img'],'file'))
    movefile([homogBrainFileRestore,'.img'],[homogBrainFile,'.img']);
    movefile([homogBrainFileRestore,'.hdr'],[homogBrainFile,'.hdr']);
end

disp('Doing inhomogeneity correction');
fslCommand=[fullfile(fslPath,FASTcommand),' -t1 -od ',homogBrainFile,' -or -n -v3 ',brainFile];
fprintf('FAST command: %s\n',fslCommand);
if(~clobber & exist([homogBrainFile,'.img'],'file'))
    disp(['Skipping- ',homogBrainFile,' exists. Use clobber flag to force overwrite.']);
else
    dos(fslCommand);
    % The movefile stuff commented out below was breaking all the time on network
    % drives and windows boxes.
    % Perhaps it takes too long to copy the file before the delete command
    % starts?
    % Whatever - since the file is an intermediate anyway, let's make life
    % simple and just work with the filename extension that FSL provides...
    %
    % movefile([homogBrainFileRestore,'.hdr'],[homogBrainFile,'.hdr']);
    % movefile([homogBrainFileRestore,'.img'],[homogBrainFile,'.img']);
    homogBrainFile=homogBrainFileRestore;
end

% Diagnostics
if (DIAGNOSTICPLOTS)
	homogImg = loadAnalyze(homogBrainFile,'ieee-le',0);
	fprintf('Momogneous image %s:\n\tmin = %g, max = %g, mean = %g\n', ...
        homogBrainFile,min(homogImg(:)),max(homogImg(:)),mean(homogImg(:)));
	figure(1); subplot(2,3,3);
	imshow(homogImg(:,:,round(size(homogImg,3)/2)),[]);
	title('Homogeneous');
	clear homogImg
end

% Generate an image that consists of the homogeneous brain and the original skull.
% The source should be the image without the skull, since the mask is a brain
% mask.
Source = homogBrainFile; 
Destination = inFile; 
homogBrainSkullFile = [homogBrainFile,'_Skull'];
combineWithMask(Source, Destination, maskFile, homogBrainSkullFile, 0);
if (DIAGNOSTICPLOTS)
	skullImg = loadAnalyze(homogBrainSkullFile,'ieee-le',0);
	fprintf('Skull image %s:\n\tmin = %g, max = %g, mean = %g\n', ...
        homogBrainSkullFile,min(skullImg(:)),max(skullImg(:)),mean(skullImg(:)));
	figure(1); subplot(2,3,4);
	imshow(skullImg(:,:,round(size(skullImg,3)/2)),[]);
	title('Skull');
	clear skullImg
end

% Now align the brain-stripped, homog file to the reference volume.
% Restricting it to 6 degrees of freedom means that it can only do translations and
% rotation. Note that the output from here will also be resampled to 1x1x1 and 
% embedded in a 256x256x256 array. Note also that this part can take a really long 
% time (ca 2 hrs on a P450 linux box). And note >also< that we save out the xform 
% matrix so that we can apply it to other volumes (notably the brain+skull image we just created)
fprintf('Finding alignment between reference brain and this one\n');
homogBrainAlignedFile = [homogBrainFile,'_aligned'];
alignmentMatrix = [homogBrainAlignedFile,'_XFORM.dat'];
fslCommand = [fullfile(fslPath,FLIRTcommand),' -in ',homogBrainFile,' -ref ',refFile,...
        ' -out ',homogBrainAlignedFile,' -omat ',alignmentMatrix,' -dof 6 -verbose 3',...
        ' -interp sinc -sincwidth 7 -sincwindow hanning'];
fprintf('FLIRT command: %s\n',fslCommand);
fprintf('Starting first alignment step:\n');
if(~clobber & exist([homogBrainAlignedFile,'.img'],'file') & exist(alignmentMatrix,'file'))
    disp(['Skipping- ',homogBrainAlignedFile,' exists. Use clobber flag to force overwrite.']);
else
    dos(fslCommand);
end
if (DIAGNOSTICPLOTS)
	alignImg = loadAnalyze(homogBrainAlignedFile,'ieee-le',0);
	fprintf('Aligned image %s:\n\tmin = %g, max = %g, mean = %g\n', ...
        homogBrainAlignedFile,min(alignImg(:)),max(alignImg(:)),mean(alignImg(:)));
	figure(1); subplot(2,3,5);
	imshow(alignImg(:,:,round(size(alignImg,3)/2)),[]);
	title('Aligned No Skull');
	clear alignImg
end

% Now also apply the transform to the original (non-skull-stripped) file
homogBrainSkullAlignedFile = [homogBrainSkullFile,'_aligned'];
fprintf('Aligning original homogeneous file\n');
fslCommand = [fullfile(fslPath,FLIRTcommand),' -in ',homogBrainSkullFile,' -ref ',refFile,...
        ' -applyxfm -init ',alignmentMatrix,' -out ',homogBrainSkullAlignedFile,...
        ' -interp sinc -sincwidth 7 -sincwindow hanning'];
fprintf('FLIRT command: %s\n',fslCommand);
if(~clobber & exist([homogBrainSkullAlignedFile,'.img'],'file'))
    disp(['Skipping- ',homogBrainSkullAlignedFile,' exists. Use clobber flag to force overwrite.']);
else
    dos(fslCommand);
end
if (DIAGNOSTICPLOTS)
	alignSkullImg = loadAnalyze(homogBrainSkullAlignedFile,'ieee-le',0);
	fprintf('Aligned image %s:\n\tmin = %g, max = %g, mean = %g\n', ...
        homogBrainSkullAlignedFile,min(alignSkullImg(:)),max(alignSkullImg(:)),mean(alignSkullImg(:)));
	figure(1); subplot(2,3,6);
	imshow(alignSkullImg(:,:,round(size(alignSkullImg,3)/2)),[]);
	title('Aligned Skull');
	clear alignSkullImg
end

% In case the homogeneity correction screwed things up, apply it to the
% non-corrected brian too.
%
%  This is currently commented out.
%
% disp('Aligning original file');
% brainAlignedFile = [brainFile,'_aligned'];
% fslCommand = [fullfile(fslPath,FLIRTcommand),' -in ',brainAlignedFile,' -ref ',refFile, ...
%         ' -applyxfm -init ',alignmentMatrix,' -out ',homogBrainSkullAlignedFile,...
%         ' -interp sinc -sincwidth 7 -sincwindow hanning']
% if(~clobber & exist([brainAlignedFile,'.img'],'file'))
%     disp(['Skipping- ',brainAlignedFile,' exists. Use clobber flag to force overwrite.']);
% else
%     dos(fslCommand);
% end

% The resulting image is correctly aligned in analyze format. But BV has some problem reading these
% files (it flips U/P and permutes the dimensions). So we write out an analyze file that BV will
% read in the correct orientation. It will have the suffix 'permuted'.
%
% This is currently commented out.
%
% homogBrainAlignedBVFile = [homogBrainAlignedFile,'_BV'];
% BV_rotateAnalyze(homogBrainAlignedFile,[],homogBrainAlignedBVFile);

% We can also write it out in .VMR format.
%
% This is currently commented out.
%
% BV_analyze2VMR(homogBrainAlignedBVFile,[homogBrainAlignedBVFile,'.VMR']);
% analyze2mrGrayAnatomy(homogBrainAlignedFile);

% Say we're done.
fprintf(['Finished. You may want to run createVolAnat(''',...
        homogBrainSkullAlignedFile,''') to generate a mrGray file.']);
