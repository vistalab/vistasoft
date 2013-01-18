function Edges = detectAreaBorders(images)

images(isnan(images))=0;
% Edges=double(edge(images, 'canny'));
images = images+1;
Edges = zeros(size(images));
for area=3:max(images(:))-1
    images_tmp = double(images==area);
    Edges=Edges | double(edge(images_tmp, 'canny'));
end
% figure;imagesc(Edges)
