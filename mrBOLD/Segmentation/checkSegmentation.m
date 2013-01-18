
view=getSelectedVolume;
classFileName = [view.leftPath(1:end-5) '.class'];
c = readClassFile(classFileName);
anatSize = size(view.anat);

voi = c.header.voi;
anat = uint8(zeros([anatSize, 3]));
wm = repmat(logical(0), anatSize);
wm([voi(3):voi(4)], [voi(1):voi(2)], [voi(5):voi(6)]) = permute(c.data, [2,1,3])==c.type.white;
for(ii=1:3)
    anat(:,:,:,ii) = view.anat;
end
tmp = anat(:,:,:,1);
tmp(wm) = uint8(double(tmp(wm))+20);
anat(:,:,:,1) = tmp;

mHires = makeMontage3(anat(:,:,:,1), anat(:,:,:,2), anat(:,:,:,3), [voi(5):voi(6)], view.mmPerVox(1), 0);