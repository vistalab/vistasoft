function deformField = dtiComputeWhiteMatterWarp(handles, volView)

if(isempty(volView.anat))
    disp('Loading mrVista anatomy...');
    volView = loadAnat(volView);
end
anatSize = size(volView.anat);
wmVol = zeros(anatSize);

classFileName = [volView.leftPath(1:end-5) '.class'];
c = readClassFile(classFileName);
voi = c.header.voi;
wmVol([voi(3):voi(4)], [voi(1):voi(2)], [voi(5):voi(6)]) = permute(c.data, [2,1,3])==c.type.white;

classFileName = [volView.rightPath(1:end-5) '.class'];
c = readClassFile(classFileName);
voi = c.header.voi;
wmVolTmp = wmVol;
wmVolTmp([voi(3):voi(4)], [voi(1):voi(2)], [voi(5):voi(6)]) = permute(c.data, [2,1,3])==c.type.white;

% combine left and right
wmVol = wmVol | wmVolTmp;

%wmVol = smooth3(wmVol, 'gaussian', 3);

[wmDti,mmDt,xformDt] = dtiGetNamedImage(handles.bg, 'white matter');
xform = handles.xformVAnatToAcpc;
bb = [-72 -110 -45; 72 85 85];
wmVolDti = dtiResliceVolume(wmVol, inv(xform), bb, mmDt);
wmVolDti = permute(wmVolDti, [2 1 3]);

figure; 
subplot(2,3,1); imagesc(wmVolDti(:,:,20)); colorbar; title('mrVista WM');
subplot(2,3,2); imagesc(wmDti(:,:,20)); colorbar; title('DTI WM');
subplot(2,3,3); imagesc(wmVolDti(:,:,20)-wmDti(:,:,20)); colorbar; title('mrVista WM - dti WM');

disp('Computing deformation- please wait...');
[deformField, newImg, absDeform, MSE] = dtiDeformationScalar(wmVolDti, wmDti, 25, [7 5 3]);
deformField = -deformField;

subplot(2,3,4); plot(MSE); title('MSE');
subplot(2,3,5); imagesc(newImg(:,:,20)); colorbar; title('warped mrVista WM');
subplot(2,3,6); imagesc(newImg(:,:,20)-wmDti(:,:,20)); colorbar; title('warped mrVista WM - dti WM');


return;
