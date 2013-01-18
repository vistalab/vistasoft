function [dt6,b0,anat] = dtiDeformationFast(srcFile,tempFile,destinationDir)
% [deformedBrain] = dtiDeformationFast(srcFile,tempFile,destinationDir)
%
% Wrapper function for M Bolten's fast deformation code.  Resultant
% deformation fields show how to warp the template brain (tempFile) to fit
% the subject (srcFile) brain.
%
% INPUTS:
% srcFile: dt6-file of source image
% tempFile: dt6-file of "template" image or target image
% destinationDir: directory to store output files
% 
% OUTPUTS:
% dt6, b0, anat: warped versions of each image type
%
% Files (note subject codes are of form aa010101, extracted from filenames):
% sourceCode_reg2_tempCode.mat: dt6-file with warped dt6, b0, and T1
% anatomy images
% sourceCode_2_tempCode_DF.mat: deformation field saved out as deformField
% sourceCode_reg2_tempCode_b0map.mat: analyze format file of warped b0 map
% sourceCode_reg2_tempCode_FAmap.mat: analyze format file of warped FA map
%
%
% NOTES:
%  *** Why are there divide-by-2's in here (and in sub-functions)?
%  Matthias' code seems to return defomations that were 2x too much, so
%  Girish added some /2 and it seemed to fix things.
%
%
% HISTORY:
% 2005.03.07 GSM (gmulye@stanford.edu): Modified to warp T1 anatomy image as well


src = load(srcFile);
source = src.dt6;
source(isnan(source)) = 0; %Get rid of NANs
sourceB0 = double(src.b0); %Double version of b0 for mask purposes
sourceB0(isnan(sourceB0)) = 0;%Get rid of NANs
tmplt = load(tempFile);
template = tmplt.dt6;
template(isnan(template)) = 0; %Get rid of NANs
templateB0 = tmplt.b0;
templateB0(isnan(templateB0)) = 0; %Get rid of NANs

% Zero outside brain and Mean tensor padding (for source)
mask = dtiCleanImageMask(sourceB0 > 250);
maskDt6 = repmat(mask,[1 1 1 6]);
source = source.*maskDt6; %Zeroed out all regions outside b0 image
% Finding average dt6
meanDt6 = zeros(6,1);
nonZeroVoxels = sum(mask(:));
for i = 1:6
    tempDt6 = source(:,:,:,i).*mask;
    meanDt6(i) = sum(tempDt6(:))/nonZeroVoxels;
end
%Fill in average dt6 values
mask = zeros(size(maskDt6));
for i = 1:6
    temp = ~(maskDt6(:,:,:,i));
    mask(:,:,:,i) =  double(temp) * meanDt6(i);
end
source = source + mask;

% Zero outside brain and Mean tensor padding (for template)
mask = dtiCleanImageMask(templateB0 > 250);
maskDt6 = repmat(mask,[1 1 1 6]);
template = template.*maskDt6; %Zeroed out all regions outside b0 image
% Finding average dt6
meanDt6 = zeros(6,1);
nonZeroVoxels = sum(mask(:));
for i = 1:6
    tempDt6 = template(:,:,:,i).*mask;
    meanDt6(i) = sum(tempDt6(:))/nonZeroVoxels;
end
%Fill in average dt6 values
mask = zeros(size(maskDt6));
for i = 1:6
    temp = ~(maskDt6(:,:,:,i));
    mask(:,:,:,i) = double(temp) * meanDt6(i);
end
template = template + mask;

iterations = 10;
[delX,delY,delZ,junk,deformedBrain] = elasticRegistration3d(source,template);
dim = size(delX);
deformField = zeros(dim(1),dim(2),dim(3),3);
% Constructing deformation fields
% Note that the original output of fast algorithm seems to be 2x larger
% than what we want. ***
deformField(:,:,:,1) = delY./2;
deformField(:,:,:,2) = delX./2;
deformField(:,:,:,3) = delZ./2;
%PPD Correction (added 2/25/05)
deformedBrain = dtiXformTensorsPPD(deformedBrain,deformField,1);

% Deforming B0 image according to above deformation fields
newB0 = dtiDeformer(sourceB0,deformField); %sourceB0 is a double
b0 = int16(newB0);%Our newly deformed b0 

% Deforming anat image according to above deformation fields
% Upsample above dFields
anatOld = src.anat.img;
origin  = src.xformToAnat\[0 0 0 1]';
origin  = origin(1:3)';
voxSize = src.anat.mmPerVox;
bb = [-voxSize .* (origin-1) ; voxSize .*(size(src.anat.img)-origin)];
upsampledDF = mrAnatResliceSpm(deformField, inv(src.xformToAnat), bb, src.voxSize, [1 1 1 0 0 0]);
% Deform anatomy image as per new, upsampled dField
newAnat = dtiDeformer(src.anat.img,upsampledDF);
anat = src.anat;
anat.img = newAnat; %Replace anatomy image with registered version


% SAVES OUT DEFORMATION FIELD FILE
[srcImgDir srcImgFN b c] = fileparts(srcFile);
[trgtImgDir trgtImgFN b c] = fileparts(tempFile);
us=findstr('_',srcImgFN);
srcCode = srcImgFN(1:us(1)-1);
if (~exist('destinationDir','var'))
    destinationDir = '/teal/scr1/dti/temp/';
end
deformationFN = fullfile(destinationDir,[srcCode,'_2_',trgtImgFN,'_DF']); %dField filename
sourceImage = srcCode;
targetImage = trgtImgFN;
save(deformationFN ,'deformField' ,'sourceImage' ,'targetImage' ,'iterations');

%SAVING OUT REGISTERED BRAIN
%First setting rest of the variables correctly
xformToAcPc = src.xformToAcPc;
xformToAnat = src.xformToAnat;
mmPerVox = src.mmPerVox;
dt6 = deformedBrain;
newImgFN = fullfile(destinationDir,[srcCode,'_reg2_',trgtImgFN]); %Registered brain filename
notes = strcat(sourceImage,' registered to SS brain with some excluded brains');

%Saving out new registered brain
save(newImgFN ,'b0' ,'xformToAcPc' ,'xformToAnat' ,'anat' ,'notes' ,'mmPerVox' ,'dt6');
% saveAnalyze(b0, [newImgFN,'_b0Map'], [2 2 2], notes); %Save b0 in analyze format
% [eigVec eigVal] = dtiSplitTensor(dt6);
% FA = dtiComputeFA(eigVal);
% saveAnalyze(FA, [newImgFN,'_FAMap'], [2 2 2], notes); %Save FA in analyze format

return