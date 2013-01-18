function [] = dtiDeformGroupFast(templateIn,subjectDirectory,fileFragment,destinationDir)
% [] = dtiDeformGroupFast(templateIn,subjectDirectory,fileFragment,destinationDir)
%
% BATCHFILE FOR GROUP DEFORMATION USING FAST DEFORMATION CODE 
% Deforms N brains to given template and creates a new template from warped
% brains.  Note that one iteration is generally good enough; subsequent
% iterations (i.e. registering to the new template brain resulting from the
% first registration) generally are worst, as the brains are being
% registered to a template brain of lower resolution (the blurring caused
% averaging)
% 
% For the "0th iteration", where no template exists, choose a single
% subject brain to bootstrap the process and act as a "template"
%
% Arguments:
% 1. templateIn: Template brain to deform brains to
% 2. subjectDirectory: Directory containing subject files (argument for
% findSubjects)
% 3. fileFragment: Subject file identified (argument for
% findSubjects; eg '_dt6_' or '_dt6_acpc_2x2x2mm_spm.mat' )
% 4. destinationDir: Directory for deformed brains and dFields (default:
% /teal/scr1/dti/temp). 
%
%
% HISTORY:
% 2005.01.07 GSM (gmulye@stanford.edu) wrote it and cleaned up file
% organization
% 2005.01.20 GSM: Introduced mean tensor padding to reduce edge effects and
% problems due to cut-off brain edges
% 2005.01.27 GSM: Updated input/output file systems and introduced
% findSubjects

if(~exist('destinationDir','var') | ~isempty(destinationDir))
    [f,p] = uiputfile('*.mat','Base filename for output files');
    destinationDir = p;
end
if(~exist('subjectDirectory','var'))
    subjectDirectory = [];
    %[subFile,subDir] = uigetfile('*.mat','Select one of the subject files...');
    %subjectDirectory = subDir;
end   
if(~exist('fileFragment','var') | isempty(fileFragment))
    fileFragment = [];
end

%BRAINS BEING DEFORMED TO TEMPLATE
files = findSubjects(subjectDirectory,fileFragment); 
N = length(files);
controlAveOut = [templateIn,'_ave']; %Filename for new average template


% Warping brains to template and calculating deformation fields
newTemplateDt6 = 0; newTemplateB0 = 0; newTemplateAnat = 0; 
for i = 1:N
    disp(files{i})
    [dt6,b0,anat] = dtiDeformationFast(files{i},templateIn,destinationDir); 
    disp(['Brain #', num2str(i),' of ', num2str(N), ' finished!'])
    % Keeping a running tally
    newTemplateDt6 = newTemplateDt6 + dt6;
    newTemplateB0 = newTemplateB0 + double(b0);
    newTemplateAnat = newTemplateAnat + anat.img;
end
newTemplateDt6 = newTemplateDt6/N;
newTemplateB0 = int16(newTemplateB0/N);
newTemplateAnat = newTemplateAnat/N;

%NOTE: Template brain has average warped dt6, b0, and anatomy images
%SAVING OUT CONTROL BRAIN
load(templateIn);
dt6 = newTemplateDt6;b0 = newTemplateB0;anat.img = newTemplateAnat;
notes = ['SPM Normalized subject SS-based template brain, Iteration 0, N = ',num2str(N)];
save(controlAveOut ,'b0' ,'xformToAcPc' ,'xformToAnat' ,'anat' ,'notes', 'mmPerVox', 'dt6');
[vec val] = dtiSplitTensor(dt6);
saveAnalyze(dtiComputeFA(val),[controlAveOut,'_FAMap']); %Saving out average FA map
saveAnalyze(b0,[controlAveOut,'_B0Map']); %Saving out average B0 map

return