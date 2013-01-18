function status = tfi_segment(subject,startFile);
% status = tfi_segment([subject],[startFile]):
%
% Use TFI toolbox (Jonas Larsson) and FSL (oxford) tools
% to create/segment a vAnatomy. [linux/unix only]
%
% subject: subject initials/designator. Prompts for it if
% it's not supplied. All files created will be tagged with
% it, e.g. jd_right.gray, jd_fslstrip.img.
%
% startFile: a path to either a vAnatomy.dat file, ANALYZE
% image file, or T1 anatomical Genesis I or DICOM file. 
%   *If a vAnat/ANALYZE file is specified, all the files 
% generated will be placed in the same directory as that
% file. If a vAnatomy is specified, an ANALYZE file 
% will be produced with the same name, but ending 
% in .img, e.g. 'vAnatomy.img'.
%   * If an I-file/DICOM file is specified, files will
% be placed one directory above the directory containing
% the Ifiles. In this case, two additional files will 
% be produced in that parent directory: a vAnatomy.dat file
% and a vAnatomy.img analyze file.
%
% Produces the following:
%   * left and right .class files: [subject]_left.class, etc.
%   * left and right .gray files: [subject]_left.gray, etc.
%   * a skull-stripped, intensity-normalized vAnatomy file:
%     'vAnatomy_strip.dat'
%   * a directory, 'segmentationFiles', containing a series
%     of intermediate ANALYZE format files and OFF-format 
%     meshes (you can check the TFI docs on Jonas' web page,
%     or look through the code to get a sense what each one
%     represents). 
%
%
% 02/05 ras.
if ieNotDefined('subject')
    subject = input('Enter subject initials / designator: ','s');
end

if ieNotDefined('startFile')
    startFile = fullfile(pwd,'vAnatomy.dat');
end

if ~exist(startFile,'file')
    error(sprintf('%s not found.',startFile));
end

status = 0;

% options for the scripts
opts = '-verbose'; 

% let's time this...
tic

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check that we can run everything on this %
% machine                                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isunix==0
    help(mfilename)
    error('Requires linux/unix.');
end

fslBase='/usr/local/fsl-3.0';
tfiBase = '/usr/local/TFI/';

if (ispref('VISTA','fslBase'))
    disp('Setting fslBase to the one specified in the VISTA matlab preferences:');
    fslBase=getpref('VISTA','fslBase');
    disp(fslBase);
end

if (ispref('VISTA','tfiBase'))
    disp('Setting tfiBase to the one specified in the VISTA matlab preferences:');
    fslBase=getpref('VISTA','tfiBase');
    disp(tfiBase);
end

fslPath=fullfile(fslBase,'bin'); % This is where FSL lives - should also be able to get this from a Matlab pref
tfiPath=fullfile(tfiBase,'bin'); % This is where Jonas' code lives - should also be able to get this from a Matlab pref

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 0) Ensure an analyze file exists of the volume        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% a) figure out where the segmentation dir will be
% based on what file is specified
if isempty(findstr(filesep,startFile))
    % relative path specified
    startFile = fullfile(pwd,startFile);
end
[parent fname ext] = fileparts(startFile);
switch lower(ext)
    case '.dat',    
        fprintf('Making Analyze from %s...\n',startFile);
        segDir = parent;
        vAnatPath = startFile;
        startImg = 'vAnatomy.img';
        [img mmpervox] = readVolAnat(startFile);
        img = permute(img,[3 2 1]);
        img = flipdim(img,2);
        img = flipdim(img,3);
        saveAnalyze(img,'vAnatomy',mmpervox);
    case '.img',
        segDir = parent;
        startImg = [fname ext];
        fprintf('Using Analyze file %s...\n',startImg);
    otherwise, % assume DICOM or I-file
        disp('Making Analyze from I-files...')
        segDir = fileparts(parent);
        if isempty(segDir)
            segDir = pwd;
        end
        vAnatPath = fullfile(segDir,'vAnatomy.dat');
        startImg = 'vAnatomy.img';
        makeAnalyzeFromIfiles(startFile,'vAnatomy');
end

% create a segmentation directory;
% copy the start analyze image there
callingDir = pwd;
cd(segDir);
if ~exist('SegmentationFiles','dir')
    mkdir SegmentationFiles
end
startHdr = [startImg(1:end-4) '.hdr'];
unix(sprintf('cp %s SegmentationFiles/',startImg));
unix(sprintf('cp %s SegmentationFiles/',startHdr));
segDir = fullfile(segDir,'SegmentationFiles');
cd(segDir);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1) Skull-strip/intensity normalize                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('\t***** 1) Skull-stripping / Intensity Normalizing... *****\n\n');

% do a first-pass noise preprocessing step 
% (may not always be necesary, but seems unlikely to hurt)
normImg = sprintf('%s_pre.img',subject);
cmd = sprintf(['ImagePreprocess.tcl -noise 5 -wiener -x0 -1 -y0 -1 -z0 -1 ',...
               '-x1 -1 -y1 -1 -z1 -1 -lo 0 -hi 10 %s %s %s'],opts,startImg,normImg)
s = unix(cmd);
if s ~= 0
    error('Error in step 1.');
end

% FSL Strip Normalize
cmd = sprintf('FSLStripNormalize.tcl %s %s %s.img',opts,normImg,subject)
s = unix(cmd);
if s ~= 0
    error('Error in step 1.');
end

stripImg = sprintf('%sStrip.img',subject);
cmd = sprintf('SkullStrip.tcl -contrast %s_fslstrip_intensities.txt %s %s.img %s',...
              subject,opts,subject,stripImg)
s = unix(cmd);
if s ~= 0
    error('Error in step 1.');
end

% skull-stripping doesn't always seem to work:
% so for now, let's use the fsl strip file
% stripImg = sprintf('%s_fslstrip.img',subject);

% Second-pass, a hack: 
fslStripImg = sprintf('%s_fslstrip.img',subject);
tfi_hackOffSkull(normImg,fslStripImg,stripImg);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2) Fill Basal Ganglia / Ventricles                    %                    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('\t***** 2) Filling in basal ganglia / ventricles... *****\n\n');

fillImg = sprintf('%s_fill_mask.img',subject);
cmd = sprintf('FillWhiteMatter.tcl %s %s %s',opts,stripImg,fillImg)
s = unix(cmd);
if s ~= 0
    error('Error in step 2.');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3) Separate out cerebellum + Brainstem                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('\t***** 3) Dividin L/R Hemispheres, Cerebellum+Brainstem... *****\n\n');

cmd = sprintf('SegmentHemispheres.tcl %s -mask %s %s %s',...
               opts,fillImg,stripImg,subject);
s = unix(cmd)
if s ~= 0
    error('Error in step 3.');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 4) Create left/white gray matter surfaces for each    %
%    hemisphere                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('\t***** 4) Generating Cortical Surfaces... *****\n\n');

leftSfc = sprintf('%s_lefthemisphere.off',subject);
leftTopo = sprintf('%s_topo_left.img',subject);
cmd = sprintf('GenerateSurfaces.tcl %s -mask %s -hemi %s %s %s',...
               opts,fillImg,leftSfc,stripImg,leftTopo);
s = unix(cmd);
if s ~= 0
    error('Error in step 4.');
end

rightSfc = sprintf('%s_righthemisphere.off',subject);
rightTopo = sprintf('%s_topo_right.img',subject);
cmd = sprintf('GenerateSurfaces.tcl %s -mask %s -hemi %s %s %s',...
               opts,fillImg,rightSfc,stripImg,rightTopo);
s = unix(cmd);
if s ~= 0
    error('Error in step 4.');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 5) [In the finished product, should prompt to check   %
%    results and do manual editing]                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('\t***** 5) [At this point you should manually edit the');
fprintf(' Cortical surfaces, but we''ll charge ahead...] *****\n\n');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 6) Optimize surface meshes to fit gray matter         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('\t***** 6) Optimizing Surfaces... *****\n\n');
 
% first, need to convert topological .img -> .off
leftTopoSfc = sprintf('%s_topo_left.off',subject);
cmd = sprintf('image2surf -lo 0.5 -hi 1.5 -it 2 %s %s',...
               leftTopo,leftTopoSfc)
s = unix(cmd);
if s ~= 0
    error('Error in step 6.');
end

rightTopoSfc = sprintf('%s_topo_right.off',subject);
cmd = sprintf('image2surf -lo 0.5 -hi 1.5 -it 2 %s %s',...
               rightTopo,rightTopoSfc)
s = unix(cmd);
if s ~= 0
    error('Error in step 6.');
end

% now, run the optimization routine
cmd = sprintf('OptimizeSurface.tcl %s -hemi %s -anat %s %s %s_left',...
               opts,leftSfc,stripImg,leftTopoSfc,subject)
s = unix(cmd);
if s ~= 0
    error('Error in step 6.');
end

cmd = sprintf('OptimizeSurface.tcl %s -hemi %s -anat %s %s %s_right',...
               opts,rightSfc,stripImg,rightTopoSfc,subject)
s = unix(cmd);
if s ~= 0
    error('Error in step 6.');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 7) Convert meshes to .gray files                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('\t***** 7) Converting results to mrVista .gray files... *****\n\n');

leftGraySfc = sprintf('%s_left_GM.off',subject);
leftGrayImg = sprintf('%s_left_GM.img',subject);
leftGrayFile = sprintf('%s_left.gray',subject);
leftWhiteSfc = sprintf('%s_left_WM.off',subject);
cmd = sprintf(['surf2graph -gmin 40 -gmax 120 -gsurface %s '...
               '-savelabels %s -gimage %s -gray %s %s'],...
               leftGraySfc,leftGrayImg,stripImg,...
               leftGrayFile,leftWhiteSfc)
s = unix(cmd);
if s ~= 0
    error('Error in step 7.');
end

rightGraySfc = sprintf('%s_right_GM.off',subject);
rightGrayImg = sprintf('%s_right_GM.img',subject);
rightGrayFile = sprintf('%s_right.gray',subject);
rightWhiteSfc = sprintf('%s_right_WM.off',subject);
cmd = sprintf(['surf2graph -gmin 40 -gmax 120 -gsurface %s '...
               '-savelabels %s -gimage %s -gray %s %s'],...
               rightGraySfc,rightGrayImg,stripImg,...
               rightGrayFile,rightWhiteSfc)
s = unix(cmd);
if s ~= 0
    error('Error in step 7.');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 8) Create .class files from .gray files               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('\t***** 8) Creating mrVista .class files... *****\n\n');

% first, make analyze images w/ filled white matter volumes
leftWhiteSfc = sprintf('%s_left_WM.off',subject);
leftWhiteImg = sprintf('%s_left_WM.img',subject);
cmd = sprintf('surf2image -fill -type value -format %s %s %s',...
               stripImg,leftWhiteSfc,leftWhiteImg);
s = unix(cmd);
if s ~= 0
    error('Error in step 8.');
end

rightWhiteSfc = sprintf('%s_right_WM.off',subject);
rightWhiteImg = sprintf('%s_right_WM.img',subject);
cmd = sprintf('surf2image -fill -type value -format %s %s %s',...
               stripImg,rightWhiteSfc,rightWhiteImg);
s = unix(cmd);
if s ~= 0
    error('Error in step 8.');
end

% ditto for GM surfaces
leftGraySfc = sprintf('%s_left_GM.off',subject);
leftGrayImg = sprintf('%s_left_GM.img',subject);
cmd = sprintf('surf2image -fill -type value -format %s %s %s',...
               stripImg,leftGraySfc,leftGrayImg);
s = unix(cmd);
if s ~= 0
    error('Error in step 8.');
end

rightGraySfc = sprintf('%s_right_GM.off',subject);
rightGrayImg = sprintf('%s_right_GM.img',subject);
cmd = sprintf('surf2image -fill -type value -format %s %s %s',...
               stripImg,rightGraySfc,rightGrayImg);
s = unix(cmd);
if s ~= 0
    error('Error in step 8.');
end

% now, construct class files from these images
leftClass = sprintf('%s_left.class',subject);
tfi_constructClassFile(leftWhiteImg,leftClass,leftGrayImg,fillImg);
rightClass = sprintf('%s_right.class',subject);
tfi_constructClassFile(rightWhiteImg,rightClass,rightGrayImg,fillImg);


%%%%%%%%%%%%%%%%%%%%%%%%%
%       Done!           %
%%%%%%%%%%%%%%%%%%%%%%%%%
% move the .class and .gray files to the parent dir
unix(sprintf('mv %s ..',leftGrayFile));
unix(sprintf('mv %s ..',rightGrayFile));
unix(sprintf('mv %s ..',leftClass));
unix(sprintf('mv %s ..',rightClass));

% make a vAnatomy of the stripped, normalized anatomy
% (later)

% finish up
status = 1;
cd(callingDir);
fprintf(' Total Time: %3.0f min %2.2f sec.\n',toc/60,mod(toc,60));
fprintf('\t***** Finished! Phew! *****\n\n');

return
