function fileNameList=prepareAnatomyNew(inFile,outFileRoot,BET_Level,clobber,monkeyFlag);
% fileNameList=BV_PrepAnalyzeAnatomy([inFile],[outFileRoot],[BET_Level],[clobber]);
% 
% Take an analyze file and processes it to produce
% an anatomy file suitable for BrainVoyager's automatic segmentation routine.
% You might also like to use this file as a starting point for segmentation in mrGray.
% 
% INPUT: inFile: analyze file used as input. This might be the output of makeAverageAnalyze
%        outFileRoot: Intermediate analyze files and the final .VMR file will be output using this 
%                    name as a root. For example, if it's 'joe_bloggs' then you will generate a final
%                   output file called 'joe_bloggs_prepped.vmr';
%        BET_Level : (Optional : Default =0.4) . The Brain Extraction Tool (BET) from the FSL
%                   toolbox uses this value to determine how enthusiastic to be when skull stripping. 
%                   Lower value mean more skull (and potentially more cortex) will be stripped.
%        clobber: (default = 1) if(~clobber) then existing files will not
%                  be overwritten. The steps taht generate those files will be
%                  skipped.
%
% Our aim is to use the fsl tools to perform the initial stages of the BrainVoyager
% anatomy segmentation: removal of the inhomogeneity, iso-voxel resampling, talairach 
% alignment.
% But we want to avoid any sort of rescaling or shearing.
% The hope is that BV can segment a volume like this even if it's not
% scaled to Talairach coordinates.
% EXAMPLE: 
%          BV_PrepAnatomy('./Ifiles/I','joe_bloggs',0.3);
% ARW 093002: Wrote it
% 2002.11.11 RFD: added default for outFileRoot, cleaned a bit.
% 2002.12.09 RFD: changed to sinc interpolation.
% $Author: wade $
% $Date: 2005/01/06 00:40:13 $

% Martin installed fsl on white so we may not even have to set these two
% paths...
% Set default locations for the FSL toolbox and the reference volume.
% This version seeks to iron out a few small issues: Ideally we now take
% .nii files to improve compatibility with UCSF NIC system and maintain
% orientation info.

tic

    if(ispc)
     error('This version of prepareAnatomy does not work on Windows');
        
    else
       disp('Assuming UNIX-ish settings');

        % Here's where the unix version might be
        fslBase = '/raid/MRI/toolbox/FSL/fsl4_centos5/';
        BETcommand='bet';
        FASTcommand='fast';
        FLIRTcommand='flirt';
    end

    % You can also set a matlab preference
    % VISTA:fslBase. This will override the 
    % settings above
    if (ispref('VISTA','fslBase'))
        disp('Settingn fslBase to the one specified in the VISTA matlab preferences:');
        fslBase=getpref('VISTA','fslBase');
        disp(fslBase);
    end
    
    fileExt='.nii';
    
%if(fslDir(end)~='/') fslDir = [fslDir,'/']; end

fslPath=fullfile(fslBase,'bin')

%refFile='/usr/local/fsl/BV_RefImages/iso_acpc_tal_ref'; % This is a volume that we took from BV. It has been rotated, aligned 
                                                         % and morphed so that it fits the BV template. 
if(~exist('clobber','var') | isempty(clobber))
    clobber = 1;
end
if(~exist('monkeyFlag','var'))
monkeyFlag=0;
end

if (monkeyFlag)
    disp('Using monkey reference');
    
refFile=fullfile(fslBase,'BV_RefImages','macaque');
else
refFile=fullfile(fslBase,'BV_RefImages','iso_acpc_tal_ref');
end

fprintf('\nReference file:%s',refFile);

% Parse the inFile
if (~exist('inFile','var') | isempty(inFile))
    % You can call this routine with no arguments. It'll prompt you for an input file...
    [inFileRootName,inFileRootPath]=uigetfile('*');
    inFile=fullfile(inFileRootPath,inFileRootName);
end

% Strip off the suffix (if it exists)
[p,f,e] = fileparts(inFile);
inFile = fullfile(p,f);

if (~exist('outFileRoot','var') | isempty(outFileRoot))
    % add an 'r' for 'resliced'
    outFileRoot = [inFile,'r'];
end

% BET_Level: A parameter passed to the BET routine that says how much skull to strip. Lower is more.
if (~exist('BET_Level','var') | isempty(BET_Level))
    BET_Level=0.4;
end

% The reference image has been skull stripped. So do the same to the source image
disp('Doing brain extraction');
brainFile=[outFileRoot,'_brain'];
maskFile = [brainFile,'_mask']; 

% Note the -m command here - outputs a binary brain image (maskFile). 
% We use this later to reconstruct the full brain (with skull).
% Note also the -B option. The new version of bet in FSL4 uses this option
% to indicate that it should do a better job of bias correction and dealing
% with structures in the neck.

fslCommand=[fullfile(fslPath,BETcommand),' ',inFile,' ',brainFile,' -B -m -f ',num2str(BET_Level)]

if(~clobber & exist([brainFile,fileExt],'file') & exist([maskFile,fileExt],'file'))
    disp(['Skipping- ',brainFile,' exists. Use clobber flag to force overwrite.']);
else
    dos(fslCommand);
end

% Do FAST inhomogeneity correction at this point. The image is smaller than
% it is after FLIRT so FAST will be, well, faster..
homogBrainFile=[brainFile,'_homog'];
% This fslCommand (fast) will add a _restore to the output file.
homogBrainFileRestore = [homogBrainFile,'_restore'];

if(~clobber & exist([homogBrainFileRestore,fileExt],'file'))
    movefile([homogBrainFileRestore,fileExt],[homogBrainFile,fileExt]);
 %   movefile([homogBrainFileRestore,'.hdr'],[homogBrainFile,'.hdr']);
end

disp('Doing inhomogeneity correction');
fslCommand=[fullfile(fslPath,FASTcommand),' -t1 -od ',homogBrainFile,' -or -n -v3 ',brainFile];
if(~clobber & exist([homogBrainFile,fileExt],'file'))
    disp(['Skipping- ',homogBrainFile,' exists. Use clobber flag to force overwrite.']);
else
    dos(fslCommand);
    % This movefile stuff is breaking all the time on network drives and windows boxes.
    % Perhaps it takes too long to copy the file before the delete command
    % starts?
    % Whatever - since the file is an intermediate anyway, let's make life
    % simple and just work with the filename extension that FSL provides...
    homogBrainFile=homogBrainFileRestore;
    
%     movefile([homogBrainFileRestore,'.img'],[homogBrainFile,'.img']);
%     movefile([homogBrainFileRestore,'.hdr'],[homogBrainFile,'.hdr']);
end


% Generate an image that consists of the homogeneous brain and the original skull.
% The source should be the image without the skull, since the mask is a brain
% mask.
Source = homogBrainFile; 
Destination = inFile; 
homogBrainSkullFile = [homogBrainFile,'_Skull'];
*** THIS IS WHERE WE ARE. THIS IS WHAT NEEDS TO BE EDITED NEXT! BV_CombineWithMask(Source, Destination, maskFile, homogBrainSkullFile,1);

% Now align the brain-stripped, homogi
file to the reference volume.
% Restricting it to 6 degrees of freedom means that it can only do translations and
% rotation. Note that the output from here will also be resampled to 1x1x1 and 
% embedded in a 256x256x256 array. Note also that this part can take a really long 
% time (ca 2 hrs on a P450 linux box). And note >also< that we save out the xform 
% matrix so that we can apply it to other volumes (notably the brain+skull image we just created)
disp('Finding alignment between reference brain and this one');

homogBrainAlignedFile = [homogBrainFile,'_aligned'];
alignmentMatrix = [homogBrainAlignedFile,'_XFORM.dat'];
fslCommand = [fullfile(fslPath,FLIRTcommand),' -in ',homogBrainFile,' -ref ',refFile,...
        ' -out ',homogBrainAlignedFile,' -omat ',alignmentMatrix,' -dof 6 -verbose 3',...
        ' -interp sinc -sincwidth 7 -sincwindow hanning']
disp('Starting first alignment step:');
if(~clobber & exist([homogBrainAlignedFile,'.img'],'file') & exist(alignmentMatrix,'file'))
    disp(['Skipping- ',homogBrainFile,' exists. Use clobber flag to force overwrite.']);
else
    dos(fslCommand);
end

% Now also apply the transform to the original (non-skull-stripped) file
homogBrainSkullAlignedFile = [homogBrainSkullFile,'_aligned'];
disp('Aligning original homogeneous file');
fslCommand = [fullfile(fslPath,FLIRTcommand),' -in ',homogBrainSkullFile,' -ref ',refFile,...
        ' -applyxfm -init ',alignmentMatrix,' -out ',homogBrainSkullAlignedFile,...
    ]
if(~clobber & exist([homogBrainSkullAlignedFile,fileExt],'file'))
    disp(['Skipping- ',homogBrainSkullAlignedFile,' exists. Use clobber flag to force overwrite.']);
else
    dos(fslCommand);
end

% In case the homogeneity correction screwed things up, apply it to the
% % non-corrected brian too.
disp('Aligning original file');
brainAlignedFile = [brainFile,'_aligned'];
fslCommand = [fullfile(fslPath,FLIRTcommand),' -in ',brainAlignedFile,' -ref ',refFile, ...
        ' -applyxfm -init ',alignmentMatrix,' -out ',homogBrainSkullAlignedFile,...
        ' -interp sinc -sincwidth 7 -sincwindow hanning']
if(~clobber & exist([brainAlignedFile,fileExt],'file'))
    disp(['Skipping- ',brainAlignedFile,' exists. Use clobber flag to force overwrite.']);
else
    dos(fslCommand);
end

% The resulting image is correctly aligned in analyze format. But BV has some problem reading these
% files (it flips U/P and permutes the dimensions). So we write out an analyze file that BV will read in the 
% correct orientation. It will have the suffix 'permuted'
% homogBrainAlignedBVFile = [homogBrainAlignedFile,'_BV'];
% BV_rotateAnalyze(homogBrainAlignedFile,[],homogBrainAlignedBVFile);

% We also write it out in .VMR format
%BV_analyze2VMR(homogBrainAlignedBVFile,[homogBrainAlignedBVFile,'.VMR']);
%analyze2mrGrayAnatomy(homogBrainAlignedFile);
disp(['Finished. You may want to run analyze2mrGrayAnatomy(''',...
        homogBrainSkullAlignedFile,''') to generate a mrGray file.']);
toc
return;

