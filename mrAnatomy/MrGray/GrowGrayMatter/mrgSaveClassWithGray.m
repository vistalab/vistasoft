function classNi = mrgSaveClassWithGray(nGrayLayers, classNi, classFileOut)
%
% function classNi = mrgSaveClassWithGray(nGrayLayers, classFileIn, classFileOut)
% 
% Purpose: Wrapper to add gray layers to a nifti class file
%
% 10/30/2008: JW (mostly copied from mrAlignCTtoMRI)

if nargin < 1, help mrgSaveClassWithGray; return; end

if notDefined('nGrayLayers'),    nGrayLayers = 3; end
if notDefined('classNi'),        classNi = 't1_class.nii.gz'; end
if notDefined('classFileOut')
    classFileOut = sprintf('t1_class_gray_%d_layers.nii.gz', nGrayLayers);
end

if(~isstruct(classNi))
    try
        classNi = readFileNifti(classNi);
    catch ME
        warning(ME.message);
        disp(sptintf('[%s]: Cannot load class file %s.', mfilename, classNi));
    end
end

% left hemisphere
class = readClassFile(classNi,0,0,'left');
[~,~,classData] = mrgGrowGray(class,nGrayLayers);
lGM = classData.data==classData.type.gray;

% right hemisphere
class = readClassFile(classNi,0,0,'right');
[~,~,classData] = mrgGrowGray(class,nGrayLayers);
rGM = classData.data==classData.type.gray;

% you may need to flip some dimensions to get the correct orientation
lGM = permute(flipdim(flipdim(lGM,2),1),[3 1 2]);
rGM = permute(flipdim(flipdim(rGM,2),1),[3 1 2]);
l = mrGrayGetLabels;
classNi.data(lGM) = l.leftGray;
classNi.data(rGM) = l.rightGray;

classNi.fname = classFileOut;
writeFileNifti(classNi);

return
