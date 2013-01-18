function [] = dtiAnalyzeVolumetry(subjectDir,backgroundImage)
% [] = dtiAnalyzeVolumetry(subjectDir,backgroundImage)
% Tensor-based morphometry measures of group data
%
% Produces correlation maps of template-to-subject deformation maps and
% reading abilities.  The volume dialation/contraction measure used is the
% determinant of the Jacobian of the deformation field.  Note that a
% positive value indicates a brain structure in the subject to be larger
% than the template (i.e. a positive correlation indicates a correlation
% between high reading score and larger-than-normal region size).
%
% Inputs:
% subjectDir: Directory of all subjects.  Note that both deformation fields
% (format: XXXX_2_YYYY_DF.mat) and deformed brains (XXXX_reg2_YYYY.mat)
% should be in this directory.
% backgroundImage: Analyze-format file for background of overlay (usually a
% FA or B0 map of the template brain or average brain)
s = findSubjects(subjectDir,'_2_');
s_warped = findSubjects(subjectDir,'reg2');
N = length(s);
for i = 1:N
    [p f junk junks] = fileparts(s{i});
    us=findstr('_',f);
    sCode{i} = f(1:us(1)-1);
end    
behData = dtiGetBehavioralData(sCode);
basicRead = behData(:,1);


temp = load(s{1});
dim = size(temp.deformField);
vol_img = zeros(dim(1),dim(2),dim(3),N);
for i = 1:N
    %Logistics of finding paths and filenames
    [p,f,e] = fileparts(s{i});
    dt6FileNameList{i} = f;
    dt6FilePathList{i} = p;
    [junk f_warped junk2] = fileparts(s_warped{i});
   %------------------------------------------
    temp = load(s{i});
    df = temp.deformField;
    %Masking out deformation fields outside brain
    b0 = loadAnalyze(fullfile(p,[f_warped,'_B0Map.hdr']));
    mask = repmat((b0 > 425),[1 1 1 3]);
    df = df.*mask;    
    %-----------------------------------------
    jakeDF = jacobian(df);
    vol_img(:,:,:,i) = fastDet(jakeDF);
    i
end


vol_img(isnan(vol_img(:))) = 0;

mn_vol = mean(vol_img, 4);
sd_vol = std(vol_img, 1, 4);

mn_rs = mean(basicRead);
sd_rs = std(basicRead);

vol_Z = (vol_img-repmat(mn_vol, [1 1 1 N])) ./ repmat(sd_vol, [1 1 1 N]);
rs_Z = (basicRead-mn_rs) ./ sd_rs;

r = 0;
for(ii=1:N)
    r = r + vol_Z(:,:,:,ii).*rs_Z(ii);
end
r = r./N;

% compute Fischer's z'
z = 0.5*(log((1+r)./(1-r)));
df = N-3;
p = erfc((abs(z)*sqrt(df))/sqrt(2));
%BUT WHAT ABOUT NANs?
p(isnan(p)) = 1; %disregard NaNs - probability 1 sets it to background noise

%Saving out file
stat{1} = r; stat{2} = z; stat{3} = p;
statName{1} = 'r'; statName{2} = 'z'; statName{3} = 'p';
% atlas = '/teal/scr1/dti/ssRegistration050209/ssTemplate_Iter0.mat';
% notes = 'Correlation with basic reading';
% filename = '/teal/scr1/dti/basicReadingMaps050209.mat';
imR_X = makeMontage(imrotate(r,90),[20:49]);figure; imagesc(imR_X); axis image; colorbar; 
title([subjectDir,'Basic Reading Score and Contraction Correlations, Axial View']); 
imR_Y = makeMontage(imrotate(shiftdim(r,1),90),[20:49]);figure; imagesc(imR_Y); axis image; colorbar; 
title([subjectDir,'Basic Reading Score and Contraction Correlations, Sagittal View']); 
imR_Z = makeMontage(imrotate(shiftdim(r,2),180),[20:49]);figure; imagesc(imR_Z); axis image; colorbar; 
title([subjectDir,'Basic Reading Score and Contraction Correlations, Coronal View']); 

imP = makeMontage(imrotate(p,90),[20:49]);figure; imagesc(imP); axis image; colormap hot;colorbar;

mask_P = p<.01;
p_norm = -log10(p);
p_norm = p_norm/max(p_norm(:));
p_norm = round(p_norm*255+1);
cmap = hsv(256);

%FA = loadAnalyze([subjectDir '/ssTemplate_Iter0_FAMap']);
FA = loadAnalyze(backgroundImage);
FA =FA./max(FA(:));

R = FA; G = FA; B = FA;
R(mask_P) = cmap(p_norm(mask_P),1);
G(mask_P) = cmap(p_norm(mask_P),2);
B(mask_P) = cmap(p_norm(mask_P),3);
im = makeMontage3(R,G,B,[20:60], 2);
figure; image(im); axis image; title('Volumetry Thresholded Probabilities');
cbar = [0:.05:1];
figure; imagesc(cbar); colormap(cmap);
return

function J = jacobian(vectorField)
%Approximates Jacobian of a vector field - each voxel has an associated 3x3 jacobian
dim = size(vectorField);
J = zeros(dim(1),dim(2),dim(3),3,3);
for i = 1:3 %Approximates gradients one tensor value at a time
    [gradX,gradY,gradZ] = gradient(vectorField(:,:,:,i),1);  
    J(:,:,:,i,1) = -gradY; 
    J(:,:,:,i,2) = -gradX; 
    J(:,:,:,i,3) = -gradZ;
end
return

function determinant = fastDet(jakeDF)
% %Function to calculate det(eye(3) + jakeDF(ii,jj,kk,:,:)) quickly
% determinant = (jakeDF(:,:,:,1,1)+1).*(jakeDF(:,:,:,2,2)+1).*(jakeDF(:,:,:,3,3)+1) + jakeDF(:,:,:,1,2).*jakeDF(:,:,:,2,3).*jakeDF(:,:,:,3,1) + ...
%     jakeDF(:,:,:,1,3).*jakeDF(:,:,:,2,1).*jakeDF(:,:,:,3,2) - jakeDF(:,:,:,3,1).*(jakeDF(:,:,:,2,2)+1).*jakeDF(:,:,:,1,3) - ...
%     jakeDF(:,:,:,3,2).*jakeDF(:,:,:,2,3).*(jakeDF(:,:,:,1,1)+1) - (jakeDF(:,:,:,3,3)+1).*jakeDF(:,:,:,2,1).*jakeDF(:,:,:,1,2);

determinant = (jakeDF(:,:,:,1,1)).*(jakeDF(:,:,:,2,2)).*(jakeDF(:,:,:,3,3)) + jakeDF(:,:,:,1,2).*jakeDF(:,:,:,2,3).*jakeDF(:,:,:,3,1) + ...
    jakeDF(:,:,:,1,3).*jakeDF(:,:,:,2,1).*jakeDF(:,:,:,3,2) - jakeDF(:,:,:,3,1).*(jakeDF(:,:,:,2,2)).*jakeDF(:,:,:,1,3) - ...
    jakeDF(:,:,:,3,2).*jakeDF(:,:,:,2,3).*(jakeDF(:,:,:,1,1)) - (jakeDF(:,:,:,3,3)).*jakeDF(:,:,:,2,1).*jakeDF(:,:,:,1,2);
return
