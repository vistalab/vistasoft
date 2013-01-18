function images = areaNumTransform(images)

% images.areasImg(find(images.areasImg==5))=0;
% images.areasImg(find(images.areasImg==6))=5;
% images.areasImg = images.areasImg+1;

images(find(images==5))=0;
images(find(images==6))=5;
images = images+1;
