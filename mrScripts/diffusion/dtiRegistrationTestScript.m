addpath /snarp/u1/data/dti/matlab/
baseDir = '/snarp/u1/data/dti/childData/Registration/nonPPDRegistration/Iteration4/';
d=dir(fullfile(baseDir,'*.mat'));
template = load('/snarp/u1/data/dti/childData/Registration/nonPPDRegistration/controlBrainAve_threeIter.mat');
b0 = double(template.b0);
b0 = b0./max(b0(:));
con = [];
dys = [];
for(ii=1:length(d))
    sc = strfind(d(ii).name,'_');
    sc = d(ii).name(1:sc(1)-1);
    subType = getSubjectType(sc);
    if(~isempty(subType))
        def = load(fullfile(baseDir, d(ii).name));
        if(subType{1}=='c')
            [dField absDField] = dtiDeformEigenfaces3D(def.deformField);
            con(length(con)+1).deformField = dField;
            con(length(con)).absDeform = absDField;
        else
            [dField absDField] = dtiDeformEigenfaces3D(def.deformField);
            dys(length(dys)+1).deformField = dField;
            dys(length(dys)).absDeform = absDField;
        end
    end
end

vmc = mean(cat(5,con.deformField),5);
vmd = mean(cat(5,dys.deformField),5);
mc = sqrt(vmc(:,:,:,1).^2+vmc(:,:,:,2).^2+vmc(:,:,:,3).^2);
md = sqrt(vmd(:,:,:,1).^2+vmd(:,:,:,2).^2+vmd(:,:,:,3).^2);



mc = mean(cat(4,con.absDeform),4);
sc = std(cat(4,con.absDeform),0,4);
md = mean(cat(4,dys.absDeform),4);
sd = std(cat(4,dys.absDeform),0,4);
figure; imagesc(makeMontage(mc,[10:56])); axis image; colorbar; title('mean control deformation');
figure; imagesc(makeMontage(sc,[10:56])); axis image; colorbar; title('stdev control deformation');
figure; imagesc(makeMontage(md,[10:56])); axis image; colorbar; title('mean dyslexic deformation');
figure; imagesc(makeMontage(sd,[10:56])); axis image; colorbar; title('stdev dyslexic deformation');
ss = abs((md-mc)./sc);
figure; imagesc(makeMontage(ss,[10:56])); axis image; colormap hsv; colorbar; 
title('(mean(dys) - mean(con))/std(con)');
ssBlur = smooth3(ss, 'gaussian', 7);
figure; imagesc(makeMontage(ssBlur,[10:56])); axis image; colormap hsv; colorbar; 
title('smooth3((mean(dys) - mean(con))/std(con))');
mask = ssBlur>2;

ssNorm = ssBlur;
ssNorm(ssNorm>10) = 10; ssNorm(ssNorm<-10) = -10; 
ssNorm = round((ssNorm+10)./20.*255)+1;
cmap = hsv(256);
ssR = b0; ssR(mask) = cmap(ssNorm(mask),1);
ssG = b0; ssG(mask) = cmap(ssNorm(mask),2);
ssB = b0; ssB(mask) = cmap(ssNorm(mask),3);
im = makeMontage3(ssR,ssG,ssB,[10:56], 2);
figure; image(im); axis image;
cbar = [0:.05:1];
figure; imagesc(cbar); colormap(cmap);

vec = squeeze(con(1).deformField(:,:,30,:));
mag = squeeze(con(1).absDeform(:,:,30,:));
figure; imagesc(mag); axis xy
%figure; quiver3(ones(size(vec(:,:,1))), vec(:,:,1), vec(:,:,2), vec(:,:,3));
figure; quiver(vec(:,:,1), vec(:,:,2));

vec = squeeze(dys(1).deformField(:,:,30,:));
mag = squeeze(dys(1).absDeform(:,:,30,:));
figure; imagesc(mag); axis xy
%figure; quiver3(ones(size(vec(:,:,1))), vec(:,:,1), vec(:,:,2), vec(:,:,3));
figure; quiver(vec(:,:,1), vec(:,:,2));
