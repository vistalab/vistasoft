function anat = motionCompResampleAnatomy(view)

%    anat = motionCompResampleAnatomy(view)
%
% gb 02/14/05
%
% Loads and resample the anatomy so that it can have the crop Size of the
% subject

global dataTYPES
curType = viewGet(view,'curdatatype');

size1 = dataTYPES(curType).scanParams(1).cropSize;
size2 = size(view.anat);

T = maketform('affine',[size1(2)/size2(2) 0 0; 0 size1(1)/size2(1) 0; 0 0 1]);
anat = imtransform(view.anat,T,'linear');
anat = anat(1:size1(1),1:size1(2),1:size2(3));