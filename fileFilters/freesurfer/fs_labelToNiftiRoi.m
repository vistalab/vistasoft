function [nRoi, fsLabelName, outName] = fs_labelToNiftiRoi(fsIn,labelVal,outName,smoothKernel)
%
%  [nRoi, fsLabelName, outName] = fs_labelToNiftiRoi([fsIn],[labelVal],[outName],[smoothKernel])
% 
% This function will take a freesurfer segmentation file (eg fsIn =
% aparc+aseg.nii) and convert specific lables within it to a nifti roi. If
% you pass in a .mgz file it will be converted to a nifti file on the fly
% and saved with the .nii.gz file extension. That file will be saved with
% the same basename as fsIn.
% 
% You can smooth the resulting roi if you set smoothKernel. (eg
% smoothKernel = 3 will smooth the roi with a 3mm [3 3 3] kernel. This will
% produce 2 rois; one without smoothing and one with.
% 
% By default the code will write out the file in the same directory as fsIN
% with the name of the actual roi (using the values in fslabel.mat), but
% you can change this if you use outFileName to set a different file
% name/path.
% 
% INPUTS:
%       fsIn    - Path to the free surfer segmentation file
% 
%       labelVal- The value (in string) for the ROI you want returned.
% 
%       outName - Name used to save the ROI (full path)
% 
%       smoothKernel - Size of the smoothing kernel applied to the ROI
% 
% OUTPUTS:
%       nRoi    - The resulting roi structure
% 
%       fsLabelName - the name of the label from labelVal
% 
%       outName - Name used to save the roi. 
% 
% 
% SEE:  http://surfer.nmr.mgh.harvard.edu/fswiki/FsTutorial/AnatomicalROI/FreeSurferColorLUT
%       for help with naming the labels. OR look at fslabels.txt. (load
%       fslabel.mat) It has all of the label numbers and names and is in your path.
% 
% SEE:  fs_mgzSegToNifti to convert the aparc+aseg.mgz file to nii
%       seperately.
% 
% EXAMPLE USAGE: 
%       fsIn = '/home/lmperry/software/freesurfer/subjects/JB5/mri/aparc+aseg.nii.gz'
%       labelVal = '1026';
%       outName = '/home/lmperry/software/freesurfer/subjects/JB5/mri/rostralanteriorcingulate.nii.gz';
%       smoothKernel = 3;
%       fs_labelToNiftiRoi(fsIn,labelVal,outName,smoothKernel);
% 
% 
% (C) Stanford University, VISTA Lab [2011-2012]
% 
      
% IDEAS:
%       * Load the resulting nifti on the t1 in itkgray
%       * Remove the warning dialog - and just have the warning throw to
%         the prompt. * 
%       * Just take in a subject's name and take the fs sub dir after that.
%       * Check to see if the labelVal exist in the fslabel.mat.* DONE
%       * Accept an entire list of ROIs - or all of them
%       * Save out in .mat or .nii.gz 
% 
%       
%        
% HISTORY: 
%       2011.03.22 - LMP Wrote the thing.
%       2011.04.21 - LMP added a dialog so that you don't have to pass any
%       inputs at all. You will be presented with a window that will allow
%       you to choose the label and the name you want to use. You can
%       provide just a name, or you can provide the entire path. This
%       function will also convert your mgz file to a nifti by calling
%       fs_mgSegToNifti.
%       2011.04.22 - LMP completely changed it again. Now the naming scheme
%       is taken from fslabels.mat. The code has also been modularized.
%       Option to smooth the roi has been added and 'smooth' added to the
%       name in that case so the use can keep track.
% 


%% Check for necessary software and set up arguments that are not passed in

% Get the fsIn file. 
if notDefined('fsIn') || ~exist(fsIn,'file')
    fsSubDir = getenv('SUBJECTS_DIR');
    [fileName, path] = uigetfile({'*'},'Select the aparc_aseg Freesurfer Nifti or MGZ File',fsSubDir);    
    if isnumeric(fileName); disp('Canceled by user.'); return; end

    fsIn = fullfile(path,fileName);
else
    [p, ~] = fileparts(fsIn);
    if isempty(p)
        fsIn = fullfile(pwd,fsIn);
    end
end


%% Check to see if the file is an mgz. If yes, convert it to nifti.

fsIn = f_fsMgzCheck(fsIn); 

% Set labelVal if notDefined. If the user does not pass in a label value
% then we ask them to select one. In this case they also can select a name for the roi.
if notDefined('labelVal')
    [labelVal, outName, smoothKernel] = f_getLabelVal(fsIn);
    
end


%% Check that labelVal is a string and a valid Freesurfer label number and
% Load the file with the label names and values.

if ~ischar(labelVal); 
    labelVal = num2str(labelVal); 
end

load fslabel.mat; 

if isempty(find(ismember(fslabel.num,labelVal)==1, 1));
    error('You must enter a valid FREESURFER label number! Load fslabel.mat for label number and names.');
end

% In the scripted case: If a name for the roi is not provided the label
% number is used and the path for the roi is set to the be the same as that
% of the seg file.
if notDefined('outName')
    load fslabel.mat;
    index = find(ismember(fslabel.num, labelVal)==1);
    fsLabelName = (fslabel.name{index}); %#ok<*FNDSB,*FNDSB>
    [p, n, e] = fileparts(fsIn);
    outName = fullfile(p,['roi_'  fsLabelName '_' labelVal  '_' n e]);
else
    [p, n, e] = fileparts(outName);
    if isempty(e)
        e = '.nii.gz';
        n = [n e]; 
        outName = fullfile(p,n);
    end
    fsLabelName = fs_getROILabelNameFromLUT(labelVal);
end


%% Handle the smoothKernel argument

if notDefined('smoothKernel') || isempty(smoothKernel);
    fprintf('Not smoothing ROI...\n'); 
    smoothFlag = 0;
elseif ~isempty('smoothKernel')
    if ~ischar(smoothKernel); 
        smoothKernel = num2str(smoothKernel); 
    end
    smoothFlag = 1; 
    sk = str2double(smoothKernel);    
end


%% Create the ROI 

fsNii = dtiRoiFromNifti(fsIn,labelVal,outName,'nifti',false);

% Write out our binary ROI
niftiWrite(fsNii,outName);


%% Do the smoothing

% If smooth flag is tripped load the nifti and do the smoothing here. 
if smoothFlag == 1 && exist('sk','var')
    f_smoothAndSaveRoi(outName,smoothKernel,sk);
else
    fprintf('Saved: %s\n',outName);
end

% After it's all said and done we read the file to send back to the user.
nRoi = niftiRead(outName);


return



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTIONS
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  This funciton checks the file type of fsIn. If MGZ convert to NIFIT.
function fsIn = f_fsMgzCheck(fsIn)
[p, f, e] = fileparts(fsIn);
flag = strcmp(e,'.mgz');
if flag == 1
   % Warn the user that they have passed in a .mgz file and wait for their response
   fprintf('[%s] MGZ file passed in. \n Converting MGZ to NIFTI-1',mfilename);
   outName = fullfile(p,[f '.nii.gz']);
   fs_mgzSegToNifti(fsIn,[],outName);
   fsIn = outName;   
   fprintf('[%s] Written file: %s\n',mfilename,outName); 
end
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Launches a dialog that will prompt the user to input the arguments we
% need. We're here because labelVal is not passed in. 
function [labelVal, outName, smoothKernel] = f_getLabelVal(fsIn)
% Set options for the dialog prompt
prompt              = {sprintf('Enter a valid Freesurfer label number (REQUIRED) \n  (See fslabel.mat for label numbers and names.)\n'),...
                        sprintf('Enter a name for the ROI (OPTIONAL) \n'),...
                        sprintf('Enter a smoothing kernel (e.g. 3) (OPTIONAL) \n')};
dlg_title           = 'fs_labelToNiftiRoi';
num_lines           = 1;
defaultanswer       = {'','',''};
options.Resize      = 'on';
options.WindowStyle = 'normal';
options.Interpreter = 'tex';

% Launch the dialog and extract the output arguments
inputs = inputdlg(prompt,dlg_title,num_lines,defaultanswer,options);
if isempty(inputs)
    error('User canceled'); 
else
    labelVal = inputs{1};
    if ~isempty(inputs{2})
        uiName = inputs{2};
        % If the name does not have the full path then we set the path
        % to be the same as the fsIn file. This is a hacky way to check.
        check = strcmp(uiName(1),'/');
        if check==0
            % Remove .nii.gz from the name.
            l=length(fsIn);
            inds=l-6:l;
            fsIn(inds)=[];
            [p, n] = fileparts(fsIn);
            outName = fullfile(p, ['roi_' uiName '_' n '.nii.gz']);
        else
            outName = uiName;
        end
    else
        % inputs{2} is empty. so lets name the roi with the actual name of
        % the roi in freesurfer. We can append the real name to the label
        % number. Load the labels file (from the repo).
        load fslabel.mat;
        index = find(ismember(fslabel.num, inputs{1})==1);
        fsLabelName = (fslabel.name{index}); %#ok<*FNDSB>
        [p, n, e] = fileparts(fsIn);
        outName = fullfile(p, ['roi_'  fsLabelName '_' labelVal  '_' n e]);
    end
    if ~isempty(inputs{3})
        smoothKernel = inputs{3};
    else
        smoothKernel = [];
    end
end
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The smoothFlag was tripped. We read in the roi we created and smooth it.
% We then append the name (in a hacky way) and save it out.
function f_smoothAndSaveRoi(outName,smoothKernel,sk)
 fprintf('Smoothing ROI with a %smm Kernel...\n',smoothKernel);
    ni = niftiRead(outName);
    ni.data = dtiCleanImageMask(ni.data,sk);
    % Handle the naming. Move the .nii.gz off the end and replace it.
    l = length(outName);
    inds = l-6:l;
    outName(inds) = [];
    outName = [outName '_smooth' smoothKernel '.nii.gz'];
    ni.fname = outName;
    writeFileNifti(ni);
    fprintf('%s has been saved.\n',outName);
 return


 
 %%
 
% n = strfind(inputs{1},' ');
% num = 0;
% start = 1;
% 
% for jj = 1:(numel(n)+1)
%     num = num+1;
%     finish = (start+3);
%     tags{num} = inputs{1}(start:finish);
%     start = start+5;
% end


% % Read in the FreeSurfer nifti
% fsNii = niftiRead(fsIn);
% 
% % Find those indices that are not = labelVal and set them = 0
% not = find(fsNii.data~=str2double(labelVal));
% fsNii.data(not) = 0;
% 
% % Find the indicies = labelVal and set = 1
% is = find(fsNii.data==str2double(labelVal));
% fsNii.data(is) = 1;



    
