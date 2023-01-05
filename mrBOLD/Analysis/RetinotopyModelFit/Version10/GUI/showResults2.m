function [dM1m dM2m dM3m Edges dEdges A1m A2m M1m M2m M3m W1m W2m COm dW1m dW2m dCOm dAreasImgm dA1m dA2m dA3m] = showResults2(yOpt, yOpt_inv, corners, filename, images)

load(filename);

m=[2^maxLevel 2^maxLevel];
Omega = [1, 1];
X=getGrid(Omega,m);
h=Omega./m;

yCentered=stg2center(yOpt,m,'Py');

% % Check whether yOpt + yOpt_inv generaets original image
% dA1i1=interpolation(TD1,Omega,yCentered);
% dA1m1=flipud(reshape(dA1i1,m)');
% 
% dA1i2=interpolation(dA1m1,Omega,yOpt_inv);
% dA1m2=flipud(reshape(dA1i2,m)');
% 
% figure
% subplot(311)
% imagesc(TD1)
% subplot(312)
% imagesc(dA1m1)
% subplot(313)
% imagesc(dA1m2)

% interpolate raw data
interpolation('set','MODE','linear-periodic','period',2*pi);
M2i=interpolation(images.M2,Omega,X);
dA2i=interpolation(TD2,Omega,yCentered);
interpolation('set','MODE','linear');
% M1i=interpolation(RD1,Omega,X);
M1i=interpolation(images.M1,Omega,X);
M3i=interpolation(images.M3,Omega,X);
dA1i=interpolation(TD1,Omega,yCentered);
if isfield(images,'A3')
    dA3i=interpolation(images.A3,Omega,yCentered);
    dA3m=ip2mat(dA3i,m);
end

if max(areasImg(:))==6 % LO/TO maps
    areasImg = areaNumTransform(areasImg);
end
dAreasImgi=(interpolation(areasImg,Omega,yCentered));
W1i=interpolation(WD1,Omega,X);
W2i=interpolation(WD2,Omega,X);
COi=interpolation(images.CO,Omega,X);

M2m=ip2mat(M2i,m);
M1m=ip2mat(M1i,m);
M3m=ip2mat(M3i,m);
dA1m=ip2mat(dA1i,m);
dA2m=ip2mat(dA2i,m);
W1m=ip2mat(W1i,m);
W2m=ip2mat(W2i,m);
COm=ip2mat(COi,m);
dAreasImgm=ip2mat(dAreasImgi,m);

% transform raw data into atlas space
interpolation('set','MODE','linear-periodic','period',2*pi);
dM2i=interpolation(images.M2,Omega,yOpt_inv);
A2i=interpolation(TD2,Omega,X);
interpolation('set','MODE','linear');
dM1i=interpolation(images.M1,Omega,yOpt_inv);
dM3i=interpolation(images.M3,Omega,yOpt_inv);
A1i=interpolation(TD1,Omega,X);
dW1i=interpolation(WD1,Omega,yOpt_inv);
dW2i=interpolation(WD2,Omega,yOpt_inv);
dCOi=interpolation(COm,Omega,yOpt_inv);
AreasImgi=(interpolation(areasImg,Omega,X));

dM2m=ip2mat(dM2i,m);
dM1m=ip2mat(dM1i,m);
dM3m=ip2mat(dM3i,m);
A1m=ip2mat(A1i,m);
A2m=ip2mat(A2i,m);
AreasImgm=ip2mat(AreasImgi,m);
dW1m=ip2mat(dW1i,m);
dW2m=ip2mat(dW2i,m);
dCOm=ip2mat(dCOi,m);

% remove walls to draw edges
% areasImg(find(areasImg==5))=NaN;
% areasImg(find(areasImg==6))=NaN;

% get interporated areas of interest
OV=ceil(interpolation(areasImg,Omega,X));
OVm=ip2mat(OV,m);
OVm(isnan(OVm))=0;
if isfield(images,'A3') % for LO-1/2, TO-1/2
    Edges = detectAreaBorders(OVm);
else % for V1-3
    Edges=double(edge(OVm, 'Canny'));
end

% get deformed areas of interest
OV=round(interpolation(areasImg,Omega,yCentered));
OVm=ip2mat(OV,m);
OVm(isnan(OVm))=0;
if isfield(images,'A3') % for LO-1/2, TO-1/2
    dEdges = detectAreaBorders(OVm);
else % for V1-3
    dEdges=double(edge(OVm, 'Canny'));
end

% images_size = size(images.A1,1);
% figure
% subplot(231)
% hold on
% imagesc(1:(images_size-1)/(2^maxLevel-1):images_size,1:(images_size-1)/(2^maxLevel-1):images_size,mergedImage(M1m,dEdges,hsv,15))
% % I=flipdim(mergedImage(dM2m,Edges,hsv,2*pi),1); 
% % image(h(1)/2:h(1):1,h(2)/2:h(2):1,I);
% axis image; axis xy;axis off;
% set(gca,'YDir','reverse');
% 
% subplot(234)
% hold on
% imagesc(1:(images_size-1)/(2^maxLevel-1):images_size,1:(images_size-1)/(2^maxLevel-1):images_size,mergedImage(dM1m,Edges,hsv,15))
% plot(corners{1}(:,1),corners{1}(:,2),'k+','LineWidth',2)
% plot(corners{2}(:,1),corners{2}(:,2),'k+','LineWidth',2)
% plot(corners{3}(:,1),corners{3}(:,2),'k+','LineWidth',2)
% plot(corners{4}(:,1),corners{4}(:,2),'k+','LineWidth',2)
% % I=flipdim(mergedImage(dM2m,Edges,hsv,2*pi),1); 
% % image(h(1)/2:h(1):1,h(2)/2:h(2):1,I);
% axis image; axis xy;axis off;
% set(gca,'YDir','reverse');
% 
% subplot(232)
% hold on
% imagesc(1:(images_size-1)/(2^maxLevel-1):images_size,1:(images_size-1)/(2^maxLevel-1):images_size,mergedImage(M2m,dEdges,hsv,2*pi))
% % I=flipdim(mergedImage(dM2m,Edges,hsv,2*pi),1); 
% % image(h(1)/2:h(1):1,h(2)/2:h(2):1,I);
% axis image; axis xy;axis off;
% set(gca,'YDir','reverse');
% 
% subplot(235)
% hold on
% imagesc(1:(images_size-1)/(2^maxLevel-1):images_size,1:(images_size-1)/(2^maxLevel-1):images_size,mergedImage(dM2m,Edges,hsv,2*pi))
% plot(corners{1}(:,1),corners{1}(:,2),'k+','LineWidth',2)
% plot(corners{2}(:,1),corners{2}(:,2),'k+','LineWidth',2)
% plot(corners{3}(:,1),corners{3}(:,2),'k+','LineWidth',2)
% plot(corners{4}(:,1),corners{4}(:,2),'k+','LineWidth',2)
% % I=flipdim(mergedImage(dM2m,Edges,hsv,2*pi),1); 
% % image(h(1)/2:h(1):1,h(2)/2:h(2):1,I);
% axis image; axis xy;axis off;
% set(gca,'YDir','reverse');
% 
% tmp=cool_springCmap;
% subplot(233)
% hold on
% imagesc(1:(images_size-1)/(2^maxLevel-1):images_size,1:(images_size-1)/(2^maxLevel-1):images_size,mergedImage(M3m,dEdges,tmp(129:224,:),15))
% % I=flipdim(mergedImage(dM2m,Edges,hsv,2*pi),1); 
% % image(h(1)/2:h(1):1,h(2)/2:h(2):1,I);
% axis image; axis xy;axis off;
% set(gca,'YDir','reverse');
% 
% subplot(236)
% hold on
% imagesc(1:(images_size-1)/(2^maxLevel-1):images_size,1:(images_size-1)/(2^maxLevel-1):images_size,mergedImage(dM3m,Edges,tmp(129:224,:),15))
% plot(corners{1}(:,1),corners{1}(:,2),'k+','LineWidth',2)
% plot(corners{2}(:,1),corners{2}(:,2),'k+','LineWidth',2)
% plot(corners{3}(:,1),corners{3}(:,2),'k+','LineWidth',2)
% plot(corners{4}(:,1),corners{4}(:,2),'k+','LineWidth',2)
% % I=flipdim(mergedImage(dM2m,Edges,hsv,2*pi),1); 
% % image(h(1)/2:h(1):1,h(2)/2:h(2):1,I);
% axis image; axis xy;axis off;
% set(gca,'YDir','reverse');
