function dtiWarpToWhiteMatter(handles)

view = getSelectedVolume;
anatSize = size(view.anat);
wmVol = zeros(anatSize);

classFileName = [view.leftPath(1:end-5) '.class'];
c = readClassFile(classFileName);
voi = c.header.voi;
wmVol([voi(3):voi(4)], [voi(1):voi(2)], [voi(5):voi(6)]) = permute(c.data, [2,1,3])==c.type.white;

classFileName = [view.rightPath(1:end-5) '.class'];
c = readClassFile(classFileName);
voi = c.header.voi;
wmVolTmp = wmVol;
wmVolTmp([voi(3):voi(4)], [voi(1):voi(2)], [voi(5):voi(6)]) = permute(c.data, [2,1,3])==c.type.white;

% combine left and right
wmVol = wmVol | wmVolTmp;

wmVol = smooth3(wmVol, 'gaussian', 3);

[wmDti,mmDt,xformDt] = dtiGetNamedImage(handles.bg, 'white matter');
xform = handles.xformVAnatToAcpc;
bb = [-72 -110 -45; 72 85 85];
wmVolDti = dtiResliceVolume(wmVol, inv(xform), bb, mmDt);
wmVolDti = permute(wmVolDti, [2 1 3]);

figure;imagesc(wmVolDti(:,:,20)); colorbar;
figure;imagesc(wmDti(:,:,20)); colorbar;
figure;imagesc(wmVolDti(:,:,20)-wmDti(:,:,20)); colorbar;

% M = estMotionIter3(wmDti, wmVolDti, 3, eye(4), 0, 1);
% 
% x = inv(dtiGetStandardXform(handles, xformDt)) * M;
% newWmDti = dtiResliceVolume(wmDti, x, bb, mmDt);
% newWmDti = permute(newWmDti, [2 1 3]);
% figure;imagesc(newWmDti(:,:,20)); colorbar;
% figure;imagesc(wmVolDti(:,:,20)-newWmDti(:,:,20)); colorbar;


[deformField, newImg, absDeform, MSE] = dtiDeformationScalar(wmVolDti, wmDti, 25, [7 5 3]);
figure;imagesc(newImg(:,:,20)); colorbar;
figure;imagesc(newImg(:,:,20)-wmVolDti(:,:,20)); colorbar;
