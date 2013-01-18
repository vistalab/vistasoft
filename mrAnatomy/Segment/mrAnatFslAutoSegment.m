function mrAnatFslAutoSegment(segToRun,t1File,outDir,betFile,betThresh,betOpt,convert,smooth,fName)
% mrAnatFslAutoSegment(segToRun,[t1File],[outDir],[betFile],[betThresh],[betOpt],[convert],[smooth],[fName])

% This function will run a subject's t1 anatomical image through FSL's
% automatic segmentation pipleline. The user can choose if they want to run
% FIRST, FAST, or BOTH. BET will be automatically run if a betFile does not
% exist in the directory and the user does not provide one. 
% 
% Soft links to the files used for segmentation will be placed in the
% outDir to remind the user later which images were used. 

% You will need to: 
%   1. Have FSL installed and in your unix path. VISTA Lab: See
%      http://white.stanford.edu/newlm/index.php/FSL for help with this.
%   2. Have a t1 file
%   3. Set the input args 
%       * segToRun:
%           - 'first' = Run FIRST (only)
%           - 'fast'  = Run FAST (only)
%           - 'all'   = Run FIRST and FAST
%       * t1File 
%           - Full path to t1 nifti file
%       * outDir
%           - Full path to where you want the files placed (defaults to fullfile((mrvDirup(t1File)), 'seg','fsl');
%       * betFile
%           - Full path to brain extracted image (if you have one).
%       * betThresh
%           - Defaults to .04
%       * betOpt
%           - String of options allows you to set other options (e.g., -m).
%       * convert
%           - 1 or 0 - if 1 (true) mrGrayConvertFirstToClass
%             will be run to convert the segmentation to a "class" file that
%             has left and right lables etc. Default = 1. If you don't want
%             it to run set to 0.
%       * smooth
%           - num (e.g, 3) that specifies a kernel size to smooth the
%             resulting segmentation when passed into% If the segmentation
%             file does not exist run this code - this will
%             allow us to loop through all of the subjects and run the
%             classification. mrGrayConvertFirstToClass. Defaults to 0. Can
%             be multiple values [0 1 2]. The script will write out
%             seperate images with each value applied.
%       * fname
%           - fname allows the user to set a uniqe file name root for the
%             files that are created.
%             
%   4. Wait... it takes a while. ~5 min for FAST and ~30 for FIRST

% HISTORY:
% 2010.08.04 LMP Wrote the thing.
% 2010.10.21 LMP copied from dtiAutoSegmentationFsl and renamed. 

% IMPORTANT: There seems to be some kind of strange flip/displacement of
% the sub-cortical segmentation images that renderes the FIRST segmentation
% completely useless. Not sure what to do about this. As of the last edits
% we are only running the FAST segmentation.


%% I. Set Directory Structure and Options

switch segToRun
    case {'first','First','FIRST',1}
        firstFlag   = 1;
        fastFlag    = 0;
    case {'fast','Fast','FAST',2};
        firstFlag   = 0;
        fastFlag    = 1;
    case {'all','All','ALL',3};
        fastFlag    = 1;
        firstFlag   = 1;
end

if notDefined('t1File'), t1File = mrvSelectFile([],'*.nii.gz','Choose a T1 Image',pwd); end

if notDefined('t1File'), error('You need to select a t1 file'); end

if notDefined('betFile') || ~exist(betFile,'file'), createBetFile = 1; else createBetFile = 0; end

if notDefined('outDir')
    outDir = fullfile((mrvDirup(t1File)), 'seg','fsl');
    if ~exist('outDir','file')
        [theOutDir,create] = setOutDir(outDir);
        outDir = theOutDir;
        if create == 1, mkdir(outDir), disp(['Created ' outDir]); end
        if create == 0, error('The output directory does not exist'); end
    end
end
if ~exist(outDir,'file'), mkdir(outDir), disp(['Created ' outDir]); end

if notDefined('betThresh') || isempty(betThresh), betThresh = '0.4'; end
if notDefined('betOpt') || isempty(betOpt) || ~ischar(betOpt), betOpt = ''; end
if notDefined('convert') || isempty(converty) || convert == 1
        convertFlag = 1;
else
        convertFlag = 0;
end
if ~exist('smooth','var') || isempty(smooth)
    smooth = 0;
end

if ~exist('fName','var') || isempty(smooth)
    fName = 't1';
end


%% Ia. Make a soft-link to the t1File in the outDir and point t1File to it.

cd(outDir);
[tmp t1Name ext] = fileparts(t1File); clear(tmp);
t1Name           = [t1Name ext];

if ~exist(fullfile(outDir,t1Name),'file')
    linkCommand     = ['ln -s ' t1File ' .'];
    [status result] = system(linkCommand);
    if status ~= 0, disp(result); end
end

t1File = fullfile(outDir,t1Name);


%% II. Build Commands

betCommand    = ['bet ' t1File ' ' (fullfile(outDir,[fName '_bet'])), ' -f ' betThresh ' ' betOpt];
firstCommand  = ['run_first_all -i ' t1File ' -o ' [fName '_firstSeg']];
fastCommand   = ['fast ' [fName '_bet.nii.gz']];


%% III. Run Commands

% Run Brain Extraction Tool
if createBetFile == 1
    fprintf('Running Brain Extraction Tool (BET)...\n');
    [status result] = system(betCommand);
    if status ~= 0, disp(result); end
else
    if ~exist(fullfile(outDir,[fName '_bet.nii.gz']),'file') && exist(betFile,'file')
        cd(outDir)
        [p f e] = fileparts(betFile);
        betFileName = [f e];
        linkCommand = ['ln -s ' betFile ' ./' betFileName];
        [status result] = unix(linkCommand,'-echo');
        if status ~= 0, disp(result); end
    end
end

% Run FSL Automatic Segmentation Tool
if fastFlag == 1
    fprintf('Running Automatic Segmentation Tool (FAST)...\n');
    [status result] = unix(fastCommand,'-echo');
    if status ~= 0, disp(result); end
end

% Run FSL SubCortical Segmentation
if firstFlag == 1
    fprintf('Running SubCortical Segmentation (FIRST)...\n');
    [status result] = unix(firstCommand,'-echo');
    if status ~= 0, disp(result); end
end

% Combine the segmentations using mrGrayConvertFirstToClass (if both FIRST and FAST were run)
if  firstFlag == 1 && fastFlag == 1 && convertFlag == 1
    disp('Combining Segmentations...');
    cd(outDir)
    mrGrayConvertFirstToClass([fName '_firstSeg_all_fast_firstseg.nii.gz'],[fName '_bet_seg.nii.gz'],fullfile(outDir,[fName '_autoClassFsl' num2str(smooth) '.nii.gz']),[],smooth);
end

if fastFlag == 1 && firstFlag ~=1 && convertFlag ==1
    disp('Converting FAST Segmentation to Class File...');
    cd(outDir)
    firstNifti = [];
    for ss = 1:numel(smooth)
        mrGrayConvertFirstToClass(firstNifti,[fName '_bet_seg.nii.gz'],fullfile(outDir,[fName '_fastClassSmooth' num2str(smooth(ss)) '.nii.gz']),[],smooth(ss));
    end
end

return


%% IV. Functions

% Dialog that will ask the user to specify where they would like to store the files if they don't provide an outDir.
function [theOutDir,create] = setOutDir(outDir)
    inDir = outDir;
    prompt = {'The output file directory is shown below. Please confirm this is correct, or make changes.',...
               'Would you like to create this directory if it does not exist? Enter 0 (NO) or 1 (YES): '};
    dlg_title           = 'Chose Output File Directory';
    num_lines           = 1;
    defaultanswer       = {inDir,'1'};
    options.Resize      = 'on';
    options.WindowStyle = 'normal';
    options.Interpreter = 'tex';

    Inputs     = inputdlg(prompt,dlg_title,num_lines,defaultanswer,options);
    theOutDir  = Inputs{1};
    create     = str2double(Inputs{2});
return
