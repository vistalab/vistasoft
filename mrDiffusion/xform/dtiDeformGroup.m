function [] = dtiDeformGroup(templateIn,controlAveOut,dyslexicAveOut)
% [] = dtiDeformGroup(templateIn,controlAveOut,dyslexicAveOut)
%
% BATCHFILE FOR GROUP DEFORMATION 
% Deforms N brains to given template and creates new average control and dyslexic brains
% 
% For the "0th iteration", where no template exists, choose a single
% subject brain to bootstrap the process and act as a "template"
%
% How to use me:
% 1. Switch to directory containing only original brains to be deformed
% 2. Specify template brain to deform to (templateIn)
% 3. Specify output filenames for control and dyslexic template brains 
%
% NOTES ON INPUT FILE FORMATS:
% 1. Raw data filenames should be of form: XXXXXXX_dt6.mat
% 2. Template brains should be of form controlBrainAve_XXXX (typically
% controlBrainAve_IterX, where X = 0 is brain resulting from bootstrap)

addpath('/biac2/wandell2/data/dti/matlab'); %Path for getSubjectType()

%BRAINS BEING DEFORMED TO TEMPLATE
files = dir('./*_dt6.mat');
N = length(files);


%WARP ALL BRAINS TO TEMPLATE
for i = 1:N
    [warpedBrain,a,b] = dtiDeformation(files(i).name,templateIn,50,'trilinear'); 
    'Giddyup! Brain finished!',i
end


%CREATE AVERAGE CONTROL AND DYSLEXIC BRAINS
aveCtrlDt6 = 0; aveCtrlB0 = 0; ctrlN = 0;
aveDyslDt6 = 0; aveDyslB0 = 0; dyslN = 0;

for i = 1:N
    subFile = files(i).name;
    us=findstr('_',subFile);
    subjectCode = subFile(1:us(1)-1);
    load([subjectCode,'_reg2_','controlBrainAve']);
        
    if (cell2mat(getSubjectType(subjectCode)) == 'c') %Check for controls
        aveCtrlDt6 = aveCtrlDt6 + dt6;
        aveCtrlB0 = aveCtrlB0 + double(b0);
        ctrlN = ctrlN + 1;
    elseif (cell2mat(getSubjectType(subjectCode)) == 'd') %Check for dyslexics
        aveDyslDt6 = aveDyslDt6 + dt6;
        aveDyslB0 = aveDyslB0 + double(b0);
        dyslN = dyslN + 1;
    end        
end

aveCtrlDt6 = aveCtrlDt6/ctrlN;
aveCtrlB0 = aveCtrlB0/ctrlN;
aveDyslDt6 = aveDyslDt6/dyslN;
aveDyslB0 = aveDyslB0/dyslN;

%NOTE: EVERYTHING EXCEPT B0 AND DT6 ASSOCIATED WITH AVERAGE BRAINS IMAGES
%IS GARBAGE
%SAVING OUT CONTROL BRAIN
load(files(1).name);
dt6 = aveCtrlDt6;b0 = int16(aveCtrlB0);
notes = ['Averaged control brain, N = ',num2str(ctrlN)];

save(controlAveOut,'b0','xformToAcPc','xformToAnat','anat','notes','mmPerVox','dt6');

dt6 = aveDyslDt6;b0 = int16(aveDyslB0);
notes = ['Averaged dyslexic brain, N = ',num2str(dyslN)];
save(dyslexicAveOut,'b0','xformToAcPc','xformToAnat','anat','notes','mmPerVox','dt6');

return

function [dt6,b0] = dtiDeformer(inputImgFN,deformFieldFN,type,outputImgFN)
%DTI Deformer: Takes in image and deformation field
if(~exist('type','var') | isempty(type))
    type = 0; 
else
    type = lower(type);
    type = type(1);
    if type == 'i'
        type = 0;
    elseif type == 'd'
        type = 1;
    else
        'Choose "Image" or "Deformation Field"'
    end
end
load(deformFieldFN);
load(inputImgFN);
if type == 0
    dimSrc = size(dt6);
else
    dimSrc = size(deformField)
end
H = zeros(dimSrc(1),dimSrc(2),dimSrc(3),3);
for x = 1:dimSrc(1)
    for y = 1:dimSrc(2)
        for z = 1:dimSrc(3)
            H(x,y,z,:) = [y x z];
        end
    end
end
newH = H + deformField;
%Giant matrix of coordinates

% CREATE NEW DT6 IMAGE
if (type == 0)
    coordsList = reshape(newH,dimSrc(1)*dimSrc(2)*dimSrc(3),3);
    newDt6List = zeros(dimSrc(1)*dimSrc(2)*dimSrc(3),6);
    for i = 1:6
        newDt6List(:,i) = myCinterp3(dt6(:,:,:,i),[dimSrc(1),dimSrc(2)],dimSrc(3),coordsList)';
    end
    newDt6 = zeros(dimSrc(1),dimSrc(2),dimSrc(3),6);
    for i = 1:6
        newDt6(:,:,:,i) = reshape(newDt6List(:,i),dimSrc(1),dimSrc(2),dimSrc(3));
    end
    dt6 = newDt6; %clear newDt6 newDt6List;

elseif (type == 1)
    coordsList = reshape(newH,dimSrc(1)*dimSrc(2)*dimSrc(3),3);
    newDeformList = zeros(dimSrc(1)*dimSrc(2)*dimSrc(3),3);
    newAbsDeformList = myCinterp3(absDeform,[dimSrc(1),dimSrc(2)],dimSrc(3),coordsList)';
    newAbsDeform = reshape(newAbsDeformList,dimSrc(1),dimSrc(2),dimSrc(3));
    absDeform = newAbsDeform; %clear newDt6 newDt6List;
    for i = 1:3
        newDeformList(:,i) = myCinterp3(deformField(:,:,:,i),[dimSrc(1),dimSrc(2)],dimSrc(3),coordsList)';
    end
    newDeform = zeros(dimSrc(1),dimSrc(2),dimSrc(3),3);
    for i = 1:3
        newDeform(:,:,:,i) = reshape(newDeformList(:,i),dimSrc(1),dimSrc(2),dimSrc(3));
    end
    deformField = newDeform;
end

%CREATE NEW B0 IMAGE, SAVE OUT
if (type == 0)
    newB0List(:,:,:) = myCinterp3(double(b0),[dimSrc(1),dimSrc(2)],dimSrc(3),coordsList)';
    newB0 = reshape(newB0List,dimSrc(1),dimSrc(2),dimSrc(3));
    b0 = int16(newB0); clear newB0List newB0; clear coordsList;
    if (~exist('outputImgFN', 'var'))
        [a imgFN b c] = fileparts(inputImgFN);
        us=findstr('_',inputImgFN);
        subjectCode = inputImgFN(1:us(1)-1);
        outputImgFN = ['registered_',subjectCode];
    end
    deformationNotes = [deformFieldFN];
    save(outputImgFN,'b0','xformToAcPc','xformToAnat','notes','deformationNotes',...
        'mmPerVox','anat','dt6');
elseif (type == 1)
    if (~exist('outputImgFN', 'var'))
        [a imgFN b c] = fileparts(inputImgFN);
        us=findstr('_',inputImgFN);
        subjectCode = inputImgFN(1:us(1)-1);
        outputImgFN = ['registeredDeform_',subjectCode];
    end
    save(outputImgFN,'deformField','absDeform');
end

return

