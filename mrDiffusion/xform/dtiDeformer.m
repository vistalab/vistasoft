function [dt6,b0] = dtiDeformer(dt6,b0,deformField)
% function [outDt6,outb0] = dtiDeformer(inputImgFN,deformFieldFN,dfType,outputImgFN)
% DTI Deformer: Warps dt6 image according to given deformation field
%
% ARGUMENTS:
% dt6: Input dt6 image
% b0: input b0 image
% deformField: Deformation field (XxYxZx3)
% 
% HISTORY:
% 2004.01.19 GSM (gmulye@stanford.edu) wrote it and cleaned up the interface
%

dimSrc = size(dt6);
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
coordsList = reshape(newH,dimSrc(1)*dimSrc(2)*dimSrc(3),3);
newDt6List = zeros(dimSrc(1)*dimSrc(2)*dimSrc(3),6);
for i = 1:6
    newDt6List(:,i) = myCinterp3(dt6(:,:,:,i),[dimSrc(1),dimSrc(2)],dimSrc(3),coordsList)';
end
newDt6 = zeros(dimSrc(1),dimSrc(2),dimSrc(3),6);
for i = 1:6
    newDt6(:,:,:,i) = reshape(newDt6List(:,i),dimSrc(1),dimSrc(2),dimSrc(3));
end
dt6 = newDt6; clear newDt6 newDt6List;


%CREATE NEW B0 IMAGE, SAVE OUT
newB0List(:,:,:) = myCinterp3(double(b0),[dimSrc(1),dimSrc(2)],dimSrc(3),coordsList)';
newB0 = reshape(newB0List,dimSrc(1),dimSrc(2),dimSrc(3));
b0 = int16(newB0); clear newB0List newB0; clear coordsList;

% %OUTPUT FILE NAMING CONVENTION
% if (~exist('outputImgFN', 'var'))
%     [a imgFN b c] = fileparts(inputImgFN);
%     us=findstr('_',inputImgFN);
%     subjectCode = inputImgFN(1:us(1)-1);
%     outputImgFN = ['registered_',subjectCode];
% end
% deformationNotes = [deformFieldFN];
% save(outputImgFN,'b0','xformToAcPc','xformToAnat','notes','deformationNotes',...
%     'mmPerVox','anat','dt6');

return
