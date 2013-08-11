function [ccCoords] = dtiFindCallosum(dt6,b0,xformToAcpc,finalThresh,sumFigFileName,figNum)
%
% [ccCoords] = dtiFindCallosum(dt6, b0, xformToAcpc, [finalThreshold=0.5], [sumFigFileName],[figNum])
%
% 
%
% HISTORY:
% 2007.04.19 RFD: wrote it.
% 2010.01.06 DY & RFD: fixed or-statement syntax on line 161

if(~exist('sumFigFileName','var')), sumFigFileName = ''; end
if(~exist('finalThresh','var')||isempty(finalThresh)), finalThresh = 0.5; end
if(~exist('figNum','var')), figNum = []; end
if(~isempty(figNum) && figNum==0 && isempty(sumFigFileName))
    showFigs = false;
else
    showFigs = true; 
end
useLevelSet = false;

targetMd = [0.7 1.1]; % in micrometers^2/msec
targetFa = [0.4 1.0];
% Note: For some data (e.g., NYU) the FA and MD target values may need to
% be adjusted. We have used the following with some success.
% targetMd = [0.4 1.1]; % in micrometers^2/msec
% targetFa = [0.4 1.1];

% Find left-right oriented PDDs:
targetPdd = [1 0 0];
% The PDD error function will be clamped to 0 with PDD angular errors +/-
% pddToleranceDeg degrees.
pddToleranceDeg = 10;
thick = [-1 0 1];
midSag = 0; % should be X=0
ax = 1; % sagittal plane is a cut along the first axis
templateFile = which('corpusCallosum.nii.gz');

% Ensure diffusivity units are in micrometers^2/msec
[curUnitStr,scale] = dtiGuessDiffusivityUnits(dt6);
dt6 = dt6.*scale;

%% GET THE SLICES
% We use nearest-neighbor ('n') to ensure no interpolation
[msDt6] = dtiGetSlice(xformToAcpc, dt6, ax, midSag, [], 'n');
[msB0] = dtiGetSlice(xformToAcpc, b0, ax, midSag, [], 'n');
% The image is now sampled at 1mm
xform = eye(4); xform(1:3,4) = xformToAcpc(1:3,4);

[eigVec,eigVal] = dtiEig(msDt6);
% HACK! We clip negative eigenvalues to zero here:
eigVal(eigVal<0) = 0;

% The matlab representation puts inferior-superior along the columns and
% anterior-posterior along the rows.

%% Compute PDD Error term
pddErr = eigVec(:,:,1,1).*targetPdd(1)+eigVec(:,:,2,1).*targetPdd(2)+eigVec(:,:,3,1).*targetPdd(3);
pddErr(pddErr>1) = 1; pddErr(pddErr<-1) = -1;
pddErr = acos(pddErr);
% Reflect about pi/2 for angles > pi/2 (diffusion is symmetric along the eigenvector axis)
pddErr(pddErr>pi/2) = pi/2-(pddErr(pddErr>pi/2)-pi/2);
% Make the error function flat within the PDD angular tolerance region
pddTol = pddToleranceDeg./180.*pi;
pddErr = (pddErr-pddTol);
pddErr(pddErr<0) = 0;
pddErr = pddErr./(pi/2-pddTol);
pddErr(isnan(pddErr)) = 1;


%% Compute FA Error term
[fa,md] = dtiComputeFA(eigVal);
%faErr = targetMinFa-fa;
% % Voxels > the target min get zero error.
%faErr(faErr<0) = 0;
%faErr(faErr>targetMinFa) = targetMinFa;
%faErr = faErr./targetMinFa;
faErr = zeros(size(fa));
faErr(fa<targetFa(1)) = (targetFa(1)-fa(fa<targetFa(1)))./targetFa(1);
faErr(fa>targetFa(2)) = (fa(fa>targetFa(2))-targetFa(2))./targetFa(2);
faErr(faErr>1) = 1;
faErr(isnan(faErr)) = 1;

% things with bogus fa>=1 values are always bad
faErr(fa>=1) = 1;

%% Compute MD Error term
% TODO: ensure md is in micrometers^2/msec!
mdErr = zeros(size(md));
mdErr(md<targetMd(1)) = (targetMd(1)-md(md<targetMd(1)))./targetMd(1);
mdErr(md>targetMd(2)) = (md(md>targetMd(2))-targetMd(2))./targetMd(2);
mdErr(mdErr>1) = 1;
mdErr(isnan(mdErr)) = 1;

%% Compute location prior from a template
ccLocPriorNi = niftiRead(templateFile);
sz = size(faErr);
xf = ccLocPriorNi.qto_ijk*xform;
[sampZ,sampY] = meshgrid(1:sz(2),1:sz(1));
sampY = sampY(:); sampZ = sampZ(:); 
coords = mrAnatXformCoords(xf,[ones(size(sampY)) sampY sampZ]);
ccLocPrior = interp2(double(squeeze(ccLocPriorNi.data)),coords(:,3),coords(:,2));
ccLocPrior = reshape(ccLocPrior,sz);
ccLocPrior(isnan(ccLocPrior)) = 0;
ccLocPrior = imblur(ccLocPrior,9);
%ccLocPrior = imfilter(ccLocPrior,fspecial('disk',5),'replicate');
ccLocPriorThresh = ccLocPrior;
ccLocPriorThresh(ccLocPriorThresh>0.1) = 0.1;
ccLocPriorThresh = ccLocPriorThresh./0.1;

%% Compute the b0 error.
% Since the b0 intensity scale is arbitrary, we'll use the info we have so
% far to get an empirical estimate of the desired b0 range. We assume that
% the b0 within the target region is roughly uniform, a safe assumption
% for all white matter regions. 
%
% The b0 adds an important check against artifacts, since certain common
% anatomical features (such as large sinuses) create very low b0 values,
% but the FA is high and MD is often within the normal tissue range. 
%
% Get an initial estimate based on fa, md, pdd and location prior
img = (1-faErr).*(1-mdErr).*(1-pddErr).*ccLocPriorThresh;
ccGuess = img>finalThresh*0.95;
[imgLabel,numObjects] = bwlabeln(ccGuess, 8);
if(numObjects>1)
    [imgHist,labelNum] = hist(imgLabel(:),0:numObjects);
    largestObjectLabel = labelNum(imgHist==max(imgHist(2:end)));
    ccGuess = imgLabel==largestObjectLabel(1);
    clear imgHist labelNum;
end
clear imgLabel;
mnB0 = mean(msB0(ccGuess(:)));
stdB0 = std(msB0(ccGuess(:)));
% b0Err is essentially a z-score clipped at ~4SDs and normalized to the 0-1
% range. We clip and normalize symmetrically (with 'abs').
b0Err = abs((msB0-mnB0)./stdB0);
b0Err(b0Err>5) = 5;
b0Err = b0Err-1;
b0Err(b0Err<0) = 0;
b0Err = b0Err./4;

%% Compute the final score
% Note that FA votes twice
img = (1-faErr).*(1-faErr).*(1-mdErr).*(1-pddErr).*(1-b0Err).*ccLocPriorThresh;
ccEst = img>finalThresh;

[imgLabel,numObjects] = bwlabeln(ccEst, 8);
% Clean up the mask by removing satelites.
if(numObjects>1)
    % We find the largest object and assume everything else is a satelite.
    % *** We might want to check the size of the next largest object to
    % make sure it isn't another part of the callosum.
    [imgHist,labelNum] = hist(imgLabel(:),0:numObjects);
    % we skip the first bin, since it is full of all the zeros
    imgHist = imgHist(2:end);
    labelNum = labelNum(2:end);
    % Sort so that largest objects are first
    [imgHist,ind] = sort(imgHist,'descend');
    labelNum = labelNum(ind);
    if(numObjects>2 && imgHist(2)>imgHist(1)*0.10)
        % If the next-largest is big (>10% of largest), then take both
        ccEst = imgLabel==labelNum(1) | imgLabel==labelNum(2);
    else
        % otherwise just take the largest
        ccEst = imgLabel==labelNum(1);
    end
    clear imgHist labelNum;
end
clear imgLabel;
% Fill holes
ccEst = imfill(ccEst,'holes');
    
%% SHOW RESULTS FIGURE
if(showFigs||~isempty(sumFigFileName))
    if(~isempty(figNum))
        fh = figure(figNum);
    else
        fh = figure;
    end
    subplot(3,3,1);imagesc(pddErr');colormap gray; axis equal tight xy off; title('PDD error');
    subplot(3,3,2);imagesc(faErr');colormap gray; axis equal tight xy off; title('FA error');
    subplot(3,3,3);imagesc(mdErr');colormap gray; axis equal tight xy off; title('MD error');
    subplot(3,3,4);imagesc(b0Err');colormap gray; axis equal tight xy off; title('b0 error');
    subplot(3,3,5);imagesc(ccLocPriorThresh');colormap gray; axis equal tight xy off; title('Location prior');
    subplot(3,3,6);imagesc(img');colormap gray; axis equal tight xy off; title('Final score');
    r = clip(fa'); g = r; b = r;
    r(ccEst') = 0.7*r(ccEst')+0.3; g(ccEst') = 0.7*g(ccEst'); b(ccEst') = 0.7*b(ccEst');
    subplot(3,3,7);image(cat(3,r,g,b));axis equal tight xy off; title('CC on FA');
    r = clip([md./max(md(:))]'); g = r; b = r;
    r(ccEst') = 0.7*r(ccEst')+0.3; g(ccEst') = 0.7*g(ccEst'); b(ccEst') = 0.7*b(ccEst');
    subplot(3,3,8);image(cat(3,r,g,b));axis equal tight xy off; title('CC on MD');
    r = clip([msB0./max(msB0(:))]'); g = r; b = r;
    r(ccEst') = 0.7*r(ccEst')+0.3; g(ccEst') = 0.7*g(ccEst'); b(ccEst') = 0.7*b(ccEst');
    subplot(3,3,9);image(cat(3,r,g,b));axis equal tight xy off; title('CC on b0');
    if(~isempty(sumFigFileName))
        [p,f,e] = fileparts(sumFigFileName);
        set(fh,'name',f);
        pause(1);
        mrUtilPrintFigure(sumFigFileName,fh,300);
    end
    %if(~showFigs) close(fh); end
end

if(~useLevelSet)
    [ccY,ccZ] = ind2sub(size(img),find(ccEst));
    ms = [midSag+thick]; ms = ms(:);
    msImg = inv(xform)*[ms ones(length(ms),3)]';
    msImg = msImg(1,:)';
    ccCoords(:,2:3) = repmat([ccY,ccZ],length(msImg),1);
    msImg = repmat(msImg',length(ccY),1);
    ccCoords(:,1) = msImg(:);
    ccCoords = mrAnatXformCoords(xform, ccCoords);
else
    % Level-set stuff to find the boundaries.
    % The segmentation is usually good enough that we don't need this.
    lsImg = img.*255;
    sigma=1.1;    % scale parameter in Gaussian kernel for smoothing. (1.5)
    G=fspecial('gaussian',15,sigma);
    imgSmooth=conv2(lsImg,G,'same');  % smooth image by Gaussiin convolution
    [ix,iy]=gradient(imgSmooth);
    f=ix.^2+iy.^2;
    g=1./(1+f);  % edge indicator function.
    epsilon=1.5; % the paramater in the definition of smoothed Dirac function
    timestep=5;  % time step
    mu=0.2/timestep;  % coefficient of the internal (penalizing) energy term P(\phi)
    % Note: the product timestep*mu must be less than 0.25 for stability!
    lambda=5; % coefficient of the weighted length term Lg(\phi)
    alf=1.5;  % coefficient of the weighted area term Ag(\phi);
    % Note: Choose a positive(negative) alf if the initial contour is outside(inside) the object.

    % define initial level set function (LSF) as -c0, 0, c0 at points outside, on
    % the boundary, and inside of a region R, respectively.
    c0 = 4;
    initialLSF = -c0*double(imblur(ccLocPrior,9)>0.01);
    initialLSF(initialLSF>0) = c0;

    u = initialLSF;
    figure;imagesc(lsImg);colormap(gray); axis equal tight xy off; hold on;
    [c,h] = contour(u,[0 0],'r');
    title('Initial contour');

    % start level set evolution
    for n=1:500
        u=mrUtilLevelSet(u, g ,lambda, mu, alf, epsilon, timestep, 1);
        if mod(n,20)==0
            pause(0.001);
            imagesc(lsImg);colormap(gray); axis equal tight xy off; hold on;
            [c,h] = contour(u,[0 0],'r');
            iterNum=[num2str(n), ' iterations'];
            title(iterNum);
            hold off;
        end
    end
    imagesc(lsImg);colormap(gray); axis equal tight xy off; hold on;
    [c,h] = contour(u,[0 0],'r');
    totalIterNum=[num2str(n), ' iterations'];
    title(['Final contour, ', totalIterNum]);
end

return;


%% CODE USED TO RUN THIS FUNCTION ON A BUNCH OF DATASETS
%
bd = '/biac3/wandell4/data/reading_longitude/dti_y4';
d = dir(fullfile(bd,'*'));
figNum = figure;
for(ii=1:length(d))
    fn = fullfile(bd,d(ii).name,['rawDti_aligned_dt6.mat']);
    if(d(ii).isdir && exist(fn,'file'))
        imFn = fullfile('/teal/scr1/ccCheck',['CC_' d(ii).name '_mrd.png']);
        roiFn = fullfile(bd,d(ii).name,'ROIs','CC');
        dt = load(fn);
        figure(figNum);
        set(figNum,'name',d(ii).name);
        ccCoords = dtiFindCallosum(dt.dt6,dt.b0,dt.xformToAcPc,[],imFn,figNum);
        roi = dtiNewRoi('CC','c',ccCoords);
        dtiWriteRoi(roi, roiFn);
    end
end




%% CODE USED TO GENERATE CC TEMPLATE
%
bd = '/biac2/wandell2/data/reading_longitude/dti';
d = dir(fullfile(bd,'*'));
n = 0;
for(ii=1:length(d))
    if(d(ii).isdir && exist(fullfile(bd,d(ii).name,'ROIs','CC_FA.mat'),'file'))
        n = n+1;
        tmp = load(fullfile(bd,d(ii).name,'ROIs','CC_FA.mat'));
        cc{n} = tmp.roi.coords;
    end
end
bd = '/biac2/wandell2/data/reading_longitude/dti_adults';
d = dir(fullfile(bd,'*'));
for(ii=1:length(d))
    if(d(ii).isdir && exist(fullfile(bd,d(ii).name,'ROIs','CC_FA.mat'),'file'))
        n = n+1;
        tmp = load(fullfile(bd,d(ii).name,'ROIs','CC_FA.mat'));
        cc{n} = tmp.roi.coords;
    end
end

%bb = dtiGet(0,'defaultbb');
bb = [0 -60 -20; 0 50 50];
ccProbImg = zeros(diff(bb)+1);
ccProbXform = [diag([1 1 1]) [bb(1,:)-1]';[0 0 0 1]];
sz = size(ccProbImg);
for(ii=1:n)
    c = cc{ii}(cc{ii}(:,1)==0,:);
    imC = round(mrAnatXformCoords(inv(ccProbXform),c));
    inds = sub2ind(sz,imC(:,1),imC(:,2),imC(:,3));
    inds = unique(inds);
    tmp = zeros(sz);
    tmp(inds) = 1;
    tmp = dtiSmooth3(tmp,5);
    ccProbImg = ccProbImg+double(tmp);
end
ccProbImg = ccProbImg./max(ccProbImg(:));
figure;imagesc(squeeze(ccProbImg));colormap gray; axis equal tight; colorbar;
notes = sprintf('AC-PC space location prior for the corpus callosum, computed from hand-defined ROIs in %d subjects (children and adults)',n); 
dtiWriteNiftiWrapper(single(ccProbImg), ccProbXform, '/home/bob/cvs/VISTASOFT/mrDiffusion/templates/corpusCallosum.nii.gz',1,notes);

