function figHandle = dtiRenderAdcEllipsoids(adcNi, coords, figName, plotType)
% Should become obsolete.
% Fit a tensor to the ADC data; displays ellipsoid and the raw ADC values.
%
% dtiH = dtiRenderAdcEllipsoids(adcFileOrNifti, acpcCoords, [figName], [plotType='adcProfile'])
%
% NOTE:  I think this only works properly with a dt6 structure.  More needs
% to be done to make it work with an ADC data set. (BW).
%
% Fits a tensor to the ADC data and displays the resulting ellipsoid,
% along with the raw ADC values.
%
% If adcFileOrData is 
%  - a string, it is should be a NIFTI filename containing the  ADC data.
%  - isnumeric(adcNi) && size(adcNi,4)==6, then it is a dt6 struct
%  - a NIFTI struct with adcNi.data, adcNi.bvals, and adcNi.bvecs.
%
% NIFTI doesn't yet have a DTI header extension, so we need to get the
% bvecs- a 3xM list of diffusion gradient directions where M = the number
% of ADC volumes in the dataset. Again, if this is a string, it is assumed
% to be a filename pointing to an FSL-style bvecs file (space-delimited
% text file).
%
% acpcCoords is an Nx3 list of acpc coords to analyze. If N>1, the adc
% values will be averaged. The NIFTI qform will be used to convert acpc
% space to image space.
%
% plotType options currently include: 
%   'adcProfile'
%   'diffusionEllipsoid'
%
% Returns the figure handle.
%
% Example:
%    adcNiFile= fullfile(mrvDataRootPath,'diffusion','sampleData','raw','dwi.nii.gz');
%    [X,Y,Z] = meshgrid(40:2:50,40:2:50,40:2:50); 
%    coords = [X(:),Y(:),Z(:)];
%    dtiRenderAdcEllipsoids(adcNiFile, coords);
%
% NOTE: we don't need the full ADC dataset to just show the diffusion
% ellipsoid. We only need that if we want to show the adc points as well.
% So if you just want the ellipsoid, you can pass a dt6 array in place of
% the adcNi and pass the acpc-to-image xform in bvecs.
%
% HISTORY:
% 2007.01.02 RFD: wrote it, based on a draft by BAW.
%
% (c) Stanford VISTA Team 2007

% This will double the number of ADC points by reflection. It's useful for
% visually 'filling-out' sparse and/or clustered gradient dirs.
reflectADCs = false;

% This file is supposed to have bvals and bvecs.  Most don't.  That
% produces and error.  We should use the routine loadRawADC inside of
% dtiFiberUI and attach the values to the adcNI here. - BW
if(ischar(adcNi)), adcNi = niftiRead(adcNi); end

if(~exist('plotType','var')||isempty(plotType))
    % options include: adcProfile, diffusionEllipsoid
    plotType = 'diffusionEllipsoid';
end

if(~exist('figName','var') || isempty(figName)), figName = ''; end

if(isnumeric(adcNi) && size(adcNi,4)==6)
    % Then it's a dt6 array.
    dt6vals = zeros(size(coords,1),6);
    for ii=1:size(coords,1)
        dt6vals(ii,:) = squeeze(adcNi(coords(ii,1),coords(ii,2),coords(ii,3),:));
    end
    coef = mean(dt6vals,1);
    D = [coef(1) coef(4) coef(5); coef(4) coef(2) coef(6); coef(5) coef(6) coef(3)];
    if(plotType(1)~='d')
        warning('When passing a dt6 array, you can only plot the diffusion ellipsoid.');
        plotType = 'd';
    end
else
    % It's a raw DWI NIFTI struct- prep the ADC data
    % I don't think this code works properly yet (BW).

    % nadc = size(adcNi.data,4);
    roiRaw = zeros(size(coords,1),adcNi.dim(4));
    for ii=1:size(coords,1)
        roiRaw(ii,:) = squeeze(adcNi.data(coords(ii,1),coords(ii,2),coords(ii,3),:));
    end
    
    % Nifti structs don't always have bvals.  Where does this come from?
    dwInds = (adcNi.bvals > 0);
    mnRoiRaw = mean(double(roiRaw),1)';
    
    % Fit the Stejskal-Tanner equation: S(b) = S(0) exp(-b ADC),
    % where S(b) is the image acquired at non-zero b-value, and S(0) is
    % the image acquired at b=0. We find the ADC value from S(b) and b as
    %
    %       ADC = -1/b * log( S(b) / S(0) )
    %
    % To avoid divide-by-zero, we need to add a small offset to
    % S(0). We need a small offset to avoid log(0).
    offset = 1e-6;
    logB0 = mean(log(mnRoiRaw(~dwInds) + offset));
    logDw = log(mnRoiRaw(dwInds) + offset);
    mnRoiAdc = -1./adcNi.bvals(dwInds)'.*(logDw-logB0);
    %mnRoiAdc = -1./adcNi.bvals(dwInds)*log(mnRoiRaw(dwInds)./(mnRoiB0+offset)+offset);

    % The bvecs are unit vectors in three space.
    % plot3(bvecs(1,:),bvecs(2,:),bvecs(3,:),'.'); axis equal

    % Compute the diffusion tensor D using a least-squares fit.
    % See, e.g., http://sirl.stanford.edu/dti/maj/
    bvecs = adcNi.bvecs(:,dwInds);
    bv = bvecs';
    m = [bv(:,1).^2 bv(:,2).^2 bv(:,3).^2 2*bv(:,1).*bv(:,2) 2*bv(:,1).*bv(:,3) 2*bv(:,2).*bv(:,3)];
    coef = pinv(m)*mnRoiAdc;
    D = [coef(1) coef(4) coef(5); coef(4) coef(2) coef(6); coef(5) coef(6) coef(3)];

    % Compute the error of the predicted ADC based on the tensor model.
    % This can also be calculated with v*D*v', where v is a 1x3 grad dir
    pADC = m*coef;
    adcError = pADC - mnRoiAdc;
    fprintf('RMS ADC error from tensor model: %g.\n',sqrt(sum(adcError.^2)));
    %figure;
    %plot3(dirADC(:,1),dirADC(:,2),dirADC(:,3),'k.',pDirADC(:,1),pDirADC(:,2),pDirADC(:,3),'r.')
    %axis equal; grid on;
    
    if(plotType(1)=='d')
      for ii=1:length(mnRoiAdc)
        dirADC(ii,:) = [bvecs(:,ii).*sqrt(mnRoiAdc(ii))]';
	%pu(ii) = dirADC(:,ii)'*D*dirADC(:,ii);
      end
        %dirADC = [bvecs/diag(sqrt(mnRoiAdc))];
        %pDirADC = [bvecs*diag(sqrt(2*pADC))]';
    elseif(plotType(1)=='a')
        % Plot raw ADC values for an adcProfile plot
        dirADC = (bvecs*diag(mnRoiAdc))';
        % pDirADC = (bvecs*diag(pADC))';
    end
end

%% Compute the diffusion distance ellipsoid

% This ellipsoid defines a surface of constant mean-squared displacement of
% the spin-labeled protons at time T (the mean squared diffusion distance
% of the protons over time T). The length of each of the ellipsoid axes is
% sqrt(2*lambda_i*T), where lambda_i is the eigenvalue for that axis and T
% is the diffusion time. Since the ADCs are per unit time, we set T to 1.
% (See, e.g., Le Bihan et. al. 2001, JMRI and Basser et. al. BiophysJ 1994)

% First make unit sphere vectors in the rows of u.
[x,y,z] = sphere(32);
sz = size(x);
u = [x(:), y(:), z(:)];

% scale the unit vectors according to the eigensystem of D to make the
% ellipsoid.  val is a diagonal matrix with the eigenvalues of the
% diffusion tensor, D.  The columns of vec are the eigenvectors.
[vec,val] = eig(D);


% From the code below, we see that the eigenvalues of D are related to the
% ADC values by sqrt(2*lambda_i).  When u is in the principal direction,
% the ADC is sqrt(2*val).  More notes needed here.  We should understand
% this from Bob somewhere.  The relationship between D and the ADC is in a
% formula somewhere, probably in dtiInit.  (dtiFitTensor)
if plotType(1) == 'd'
    % diffusion distance ellipsoid axis lengths = sqrt(2*lambda_i*T); here
    % T=1 Scale the eigenvectors in the columns of vec by sqrt(2*lambda_i).
    % Project the set of unit vectors (u) onto these scaled vectors.
    e = u*sqrt(2*val)*vec';
elseif plotType(1 == 'a')
    % Compute the predicted ADC for each of the unit sphere points
    sphAdc = zeros(size(u,1),1);
    for ii=1:size(u,1)
        sphAdc(ii) = u(ii,:)*D*u(ii,:)';
    end
    e = diag(sphAdc)*u;  %Unit vectors in the rows.  Each row scaled.
end

% Now reshape and plot
x = reshape(e(:,1),sz); 
y = reshape(e(:,2),sz); 
z = reshape(e(:,3),sz);
 
figHandle = figure;
set(figHandle,'Name',figName);
cmap = autumn(255);
surf(x,y,z,repmat(256,size(z)),'EdgeAlpha',0.1);
axis equal, colormap([cmap; .25 .25 .25]), alpha(0.5)

camlight;
lighting phong;
material shiny;
set(gca, 'Projection', 'perspective');
axLen = diag(D)*2+.2;
hold on;
line([0;axLen(1)],[0;0],[0;0],'Color','r','LineWidth',2);
line([0;0],[0;axLen(2)],[0;0],'Color','g','LineWidth',2);
line([0;0],[0;0],[0;axLen(3)],'Color','b','LineWidth',2);
axis off vis3d; grid off;
%scatter3(dirADC(:,1),dirADC(:,2),dirADC(:,3),24,cmap(errInd,:),'.'); 
hold off

if(plotType(1)=='a')
    % Add the points
    if(reflectADCs)
        dirADC = [dirADC; -1*dirADC];
        adcError = [adcError; adcError];
    end
    errInd = abs(adcError); errInd = round(errInd./max(errInd).*(size(cmap,1)-1)+1);
    hold on;
    for(ii=1:length(errInd))
        [sx sy sz] = ellipsoid(dirADC(ii,1),dirADC(ii,2),dirADC(ii,3),.02,.02,.02,8);
        surf(sx,sy,sz,repmat(errInd(ii),size(sz)),'EdgeAlpha',0);
    end
    hold off;
    maxErr = max(abs(adcError));
    labelNum = linspace(0,maxErr,5);
    for(ii=1:5) label{ii} = sprintf('%0.2f',labelNum(ii)); end
    axHandle = axes('position',[0.64 0.02 .35 .20]);
    mrUtilMakeColorbar(autumn(254),label,'ADC error (\mum^2/msec)','',figHandle,axHandle);
elseif(plotType(1)=='d' && exist('pADC','var'))
    % Add the points
    if(reflectADCs)
        dirADC = [dirADC; -1*dirADC];
        adcError = [adcError; adcError];
    end
    errInd = abs(adcError); errInd = round(errInd./max(errInd).*(size(cmap,1)-1)+1);
    hold on;
    for(ii=1:length(errInd))
        [sx sy sz] = ellipsoid(dirADC(ii,1),dirADC(ii,2),dirADC(ii,3),.05,.05,.05,8);
        surf(sx,sy,sz,repmat(errInd(ii),size(sz)),'EdgeAlpha',0);
    end
    hold off;
    maxErr = max(abs(adcError));
    labelNum = linspace(0,maxErr,5);
    for(ii=1:5) label{ii} = sprintf('%0.2f',labelNum(ii)); end
    axHandle = axes('position',[0.64 0.02 .35 .20]);
    mrUtilMakeColorbar(autumn(254),label,'ADC error (\mum^2/msec)','',figHandle,axHandle);
end

%mrUtilPrintFigure(figName);
return;
