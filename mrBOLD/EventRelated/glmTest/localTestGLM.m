% Comparing the SPM beta weights and the ones derived from mrVista
%
% We ran SPM version 2 in this directory.  The time series data are stored
% in the imageSlice sub-directory. The data here is a toy set with only one
% slice that allows us to debug the beta weight computations in the mrVista
% GLM and in the SPM analysis.
% 
% When we ran the SPM model we created an SPM.mat file that is in this
% directory that contains all of the relevant information for the two types
% of events that take place in the experiment: rhymes and lines.  You can
% view the design matrix by running SPM2 | fMRI-time series | Review (or
% something like that). The design matrix is also just read in below.
%

% We could only run the SPM2 code on slightly older versions of Matlab, say
% Matlab 7.0.4.  This doesn't run properly on Matlab 2007a, for example. 

%% The first part is about properly computing the model weights
% This part confirmed that our weights and SPM are the same up to a single
% global scale factor.

% Current directory.
chdir(fullfile(mrvRootPath,'EventRelated','glmTest'))

% This is the original SPM Michal and I created, but I cleared the .xM
% field so that there is no mask.  This makes the data comparable to Rory's
% calculation, point by point.
load('SPM-noMask');

% The spm calculation of the betas is in spm_spm_local
spm_defaults
[SPM,pKX] = spm_spm_local(SPM);

% We set X, the design matrix, to be the one we built using the SPM gui.
% this design matrix has 1 predictor per condition, plus a column of ones.
% it uses the hrf from SPM
X = SPM.xX.X;
% figure(1); plot(X)
% tmp = pinv(pKX); max(abs(X(:) - tmp(:))) 

% We created the beta files using the SPM interface (Estimate).  We read
% the files here using the builtin Matlab analyze reader.
% chdir('SPM-UI')
tmp = analyzeRead('beta_0001');  spmBeta(:,1) = tmp(:);
tmp = analyzeRead('beta_0002');  spmBeta(:,2) = tmp(:);
tmp = analyzeRead('beta_0003');  spmBeta(:,3) = tmp(:);
[r,c] = size(tmp);
% imtool(reshape(spmBeta(:,1),r,c))
% figure(1); imagesc(reshape(spmBeta(:,1),r,c)); axis image;

% We convert the time series in analyze format into our own time series.
inFileRoot = ...
    fullfile(mrvRootPath,'EventRelated',...
    'glmTest',...
    'imageFiles',...
    'Scan1-Slice6');
outFileRoot = inFileRoot;
nVols = 78;
firstVolIndex = 0;
doRotate = 0;
scaleFact = [1,1];
flipudFlag = 0;
fliplrFlag = 0;
tSeries = analyze2mrLoadRet3TSeries(inFileRoot,outFileRoot,nVols,...
    firstVolIndex,doRotate,scaleFact,flipudFlag,fliplrFlag);

% figure(1); plot(tSeries)
%   max(abs(KWY(:) - tSeries(:)))

% Compute the beta weights from mrVista
tr = 2; nh = 1;
model    = glm(tSeries, X, tr, nh);
mrvBetas = squeeze(model.betas);

% Compare the beta weights for the different model terms
ii = 1;
mrvB = reshape(mrvBetas(ii,:),r,c);
figure(2); imagesc(mrvB); axis image; colormap(gray(256))
figure(1); hist(mrvB(:),100)

% Compare the values directly.
figure(1); plot(mrvBetas(ii,:),spmBeta(:,ii),'.')
grid on

% We can check the images read through the SPM call and our call based on
% analyze Read. They are the same.
% vName = 'imageFiles\Scan1-Slice6\000.img';
vName = 'C:\u\brian\Matlab\VISTASOFT\mrLoadRet-3.0\EventRelated\glmTest\imageFiles\Scan1-Slice6\077.img';

tmp = analyzeRead(vName);
figure(1); hist(tmp(:),100)
imtool(tmp/max(tmp(:)));
mean(tmp(:))

% V = VY(i)
V.fname = vName;
V.pinfo = [0.0066, 0, 0]';
r = 124; c= 99;
[X,Y] = meshgrid(1:r,1:c);
Z = ones(size(X(:)));
XYZ = [X(:),Y(:),Z(:)]';
spmY = spm_get_data(V,XYZ);
figure(2);hist(spmY(:),100)

spmY = reshape(spmY,c,r)';
imtool(spmY/max(spmY(:)));
mean(spmY(:))

%% We analyze the t-contrast images using mrVista.  We created a
% t-contrast using SPM via its GUI.  These are in SPMT004 and con_004. 
chdir(fullfile(mrvRootPath,'EventRelated','glmTest'))

% For the contrasts, we used this SPM
load('SPM');
X = SPM.xX.X;

% Get the time series
inFileRoot = ...
    fullfile(mrvRootPath,'EventRelated',...
    'glmTest',...
    'imageFiles',...
    'Scan1-Slice6');
outFileRoot = inFileRoot;
nVols = 78;
firstVolIndex = 0;
doRotate = 0;
scaleFact = [1,1];
flipudFlag = 0;
fliplrFlag = 0;
tSeries = analyze2mrLoadRet3TSeries(inFileRoot,outFileRoot,nVols,...
    firstVolIndex,doRotate,scaleFact,flipudFlag,fliplrFlag);

% Build the GLM model
tr = 2; nh = 1;
model    = glm(tSeries, X, tr, nh);

active = 1;   % Rhyme condition
control= 2;   % Line condition
[stat, ces, vSig, units] = glm_contrast(model,active,control);
[statT, ces, vSig, units] = glm_contrast(model,active,control,'t');

r = 124; c= 99;
mrvCON = reshape(stat,r,c);
figure(1); imagesc(mrvCON); axis image

spmCON = analyzeRead('con_0004');
spmCON = reshape(spmCON,r,c);
figure(2); imagesc(spmCON); axis image
imtool(spmCON)

plot(spmCON(:),mrvCON(:),'.'); axis equal; grid on

spmT = analyzeRead('SPMT_0004');
spmT = reshape(spmT,r,c);
figure(3); imagesc(spmT); axis image

mrvCONT = reshape(statT,r,c);
figure(1); imagesc(mrvCONT); axis image

% Notice that there are a lot of mrvCONT values that are high were the SPMT
% values are zero.  We think these are from places that SPM masks and mrV
% doesn't.  We need to figure this out.
plot(spmT(:),mrvCONT(:),'.');axis equal; grid on

% hist(mrvCONT(:),20)

l = (spmT(:) == 0);
tmp = zeros(size(spmT));
tmp(l) = 1;
tmp = reshape(tmp,r,c);
figure(4); subplot(1,2,1), imagesc(tmp)
colorbar('vert'); axis image

l = (mrvCONT(:) == 0);
tmp = zeros(size(mrvCONT));
tmp(l) = 1;
tmp = reshape(tmp,r,c);
figure(4); subplot(1,2,2), imagesc(tmp)
colorbar('vert'); axis image


