function [images images2 images3 view]= RawToCommonAtlas(images, corners, safirData, safirResult, view, flip_lr)
% From the results of atlas fitting, get the data morphed into an individual 
% atlas space (images2), and that morphed into a common atlas space (images3)
%
% [images images2 images3 view]= RawToCommonAtlas(images, corners, safirData, safirResult, [view], [flip_lr])
%
% INPUT
%  images: a structure including raw data (M1,M2,M3) and inital atlas (A1,A2)
%  corners: corners of the initial atlas
%  safirData: data structure for the atlas fitting GUI
%  safirResult: morphing matrix
%  view: has to be specified if you want to get ROIs
%  flip_lr: flip 
%
% OUTPUT
%  images: raw data with the fitted atlas
%  images2: the data morphed into an individual atlas space
%  images3: the data morphed into a common atlas space
%  view: has to be specified if you want to get ROIs
% Example
%  [images images2 images3]= RawToCommonAtlas(images, corners, 'safirData', 'safirResult');
%
% 07/03 KA wrote it 

% Check arguments
if notDefined('images'), error('images should be defined'); end
if notDefined('corners'), error('corners should be defined'); end
if notDefined('safirData'), safirData = 'safirData'; end
if notDefined('safirResult'), safirData = 'safirResult'; end
if notDefined('flip_lr'), flip_lr=0; end
    
load(safirResult)
load(safirData,'maxLevel')

if size(corners,2)==6 % LO,TO
    area_num=4;
elseif size(corners,2)==5 % V1-3
    area_num=5;
end

yOpt_inv = inverse_yOpt(yOpt,maxLevel);
if isfield(images,'A3')
    [dM1m dM2m dM3m Edges dEdges A1m A2m M1m M2m M3m W1m W2m COm dW1m dW2m dCOm dAreasImgm dA1m dA2m dA3m] = showResults2(yOpt,yOpt_inv,corners, safirData,images);
else
    [dM1m dM2m dM3m Edges dEdges A1m A2m M1m M2m M3m W1m W2m COm dW1m dW2m dCOm dAreasImgm dA1m dA2m] = showResults2(yOpt,yOpt_inv,corners, safirData,images);
end

images_size = size(images.A1,1);
if strfind(safirData,'left')>0
    curSlice = 1;
elseif  strfind(safirData,'right')>0
    curSlice = 2;
end
if notDefined('view')==0
    view = transformAtlasToROIs(round(dAreasImgm), images_size, curSlice, view);
end

% raw data spcae
images.M1 = M1m;
images.M2 = M2m;
images.M3 = M3m;
images.W1 = W1m;
images.W2 = W2m;
images.CO = COm;
images.dA1 = dA1m;
images.dA2 = dA2m;
if isfield(images,'A3')
    images.dA3 = dA3m;
end
images.dEdges = dEdges;
images.dareasImg = round(dAreasImgm);

% individual atlas space
images2.A1 = A1m;
images2.A2 = A2m;
images2.M1 = dM1m;
images2.M2 = dM2m;
images2.M3 = dM3m;
images2.W1 = dW1m;
images2.W2 = dW2m;
images2.CO = dCOm;
images2.areasImg = round(dAreasImgm);

% For flipped image (since sometimes flat view itself is flipped)
if flip_lr
    images2.M1 = fliplr(images2.M1);
    images2.M2 = fliplr(images2.M2);
    images2.M3 = fliplr(images2.M3);
    images2.A1 = fliplr(images2.A1);
    images2.A2 = fliplr(images2.A2);
    images2.W1 = fliplr(images2.W1);
    images2.W2 = fliplr(images2.W2);
    images2.CO = fliplr(images2.CO);
    images2.areasImg = fliplr(images2.areasImg);

    for i=1:size(corners,2)
        corners{i}(:,1) = size(images.A1,2)+1-corners{i}(:,1);
    end
end

% scale corner coordinates
for i=1:size(corners,2)
    corners_scaled{i} = corners{i}*(size(images.A1,1)-1)/(size(images.A1,1)-1);
%     corners_scaled{i} = corners{i};
end

if size(corners,2)==6 % LO-1/2, TO-1/2
    images3.A1 = transform_image_LO_TO(images2.A1,corners,'bicubic');
    images3.A2 = transform_image_LO_TO(images2.A2,corners,'bicubic');
    images3.M1 = transform_image_LO_TO(images2.M1,corners,'bicubic');
    images3.M2 = transform_image_LO_TO(images2.M2,corners,'bicubic');
    images3.M3 = transform_image_LO_TO(images2.M3,corners,'bicubic');
    images3.W1 = transform_image_LO_TO(images2.W1,corners,'bicubic');
    images3.W2 = transform_image_LO_TO(images2.W2,corners,'bicubic');
    images3.CO = transform_image_LO_TO(images2.CO,corners,'bicubic');
    images3.CO2=images3.CO;
    images3.CO2(find(images3.CO2<0.1))=0;
    images3.COmask = double(images3.CO>=0.1);
    images3.areasImg = round(transform_image_LO_TO(images2.areasImg,corners,'nearest'));
elseif size(corners,2)==5 % V1-3
    images3.A1 = transform_image_V1_V3(images2.A1,corners,'bicubic');
    images3.A2 = transform_image_V1_V3(images2.A2,corners,'bicubic');
    images3.M1 = transform_image_V1_V3(images2.M1,corners,'bicubic');
    images3.M2 = transform_image_V1_V3(images2.M2,corners,'bicubic');
    images3.M3 = transform_image_V1_V3(images2.M3,corners,'bicubic');
    images3.W1 = transform_image_V1_V3(images2.W1,corners,'bicubic');
    images3.W2 = transform_image_V1_V3(images2.W2,corners,'bicubic');
    images3.CO = transform_image_V1_V3(images2.CO,corners,'bicubic');
    images3.CO2=images3.CO;
    images3.CO2(find(images3.CO2<0.1))=0;
    images3.COmask = double(images3.CO>=0.1);
    images3.areasImg = round(transform_image_V1_V3(images2.areasImg,corners,'nearest'));
end

if ~notDefined('images3')    
    images3.M1(find(isnan(images3.CO)))=0;
    images3.M2(find(isnan(images3.CO)))=0;
    images3.M3(find(isnan(images3.CO)))=0;
    images3.CO(find(isnan(images3.CO)))=0;

    images3.M1(find(images3.CO>1))=0;
    images3.M2(find(images3.CO>1))=0;
    images3.M3(find(images3.CO>1))=0;
    images3.CO(find(images3.CO>1))=0;
end

if size(corners,2)==6 % LO-1/2, TO-1/2
%     corners2 =  [30 40; 90 40; 90 80; 30 80; 30 40; 45 40; 45 80; 60 80; 60 40; 75 40; 75 80];
    corners2 =  [30 40; 105 40; 105 80; 105 40; 90 40; 90 80; 30 80; 30 40; 45 40; 45 80; 60 80; 60 40; 75 40; 75 80; 90 80; 105 80];
else % V1-3
    corners2 =  [15 40; 105 40; 105 80; 15 80; 15 40; 30 40; 30 80; 45 80; 45 40; 75 40; 75 80; 90 80; 90 40];
end

tmp=load('WedgeMapLeft');
figure
subplot(331)
imagesc(1:(images_size-1)/(2^maxLevel-1):images_size,1:(images_size-1)/(2^maxLevel-1):images_size,mergedImage(images.M2.*double(images.CO>0.1),dEdges,[tmp.modeInformation.cmap(119:128,:);tmp.modeInformation.cmap(65:118,:)],2*pi))
% contourf(images.M2.*double(images.CO>0.1))
set(gca,'YDir','reverse');
axis equal
axis([1 images_size 1 images_size])
title('Angle map with fitted atlas')
set(gca,'XTickLabel','')
set(gca,'YTickLabel','')
axis off

subplot(332)
hold on
imagesc(1:(images_size-1)/(2^maxLevel-1):images_size,1:(images_size-1)/(2^maxLevel-1):images_size,mergedImage(images2.M2.*double(images2.CO>0.1),[],[tmp.modeInformation.cmap(119:128,:);tmp.modeInformation.cmap(65:118,:)],2*pi))
for ii=1:size(corners,2)
    plot([corners{ii}(:,1);corners{ii}(1,1)],[corners{ii}(:,2);corners{ii}(1,2)],'k','LineWidth',2)
end
if size(corners,2)==5
    plot([corners{5}(:,1);corners{5}(1,1)],[corners{5}(:,2);corners{5}(1,2)],'k','LineWidth',2)
end
% plot([corners{7}(:,1);corners{7}(1,1)],[corners{7}(:,2);corners{7}(1,2)],'k','LineWidth',2)
set(gca,'YDir','reverse');
axis equal
axis([1 images_size 1 images_size])
title('Angle (raw data space)')
title('Deformed angle map with initial atlas')
set(gca,'XTickLabel','')
set(gca,'YTickLabel','')
axis off

if ~notDefined('images3')
    subplot(333)
    hold on
    imagesc(1:(images_size-1)/(2^maxLevel-1):images_size,1:(images_size-1)/(2^maxLevel-1):images_size,mergedImage(images3.M2.*double(images3.CO>0.1),[],[tmp.modeInformation.cmap(119:128,:);tmp.modeInformation.cmap(65:118,:)],2*pi))
    plot(corners2(:,1),corners2(:,2),'k','LineWidth',2)
    set(gca,'YDir','reverse');
    axis equal
    axis([1 120 1 120])
    title('Deformed angle map with common atlas')
    set(gca,'XTickLabel','')
    set(gca,'YTickLabel','')
    axis off
end

subplot(334)
imagesc(0:images_size/127:images_size,0:images_size/127:images_size,mergedImage(images.M1.*double(images.CO>0.1),dEdges,hsvTbCmap(0,256), 15))
set(gca,'YDir','reverse');
axis equal
axis([1 images_size 1 images_size])
title('Eccentricity map with fitted atlas')
set(gca,'XTickLabel','')
set(gca,'YTickLabel','')
axis off

subplot(335)
hold on
imagesc(1:(images_size-1)/(2^maxLevel-1):images_size,1:(images_size-1)/(2^maxLevel-1):images_size,mergedImage(images2.M1.*double(images2.CO>0.1),[],hsvTbCmap(0,256),15))
for ii=1:size(corners,2)
    plot([corners{ii}(:,1);corners{ii}(1,1)],[corners{ii}(:,2);corners{ii}(1,2)],'k','LineWidth',2)
end
set(gca,'YDir','reverse');
axis equal
axis([1 images_size 1 images_size])
title('Deformed eccentricity map with initial atlas')
set(gca,'XTickLabel','')
set(gca,'YTickLabel','')
axis off

if ~notDefined('images3')
    subplot(336)
    hold on
    imagesc(1:(images_size-1)/(2^maxLevel-1):images_size,1:(images_size-1)/(2^maxLevel-1):images_size,mergedImage(images3.M1.*double(images3.CO>0.1),[],hsvTbCmap(0,256),15))
    plot(corners2(:,1),corners2(:,2),'k','LineWidth',2)
    set(gca,'YDir','reverse');
    axis equal
    axis([1 120 1 120])
    title('Deformed eccentricity map with common atlas')
    set(gca,'XTickLabel','')
    set(gca,'YTickLabel','')
    axis off
end

tmp=cool_springCmap;
subplot(337)
imagesc(1:(images_size-1)/(2^maxLevel-1):images_size,1:(images_size-1)/(2^maxLevel-1):images_size,mergedImage(images.M3.*double(images.CO>0.1),dEdges,tmp(129:224,:), 15))
set(gca,'YDir','reverse');
axis equal
axis([1 images_size 1 images_size])
title('pRF size map with fitted atlas')
set(gca,'XTickLabel','')
set(gca,'YTickLabel','')
axis off

subplot(338)
hold on
imagesc(1:(images_size-1)/(2^maxLevel-1):images_size,1:(images_size-1)/(2^maxLevel-1):images_size,mergedImage(images2.M3.*double(images2.CO>0.1),[],tmp(129:224,:),15))
for ii=1:size(corners,2)
    plot([corners{ii}(:,1);corners{ii}(1,1)],[corners{ii}(:,2);corners{ii}(1,2)],'k','LineWidth',2)
end
set(gca,'YDir','reverse');
axis equal
axis([1 images_size 1 images_size])
title('Deformed pRF size map with initial atlas')
set(gca,'XTickLabel','')
set(gca,'YTickLabel','')
axis off

if ~notDefined('images3')
    subplot(339)
    hold on
    imagesc(1:(images_size-1)/(2^maxLevel-1):images_size,1:(images_size-1)/(2^maxLevel-1):images_size,mergedImage(images3.M3.*double(images3.CO>0.1),[],tmp(129:224,:),15))
    plot(corners2(:,1),corners2(:,2),'k','LineWidth',2)
    set(gca,'YDir','reverse');
    axis equal
    axis([1 120 1 120])
    title('Deformed pRF size map with common atlas')
    set(gca,'XTickLabel','')
    set(gca,'YTickLabel','')
    axis off

    % mask = (images3.CO>0.1).*(images3.M2>pi/2-pi/4).*(images3.M2<pi/2*3+pi/4);
    mask = double(images3.CO>0.1).*double(double(images3.CO<=1));
    mask_nan = mask;
    mask_nan(find(mask==0))=nan;

    % Angle modulation averaged across iso-ecc lines
    polar_ave=nan(3,size(round(10/(images_size-1)*(2^maxLevel-1)):round(110/(images_size-1)*(2^maxLevel-1)),2));
    polar_min=nan(3,size(round(10/(images_size-1)*(2^maxLevel-1)):round(110/(images_size-1)*(2^maxLevel-1)),2));
    polar_max=nan(3,size(round(10/(images_size-1)*(2^maxLevel-1)):round(110/(images_size-1)*(2^maxLevel-1)),2));
    for i=round(10/(images_size-1)*(2^maxLevel-1)):round(110/(images_size-1)*(2^maxLevel-1))
        for k=1:3
            tmp=[];
            for j=round((80-k*10)/(images_size-1)*(2^maxLevel-1)):round((90-k*10)/(images_size-1)*(2^maxLevel-1))
                % select the data for the averaging
                if mask(j,i)==1
                    tmp = [tmp [images3.M2(j,i);images3.CO(j,i)]];
                end
            end
            if sum(size(tmp))>0
                polar_ave(k,i-round(10/(images_size-1)*(2^maxLevel-1))+1)=sum(tmp(1,:).*tmp(2,:))/sum(tmp(2,:));
                polar_min(k,i-round(10/(images_size-1)*(2^maxLevel-1))+1)=min(tmp(1,:));
                polar_max(k,i-round(10/(images_size-1)*(2^maxLevel-1))+1)=max(tmp(1,:));
            end
        end
    end

    % Ecc modulation averaged across iso-polar lines
    ecc_ave=nan(area_num,44);
    for j=round(40/(images_size-1)*(2^maxLevel-1)):round(80/(images_size-1)*(2^maxLevel-1))
        for k=1:area_num
            tmp=[];
            for i=round((15+k*15)/(images_size-1)*(2^maxLevel-1)):round((30+k*15)/(images_size-1)*(2^maxLevel-1))
                if mask(j,i)==1
                    tmp = [tmp [images3.M1(j,i);images3.CO(j,i)]];
                end
            end
            if sum(size(tmp))>0
                ecc_ave(k,round(80/(images_size-1)*(2^maxLevel-1))+1-j)=sum(tmp(1,:).*tmp(2,:))/sum(tmp(2,:));
            end
        end
    end

    upper_model = [pi:pi/2/16:pi*1.5 pi*1.5-pi/2/16:-pi/2/16:pi pi+pi/2/16:pi/2/16:pi*1.5 pi*1.5-pi/2/16:-pi/2/16:pi];
    lower_model = [pi:pi/2/16:pi*1.5 pi*1.5-pi/2/16:-pi/2/16:pi pi+pi/2/16:pi/2/16:pi*1.5 pi*1.5-pi/2/16:-pi/2/16:pi]-pi*0.5;
    hemi_model = [pi*0.5:pi/16:pi*1.5 pi*1.5-pi/16:-pi/16:pi*0.5 pi*0.5+pi/16:pi/16:pi*1.5 pi*1.5-pi/16:-pi/16:pi*0.5];

    % Phase plot along iso-ecc lines and ecc plot along iso-polar lines
    figure
    for k=1:3
        subplot(2,3,k)
        hold on
        plot(-20:100/(round(110/(images_size-1)*(2^maxLevel-1))-round(10/(images_size-1)*(2^maxLevel-1))):80, ...
            images3.M2(round((80-k*10)/(images_size-1)*(2^maxLevel-1)):round((90-k*10)/(images_size-1)*(2^maxLevel-1)),round(10/(images_size-1)*(2^maxLevel-1)):round(110/(images_size-1)*(2^maxLevel-1)))' ...
            .*mask_nan(round((80-k*10)/(images_size-1)*(2^maxLevel-1)):round((90-k*10)/(images_size-1)*(2^maxLevel-1)),round(10/(images_size-1)*(2^maxLevel-1)):round(110/(images_size-1)*(2^maxLevel-1)))'-pi,'k','LineWidth',1)
        plot(-20:100/(round(110/(images_size-1)*(2^maxLevel-1))-round(10/(images_size-1)*(2^maxLevel-1))):80, polar_ave(k,:)-pi,'r','LineWidth',2)
        %     plot(0:70/74:70, polar_min(k,:)-pi,'r:','LineWidth',2)
        %     plot(0:70/74:70, polar_max(k,:)-pi,'r:','LineWidth',2)
        %     plot(0:80/85:80, upper_model-pi,'b','LineWidth',2);
        %     plot(0:80/85:80, lower_model-pi,'g','LineWidth',2);
        %     plot(0:80/85:80, hemi_model-pi,'m','LineWidth',2);
        xlabel('Atlas distance')
        ylabel('Angle from HM')
        if size(corners,2)==6 % LO,TO
            xlim([-10 70])
        else
            xlim([-20 80])
        end
        ylim([-2 2])
        if size(corners,2)==6 % LO,TO
            text(3,1.5,'LO1')
            text(18,1.5,'LO2')
            text(33,1.5,'TO1')
            text(48,1.5,'TO2')
        else
            text(-10,1.8,'V3v')
            text(5,1.8,'V2v')
            text(28,1.8,'V1')
            text(50,1.8,'V2d')
            text(65,1.8,'V3d')
        end
        
        if k==1
            title('Ecc = 0-4 deg')
        elseif k==2
            title('Ecc = 4-8 deg')
        else
            title('Ecc = 8-12 deg')
        end
    end

    for k=1:area_num
        subplot(2,area_num,area_num+k)
        hold on
        plot(40:-40/(round(80/(images_size-1)*(2^maxLevel-1))-round(40/(images_size-1)*(2^maxLevel-1))):0, ...
            images3.M1(round(40/(images_size-1)*(2^maxLevel-1)):round(80/(images_size-1)*(2^maxLevel-1)),round((15+15*k)/(images_size-1)*(2^maxLevel-1)):round((30+15*k)/(images_size-1)*(2^maxLevel-1))) ...
            .*mask_nan(round(40/(images_size-1)*(2^maxLevel-1)):round(80/(images_size-1)*(2^maxLevel-1)),round((15+15*k)/(images_size-1)*(2^maxLevel-1)):round((30+15*k)/(images_size-1)*(2^maxLevel-1))),'k','LineWidth',1)
        plot(0:(round(80/(images_size-1)*(2^maxLevel-1))-round(40/(images_size-1)*(2^maxLevel-1))):40, ecc_ave(k,:),'r','LineWidth',2)
        xlabel('Atlas distance')
        ylabel('Eccentricity (deg)')
        xlim([0 40])
        ylim([0 15])
        if size(corners,2)==6 % LO,TO
            if k==1
                title('LO1')
            elseif k==2
                title('LO2')
            elseif k==3
                title('TO1')
            else
                title('TO2')
            end
        elseif size(corners,2)==5 % V1-3
            if k==1
                title('V3v')
            elseif k==2
                title('V2v')
            elseif k==3
                title('V1')
            elseif k==4
                title('V2d')
            else
                title('V3d')
            end
        end
    end
end
return;

